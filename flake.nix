{
  description = "Dotfiles d'Erwan — vega et orion";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      host = hostname: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home.nix ];
        extraSpecialArgs = { inherit hostname; };
      };
    in {
      homeConfigurations = {
        "erwan@vega" = host "vega";
        "erwan@orion" = host "orion";
      };
    };
}
