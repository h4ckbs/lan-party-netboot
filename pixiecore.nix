{ pkgs ? import <nixpkgs> {}, nfsIp }:

let
  sys = import ./system.nix { inherit nfsIp; };
  nix-path-registration = pkgs.closureInfo { rootPaths = sys.config.netboot.storeContents; };
  run-pixiecore = let
    build = sys.config.system.build;
  in pkgs.writers.writeBash "run-pixiecore" ''
    exec ${pkgs.pixiecore}/bin/pixiecore \
      boot ${build.kernel}/bzImage ${build.netbootRamdisk}/initrd \
      --cmdline "init=${build.toplevel}/init boot.shell_on_fail=1 loglevel=4 nix-path-registration=${nix-path-registration}/registration" \
      --debug --dhcp-no-bind \
      --port 64172 --status-port 64172 "$@"
  '';
in
pkgs.stdenv.mkDerivation {
  name = "lan-party";
  unpackPhase = "true";
  installPhase = ''
    mkdir -p "$out"
    ln -s ${run-pixiecore} "$out/run-pixiecore"
    ln -s ${nix-path-registration} "$out/image-info"

    mkdir -p "$out/nixstore"
    cat ${nix-path-registration}/store-paths | while read line;
    do
      cp -R "$line" "$out/nixstore/''${line#/nix/store/}"
    done
    pathReg="${nix-path-registration}"
    cp -R "$pathReg" "$out/nixstore/''${pathReg#/nix/store/}"
  '';
  fixupPhase = "true";
}
