# =============================================================================
# login-items.nix — apps that start automatically at login.
#
# nix-darwin has no first-class "Login Items" list (System Settings → General →
# Login Items). Instead we declare a per-user LaunchAgent per app: nix-darwin
# writes ~/Library/LaunchAgents/org.nixos.<name>.plist on each drs and removes
# it when the entry is deleted here — so the set stays in sync with this file.
#
# Each agent runs `open -gj -a <App>` at load: -g keeps the app in the
# background (no foreground switch) and -j launches it hidden (no windows).
# KeepAlive is false so quitting the app by hand doesn't get it relaunched
# until the next login.
# =============================================================================
{ lib, ... }:
{
  launchd.user.agents =
    let
      # app names as they appear in /Applications (without .app)
      loginApps = [
        "Rectangle"
        "1Password"
        "Dropbox"
        "Muesli"
        "LM Studio"
      ];
      mkLoginItem = app: {
        # lowercased, spaces stripped → launchd label / plist filename
        name = builtins.replaceStrings [ " " ] [ "" ] (lib.toLower app);
        value.serviceConfig = {
          ProgramArguments = [ "/usr/bin/open" "-g" "-j" "-a" app ];
          RunAtLoad = true;
          KeepAlive = false;
        };
      };
    in
    builtins.listToAttrs (map mkLoginItem loginApps);
}
