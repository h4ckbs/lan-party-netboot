{ config, lib, ... }:

with lib;

{
  documentation.enable = mkDefault false;

  documentation.doc.enable = mkDefault false;

  documentation.info.enable = mkDefault false;

  documentation.man.enable = mkDefault false;

  documentation.nixos.enable = mkDefault false;

  # Perl is a default package.
  environment.defaultPackages = mkDefault [ ];

  # The lessopen package pulls in Perl.
  programs.less.lessopen = mkDefault null;

  # This pulls in nixos-containers which depends on Perl.
  boot.enableContainers = mkDefault false;

  programs.command-not-found.enable = mkDefault false;

  services.logrotate.enable = mkDefault false;

  services.udisks2.enable = mkDefault false;
}
