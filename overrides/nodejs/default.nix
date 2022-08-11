{
  lib,
  pkgs,
  # dream2nix
  satisfiesSemver,
  ...
}: {
  webcord.runBuild = {
    postBuild = ''
      mkdir code
      mv app/* code
      mv code app
      cp -r sources/translations app
    '';

    postFixup = ''
      wrapProgram $out/bin/webcord \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland}}" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [pkgs.pipewire]}"
    '';
  };
}
