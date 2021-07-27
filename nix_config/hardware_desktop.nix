{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.loader.grub.device = "/dev/sdc"; # or "nodev" for efi only

  hardware.pulseaudio.enable = true;
  hardware.opengl.driSupport32Bit = true;

  hardware.bluetooth.enable = true;

  services.xserver.videoDrivers = ["nvidia"];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/f3385fbd-bd01-4bce-a515-d8e219690693";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/91abfb17-4c00-4cd6-b4aa-e4c13ee48499"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
