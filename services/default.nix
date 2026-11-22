{...}: {
  # STORM Gear specific services
  imports = [
    ./storm-backend.nix
    ./database.nix
    ./directus.nix
    ./obot.nix
    ./hermes-agent
  ];
}
