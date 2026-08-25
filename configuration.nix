{config, ...}: let
  domain = "stormvario.fr";

  backendDomain = "backend.${domain}";
  backendPort = 57053;

  directusDomain = "admin.${domain}";
  directusPort = 8055;
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
  ## Backend
  storm.services.backend = {
    enable = true;
    port = backendPort;
    secretsFile = config.sops.secrets."backend.env".path;
    debug = true;
  };

  ## Database
  services.postgresql = {
    enable = true;
    dataDir = "/var/lib/storm/postgres";
    ensureDatabases = [
      "storm"
    ];
    ensureUsers = [
      {
        name = "storm";
        ensureDBOwnership = true;
      }
    ];
  };

  ## Directus
  virtualisation.oci-containers.containers = {
    storm-directus = {
      image = "docker.io/directus/directus:12";
      pull = "newer";
      autoStart = true;
      ports = [
        "127.0.0.1:${toString directusPort}:8055"
      ];
      environment = {
        DB_CLIENT = "pg";
        DB_CONNECTION_STRING = "postgresql://storm/storm?host=/var/run/postgresql";
        PUBLIC_URL = "https://${directusDomain}";
        WEBSOCKETS_ENABLED = "true";
      };
      environmentFiles = [
        config.sops.secrets."directus.env".path
      ];
      volumes = [
        "/var/run/postgresql:/var/run/postgresql"

        "/var/lib/storm/directus/uploads:/directus/uploads"
        "/var/lib/storm/directus/extensions:/directus/extensions"
      ];
    };
  };

  # Caddy
  services.caddy = {
    enable = true;

    virtualHosts."${backendDomain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString backendPort}
    '';

    virtualHosts."${directusDomain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString directusDomain}
    '';
  };

  # SOPS
  sops = {
    secrets = {
      "backend.env".owner = config.storm.services.backend.user;
      "directus.env".owner = "root";
    };

    defaultSopsFile = ./secrets/default.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };

  system.stateVersion = "26.11";
}
