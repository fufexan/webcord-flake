{
  description = "WebCord Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    dream2nix = {
      url = "github:nix-community/dream2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    webcord = {
      url = "github:SpacingBat3/WebCord";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    dream2nix,
    webcord,
    ...
  }: let
    supportedSystems = [
      "aarch64-linux"
      "x86_64-linux"

      # open an issue if you want these
      #"aarch64-darwin"
      #"x86_64-darwin"
    ];
    genSystems = nixpkgs.lib.genAttrs supportedSystems;

    dreamlib = genSystems (system:
      dream2nix.lib.init {
        pkgs = nixpkgs.legacyPackages.${system};
        config = {
          projectRoot = ./.;
          overridesDirs = ["${dream2nix}/overrides" ./overrides];
        };
      });
    dream = genSystems (system: dreamlib.${system}.makeOutputs {source = webcord;});
  in {
    packages = genSystems (system: rec {
      inherit (dream.${system}.packages) webcord;
      default = webcord;
    });
  };
}
