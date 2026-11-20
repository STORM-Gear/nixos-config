{config, ...}: let
  cfg = config.storm-gear;

  backendDomain = "backend.${cfg.domain}";
  backendPort = 57053;
in {
  sops.secrets."backend.env".owner = cfg.serviceUser;

  services.caddy.virtualHosts."http://${backendDomain}".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString backendPort}
  '';

  storm.services.backend = {
    enable = true;
    port = backendPort;
    secretsFile = config.sops.secrets."backend.env".path;
    debug = true;
  };
}
