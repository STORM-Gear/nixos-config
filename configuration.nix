{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostname = "storm";

  system.stateVersion = "26.11";
}
