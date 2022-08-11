{
  lib,
  pkgs,
  # dream2nix
  satisfiesSemver,
  ...
}: {
  webcord.runBuild = let
    desktopItem = pkgs.makeDesktopItem {
      name = "WebCord";
      desktopName = "WebCord";
      genericName = "Discord and Fosscord client";
      exec = "webcord";
      icon = "webcord";
      categories = ["Network" "InstantMessaging"];
      mimeTypes = ["x-scheme-handler/discord"];
    };
  in {
    postBuild = ''
      mkdir code
      mv app/* code
      mv code app
      cp -r sources/translations app
    '';

    postInstall = ''
      mkdir -p $out/share/icons/hicolor
      for res in {24,48,64,128,256}; do
        mkdir -p $out/share/icons/hicolor/''${res}x''${res}
        ln -s $out/lib/node_modules/webcord/sources/assets/icons/app.png \
          $out/share/icons/hicolor/''${res}x''${res}/webcord.png
      done

      ln -s "${desktopItem}/share/applications" $out/share/
    '';

    postFixup = ''
      wrapProgram $out/bin/webcord \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland}}" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [pkgs.pipewire]}"
    '';
  };
}
