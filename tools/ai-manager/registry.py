#!/usr/bin/env python3
"""
Build, search, and audit your model registry.

Usage:
    python registry.py build
    python registry.py search --type lora --base sdxl
    python registry.py search --text "dreamshaperXL"
    python registry.py audit
    python registry.py audit --unused-days 90
    python registry.py info checkpoints/sdxl/dreamshaperXL_v21.safetensors
    python registry.py status checkpoints/sdxl/old_model.safetensors archived
    python registry.py stats
"""

import argparse, json, logging, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

log.info("Loading config...")
from config import AI_MODELS_ROOT, MODEL_TYPE_FOLDERS, BASE_MODELS, MODEL_EXTENSIONS
log.info(f"AI_MODELS_ROOT = {AI_MODELS_ROOT}")

REGISTRY_FILE = AI_MODELS_ROOT / "_registry" / "registry.json"


# ─── helpers ─────────────────────────────────────────────────────────────────

def find_models(root=AI_MODELS_ROOT):
    log.info(f"Scanning {root} for model files...")
    log.info(f"Looking for extensions: {MODEL_EXTENSIONS}")
    out = []
    for ext in MODEL_EXTENSIONS:
        found = list(root.rglob(f"*{ext}"))
        if found:
            log.info(f"  {ext}: {len(found)} files")
        out.extend(found)
    result = sorted(p for p in out if "_registry" not in p.parts)
    log.info(f"Total model files found: {len(result)}")
    return result


def rel(p):
    return str(p.relative_to(AI_MODELS_ROOT))


def size_mb(p):
    return p.stat().st_size / (1024 * 1024)


def fmt(mb):
    return f"{mb/1024:.1f} GB" if mb >= 1024 else f"{mb:.0f} MB"


def sidecar_path(model_path):
    return model_path.with_suffix(model_path.suffix + ".json")


def load_sidecar(p):
    sc = sidecar_path(p)
    if sc.exists():
        try:
            return json.loads(sc.read_text())
        except json.JSONDecodeError as e:
            log.warning(f"Corrupt sidecar {sc}: {e}")
            return None
    return None


def load_registry():
    log.info(f"Loading registry from {REGISTRY_FILE}...")
    if REGISTRY_FILE.exists():
        try:
            reg = json.loads(REGISTRY_FILE.read_text())
            log.info(f"Registry loaded: {len(reg.get('models', []))} models")
            return reg
        except json.JSONDecodeError as e:
            log.warning(f"Corrupt registry file: {e}")
    else:
        log.info("No registry file found, starting empty")
    return {"models": []}


def save_registry(reg):
    log.info(f"Saving registry to {REGISTRY_FILE}...")
    REGISTRY_FILE.parent.mkdir(parents=True, exist_ok=True)
    REGISTRY_FILE.write_text(json.dumps(reg, indent=2))
    log.info("Registry saved OK")


# ─── commands ────────────────────────────────────────────────────────────────

def cmd_build(_args):
    models = find_models()
    entries, orphans = [], 0
    for p in models:
        sc = load_sidecar(p)
        entry = {"path": rel(p), "size_mb": round(size_mb(p), 1)}
        if sc:
            entry.update(sc)
        else:
            orphans += 1
            log.debug(f"No sidecar: {rel(p)}")
            entry["local"] = {"status": "untracked"}
        entries.append(entry)

    log.info(f"Indexed {len(entries)} models, {orphans} without sidecars")
    reg = {"models": entries, "built": datetime.now(timezone.utc).isoformat()}
    save_registry(reg)
    total = sum(e["size_mb"] for e in entries)
    print(f"Registry built: {len(entries)} models ({fmt(total)}), {orphans} untracked")


def cmd_search(args):
    reg = load_registry()
    results = reg["models"]
    if not results:
        sys.exit("Registry empty — run 'build' first.")

    if args.type:
        log.info(f"Filtering by type: {args.type}")
        results = [m for m in results if m.get("model", {}).get("type") == args.type]
    if args.base:
        log.info(f"Filtering by base: {args.base}")
        results = [m for m in results if m.get("model", {}).get("base_model") == args.base]
    if args.tag:
        log.info(f"Filtering by tag: {args.tag}")
        t = args.tag.lower()
        results = [m for m in results if t in [x.lower() for x in m.get("model", {}).get("tags", [])]]
    if args.status:
        log.info(f"Filtering by status: {args.status}")
        results = [m for m in results if m.get("local", {}).get("status") == args.status]
    if args.text:
        log.info(f"Filtering by text: {args.text}")
        t = args.text.lower()
        results = [m for m in results if t in json.dumps(m).lower()]

    if not results:
        print("No matches.")
        return

    print(f"{len(results)} result(s):\n")
    for m in results:
        status = m.get("local", {}).get("status", "?")
        src = m.get("source", {}).get("repo_id", "") if m.get("source") else ""
        tags = ", ".join(m.get("model", {}).get("tags", []))
        print(f"  [{status}] {m['path']}  ({fmt(m.get('size_mb', 0))})")
        if src:
            print(f"         source: {src}")
        if tags:
            print(f"         tags: {tags}")
        notes = m.get("local", {}).get("notes", "")
        if notes:
            print(f"         notes: {notes[:80]}")
        print()


