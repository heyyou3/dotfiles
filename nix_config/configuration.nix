# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstableTarball =
    fetchTarball
      https://github.com/heyyou3/nixpkgs/archive/refs/tags/v1.0.4.tar.gz;
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s25.useDHCP = true;
  networking.interfaces.wlp3s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.inputMethod = {
    enabled = "fcitx";
    fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
  };
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the X11 windowing system.
  services = {
    upower.enable = true;
    blueman.enable = true;
    xserver = {
      enable = true;
      layout = "us";
      libinput = {
        enable = true;
      };
      windowManager.leftwm = {
        enable = true;
      };
    };
  };


  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.heyyou = {
    isNormalUser = true;
    home = "/home/heyyou";
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };
  fonts = {
    fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      mplus-outline-fonts
      proggyfonts
      powerline-fonts
      source-han-code-jp
      hack-font
      fira-code
      fira-code-symbols
      unstable.hackgen
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [
          "HackGenNerd"
        ];
        serif = [
          "HackGenNerd"
        ];
        sansSerif = [
          "HackGenNerd"
        ];
      };
    };
  };
  environment.variables = {
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };
  environment.systemPackages = with pkgs; [
    alacritty
    appimage-run
    binutils.bintools
    rustup
    clang
    cmake
    compton
    coreutils
    direnv
    fd
    feh
    firefox
    fzf
    gawk
    gcc
    go
    gimp
    git
    gitAndTools.tig
    gnugrep
    gnumake
    gzip
    imagemagick
    leftwm
    libtool
    lutris
    lxappearance
    neovim
    pkgconfig
    picom
    polybar
    obs-studio
    openssl
    ripgrep
    rofi
    slack
    tmux
    unzip
    vim
    wget
    wmname
    xclip
    xmobar
    xorg.xhost
    zlib
    zsh

    unstable.google-chrome
    unstable.vscode
    unstable.neovim-qt
    unstable.starship
    unstable.wineWowPackages.staging
    unstable.winetricks
    unstable.xkeysnail
    unstable.android-studio

    ((emacsPackagesNgGen emacs).emacsWithPackages (epkgs: [
      epkgs.vterm
    ]))

    python38
    (python38.withPackages (ps: with ps; [
      pip setuptools evdev lib xlib inotify-simple fetchPypi buildPythonPackage appdirs python-language-server
    ]))
  ];

  users.users.heyyou.packages = with pkgs;
  [
    lutris
    vulkan-tools
  ];

  users.users.heyyou.extraGroups = ["adbusers"];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  programs = {
    zsh.enable = true;
    dconf.enable = true;
    adb.enable = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
