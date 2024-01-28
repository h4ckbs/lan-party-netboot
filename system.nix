{ nfsIp }:

let
  # Latest Hydra build of nixos-23.11 as of 27/01/2024
  nixpkgs = builtins.getFlake "github:nixos/nixpkgs/f034d32568a1c7ea14599b191fdaea9df16aec32";
in
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ({ config, pkgs, lib, modulesPath, ... }:
    let
      games = import ./games.nix { inherit pkgs; };
      home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz";
    in
    {
      imports = [
        ./profiles/netboot-nfs-store.nix
        ./profiles/minimal-with-graphics.nix
        (import "${home-manager}/nixos")
      ];
      config = {
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0VM6VOAYcSOHz2CQMM8l5pedULxj/byifvpFWq5ckN afilini@nixos-laptop"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID8H0QcQfndr1Lx2EJ6m2q7trey+VYWqsTgKiG3ZHp3/ alekos-test"
        ];
        console.keyMap = "it";

        nixpkgs.config.pulseaudio = true;

        services.openssh.enable = true;

        hardware.opengl.driSupport32Bit = true;
        services.xserver = {
          enable = true;
          desktopManager = {
            xterm.enable = false;
            xfce.enable = true;
          };
          videoDrivers = [ "amdgpu" "ati" "nouveau" "intel" "qxl" ];
          displayManager.defaultSession = "xfce";
          displayManager.autoLogin.enable = true;
          displayManager.autoLogin.user = "player";
        };
        users.users.player = {
          isNormalUser = true;
          password = "";
          extraGroups = [ "wheel" ];
        };
        home-manager.users.player = { ... }: {
          home.file = builtins.listToAttrs (map (game: {
            name = game;
            value = {
              source = ''${games."${game}".desktopLink}/share/applications/${game}.desktop'';
              target = "Desktop/${game}.desktop";
            };
          }) ["aoe2" "tmnf" "css"]);
          home.stateVersion = config.system.nixos.release;
        };

        fileSystems."/mnt/nfs" = {
          device = "${nfsIp}:/export/data";
          fsType = "nfs";
          options = [ "nfsvers=4.2,ro"];
        };
        fileSystems."/home/player/.wine-nix" = {
          device = "overlay";
          fsType = "overlay";
          options = [ "lowerdir=/mnt/nfs,upperdir=/var/upper,workdir=/var/work" "x-systemd.automount" "noauto" ];
        };
        systemd.tmpfiles.rules = [
          "d /var/upper 0755 root root"
          "d /var/work 0755 root root"
        ];

        environment.systemPackages = [];

        netboot.nfsNixStore = "${nfsIp}:/export/nixstore";
        system.stateVersion = config.system.nixos.release;
      };
    })
  ];
}
