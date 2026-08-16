{config, ...}: let
  domain = "stormvario.fr";

  backendDomain = "backend.${domain}";
  backendPort = 57053;
in {
  imports = [
    ./hardware-configuration.nix
  ];

  # Basic settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = ["https://gasdev.cachix.org"];
    trusted-substituters = ["https://gasdev.cachix.org"];
    trusted-public-keys = ["gasdev.cachix.org-1:eBesrrBJpsMZ33OmvG4aKvfdyVkDa2OKCJ2o80IMJfE="];
  };
  time.timeZone = "Europe/Paris";
  networking.hostName = "storm-gear";

  # Storm
  storm.services.backend = {
    enable = true;
    port = backendPort;
    secretsFile = config.sops.secrets."backend.env".path;
    debug = true;
  };

  # Caddy
  services.caddy = {
    enable = true;

    virtualHosts."${backendDomain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString backendPort}
    '';
  };

  # SOPS
  sops = {
    secrets = {
      "backend.env".owner = config.storm.services.backend.user;
    };

    defaultSopsFile = ./secrets/default.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };

  system.stateVersion = "26.11";
}
