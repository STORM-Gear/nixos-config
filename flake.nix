{
  description = "STORM Gear server NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    storm-backend.url = "github:STORM-Gear/storm-backend";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: {
    nixosConfigurations.storm = nixpkgs.lib.nixosSystem {
      modules = [
        inputs.storm-backend.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
