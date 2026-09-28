{ stdenv, fetchurl, autoPatchelfHook, dbus }:

stdenv.mkDerivation rec {
  pname = "linear-cli";
  version = "0.3.28";

  src = fetchurl {
    url = "https://github.com/nesszer/linear-cli/releases/download/v${version}/linear-cli-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-WvDKxxkD3THxVVU+SJIoDb1PDzR1Nglaljv6Gut8JqM=";
  };

  sourceRoot = ".";
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ dbus stdenv.cc.cc.lib ];
  installPhase = "install -Dm755 linear-cli $out/bin/linear-cli";
}
