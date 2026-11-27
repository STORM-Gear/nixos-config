{config, ...}: let
  cfg = config.storm-gear;
in {
  imports = [
    ./fastcrw.nix
  ];

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
      # Note that the home is $stateDir/hermes-agent for podman commands
      HERMES_DOCKER_BINARY = "${config.virtualisation.podman.package}/bin/podman";

      FIRECRAWL_API_URL = "http://127.0.0.1:3000";
    };
    environmentFiles = [
      config.sops.secrets."hermes-agent.env".path
    ];

    extraDependencyGroups = [
      "messaging"
      "firecrawl"
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

      plugins = {
        enabled = ["disk-cleanup"];
      };

      terminal = {
        # Isolate hermes home
        home_mode = "profile";

        # Default one fails
        cwd = "/workspace";

        # This is where hermes is isolated from the host services
        backend = "docker";
        docker_image = "docker.io/library/ubuntu:24.04";
        docker_forward_env = [
          "DIRECTUS_ACCESS_TOKEN"
        ];
        docker_volumes = [
          "${cfg.stateDir}/hermes-agent/workspace:/workspace"
        ];
        docker_orphan_reaper = true;
        container_persistent = true;
      };
    };
  };

  # Fix container `.local` being inside of $stateDir/hermes-agent
  systemd.services.hermes-agent.environment = {
    XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.storm.uid}";
    XDG_DATA_HOME = "/home/storm/.local/share";
  };
}
