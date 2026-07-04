# =============================================================================
# packages.nix — every CLI tool and language runtime, from nixpkgs.
#
# Nix concept: `home.packages` is just a list of packages to put on PATH
# (via /etc/profiles/per-user/josrey/bin). Add a line, run `drs`, done.
# Find package names with:  nix search nixpkgs <thing>
#
# Replaces: ~70 brew formulae and all mise-managed global runtimes.
# A few tools intentionally stay in brew because nixpkgs doesn't carry them —
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
    coreutils        # GNU userland (ls --color, etc.)
    fd               # friendlier find
    duf              # friendlier df
    dust             # friendlier du
    mmv              # mass rename
    rm-improved      # rip: rm with a trash can
    rsync
    silver-searcher-ng # ag (maintained fork; brew name: the_silver_searcher)
    zellij
    zsh-completions

    # -- vcs -----------------------------------------------------------------
    gh               # package only; its self-modifying config stays a live symlink (dotfiles.nix)
    git-remote-gcrypt
    glab

    # -- dev tools -------------------------------------------------------------
    curlie
    d2
    difftastic
    exercism
    graphviz
    httpie
    jq
    yq-go            # mikefarah's Go yq (nixpkgs `yq` is a different python tool)
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
    colima           # container runtime (docker context points here)
    docker-client    # just the docker CLI — colima provides the engine
    docker-compose
    kubectl
    kubernetes-helm  # brew name: helm
    minikube
    kafkactl
    kn

    # -- cloud ---------------------------------------------------------------
    awscli2
    azure-cli
    terraform        # unfree license (BUSL) — allowed by allowUnfree in core.nix

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

    # -- language runtimes (global defaults; replaces mise) ---------------------
    # Per-project versions: use a flake devshell + direnv (programs.nix
    # enables direnv + nix-direnv already).
    clojure
    deno
    dotnet-sdk_10
    go
    gopls
    gradle
    maven
    nodejs_latest    # node 26.x — swap to `nodejs` for the LTS line
    pnpm
    poetry
    protobuf         # protoc
    python314
    uv
    ruby_3_4
    rustup           # rustup manages toolchains mutably in ~/.rustup, like before
    scala_3          # plain `scala` is still 2.13
    temporal-cli
    temurin-bin-25   # java 25 (Eclipse Temurin, same line mise installed)
    tilt

    # -- misc --------------------------------------------------------------------
    cheat
  ];
}
