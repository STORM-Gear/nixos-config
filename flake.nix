{
  description = "STORM Gear server NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    storm-backend.url = "github:STORM-Gear/storm-backend";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    nixpkgsFor = system: import nixpkgs {inherit system;};
  in {
    nixosConfigurations.storm = nixpkgs.lib.nixosSystem {
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.storm-backend.nixosModules.default
        ./configuration.nix
      ];
    };

    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor system;
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          sops
        ];
      };
    });
  };
}
