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

    wrapper = system: old: config: let
      pkgs = nixpkgs.legacyPackages.${system};
      webcord-wrapped =
        pkgs.runCommand "${old.name}-wrapped"
        {
          inherit (old) pname version meta;

          nativeBuildInputs = [pkgs.makeWrapper];
          makeWrapperArgs = config.makeWrapperArgs or [];
        }
        ''
          mkdir -p $out
          cp -r --no-preserve=mode,ownership ${old}/* $out/
          chmod +x $out/bin/*
          wrapProgram "$out/bin/webcord" ''${makeWrapperArgs[@]} ${
            if (config.flags or []) != []
            then ''
              ${pkgs.lib.concatStringsSep " " (map (flag: "--add-flags ${flag}") config.flags)}
            ''
            else ""
          }
        '';
    in
      webcord-wrapped // {override = wrapper system old;};
  in {
    packages = genSystems (system: rec {
      webcord = wrapper system dream.${system}.packages.webcord {};
      default = webcord;
    });

    homeManagerModules = rec {
      webcord = import ./hm-module.nix;
      default = webcord;
    };

    formatter = genSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
