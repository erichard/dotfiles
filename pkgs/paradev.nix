{ appimageTools, fetchurl }:

let
  pname = "paradev";
  version = "2.0.0";

  # Les assets de release portent encore l'ancien nom, Superset.
  src = fetchurl {
    url = "https://github.com/ParadevAI/Paradev/releases/download/desktop-v${version}/superset-${version}-x86_64.AppImage";
    hash = "sha256-SFfx9iVQPQ2ASKxVAKfxkGLtJhzVwb54fMSoeb9ilsI=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm644 ${contents}/superset.desktop $out/share/applications/paradev.desktop
    install -Dm644 ${contents}/superset.png $out/share/icons/hicolor/512x512/apps/superset.png
    substituteInPlace $out/share/applications/paradev.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=paradev' \
      --replace-fail 'Exec=superset' 'Exec=paradev'
  '';
}
