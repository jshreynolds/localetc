# =============================================================================
# packages.nix — every CLI tool and language runtime, from nixpkgs.
#
# Nix concept: `home.packages` is just a list of packages to put on PATH
# (via /etc/profiles/per-user/<username>/bin). Add a line, run `drs`, done.
# Find package names with:  nix search nixpkgs <thing>
#
# A few tools intentionally live in brew because nixpkgs doesn't carry them —
# see the `brews` list in nix/darwin/homebrew.nix.
#
# Tools where home-manager also manages config/shell-wiring (git, starship,
# fzf, neovim, ...) are NOT listed here — they live in programs.nix / git.nix,
# and their `programs.X.enable = true` installs the package too.
# =============================================================================
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # -- shell & files ---------------------------------------------------------
    bashInteractive # bash 5 (macOS ships ancient 3.2; zsh stays the login shell)
    coreutils # GNU userland (ls --color, etc.)
    fd # friendlier find
    duf # friendlier df
    dust # friendlier du
    mmv # mass rename
    ripgrep # rg
    rm-improved # rip: rm with a trash can
    rsync
    silver-searcher-ng # ag (maintained fork)
    zellij
    zsh-completions

    # -- vcs -----------------------------------------------------------------
    gh # package only; its self-modifying config stays a live symlink (dotfiles.nix)
    git-remote-gcrypt
    glab

    # -- dev tools -------------------------------------------------------------
    curlie
    d2
    difftastic
    graphviz
    httpie
    jq
    yq-go # mikefarah's Go yq (nixpkgs `yq` is a different python tool)
    pre-commit
    shellcheck
    tokei
    bashdb
    cowsay

    # -- lazy TUIs -------------------------------------------------------------
    lazygit
    lazydocker
    k9s

    # -- containers & kubernetes ----------------------------------------------
    colima # container runtime (docker context points here)
    docker-client # just the docker CLI — colima provides the engine
    docker-compose
    kubectl
    kubernetes-helm # the `helm` CLI
    minikube
    kafkactl
    kn

    # -- databases -------------------------------------------------------------
    mongodb-tools # mongodump/mongorestore etc.

    # -- cloud ---------------------------------------------------------------
    awscli2
    azure-cli
    terraform # unfree license (BUSL) — allowed by allowUnfree in core.nix

    # -- security --------------------------------------------------------------
    gnupg
    pinentry_mac

    # -- AI CLIs ---------------------------------------------------------------
    # NOTE: nixpkgs can lag fast-moving AI tools by days-to-weeks, and their
    # self-update commands can't write to the read-only store. If lag ever
    # hurts, move the offender to `brews` in homebrew.nix (one-line change).
    aichat
    gemini-cli
    llm
    opencode

    # -- apple dev ---------------------------------------------------------------
    xcbeautify
    xcodegen

    # -- language runtimes (deliberately lean) -----------------------------------
    # Only runtimes used ad-hoc at a shell prompt or for system scripting live
    # here. Project-specific toolchains (JVM, .NET, Ruby, ...) belong in a
    # per-project flake devshell + direnv (both enabled in programs.nix) — see
    # templates/ for ready-to-copy starters.
    go
    gopls
    nodejs # LTS line (was nodejs_latest: avoids silent major jumps on flake update)
    pnpm
    protobuf # protoc
    python314 # also load-bearing: flake `checks` compile/test the skills with this
    uv
    temporal-cli
    tilt

    # -- misc --------------------------------------------------------------------
    cheat
  ];
}
