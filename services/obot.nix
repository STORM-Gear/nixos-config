{config, ...}: let
  cfg = config.storm-gear;

  obotDomain = "mcp.${cfg.domain}";
  obotPort = 6070;
in {
  sops.secrets."obot.env".owner = cfg.serviceUser;

  services.caddy.virtualHosts."http://${obotDomain}".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString obotPort}
  '';

  systemd.tmpfiles.rules = [
    "d ${cfg.stateDir}/obot-data 0750 100070 100070 -" ## Postgres user UID inside container
  ];

  virtualisation.oci-containers.containers = {
    obot = {
      image = "ghcr.io/obot-platform/obot:latest";
      pull = "newer";
      autoStart = true;
      ports = [
        "127.0.0.1:${toString obotPort}:8080"
      ];
      environment = {
        OBOT_SERVER_ENABLE_AUTHENTICATION = "1";
        OBOT_SERVER_HOSTNAME = "https://${obotDomain}";
      };
      environmentFiles = [
        config.sops.secrets."obot.env".path
      ];
      volumes = [
        "${cfg.stateDir}/obot-data:/data"
        # In order to run MCPs as containers
        "/var/run/podman/podman.sock:/var/run/docker.sock"
      ];

      # Host user config
      podman.user = cfg.serviceUser;
      extraOptions = [
        "--userns=keep-id"
      ];
    };
  };
}
