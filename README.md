# lan-party-netboot

This repo builds a NixOS image with a bunch of games pre installed that can be network booted on multiple physical machines for a lan party.

## How to run

1. Compile the netboot image and pixiecore script:

```
nix build -f pixiecore.nix -v -o /tmp/build --argstr nfsIp 192.168.122.1
```

Replace the IP with that of your machine.

You may also have to open some ports in your firewall, check out the [nixos documentation](https://nixos.wiki/wiki/Netboot).

2. Extract your game directory somewhere and edit `nfs-server.nix` to point the "data" `bindMount` to it.

3. Build and run the `nfs-server` container:

```
sudo extra-container create --start < ./nfs-server.ni
```

Again you may have to open ports in your firewall:

```
sudo iptables -w -I nixos-fw -p udp -m multiport --dports 111,2049,4000,4001,4002,20048 -j ACCEPT
sudo iptables -w -I nixos-fw -p tcp -m multiport --dports 111,2049,4000,4001,4002,20048 -j ACCEPT
```

4. Run `pixiecore`:

```
sudo $(realpath /tmp/build/run-pixiecore)
```
