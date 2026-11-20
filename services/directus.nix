{config, ...}: let
  cfg = config.storm-gear;

  directusDomain = "admin.${cfg.domain}";
  directusPort = 8055;
in {
  sops.secrets."directus.env".owner = cfg.serviceUser;

  services.caddy.virtualHosts."http://${directusDomain}".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString directusPort}
  '';

  systemd.tmpfiles.rules = [
    "d ${cfg.stateDir}/directus 0750 ${cfg.serviceUser} ${cfg.serviceGroup} -"
    "d ${cfg.stateDir}/directus/uploads 0750 ${cfg.serviceUser} ${cfg.serviceGroup} -"
    "d ${cfg.stateDir}/directus/extensions 0750 ${cfg.serviceUser} ${cfg.serviceGroup} -"
  ];

  virtualisation.oci-containers.containers = {
    directus = {
      image = "docker.io/directus/directus:12";
      pull = "newer";
      autoStart = true;
      ports = [
        "127.0.0.1:${toString directusPort}:8055"
      ];
      environment = {
        DB_CLIENT = "pg";
        DB_HOST = "/var/run/postgresql";
        DB_PORT = "5432";
        DB_DATABASE = "storm";
        DB_USER = "storm";
        DB_PASSWORD = "";
        PUBLIC_URL = "https://${directusDomain}";
        WEBSOCKETS_ENABLED = "true";
        MCP_OAUTH_ENABLED = "true";
        MCP_OAUTH_DCR_ENABLED = "true";
      };
      environmentFiles = [
        config.sops.secrets."directus.env".path
      ];
      volumes = [
        "/var/run/postgresql:/var/run/postgresql"

        "${cfg.stateDir}/directus/uploads:/directus/uploads"
        "${cfg.stateDir}/directus/extensions:/directus/extensions"
      ];

      # Host user config
      podman.user = cfg.serviceUser;
      extraOptions = [
        "--userns=keep-id"
      ];
    };
  };

  systemd.services."${config.virtualisation.oci-containers.containers.directus.serviceName}" = {
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
  };
}
