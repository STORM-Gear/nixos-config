{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "storm";

  system.stateVersion = "26.11";
}
