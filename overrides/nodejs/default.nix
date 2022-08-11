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
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [pkgs.pipewire]}"
    '';
  };
}
