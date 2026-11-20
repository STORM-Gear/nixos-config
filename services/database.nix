{config, ...}: let
  cfg = config.storm-gear;
in {
  systemd.tmpfiles.rules = [
    "d ${cfg.stateDir}/postgres 0750 postgres postgres -"
  ];

  services.postgresql = {
    enable = true;
    dataDir = "${cfg.stateDir}/postgres";
    ensureDatabases = [
      "storm"
    ];
    ensureUsers = [
      {
        name = "storm";
        ensureDBOwnership = true;
      }
    ];
    authentication = ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
  };
}
