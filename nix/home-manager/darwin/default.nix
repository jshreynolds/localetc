# =============================================================================
# darwin/default.nix — the macOS-only half of the home configuration.
#
# Imported by nix/home-manager/default.nix when isDarwin is true; nix/home-manager/linux is
# imported instead otherwise. Everything in here would either fail to build on
# linux or point at a path that only exists on a Mac.
# =============================================================================
{ ... }:
{
  imports = [
    ./packages.nix # macOS-only tools (apple dev, colima, keychain helper)
    ./shell.nix # brew PATH, gcloud, /Applications paths, the drs alias
    ./openshell.nix # NVIDIA OpenShell — prebuilt aarch64-darwin binaries
  ];
}
