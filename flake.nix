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
    inherit (nixpkgs) lib;

    supportedSystems = [
      "aarch64-linux"
      "x86_64-linux"

      # open an issue if you want these
      #"aarch64-darwin"
      #"x86_64-darwin"
    ];
    genSystems = lib.genAttrs supportedSystems;

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
            lib.optionalString ((config.flags or []) != [])
            (lib.concatStringsSep " " (map (flag: "--add-flags ${flag}") config.flags))
          }
        '';
    in
      webcord-wrapped // {override = wrapper system old;};
  in {
    packages = genSystems (system: {
      webcord = wrapper system dream.${system}.packages.webcord {};
      default = self.packages.${system}.webcord;
    });

    homeManagerModules = {
      webcord = import ./hm-module.nix self;
      default = self.homeManagerModules.webcord;
    };

    overlays = {
      webcord = _: prev: {
        webcord = self.packages.${prev.system}.webcord;
      };
      default = self.overlays.webcord;
    };

    formatter = genSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
