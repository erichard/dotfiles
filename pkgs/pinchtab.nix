{ stdenv, fetchurl, fetchFromGitHub, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "pinchtab";
  version = "0.15.2";

  src = fetchurl {
    url = "https://github.com/pinchtab/pinchtab/releases/download/v${version}/pinchtab-linux-amd64";
    hash = "sha256-C7T5ehyS+UvNut/8OdxphaR1fIineHa7y0IUIZHoIC0=";
  };

  # Le skill agent n'est livré que par le postinstall npm : on le prend dans le source du même tag.
  skill = fetchFromGitHub {
    owner = "pinchtab";
    repo = "pinchtab";
    rev = "v${version}";
    hash = "sha256-KoZrw03jjV8PFF501qH8pBbYZirms9XwGQHhB5a0nk4=";
  };

  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    install -Dm755 $src $out/bin/pinchtab
    mkdir -p $out/share/pinchtab/skills
    cp -r ${skill}/skills/pinchtab $out/share/pinchtab/skills/
  '';
}
