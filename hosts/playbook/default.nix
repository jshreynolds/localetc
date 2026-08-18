# =============================================================================
# playbook — personal machine.
#
# PLAIN DATA, not a nix module — see hosts/mac-nl-josrey/default.nix for why.
# Field list and defaults: mkDarwinHost in flake.nix.
# =============================================================================
{
  hostname = "playbook";
  username = "jreynolds";
  work = false;

  sboxFolders = [ "yellingatrobots" ];

  casks = [
    "lulu"
    "scrivener"
    "surfshark"
    "thinkorswim"
  ];
}
