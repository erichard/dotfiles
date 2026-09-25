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

  home.packages = with pkgs; [ rtk just gh jq fd ripgrep bat eza fzf btop ];

  # Liens hors du store : Claude Code, noctalia et herdr réécrivent leur config, qui doit rester modifiable dans le dépôt.
  # hosts/<hôte>/ surcharge home/ : seuls y vivent les fichiers qu'une machine ne peut pas partager.
  home.file = lib.genAttrs (relative ./home) (link "home")
    // lib.optionalAttrs (builtins.pathExists hostDir)
         (lib.genAttrs (relative hostDir) (link "hosts/${hostname}"));
}
