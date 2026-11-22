{config, ...}: let
  cfg = config.storm-gear;
in {
  sops.secrets."hermes-agent.env".owner = cfg.serviceUser;

  systemd.tmpfiles.rules = [
    "d ${cfg.stateDir}/hermes-agent 0750 ${cfg.serviceUser} ${cfg.serviceGroup} -"
  ];

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    user = cfg.serviceUser;
    group = cfg.serviceGroup;
    createUser = false;
    stateDir = "${cfg.stateDir}/hermes-agent";

    environment = {
      HERMES_DOCKER_BINARY = "podman";
    };
    environmentFiles = [
      config.sops.secrets."hermes-agent.env".path
    ];

    hermesHomeFiles."SOUL.md" = ./SOUL.md;

    mcpServers = {
      storm-gear = {
        url = "https://mcp.stormvario.fr/mcp-connect/vmcp15h8v4";
        auth = "oauth";
      };
    };

    settings = {
      model = {
        provider = "openrouter";
        default = "deepseek/deepseek-v4.1-flash-1017";
      };

      extraDependencyGroups = [
        "messaging"
      ];

      plugins = {
        enabled = ["disk-cleanup"];
      };

      terminal = {
        # Isolate hermes home
        home_mode = "profile";

        # This is where hermes is isolated from the host services
        backend = "docker";
        docker_image = "docker.io/library/ubuntu:24.04";
        docker_run_as_host_user = true;
        container_persistent = true;
      };
    };
  };

  # Run container as user
  systemd.services.hermes-agent.serviceConfig = {
    User = cfg.serviceUser;
    Groups = cfg.serviceGroup;
  };
}
