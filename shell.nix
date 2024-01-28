{ pkgs ? import <nixpkgs> {} }:

let
  games = import ./games.nix { inherit pkgs; };
in
pkgs.mkShell {
  nativeBuildInputs = map (g: g.bin) (with games; [ aoe2 tmnf css ]);
}
