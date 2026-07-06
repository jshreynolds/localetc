{
  # ===========================================================================
  # Rust project devshell.
  #
  # Moved OUT of the global profile (nix/home/packages.nix): rustup managed
  # toolchains mutably in ~/.rustup, escaping nix's reproducibility. This uses
  # the nix-pinned Rust toolchain instead, so the lock fully determines the
  # version. For pinned nightly or extra cross targets, add the rust-overlay or
  # fenix flake input; nixpkgs' stable toolchain is enough for most projects.
  # ===========================================================================
  description = "Rust project devshell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
          system: f nixpkgs.legacyPackages.${system}
        );
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            rustc
            cargo
            rustfmt
            clippy
            rust-analyzer
          ];
        };
      });
    };
}
