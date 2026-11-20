{
  config,
  lib,
  ...
}: let
  cfg = config.storm-gear;
in {
  options.storm-gear = {
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "Server domain";
      default = "stormvario.fr";
    };

    stateDir = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "STORM root storage directory";
      default = "/var/lib/storm-gear";
    };

    serviceUser = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "STORM services user";
      default = "storm";
    };

    serviceGroup = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "STORM services group";
      default = "storm";
    };
  };

  config = {
    users.groups.storm = lib.mkIf (cfg.serviceGroup == "storm") {
      name = "storm";
    };
    users.users.storm = lib.mkIf (cfg.serviceUser == "storm") {
      isNormalUser = true;
      createHome = true;
      linger = true;
      uid = 996;
      # needs to be enabled before Podman's first run as the user
      autoSubUidGidRange = true;
      group = cfg.serviceGroup;
      extraGroups = [
        "podman"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQyRXFQ6iA5p0vDuoGSHZfajiVZPAGIyqhTziM7QgBV gaspard@nixos"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0755 ${cfg.serviceUser} ${cfg.serviceGroup} -"
    ];
  };
}
