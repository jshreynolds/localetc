{
  # ===========================================================================
  # .NET project devshell.
  #
  # Moved OUT of the global profile (nix/home/packages.nix): the .NET SDK is
  # large and project-specific. Copy this dir into a repo, then `direnv allow`.
  # Swap dotnet-sdk_10 for another SDK attribute if the project needs it.
  # ===========================================================================
  description = ".NET project devshell";

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
          packages = [ pkgs.dotnet-sdk_10 ];
        };
      });
    };
}
