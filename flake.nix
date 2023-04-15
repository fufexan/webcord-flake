{
  description = "WebCord Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    webcord = {
      url = "github:SpacingBat3/WebCord";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
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
    packages = genSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      webcord = pkgs.buildNpmPackage rec {
        pname = "webcord";
        version = "v4.2.0";
        src = pkgs.fetchFromGitHub {
          owner = "SpacingBat3";
          repo = "WebCord";
          rev = version;
          sha256 = "sha256-530iWNvehImwSYt5HnZaqa4TAslrwxAOZi3gRm1K2/w=";
        };

        npmDepsHash = "sha256-YguZtGn8CT4EqOQWS0GeNGBdZSC3Lj1gFR0ZiegWTJU=";
        nativeBuildInputs = with pkgs; [python3];

        patches = [./overrides/nodejs/patches/remove-dialog-box.patch];

        meta = with pkgs.lib; {
          description = "A Discord and Fosscord client made with the Electron API";
          homepage = "https://github.com/SpacingBat3/WebCord";
          license = licenses.mit;
        };
      };
    in {
      inherit webcord;
      default = self.packages.${system}.webcord;
    });

    homeManagerModules = {
      webcord = import ./hm-module.nix self;
      default = self.homeManagerModules.webcord;
    };

    overlays = {
      webcord = _: prev: {
        inherit (self.packages.${prev.system}) webcord;
      };
      default = self.overlays.webcord;
    };

    formatter = genSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
