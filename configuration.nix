{config, ...}: let
  domain = "stormvario.fr";

  stateDir = "/var/lib/storm-gear";

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
  ## State directory
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 root root -"
    "d ${stateDir}/postgres 0750 postgres postgres -"
    "d ${stateDir}/directus 0750 root root -"
  ];

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
    dataDir = "${stateDir}/postgres";
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

        "${stateDir}/directus/uploads:/directus/uploads"
        "${stateDir}/directus/extensions:/directus/extensions"
      ];
    };
  };
  systemd.services."${config.virtualisation.oci-containers.containers.storm-directus.serviceName}" = {
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
  };

  # Caddy
  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
      	trusted_proxies static private_ranges
      }
    '';

    virtualHosts."${backendDomain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString backendPort}
    '';

    virtualHosts."${directusDomain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString directusPort}
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
