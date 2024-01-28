{
  containers.nfs-server = {
    bindMounts = {
      "/export/data" = { hostPath = "/home/afilini/Developer/lan-party-netboot/games"; isReadOnly = true; };
      "/export/nixstore" = { hostPath = "/tmp/build/nixstore"; isReadOnly = true; };
    };

    config = { pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 ];
      networking.firewall.allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];

      # Temporary for testing
      services.nfs.server = {
        enable = true;
        # fixed rpc.statd port; for firewall
        lockdPort = 4001;
        mountdPort = 4002;
        statdPort = 4000;
        extraNfsdConfig = '''';
        exports = ''
          /export              *(ro,all_squash,anonuid=1000,anongid=100)
          /export/data         *(ro,all_squash,anonuid=1000,anongid=100)
          /export/nixstore     *(ro)
        '';
      };
    };
  };
}
