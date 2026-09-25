{ config, lib, pkgs, hostname, ... }:

let
  repo = "${config.home.homeDirectory}/repositories/dotfiles";
  orionOnly = [ ".config/hypr/" ".config/kitty/" ".config/noctalia/" ];
  dotfiles = map (lib.removePrefix "${toString ./home}/")
    (map toString (lib.filesystem.listFilesRecursive ./home));
  wanted = f: "orion" == hostname || !(lib.any (p: lib.hasPrefix p f) orionOnly);
in {
  home.username = "erwan";
  home.homeDirectory = "/home/erwan";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;

  home.packages = with pkgs; [ rtk just gh jq fd ripgrep bat eza fzf btop ];

  # Liens hors du store : Claude Code, noctalia et herdr réécrivent leur config, qui doit rester modifiable dans le dépôt.
  home.file = lib.genAttrs (lib.filter wanted dotfiles)
    (f: { source = config.lib.file.mkOutOfStoreSymlink "${repo}/home/${f}"; });
}
