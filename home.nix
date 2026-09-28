{ config, lib, pkgs, hostname, ... }:

let
  repo = "${config.home.homeDirectory}/repositories/dotfiles";
  relative = dir: map (lib.removePrefix "${toString dir}/")
    (map toString (lib.filesystem.listFilesRecursive dir));
  hostDir = ./hosts + "/${hostname}";
  link = sub: f: { source = config.lib.file.mkOutOfStoreSymlink "${repo}/${sub}/${f}"; };
in {
  home.username = "erwan";
  home.homeDirectory = "/home/erwan";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;

  # Seules les extensions passent par Nix : settings.json reste lié hors du store pour que VSCodium puisse l'écrire.
  programs.vscodium = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      anthropic.claude-code
      bmewburn.vscode-intelephense-client
      eamodio.gitlens
    ];
  };

  home.packages = with pkgs; [ age rtk just gh jq fd ripgrep bat eza fzf btop (callPackage ./pkgs/linear-cli.nix { }) ];

  # Liens hors du store : Claude Code, noctalia et herdr réécrivent leur config, qui doit rester modifiable dans le dépôt.
  # hosts/<hôte>/ surcharge home/ : seuls y vivent les fichiers qu'une machine ne peut pas partager.
  home.file = lib.genAttrs (relative ./home) (link "home")
    // lib.optionalAttrs (builtins.pathExists hostDir)
         (lib.genAttrs (relative hostDir) (link "hosts/${hostname}"));
}
