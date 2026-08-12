# =============================================================================
# packages.nix — every CROSS-PLATFORM CLI tool and language runtime, from
# nixpkgs. This list lands on macOS and NixOS alike.
#
# Nix concept: `home.packages` is just a list of packages to put on PATH
# (via /etc/profiles/per-user/<username>/bin). Add a line, rebuild, done.
# Find package names with:  nix search nixpkgs <thing>
#
# Anything that only builds or only makes sense on ONE platform goes in
# nix/home/darwin/packages.nix or nix/home/linux/default.nix instead. A
# darwin-only package added here breaks the linux hosts at eval time, which is
# what the linux entries in flake.nix's `systems` are there to catch.
#
# A few macOS tools intentionally live in brew because nixpkgs doesn't carry
# them — see the `brews` list in nix/darwin/homebrew.nix.
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
    bat # plain package, not programs.bat — see programs.nix
    coreutils # GNU userland (ls --color, etc.)
    fd # friendlier find
    duf # friendlier df
    dust # friendlier du
    mmv # mass rename
    ripgrep # rg
    rclone # also the engine behind storage-box.nix
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
    nixfmt # `ci/run-checks.sh nixfmt` shells out to this
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
    # The CLI is cross-platform; the ENGINE behind it is not. macOS gets colima
    # (nix/home/darwin/packages.nix), NixOS gets virtualisation.docker.enable
    # (nix/nixos/core.nix).
    docker-client # just the docker CLI
    docker-compose
    # Cross-platform, but it is macOS that needs it: ~/.docker/config.json sets
    # credsStore=osxkeychain and docker-client does not ship the helper. It used
    # to arrive undeclared via Rancher Desktop's ~/.rd/bin; without it every
    # registry pull fails to resolve credentials. Declared here rather than in
    # darwin/packages.nix so there is one line, not two.
    docker-credential-helpers
    (lib.hiPrio kubectl) # win the /bin/kubectl collision against minikube's bundled copy
    kubernetes-helm # the `helm` CLI
    minikube # ships its own kubectl; kubectl above takes precedence
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
    sops # edits secrets/*.env in place; recipients come from .sops.yaml
    # The pinentry program is pulled into the closure by git.nix's
    # gpg-agent.conf, which references its store path directly — and it differs
    # per platform (pinentry-mac vs pinentry-curses), so it is chosen there.

    # -- AI CLIs ---------------------------------------------------------------
    # NOTE: nixpkgs can lag fast-moving AI tools by days-to-weeks, and their
    # self-update commands can't write to the read-only store. If lag ever
    # hurts, move the offender to `brews` in homebrew.nix (one-line change).
    claude-code # was a cask + a NixOS app; nixpkgs builds it on both platforms
    codex # "
    github-copilot-cli # " (the `copilot-cli` cask)
    gemini-cli
    herdr # agent multiplexer — was a brew, but nixpkgs has it on both platforms
    llm
    opencode
    pi-coding-agent # `pi` from pi.dev (@earendil-works) — self-update won't work (read-only store)

    # (apple dev tooling — xcbeautify, xcodegen — is in darwin/packages.nix)

    # -- language runtimes (deliberately lean) -----------------------------------
    # Only runtimes used ad-hoc at a shell prompt or for system scripting live
    # here. Project-specific toolchains (JVM, .NET, Ruby, ...) belong in a
    # per-project flake devshell + direnv (both enabled in programs.nix) — see
    # templates/ for ready-to-copy starters.
    go
    gopls
    nil # nix language server (zed's nix extension wants it)
    nodejs # LTS line (was nodejs_latest: avoids silent major jumps on flake update)
    pnpm
    protobuf # protoc
    python314 # also load-bearing: flake `checks` compile/test the skills with this
    uv
    temporal-cli
    tilt

    # -- media -------------------------------------------------------------------
    ffmpeg-full # afftdn + arnndn as the default build, plus the openal capture device
    # arnndn needs a .rnnn model at runtime — pinned in rnnoise-models.nix ($RNNOISE_MODEL)
    # openal is what `podio bumper` records through: the avfoundation input in the
    # default build silently drops 11-17% of a recording, which is audible as clicks.

    # -- misc --------------------------------------------------------------------
    cheat
  ];
}
