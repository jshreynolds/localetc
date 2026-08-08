# =============================================================================
# mac-nl-josrey — work machine.
#
# PLAIN DATA, not a nix module. flake.nix must read these facts BEFORE the
# module system runs, because they become `specialArgs` — an argument TO
# nix-darwin's darwinSystem. A module is an unevaluated function at that point,
# so its contents would be unreadable. Nix that belongs to only this machine
# goes in a sibling .nix file here, listed under `modules`.
#
# Field list and defaults: mkDarwinHost in flake.nix.
# =============================================================================
{
  hostname = "mac-nl-josrey";
  username = "josrey";
}
