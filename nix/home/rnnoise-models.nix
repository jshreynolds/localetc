# =============================================================================
# rnnoise-models.nix — pinned RNN denoise models for ffmpeg's `arnndn` filter.
#
# Why a whole module for some data files? `arnndn` doesn't ship with a model;
# it loads a `.rnnn` weights file at runtime (`-af arnndn=m=<file>`). Rather
# than dropping an unversioned blob in the home dir, we pin the community model
# set to an exact commit — same lock file = same models, reproducible offline.
#
# Source: github.com/GregorR/rnnoise-models. The repo's README states the work
# (the trained models) carries no copyright; only its tools/ dir does, which we
# don't install. Verified 2026-07 before pinning.
#
# The five models map signal type against noise type (names are arbitrary):
#
#             | general noise      | voice noise        | speech noise
#   ----------+--------------------+--------------------+--------------------
#   general   | mp (marathon-...)  | lq (leavened-...)  | orig (built-in)
#   voice     | cb (conjoined-...) | bd (beguiling-...) | sh (somnolent-...)
#
# ("voice" = any human sound incl. laughter; "speech" = spoken words only.)
# Usage:  ffmpeg -i in.wav -af arnndn=m=$RNNOISE_MODEL out.wav
#         ffmpeg -i in.wav -af arnndn=m=$RNNOISE_MODELS/cb.rnnn out.wav
# =============================================================================
{ pkgs, lib, ... }:
let
  rnnoiseModels = pkgs.stdenvNoCC.mkDerivation {
    pname = "rnnoise-models";
    version = "0-unstable-2018-09-01"; # date of the newest model in the set

    src = pkgs.fetchFromGitHub {
      owner = "GregorR";
      repo = "rnnoise-models";
      rev = "3eee541a283fd3b8f81b85b1748e3b9ccbefa04d";
      hash = "sha256-+0QtVNTb9VGvO7D0IRSqBWBF2BfT/pO/ZLt5gbCsEqU=";
    };

    # Pure data: nothing to configure or compile, just collect the weights.
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/rnnoise-models"
      find . -name '*.rnnn' -exec cp {} "$out/share/rnnoise-models/" \;
      runHook postInstall
    '';

    meta = {
      description = "Pre-trained RNNoise models for ffmpeg's arnndn filter";
      homepage = "https://github.com/GregorR/rnnoise-models";
      license = lib.licenses.publicDomain; # per repo README (models only)
      platforms = lib.platforms.all;
    };
  };
in
{
  home.packages = [ rnnoiseModels ];

  home.sessionVariables = {
    RNNOISE_MODELS = "${rnnoiseModels}/share/rnnoise-models";
    RNNOISE_MODEL = "${rnnoiseModels}/share/rnnoise-models/sh.rnnn";
  };
}
