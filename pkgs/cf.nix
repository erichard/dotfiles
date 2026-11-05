{ writeShellScriptBin, nodejs_22 }:

# CLI Cloudflare officielle, en beta : npm la livre sans lockfile, avec un workerd natif dans miniflare.
# ponytail: npx épinglé plutôt que buildNpmPackage, qui demanderait un lockfile à maintenir à chaque bump ;
# passer à buildNpmPackage à la sortie de beta. nodejs_22 parce que cf exige ^24.22 et que nodejs_24 est en 24.21.
let version = "1.0.0-beta.27"; in
writeShellScriptBin "cf" ''
  exec ${nodejs_22}/bin/npx --yes cf@${version} "$@"
''
