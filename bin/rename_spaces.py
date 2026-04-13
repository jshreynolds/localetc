#!/usr/bin/env python3
"""
Rename all files and folders in the vault, replacing spaces with underscores.
Then update all wikilinks and markdown links in .md files.
"""
import os
import re
from pathlib import Path

VAULT = Path("/Users/jreynolds/Documents/vault")

def get_all_items_with_spaces():
    """Get all files and dirs with spaces, sorted deepest first."""
    items = []
    for item in VAULT.rglob("*"):
        # Skip .obsidian and the script itself
        if ".obsidian" in item.parts:
            continue
        if item.name == "rename_spaces.py":
            continue
        if " " in item.name:
            items.append(item)
    # Sort by depth (deepest first) so children are renamed before parents
    items.sort(key=lambda p: len(p.parts), reverse=True)
    return items

def build_rename_map(items):
    """
    Build mapping of old stem -> new stem for .md files.
    Also build mapping of old full path -> new full path for all items.
    """
    md_stem_map = {}   # old_stem -> new_stem (for wikilink updates)
    path_pairs = []    # (old_path, new_path) for actual renames

    for item in items:
        new_name = item.name.replace(" ", "_")
        new_path = item.parent / new_name
        path_pairs.append((item, new_path))

        if item.is_file() and item.suffix == ".md":
            old_stem = item.stem
            new_stem = new_name[:-3]
            if old_stem != new_stem:
                md_stem_map[old_stem] = new_stem

    return path_pairs, md_stem_map

def build_path_stem_map(path_pairs):
    """
    Build a map for updating markdown-style path links.
    Maps old relative path fragments to new ones.
    """
    path_map = {}
    for old_path, new_path in path_pairs:
        old_rel = str(old_path.relative_to(VAULT))
        new_rel = str(new_path.relative_to(VAULT))
        path_map[old_rel] = new_rel
    return path_map

def rename_items(path_pairs):
    """Rename all items, deepest first."""
    renamed = 0
    for old_path, new_path in path_pairs:
        if old_path.exists() and old_path != new_path:
            old_path.rename(new_path)
            renamed += 1
            print(f"  renamed: {old_path.relative_to(VAULT)}")
            print(f"       -> {new_path.relative_to(VAULT)}")
    return renamed

def update_links(md_stem_map, path_map):
    """Update all wikilinks and markdown links in .md files."""
    updated_files = 0

    for md_file in sorted(VAULT.rglob("*.md")):
        if ".obsidian" in md_file.parts:
            continue
        if md_file.name == "rename_spaces.py":
            continue

        try:
            content = md_file.read_text(encoding="utf-8")
        except Exception as e:
            print(f"  WARNING: Could not read {md_file}: {e}")
            continue

        original = content

        # Update wikilinks: [[Old Stem]], [[Old Stem#heading]], [[Old Stem|alias]]
        # Also handles path-style wikilinks: [[folder/Old Stem]]
        for old_stem, new_stem in md_stem_map.items():
            old_esc = re.escape(old_stem)
            # Match [[...Old Stem]] or [[...Old Stem#...]] or [[...Old Stem|...]]
            # The old_stem can be preceded by nothing or a path segment ending in /
            content = re.sub(
                r'(\[\[[^\]]*?)' + old_esc + r'([\]#|])',
                r'\g<1>' + new_stem + r'\2',
                content
            )

        # Update markdown-style links: [text](path/to/file name.md)
        # Sort by length descending to avoid partial replacements
        for old_rel, new_rel in sorted(path_map.items(), key=lambda x: len(x[0]), reverse=True):
            old_esc = re.escape(old_rel)
            content = re.sub(old_esc, new_rel.replace("\\", "/"), content)

        if content != original:
            md_file.write_text(content, encoding="utf-8")
            updated_files += 1
            print(f"  updated links: {md_file.relative_to(VAULT)}")

    return updated_files

def main():
    print("=== Step 1: Scanning for items with spaces ===")
    items = get_all_items_with_spaces()
    print(f"Found {len(items)} items with spaces in names")

    print("\n=== Step 2: Building rename map ===")
    path_pairs, md_stem_map = build_rename_map(items)
    path_map = build_path_stem_map(path_pairs)
    print(f"  {len(md_stem_map)} .md file stems to update in links")

    print("\n=== Step 3: Renaming files and folders ===")
    renamed = rename_items(path_pairs)
    print(f"\nRenamed {renamed} items")

    print("\n=== Step 4: Updating links in .md files ===")
    updated = update_links(md_stem_map, path_map)
    print(f"\nUpdated links in {updated} files")

    print("\n=== Done ===")

if __name__ == "__main__":
    main()
