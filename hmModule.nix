{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types;
  cfg = config.programs.webcord;
in {
  options = {
    programs.webcord = {
      enable = lib.mkEnableOption cfg.package.meta.description;

      package = lib.mkOption {
        type = types.package;
        default = pkgs.webcord;
        description = lib.mdDoc ''
          Package to use for WebCord configuration.
        '';
        example = lib.literalExpression ''
          pkgs.webcord.overrideAttrs (old: {
            flags = [
              "--start-minimized"
            ];
          })
        '';
      };

      themes = lib.mkOption {
        type = types.attrsOf types.string;
        default = {};
        description = lib.mdDoc ''
          An attribute set of themes, where each key is the name of the
          theme when linked into `$XDG_CONFIG_HOME/WebCord/Themes`,
          and the value is the file path of the CSS source.

          *This will need to change once
        '';
        example = lib.literalExpression ''
          let
            repo = pkgs.fetchFromGitHub {
              owner = "mwittrien";
              repo = "BetterDiscordAddons";
              rev = "8627bb7f71c296d9e05d82538d3af8f739f131dc";
              sha256 = "sha256-Dn6igqL0GvaOcTFZOtQOxuk0ikrWxyDZ41tNsJXJAxc=";
            };

            themes = {
              discord-recolor = "''${repo}/Themes/DiscordRecolor/DiscordRecolor.theme.css";
              settings-modal = "''${repo}/Themes/SettingsModal/SettingsModal.theme.css";
            };
          in {
            DiscordRecolor = themes.discord-recolor;
            SettingsModal = themes.settings-modal;
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # add the package
    {home.packages = [cfg.package];}

    # handle the themes if any
    (lib.mkIf (cfg.themes != {}) {
      # for every theme provided, create a symlink in the conf dir
      # to the path provided (see themes opt description)
      xdg.configFile =
        lib.mapAttrs' (name: source: {
          name = "WebCord/Themes/${name}";
          value = {inherit source;};
        })
        cfg.themes;
    })
  ]);
}
