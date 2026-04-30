{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ha-system-ronitor = {
      url = "github:zeus-x99/ha-system-ronitor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      ha-system-ronitor,
      home-manager,
      noctalia-shell,
      sops-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      nixpkgsConfig = {
        allowUnfree = true;
      };
      pkgs = import nixpkgs {
        inherit system;
        config = nixpkgsConfig;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          bacon
          cargo
          clippy
          gcc
          lldb
          openssl
          pkg-config
          python3
          ruff
          rust-analyzer
          rustc
          rustfmt
          ty
          uv
        ];

        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
      };

      nixosConfigurations.x = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          { nixpkgs.config = nixpkgsConfig; }
          ha-system-ronitor.nixosModules.default
          home-manager.nixosModules.home-manager
          noctalia-shell.nixosModules.default
          sops-nix.nixosModules.sops
          ./hardware-configuration.nix
          ./modules/default.nix
        ];
      };
    };
}
