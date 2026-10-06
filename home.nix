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
      bmewburn.vscode-intelephense-client
      eamodio.gitlens
      jdinhlife.gruvbox
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      # Absente de nixpkgs : tirée du Marketplace.
      { publisher = "mblode"; name = "twig-language-2"; version = "0.12.1"; sha256 = "1k0rfl3xzvx6dscpzi1s2dhzrs8n0xmryag99rvzcr6vq1yxj9j2"; }
    ];
  };

  # 1Password reste sous pacman : op doit être setgid pour joindre l'application, ce que le store Nix ne permet pas.
  home.packages = with pkgs; [ age chezmoi rtk just gh stripe-cli jq fd ripgrep bat eza fzf btop lazygit intelephense slack claude-code herdr nh (callPackage ./pkgs/linear-cli.nix { }) ];

  # Liens hors du store : Claude Code et herdr réécrivent leur config, qui doit rester modifiable dans le dépôt.
  # hosts/<hôte>/ surcharge home/ : seuls y vivent les fichiers qu'une machine ne peut pas partager.
  home.file = { ".config/home-manager".source = config.lib.file.mkOutOfStoreSymlink repo; }
    // lib.genAttrs (relative ./home) (link "home")
    // lib.optionalAttrs (builtins.pathExists hostDir)
         (lib.genAttrs (relative hostDir) (link "hosts/${hostname}"));
}
