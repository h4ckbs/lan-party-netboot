{ config, lib, pkgs, ... }:

with lib;

{
  options = {

    netboot.nfsNixStore = mkOption {
      type = types.str;
    };

    netboot.storeContents = mkOption {
      example = literalExpression "[ pkgs.stdenv ]";
      description = lib.mdDoc ''
        This option lists additional derivations to be included in the
        Nix store in the generated netboot image.
      '';
    };

  };

  config = {
    # Don't build the GRUB menu builder script, since we don't need it
    # here and it causes a cyclic dependency.
    boot.loader.grub.enable = false;

    # !!! Hack - attributes expected by other modules.
    environment.systemPackages = [ pkgs.grub2_efi ]
      ++ (lib.optionals (pkgs.stdenv.hostPlatform.system != "aarch64-linux") [pkgs.grub2 pkgs.syslinux]);

    boot.initrd.supportedFilesystems = [ "nfs" "nfsv4" "overlay" ];   # load needed kernel modules
    boot.initrd.availableKernelModules = [ "nfs" "nfsv4" "overlay" "e1000e" "r8169" ]; # load them again, because of cause it didn't work
    fileSystems."/" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "size=1G" ]; };
    fileSystems."/nix/.rw-store" = { fsType = "tmpfs"; options = [ "mode=0755" "size=1G" ]; neededForBoot = true; };
    fileSystems."/nix/.ro-store" =
      {
        fsType = "nfs4";
        device = config.netboot.nfsNixStore;
        options = [ "ro" ];
        neededForBoot = true;
      };
    fileSystems."/nix/store" =
      {
        fsType = "overlay";
        device = "overlay";
        options = [
          "lowerdir=/nix/.ro-store"
          "upperdir=/nix/.rw-store/store"
          "workdir=/nix/.rw-store/work"
        ];
        depends = [
          "/nix/.ro-store"
          "/nix/.rw-store/store"
          "/nix/.rw-store/work"
        ];
      };
    boot.initrd.network.enable = true;
    boot.initrd.network.flushBeforeStage2 = false; # otherwise nfs dosen't work
    networking.useDHCP = true;

    # Closures to be copied to the Nix store, namely the init
    # script and the top-level system configuration directory.
    netboot.storeContents =
      [ config.system.build.toplevel ];

    # Create the squashfs image that contains the Nix store.
    # system.build.squashfsStore = pkgs.callPackage ../../../lib/make-squashfs.nix {
    #   storeContents = config.netboot.storeContents;
    #   comp = config.netboot.squashfsCompression;
    # };

    # Create the initrd
    system.build.netbootRamdisk = pkgs.makeInitrdNG {
      inherit (config.boot.initrd) compressor;
      prepend = [ "${config.system.build.initialRamdisk}/initrd" ];
      contents = [ { object = "/dev/null"; symlink = "/.empty-root"; } ];
    };

    system.build.netbootIpxeScript = pkgs.writeTextDir "netboot.ipxe" ''
      #!ipxe
      # Use the cmdline variable to allow the user to specify custom kernel params
      # when chainloading this script from other iPXE scripts like netboot.xyz
      kernel ${pkgs.stdenv.hostPlatform.linux-kernel.target} init=${config.system.build.toplevel}/init initrd=initrd ${toString config.boot.kernelParams} ''${cmdline}
      initrd initrd
      boot
    '';

    # A script invoking kexec on ./bzImage and ./initrd.gz.
    # Usually used through system.build.kexecTree, but exposed here for composability.
    system.build.kexecScript = pkgs.writeScript "kexec-boot" ''
      #!/usr/bin/env bash
      if ! kexec -v >/dev/null 2>&1; then
        echo "kexec not found: please install kexec-tools" 2>&1
        exit 1
      fi
      SCRIPT_DIR=$( cd -- "$( dirname -- "''${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
      kexec --load ''${SCRIPT_DIR}/bzImage \
        --initrd=''${SCRIPT_DIR}/initrd.gz \
        --command-line "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}"
      kexec -e
    '';

    # A tree containing initrd.gz, bzImage and a kexec-boot script.
    system.build.kexecTree = pkgs.linkFarm "kexec-tree" [
      {
        name = "initrd.gz";
        path = "${config.system.build.netbootRamdisk}/initrd";
      }
      {
        name = "bzImage";
        path = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";
      }
      {
        name = "kexec-boot";
        path = config.system.build.kexecScript;
      }
    ];

    boot.loader.timeout = 10;

    boot.postBootCommands =
      ''
        # After booting, register the contents of the Nix store
        # in the Nix database in the tmpfs.
        nixPathRegistration=$(cat /proc/cmdline | ${pkgs.gnused}/bin/sed -e 's/^.*nix-path-registration=//' -e 's/ .*$//')
        ${config.nix.package}/bin/nix-store --load-db < $nixPathRegistration

        # nixos-rebuild also requires a "system" profile and an
        # /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      '';

  };
}
