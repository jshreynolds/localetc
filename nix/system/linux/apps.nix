# =============================================================================
# apps.nix — GUI applications, the NixOS counterpart to nix/system/darwin/homebrew.nix.
#
# There is no cask equivalent here, and none is needed: on Linux, nixpkgs
# packages GUI apps as well as it packages CLI tools, so an app is just another
# entry in environment.systemPackages. The whole reason the macs go through
# brew — GUI apps from nixpkgs are unreliable on macOS — does not apply.
#
# So the two files are parallel in ROLE, not in mechanism:
#
#   nix/system/darwin/homebrew.nix   shared cask list + hostCasks   -> `brew bundle`
#   nix/system/linux/apps.nix        shared app list  + hostApps    -> nix store
#
# System-level (not home.packages) on purpose, to match the macs: casks are a
# nix-darwin system concern there, so apps are a NixOS system concern here.
#
# These run in the GNOME session drawn by nix/system/linux/desktop.nix (display server,
# login manager, audio, printing) — the counterpart module to this one.
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
      alacritty
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

      # -- mail ---------------------------------------------------------------
      evolution

      # -- editors & IDEs ---------------------------------------------------
      zed-editor

      # -- AI ---------------------------------------------------------------
      # (claude-code, codex, github-copilot-cli: ordinary CLIs, and nixpkgs
      #  builds them on darwin too — so they moved to nix/home-manager/packages.nix and
      #  every machine gets them from one declaration)
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
        lens
      ]
    ++
      # Host-specific apps, declared per machine in hosts/<hostname>/default.nix
      # (`apps`) as nixpkgs attribute NAMES — so that file reads like a darwin
      # host's `casks = [ "lulu" ]` instead of needing a `pkgs` in scope, which
      # plain data cannot have. Dotted names ("kdePackages.kdenlive") work.
      map (name: lib.getAttrFromPath (lib.splitString "." name) pkgs) hostApps;
}
