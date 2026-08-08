# =============================================================================
# apps.nix — GUI applications, the NixOS counterpart to nix/darwin/homebrew.nix.
#
# There is no cask equivalent here, and none is needed: on Linux, nixpkgs
# packages GUI apps as well as it packages CLI tools, so an app is just another
# entry in environment.systemPackages. The whole reason the macs go through
# brew — GUI apps from nixpkgs are unreliable on macOS — does not apply.
#
# So the two files are parallel in ROLE, not in mechanism:
#
#   nix/darwin/homebrew.nix   shared cask list + hostCasks   -> `brew bundle`
#   nix/nixos/apps.nix        shared app list  + hostApps    -> nix store
#
# System-level (not home.packages) on purpose, to match the macs: casks are a
# nix-darwin system concern there, so apps are a NixOS system concern here.
#
# NOT EVERY CASK HAS A LINUX ANSWER. The mapping, including the gaps, is
# recorded inline below — a cask missing from this file should be findable here
# with the reason, rather than looking like an oversight.
#
# PREREQUISITE: these are apps, and nothing on the NixOS side draws a desktop
# yet — no display server, no compositor, no session. Installing them is
# harmless in the meantime, but they are only *usable* once a desktop module
# exists. See nix/home/linux/default.nix for the other half of that gap.
# =============================================================================
{
  pkgs,
  lib,
  username,
  hostApps ? [ ],
  ...
}:
{
  # 1Password is the one app that cannot be a plain package: the desktop app
  # needs a SUID wrapper and a polkit policy for system authentication and for
  # browser unlock to work. This module provides both; `polkitPolicyOwners` is
  # the list of users allowed to unlock it.
  programs._1password.enable = true; # the `op` CLI
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ username ];
  };

  environment.systemPackages =
    with pkgs;
    [
      # -- daily drivers --------------------------------------------------
      ghostty
      obsidian
      # (1password: see programs._1password-gui above)
      # (rectangle: no equivalent — window tiling is the compositor's job on
      #  Linux, so it arrives with the desktop module, not as an app)

      # -- browsers -------------------------------------------------------
      brave
      chromium
      firefox
      google-chrome

      # -- editors & IDEs ---------------------------------------------------
      vscode
      zed-editor

      # -- AI ---------------------------------------------------------------
      # These three are casks on macOS but ordinary CLIs from nixpkgs here.
      # They stay in THIS file rather than nix/home/packages.nix so the macs
      # keep getting them from brew — one installer per platform, no collision.
      claude-code
      codex
      github-copilot-cli
      lmstudio
      ollama # the CLI/server; there is no Linux build of the ollama desktop app
      # (chatgpt, claude desktop: macOS-only, no Linux build exists)
      # (comfy: not in nixpkgs — run ComfyUI from a project flake instead)

      # -- dev tools ----------------------------------------------------------
      google-cloud-sdk # `gcloud components` still can't self-update in the read-only
      # store, but unlike macOS there is no cask to escape to
      # (lens: x86_64-only, see the optionals block below)

      # -- misc --------------------------------------------------------------
      kdePackages.kdenlive
      # (adobe-creative-cloud, muesli: no Linux build)
      # (miro: nixpkgs `miro` is an unrelated PDF viewer, NOT the whiteboard —
      #  use the web app)
    ]
    ++
      # x86_64-only upstream: these ship prebuilt binaries with no aarch64 Linux
      # build, so listing them unconditionally would break the aarch64 host at
      # eval time.
      lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
        slack
        zoom-us
        microsoft-edge
        discord
        dropbox
        lens # the maintained Kubernetes IDE; openlens is not in nixpkgs
      ]
    ++
      # Host-specific apps, declared per machine in hosts/<hostname>/default.nix
      # (`apps`) as nixpkgs attribute NAMES — so that file reads like a darwin
      # host's `casks = [ "lulu" ]` instead of needing a `pkgs` in scope, which
      # plain data cannot have. Dotted names ("kdePackages.kdenlive") work.
      map (name: lib.getAttrFromPath (lib.splitString "." name) pkgs) hostApps;
}
