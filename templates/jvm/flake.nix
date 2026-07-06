{
  # ===========================================================================
  # JVM project devshell — Java + Gradle/Maven, Scala, Clojure.
  #
  # These moved OUT of the global profile (nix/home/packages.nix) so each
  # project pins its own toolchain instead of one global version fighting all
  # projects. Copy this dir into a repo, trim the packages to what it needs,
  # then `direnv allow` (the .envrc runs `use flake` and drops you in the shell
  # on cd). Global direnv + nix-direnv are already enabled in programs.nix.
  # ===========================================================================
  description = "JVM project devshell";

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
            temurin-bin-25 # java 25 (Eclipse Temurin)
            gradle
            maven
            scala_3 # plain `scala` is still 2.13
            clojure
          ];
        };
      });
    };
}
