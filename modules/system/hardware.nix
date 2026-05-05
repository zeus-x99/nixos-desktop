{ config, lib, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  systemd.services.nvidia-uvm-devices = {
    description = "Create NVIDIA UVM device nodes";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.kmod}/bin/modprobe nvidia_uvm || true

      major="$(${pkgs.gawk}/bin/awk '$2 == "nvidia-uvm" { print $1 }' /proc/devices)"
      if [ -n "$major" ]; then
        [ -e /dev/nvidia-uvm ] || ${pkgs.coreutils}/bin/mknod -m 666 /dev/nvidia-uvm c "$major" 0
        [ -e /dev/nvidia-uvm-tools ] || ${pkgs.coreutils}/bin/mknod -m 666 /dev/nvidia-uvm-tools c "$major" 1
        ${pkgs.coreutils}/bin/chmod 666 /dev/nvidia-uvm /dev/nvidia-uvm-tools
      fi
    '';
  };

  services.udev.extraRules = lib.mkForce ''
    KERNEL=="tun", TAG+="systemd"

    ACTION=="add|remove", SUBSYSTEM=="net", ENV{DEVTYPE}=="wlan", \
    RUN+="/run/current-system/systemd/bin/systemctl try-restart wpa_supplicant.service"

    SUBSYSTEM=="input", KERNEL=="mice", TAG+="systemd"

    KERNEL=="nvidia", RUN+="${pkgs.runtimeShell} -c '[ -e /dev/nvidiactl ] || mknod -m 666 /dev/nvidiactl c 195 255'"
    KERNEL=="nvidia", RUN+="${pkgs.runtimeShell} -c 'for i in $$(cat /proc/driver/nvidia/gpus/*/information | grep Minor | cut -d \\  -f 4); do [ -e /dev/nvidia$${i} ] || mknod -m 666 /dev/nvidia$${i} c 195 $${i}; chmod 666 /dev/nvidia$${i}; done'"
    KERNEL=="nvidia_modeset", RUN+="${pkgs.runtimeShell} -c '[ -e /dev/nvidia-modeset ] || mknod -m 666 /dev/nvidia-modeset c 195 254'"
    KERNEL=="nvidia_uvm", RUN+="${pkgs.runtimeShell} -c '[ -e /dev/nvidia-uvm ] || mknod -m 666 /dev/nvidia-uvm c $$(grep nvidia-uvm /proc/devices | cut -d \\  -f 1) 0'"
    KERNEL=="nvidia_uvm", RUN+="${pkgs.runtimeShell} -c '[ -e /dev/nvidia-uvm-tools ] || mknod -m 666 /dev/nvidia-uvm-tools c $$(grep nvidia-uvm /proc/devices | cut -d \\  -f 1) 1'"

    SUBSYSTEM=="misc", KERNEL=="sgx_enclave",   SYMLINK+="sgx/enclave"
    SUBSYSTEM=="misc", KERNEL=="sgx_provision", SYMLINK+="sgx/provision"
  '';
}