def cmd_audit(args):
    models = find_models()
    orphans, stale = [], []
    total = 0
    cutoff = None
    if args.unused_days:
        cutoff = datetime.now(timezone.utc) - timedelta(days=args.unused_days)
        log.info(f"Stale cutoff: unused since {cutoff.date()}")

    for p in models:
        s = size_mb(p)
        total += s
        sc = load_sidecar(p)
        if not sc:
            orphans.append((rel(p), s))
            continue
        if cutoff:
            lu = sc.get("local", {}).get("last_used")
            if not lu:
                stale.append((rel(p), s, "never"))
            else:
                try:
                    if datetime.fromisoformat(lu) < cutoff:
                        stale.append((rel(p), s, lu))
                except ValueError:
                    pass

    print(f"Total: {len(models)} models, {fmt(total)}")
    print(f"Tracked: {len(models) - len(orphans)}, Untracked: {len(orphans)}\n")

    if orphans:
        print("UNTRACKED (no sidecar):")
        for path, s in orphans:
            print(f"  {fmt(s):>8}  {path}")
        print(f"  Total: {fmt(sum(s for _, s in orphans))}")
        print(f"  Fix: use dl_model.py --existing <path> to create sidecars\n")

    if stale:
        print(f"STALE (unused >{args.unused_days} days):")
        for path, s, lu in sorted(stale, key=lambda x: x[1], reverse=True):
            print(f"  {fmt(s):>8}  {path}  (last used: {lu})")
        print(f"  Total: {fmt(sum(s for _, s, _ in stale))}\n")

    if not orphans and not stale:
        print("Everything looks clean.")


def cmd_info(args):
    p = AI_MODELS_ROOT / args.path
    log.info(f"Looking up {p}")
    if not p.exists():
        log.error(f"File not found: {p}")
        sys.exit(1)
    sc = load_sidecar(p)
    print(f"File: {args.path}  ({fmt(size_mb(p))})\n")
    if not sc:
        sys.exit("No sidecar. Create one with dl_model.py --existing")
    print(json.dumps(sc, indent=2))


def cmd_status(args):
    p = AI_MODELS_ROOT / args.path
    sp = sidecar_path(p)
    log.info(f"Updating status for {p}")
    if not sp.exists():
        log.error(f"No sidecar found at {sp}")
        sys.exit(1)
    sc = json.loads(sp.read_text())
    old = sc.get("local", {}).get("status", "?")
    sc.setdefault("local", {})["status"] = args.new_status
    if args.new_status == "archived":
        sc["local"]["keep"] = False
    sp.write_text(json.dumps(sc, indent=2))
    log.info(f"Sidecar updated: {sp}")
    print(f"{args.path}: {old} -> {args.new_status}")


def cmd_stats(_args):
    reg = load_registry()
    models = reg["models"]
    if not models:
        sys.exit("Registry empty — run 'build' first.")
    total = sum(m.get("size_mb", 0) for m in models)

    print(f"Total: {len(models)} models, {fmt(total)}\n")

    for label, key in [("By type", "type"), ("By base", "base_model")]:
        groups = {}
        for m in models:
            v = m.get("model", {}).get(key, "unknown") or "unknown"
            groups.setdefault(v, []).append(m)
        print(f"{label}:")
        for k in sorted(groups):
            items = groups[k]
            print(f"  {k:>15}: {len(items):>3}  ({fmt(sum(m.get('size_mb',0) for m in items))})")
        print()

    by_status = {}
    for m in models:
        s = m.get("local", {}).get("status", "unknown") or "unknown"
        by_status[s] = by_status.get(s, 0) + 1
    print("By status:")
    for s in sorted(by_status):
        print(f"  {s:>15}: {by_status[s]}")


# ─── main ────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(description="Model registry.")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("build")

    s = sub.add_parser("search")
    s.add_argument("--type", choices=MODEL_TYPE_FOLDERS.keys())
    s.add_argument("--base", choices=BASE_MODELS)
    s.add_argument("--tag")
    s.add_argument("--status")
    s.add_argument("--text")

    a = sub.add_parser("audit")
    a.add_argument("--unused-days", type=int)

    i = sub.add_parser("info")
    i.add_argument("path")

    st = sub.add_parser("status")
    st.add_argument("path")
    st.add_argument("new_status", choices=["active", "archived", "deprecated"])

    sub.add_parser("stats")

    args = p.parse_args()
    if not AI_MODELS_ROOT.exists():
        log.error(f"Models root not found: {AI_MODELS_ROOT}")
        sys.exit(f"Set AI_MODELS_ROOT env var or edit config.py")

    {"build": cmd_build, "search": cmd_search, "audit": cmd_audit,
     "info": cmd_info, "status": cmd_status, "stats": cmd_stats}[args.cmd](args)


if __name__ == "__main__":
    main()
