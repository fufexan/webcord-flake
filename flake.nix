{
  description = "WebCord";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dream2nix.url = "github:nix-community/dream2nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";
    webcord = {
      url = "github:SpacingBat3/WebCord";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, dream2nix, webcord, ... }: let
    system = "x86_64-linux";
    dreamlib = dream2nix.lib.init {
      pkgs = nixpkgs.legacyPackages.${system};
      config = {
        projectRoot = ./.;
        overridesDirs = [ "${dream2nix}/overrides" ./overrides ];
      };
    };
    dream = dreamlib.makeOutputs {
      source = webcord;
    };
  in {
    packages.${system} = rec {
      inherit (dream.packages) webcord;
      default = webcord;
    };
  };
}
