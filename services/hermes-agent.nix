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
    container = {
      enable = true;
      backend = "podman";
      extraOptions = [
        "--userns=keep-id"
      ];
    };

    environmentFiles = [
      config.sops.secrets."hermes-agent.env".path
    ];

    hermesHomeFiles."SOUL.md" = ../assets/hermes-agent/SOUL.md;

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
    };
  };

  # Run container as user
  systemd.services.hermes-agent.serviceConfig = {
    User = cfg.serviceUser;
    Groups = cfg.serviceGroup;
  };
}
