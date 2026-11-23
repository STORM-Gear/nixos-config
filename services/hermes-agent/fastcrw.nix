{
  config,
  pkgs,
  ...
}: let
  cfg = config.storm-gear;

  # Build package here until in nixpkgs stable
  fastcrw = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
    pname = "fastcrw";
    version = "0.42.1";
    __structuredAttrs = true;

    src = pkgs.fetchFromGitHub {
      owner = "fastcrw";
      repo = "crw";
      tag = "v${finalAttrs.version}";
      hash = "sha256-kmzUhdHp/h0/iWyO2ACYbPpYtp/i8n4rH7qsxughzQ8=";
    };

    cargoHash = "sha256-Z2/C76zSbml0HXxbNN0ufSD4RwTgtpuE/qsC0Wg84o0=";

    nativeBuildInputs = with pkgs; [
      rustPlatform.bindgenHook
      pkg-config
    ];

    buildInputs = with pkgs; [aws-lc];
  });

  crwConfig = (pkgs.formats.toml {}).generate "crw.local.toml" {
    server = {
      host = "127.0.0.1";
      port = 3000;
    };
    renderer.mode = "none";
    search = {
      enabled = true;
      search_backend_url = "http://127.0.0.1:8081";
    };
    crawler.stealth.enabled = true;
  };
  searxSecret = "omgworldreadablesecretthehackersaregonnagetusohno";
in {
  systemd.services.crw-server = {
    description = "scrape/crawl/search/extract engine (Firecrawl-compatible API)";
    wantedBy = ["multi-user.target"];
    after = ["network.target" "searx.service"];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${fastcrw}/bin/crw-server";
      Environment = [
        "CRW_CONFIG=${crwConfig}"
        "RUST_LOG=info"
      ];
      Restart = "on-failure";
      RestartSec = 5;
      User = cfg.serviceUser;
      Group = cfg.serviceGroup;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  services.searx = {
    enable = true;
    settings = {
      server = {
        port = 8081;
        bind_address = "127.0.0.1";
        secret_key = searxSecret;
        # Rate limiting handled by crwserver
        limiter = false;
        public_instance = false;
      };
      search = {
        safe_search = 0;
        autocomplete = "";
        default_lang = "auto";
        formats = ["html" "json"];
      };
    };
  };
}
