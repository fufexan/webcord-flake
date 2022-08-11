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
