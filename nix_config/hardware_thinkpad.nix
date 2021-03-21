{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  hardware.pulseaudio.enable = true;
  hardware.opengl.driSupport32Bit = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/fecde1e6-e4f2-476c-b36e-48aa4029c5db";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/58b7ba7a-e3e7-426b-9a26-5ba9124bbe11"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
