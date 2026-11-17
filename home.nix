{ config, lib, pkgs, hostname, ... }:

let
  repo = "${config.home.homeDirectory}/repositories/dotfiles";
  relative = dir: map (lib.removePrefix "${toString dir}/")
    (map toString (lib.filesystem.listFilesRecursive dir));
  hostDir = ./hosts + "/${hostname}";
  link = sub: f: { source = config.lib.file.mkOutOfStoreSymlink "${repo}/${sub}/${f}"; };
  pinchtab = pkgs.callPackage ./pkgs/pinchtab.nix { };
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
  home.packages = with pkgs; [ age chezmoi rtk just gh stripe-cli scaleway-cli jq fd ripgrep bat eza fzf btop lazygit intelephense slack claude-code herdr nh openspec (callPackage ./pkgs/linear-cli.nix { }) pinchtab whisrs jetbrains-mono ];
  # whisrs ne lit ses clés que dans l'environnement. Elles sortent de 1Password une fois par session,
  # vers un fichier 0600 en /run/user (tmpfs) : redémarrer whisrs ne redemande plus d'autorisation.
  systemd.user.services.whisrs-secrets = {
    Unit.Description = "Clés de whisrs depuis 1Password";
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/usr/bin/op run --account revelhome.1password.eu --env-file=%h/.config/whisrs/op.env -- sh -c 'umask 077 && env | grep ^WHISRS_ > %t/whisrs.env'";
      ExecStop = "rm -f %t/whisrs.env";
      # 1Password peut être encore verrouillé à l'ouverture de session.
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
  systemd.user.services.whisrs = {
    Unit = {
      Description = "whisrs dictation daemon";
      After = [ "graphical-session.target" "whisrs-secrets.service" ];
      Requires = [ "whisrs-secrets.service" ];
    };
    Service = {
      EnvironmentFile = "%t/whisrs.env";
      ExecStart = "${pkgs.whisrs}/bin/whisrsd";
      Restart = "on-failure";
      RestartSec = 3;
      # L'alsa-lib de Nix ne voit pas le plugin PipeWire du système : sans lui, le micro « default » et les bips échouent.
      Environment = "ALSA_PLUGIN_DIR=${pkgs.pipewire}/lib/alsa-lib";
      PassEnvironment = "HYPRLAND_INSTANCE_SIGNATURE NIRI_SOCKET SWAYSOCK WAYLAND_DISPLAY DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_RUNTIME_DIR";
    };
    Install.WantedBy = [ "default.target" ];
  };
  # Rend les polices de home.packages visibles de fontconfig, donc de kitty.
  fonts.fontconfig.enable = true;

  # Liens hors du store : Claude Code et herdr réécrivent leur config, qui doit rester modifiable dans le dépôt.
  # hosts/<hôte>/ surcharge home/ : seuls y vivent les fichiers qu'une machine ne peut pas partager.
  home.file = { ".config/home-manager".source = config.lib.file.mkOutOfStoreSymlink repo; }
    // { ".claude/skills/pinchtab".source = "${pinchtab}/share/pinchtab/skills/pinchtab"; }
    // lib.genAttrs (relative ./home) (link "home")
    // lib.optionalAttrs (builtins.pathExists hostDir)
         (lib.genAttrs (relative hostDir) (link "hosts/${hostname}"));
}
