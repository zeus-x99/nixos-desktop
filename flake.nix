{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ha-system-ronitor = {
      url = "github:zeus-x99/ha-system-ronitor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    ha-system-ronitor,
    quickshell,
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
        specialArgs = { inherit quickshell; };
        modules = [
          { nixpkgs.config = nixpkgsConfig; }
          ha-system-ronitor.nixosModules.default
          sops-nix.nixosModules.sops
          ./hardware-configuration.nix
          ./modules/default.nix
        ];
      };
    };
}
