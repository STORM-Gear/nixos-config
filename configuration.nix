{...}: {
  imports = [
    ./hardware-configuration.nix
    ./options.nix
    ./services
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
  networking = {
    hostName = "storm-gear";
    useDHCP = false;
    nameservers = ["1.1.1.1" "1.0.0.1"];
    firewall = {
      enable = true;
      allowedTCPPorts = [80 22];
    };
  };

  # SSH
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = false;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQyRXFQ6iA5p0vDuoGSHZfajiVZPAGIyqhTziM7QgBV gaspard@nixos"
  ];

  virtualisation = {
    containers.enable = true;
    podman.enable = true;
    oci-containers.backend = "podman";
  };
  # rootless permission fix inside NixOS container
  systemd.mounts = [
    {
      what = "proc";
      where = "/proc2";
      type = "proc";
      options = "nosuid,nodev,noexec";
    }
  ];
  systemd.tmpfiles.rules = ["d /proc2 0755 root root -"];

  # Caddy
  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
      	trusted_proxies static private_ranges
      }
    '';
  };

  # SOPS
  sops = {
    defaultSopsFile = ./secrets/default.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };

  system.stateVersion = "26.11";
}
