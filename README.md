# WebCord Flake

A Discord and Fosscord client implemented directly without Discord API.

## Use with flakes

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";

    webcord.url = "github:fufexan/webcord-flake";
  };

  outputs = { self, nixpkgs, webcord, ... }@inputs: {
    # for NixOS
    nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
      specialArgs = inputs;
      # ...
    };

    # for Home-Manager
    homeConfigurations.USER@HOST = home-manager.lib.homeManagerConfiguration {
      extraSpecialArgs = inputs;
      # ...
    };
  };
```

```nix
# configuration.nix or home.nix
{ pkgs, webcord, ... }:

{
  environment.systemPackages = [ # or home.packages
    webcord.packages.${pkgs.system}.default
    # ...
  ];
}
```

Don't forget to replace `HOSTNAME` with your hostname, or `USER@HOST` with your profile name!

## Use without flakes

```nix
# configuration.nix or home.nix
{config, pkgs, ...}: let
  flake-compat = builtins.fetchTarball "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
  webcord = (import flake-compat {
    src = builtins.fetchTarball "https://github.com/fufexan/webcord-flake/archive/master.tar.gz";
  }).defaultNix;
in {
  environment.systemPackages = [ # or home.packages
    webcord.packages.${pkgs.system}.default
    # ...
  ];
}
```

## Wayland

WebCord runs natively on Wayland, using the standard `--ozone-platform=wayland`
flag. This package comes with a wrapper that adds that flag automatically when
the `NIXOS_OZONE_WL=1` environment variable is set, following the example of
popular packages in Nixpkgs, like VSCode.

### NixOS

```nix
{
  environment.variables.NIXOS_OZONE_WL = "1";
}
```

### Home Manager
```nix
{
  home.sessionVariables.NIXOS_OZONE_WL = "1";
}
```

## Theming

You can set themes declaratively, by overriding the package. For example:
```nix
{pkgs, inputs, ...}: let
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "discord";
    rev = "159aac939d8c18da2e184c6581f5e13896e11697";
    sha256 = "sha256-cWpog52Ft4hqGh8sMWhiLUQp/XXipOPnSTG6LwUAGGA=";
  };

  theme = "${catppuccin}/themes/mocha.theme.css";
in {
  home.packages = [
    (inputs.webcord.packages.${pkgs.system}.default.override {flags = "--add-css-theme=${theme}";})
  ];
}
```

## Cachix

You can use the Cachix cache to download the binary directly instead of building it
```nix
nix.settings = {
  substituters = ["https://webcord.cachix.org"];
  trusted-public-keys = ["webcord.cachix.org-1:l555jqOZGHd2C9+vS8ccdh8FhqnGe8L78QrHNn+EFEs="];
}
```
