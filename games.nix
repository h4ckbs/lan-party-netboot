{ pkgs ? import <nixpkgs> {} }:

let
  wrapWine = import ./wrapWine.nix { inherit pkgs; };
  aoe2Bin = wrapWine {
    name = "aoe2";
    executable = "empires2.exe";
    chdir = "$WINEPREFIX/drive_c/Program\ Files/Microsoft\ Games/Age\ of\ Empires\ II/";
    tricks = [ "directplay" "corefonts" ];
  };
  tmnfBin = wrapWine {
    name = "tmnf";
    executable = "TmForever.exe";
    chdir = "$WINEPREFIX/drive_c/Program\ Files/TmNationsForever/";
    tricks = [ "d3dx9" ];
  };

  cssBin = wrapWine {
    name = "css";
    executable = "C:\\Program Files\\Strogino CS Portal\\Counter-Strike Source\\Counter-Strike_Source.exe";
    tricks = [ ];
  };
in
{
  aoe2 = rec {
    bin = aoe2Bin;
    logo = pkgs.fetchurl {
      url = "https://cdn2.steamgriddb.com/icon/8860b0b3ad5538d2ccc6c2bdd0341a1a/32/256x256.png";
      sha256 = "sha256-K6eLuqVgqLqjQIvG//JbC1/QpwSPibNJvUokZqScW7E=";
    };
    desktopLink = pkgs.makeDesktopItem {
      name = "aoe2";
      desktopName = "Age of Empires II";
      type = "Application";
      exec = "${bin}/bin/aoe2";
      icon = "${logo}";
    };
  };

  tmnf = rec {
    bin = tmnfBin;
    logo = pkgs.fetchurl {
      url = "https://cdn2.steamgriddb.com/icon/907ee68e550f498a93ec82d228135c00/32/256x256.png";
      sha256 = "sha256-kI6yUGZ1miTfa9xqFwOAWcvF3C9MCmGGy8XjQK5uzj8=";
    };
    desktopLink = pkgs.makeDesktopItem {
      name = "tmnf";
      desktopName = "TrackMania Nations Forever";
      type = "Application";
      exec = "${bin}/bin/tmnf";
      icon = "${logo}";
    };
  };

  css = rec {
    bin = cssBin;
    logo = pkgs.fetchurl {
      url = "https://cdn2.steamgriddb.com/icon/b305c4982512d2529ad05ee542a18133/32/256x256.png";
      sha256 = "sha256-O7ZPuHdqjHpzBsvCyysm8o+T1SF/l0WgafrL5L+L94c=";
    };
    desktopLink = pkgs.makeDesktopItem {
      name = "css";
      desktopName = "Counter-Strike: Source";
      type = "Application";
      exec = "${bin}/bin/css";
      icon = "${logo}";
    };
  };
}
