# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstableTarball =
    fetchTarball
      https://github.com/heyyou3/nixpkgs/archive/refs/tags/v1.0.9.tar.gz;
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "fcitx";
      fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
    };
    extraLocaleSettings = {
      LC_MESSAGES = "en_US.UTF-8";
    };
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
      desktopManager = {
        xterm.enable = false;
        plasma5.enable = true;
      };
      displayManager = {
        defaultSession = "none+i3";
        # Enable the Plasma 5 Desktop Environment.
        sddm.enable = true;
      };
      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;
        extraPackages = with pkgs; [
          dmenu #application launcher most people use
          i3status # gives you the default i3 status bar
          i3lock #default i3 screen locker
          i3blocks #if you are planning on using i3blocks over i3status
        ];
      };
      config = ''
        Section "Device"
          Identifier "DisplayLink"
          Driver "modesetting"
          Option "PageFlip" "false"
        EndSection
      '';
    };

    tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0=65;
        STOP_CHARGE_THRESH_BAT0=80;
        RUNTIME_PM_BLACKLIST="\"08:00.3 08:00.4\"";
        PCIE_ASPM_ON_AC="\"performance\"";
        PCIE_ASPM_ON_BAT="\"performance\"";
      };
    };
  };


  security.rtkit.enable = true;


  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  virtualisation.docker.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.heyyou = {
    isNormalUser = true;
    home = "/home/heyyou";
    extraGroups = [ "wheel" "networkmanager" "docker" "audio" "sound" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
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
      hack-font
      font-awesome
      ibm-plex
      unstable.hackgen
      unstable.firge
      unstable.cica
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "Cica"
        ];
        serif = [
          "IBM Plex Sans JP"
        ];
        sansSerif = [
          "IBM Plex Sans JP"
        ];
      };
    };
  };
  environment.pathsToLink = [ "/libexec" ];
  environment.variables = {
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    LIBGL_DRI3_DISABLE = "true";
    EDITOR = "vim";
  };
  environment.systemPackages = with pkgs;
    let
      polybar = pkgs.polybar.override {
        i3Support = true;
      };
    in
      [
        acpi
        authy
        alacritty
        appimage-run
        binutils.bintools
        blueman
        brave
        clang
        cmake
        compton
        coreutils
        direnv
        docker-compose
        fd
        feh
        firefox
        fzf
        gawk
        gcc
        gimp
        git
        gitAndTools.tig
        gnugrep
        gnumake
        go
        graphviz
        gzip
        imagemagick
        jre8
        leftwm
        libtool
        lutris
        lxappearance
        pciutils
        neofetch
        ntfs3g
        obs-studio
        openssl
        picom
        pkgconfig
        polybar
        ripgrep
        rofi
        ruby
        rustup
        tmux
        tree
        unzip
        vim
        wget
        wmname
        xorg.xev
        xclip
        xmobar
        xorg.xhost
        woeusb
        zlib
        zsh
        ranger

        unstable.android-studio
        unstable.discord
        unstable.google-chrome
        unstable.neovim-qt
        unstable.slack
        unstable.starship
        unstable.vscode
        unstable.neovim
        unstable.wineWowPackages.staging
        unstable.winetricks
        unstable.xkeysnail
        unstable.kitty

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
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
  system.autoUpgrade.channel = https://nixos.org/channels/nixos-21.05;
  system.stateVersion = "21.05"; # Did you read the comment?
}
