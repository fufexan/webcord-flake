# WebCord Flake

A Discord and Fosscord client implemented directly without Discord API.

## Use with Flakes

#### In your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";

    webcord.url = "github:fufexan/webcord-flake";
  };

  outputs = {self, nixpkgs, webcord, ...} @ inputs: {
    # for NixOS
    nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      # ...
    };

    # for Home Manager
    homeConfigurations."USER@HOSTNAME" = home-manager.lib.homeManagerConfiguration {
      extraSpecialArgs = {inherit inputs;};
      # ...
    };
  };
}
```

> Don't forget to replace `HOSTNAME` with your hostname, or `USER@HOSTNAME` with your profile name!

#### In your `configuration.nix` or `home.nix`:

```nix
{pkgs, inputs, ...}: {
  environment.systemPackages = [ # or home.packages
    inputs.packages.${pkgs.system}.default
    # ...
  ];
}
```

### Merging with `pkgs`

Optionally, if you import `nixpkgs` manually (and don't use `legacyPackages`), you can use `pkgs.webcord` as if it were any other package.

#### In your `flake.nix`:

```nix
outputs = {self, nixpkgs, webcord, ...}: let
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    # config.allowUnfree = true;
    overlays = [
      webcord.overlays.default
    ];
  };
in {
  # for NixOS
  nixosConfigurations.HOSTNAME = nixpkgs.lib.nixosSystem {
    inherit pkgs;
    # ...
  };

  # for Home Manager
  homeConfigurations."USER@HOSTNAME" = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    # ...
  };
};
```

> Don't forget to replace `HOSTNAME` with your hostname, or `USER@HOSTNAME` with your profile name!

Note that using `specialArgs` and `extraSpecialArgs` (to pass `inputs`) can be avoided in this manner.

## Use without Flakes

#### In your `configuration.nix` or `home.nix`

```nix
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
environment.variables.NIXOS_OZONE_WL = "1";
```

### Home Manager

```nix
home.sessionVariables.NIXOS_OZONE_WL = "1";
```

## Theming

There are two methods of setting themes, one of them implemented directly by WebCord, the other uses a little help from Nix.

### Home Manager Module

> - `Themes` refers to the directory `$XDG_CONFIG_DIR/WebCord/Themes`.
> - *"the flag"* refers to the shell command argument `--add-css-theme` (see [next section](#package-override)).

You can import the Home Manager module to set themes declaratively (and reproducibly).
This is recommended over using the `--add-css-theme` flag for several reasons:

- WebCord watches `Themes` and will reload itself when it detects changes to that directory.
  - If you use the flag, WebCord will need a restart, as well as some extra hand-holding (detailed later).
- When using the flag, WebCord copies specified stylesheets to `Themes`.
  - When using this module, there are fewer things for WebCord to do when starting up.
- WebCord does not delete "unused" files from `Themes` when they are removed from the launch flags.
- WebCord will load all themes, unconditionally, from `Themes`.
  - This *will* lead to conflicts unless you manually clear the directory.
- ~~WebCord will spawn a dialog asking if really want to add a theme when passed via the flag.~~
  - *This is fixed by a patch included with this Flake.*
- When using the flag, only the first path specified will be copied.
  - This means you have to manually merge themes, and pass them as a single file.

#### In your `home.nix` (only):

```nix
imports = [
  inputs.webcord.homeManagerModules.default
];

programs.webcord = {
  enable = true;
  themes = let
    catppuccin = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "discord";
      rev = "159aac939d8c18da2e184c6581f5e13896e11697";
      sha256 = "sha256-cWpog52Ft4hqGh8sMWhiLUQp/XXipOPnSTG6LwUAGGA=";
    };
  in {
    CatpuccinMocha = "${catppuccin}/themes/mocha.theme.css";
  };
};
```

### Package Override

You can set themes (non-reproducibly) by overriding the package.

#### In your `configuration.nix` or `home.nix`:

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
  system.packages = [ # or home.packages
    (inputs.webcord.packages.${pkgs.system}.default.override {
      flags = ["--add-css-theme=${theme}"];
    })
  ];
}
```

## Cachix

You can use the Cachix cache to download the binary directly instead of building it:

```nix
nix.settings = {
  substituters = ["https://webcord.cachix.org"];
  trusted-public-keys = ["webcord.cachix.org-1:l555jqOZGHd2C9+vS8ccdh8FhqnGe8L78QrHNn+EFEs="];
}
```
