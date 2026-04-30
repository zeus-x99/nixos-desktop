{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      mangohud
      bubblewrap
      ffmpeg
      fastfetch
      playerctl

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

    variables.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };
}
