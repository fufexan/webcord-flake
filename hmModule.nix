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
        description = lib.mdDoc ''
          Package to use for WebCord configuration.
        '';
        default = pkgs.webcord;
        example = lib.literalExpression ''
          pkgs.webcord.overrideAttrs (old: {
            flags = [
              "--start-minimized"
            ];
          })
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {home.packages = [cfg.package];}
  ]);
}
