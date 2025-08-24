# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{

  # Imports
  imports = [ ./hardware-configuration.nix ];

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      # Using XBOOTLDR resulted in "black screen" on my MBP17. Keep for reference (future testing)
      # xbootldrMountPoint = "/boot";
    };
    efi = {
      canTouchEfiVariables = true;
      # custom EFI partition created by macOS installer (conotains firmware for touchbar, etc.)
      efiSysMountPoint = "/boot/efi";
    };
  };

  # WIP: 6.15 kernel not supported as zfs-kernel-2.3.2-6.15-rc7 is broken. Retry later.
  # boot.kernelPackages = pkgs.linuxPackages_testing;

  # ZFS related
  networking.hostId = "da60cc6c"; # head -c 8 /etc/machine-id
  boot.zfs.extraPools = [ "zpool" ];
  # "experimental" hibernation testing on laptop
  # boot.zfs.allowHibernation = true;
  # boot.zfs.forceImportRoot = false;

  networking.hostName = "mbp17-01"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Display Manager
  # services.displayManager.sddm.enable = true;
  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings = {
    save = true;
    animation = "matrix";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "no";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "no";

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.esod = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILEvF7PEBh7El5JdDfpG23V+phQctUK2k3jgZZWx7pX0 esod_ed25519"
    ];
    isNormalUser = true;
    description = "Espen";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
  };

  security.sudo.extraRules = [{
    users = [ "esod" ];
    commands = [{
      command = "ALL";
      options =
        [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
    }];
  }];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
    unstable = import (fetchTarball
      "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
        config.allowUnfree = true;
      };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    _1password-cli
    _1password-gui
    appimage-run
    brightnessctl
    btop
    cargo
    curl
    dig
    discord
    dmidecode
    efibootmgr
    efivar
    fish
    gcc
    ghostty
    git
    glxinfo
    gnumake
    google-chrome
    grim
    htop
    killall
    kitty
    lazygit
    linuxKernel.kernels.linux_testing
    lm_sensors
    lmstudio
    logseq
    lsof
    ly
    mako
    neovim
    nextcloud-client
    nodejs_24
    nvd
    ollama
    openssl
    parted
    pciutils
    ripgrep
    slurp
    spotify
    tiny-dfr
    todoist-electron
    unstable.fzf
    unstable.obsidian
    unzip
    vim
    vivaldi
    waybar
    wezterm
    wget
    wl-clipboard
    wofi
    xdg-utils
    xfce.thunar
    xfce.tumbler
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Shells
  programs.zsh.enable = true;
  programs.fish = {
    enable = true;
    shellInit = "	fish_vi_key_bindings\n";
  };

  # Hypr
  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Enables the 1Password CLI
  programs._1password = { enable = true; };

  # Enables the 1Password desktop app
  programs._1password-gui = {
    enable = true;

    # this makes system auth etc. work properly
    polkitPolicyOwners = [ "esod" ];
  };

  # kanshi systemd service
  systemd.user.services.kanshi = {
    description = "kanshi daemon";
    environment = {
      WAYLAND_DISPLAY = "wayland-1";
      DISPLAY = ":0";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.kanshi}/bin/kanshi -c kanshi_config_file";
    };
  };

  # Docker
  virtualisation.docker.enable = true;

  # Prometheus Node Exporter
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "cpu_vulnerabilities" "ethtool" ];
    openFirewall = true;
  };

  # Prometheus Process Exporter
  services.prometheus.exporters.process = {
    enable = true;
    port = 9256;
    openFirewall = true;
    settings.process_names = [{
      name = "{{.Comm}}";
      cmdline = [ ".+" ];
    }];
  };

  # Netdata
  services.netdata = {
    enable = true;
    config = {
      global = {
        "memory mode" = "ram";
        "debug log" = "none";
        "access log" = "none";
        "error log" = "syslog";
      };
    };
  };

  # Firewall
  networking.firewall.allowedTCPPorts = [
    19999 # netdata
  ];

  #  # Logseq bruker EOL-versjon av Electron
  #  nixpkgs.config.permittedInsecurePackages = [
  #    "electron-27.3.11"
  #  ];

  # NOTE: Leftovers from while trying to fix WiFi on BCM43602 rev 02
  # networking.networkmanager.wifi.scanRandMacAddress = false;
  # networking.networkmanager.wifi.backend = "iwd";
  # networking.networkmanager.wifi.macAddress = "00:90:4c:0d:f4:3e";
  # boot.kernelParams = [ "brcmfmac.feature_disable=0x82000" ];
  # boot.kernelModules = [ "wl" ];
  # boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  # boot.blacklistedKernelModules = [ "b43" "bcma" "brcmfmac" ];

  # HACK: for WiFi on BCM43602 rev 2. See https://bugzilla.kernel.org/show_bug.cgi?id=193121
  hardware.firmware = [
    (pkgs.runCommandNoCC "brcmfmac43602-pcie" { } ''
      mkdir -p $out/lib/firmware/brcm
      cp ${
        ./brcmfmac43602-pcie.txt
      } $out/lib/firmware/brcm/brcmfmac43602-pcie.txt
    '')
  ];

  # WIP: Apple TouchBar
  hardware.apple.touchBar.enable = true;
  powerManagement.enable = true;

  # ssh_config and ForwardAgent
  programs.ssh.extraConfig = "ForwardAgent Yes";

  # Remap CAPS-lock to ESC (due to TouchBar not working yet)
  services.udev.extraHwdb = "	evdev:atkbd:*\n	KEYBOARD_KEY_3a=esc\n";

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Fonts
  fonts.packages = with pkgs;
    [
      # (nerdfonts.override { fonts = [ "ComicShannsMono" ]; })
      nerd-fonts.comic-shanns-mono
    ];

  # override currency to dollar
  # services.xserver.xkb.extraLayouts.no = {
  #   description = "override currency to dollar";
  #   languages = [ "no" ];
  #   symbolsFile = /home/esod/.xkb_symbols/custom;
  # };

  # Installer version used (initially)
  system.stateVersion = "25.05";

  # keyring
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.ly.enableGnomeKeyring = true;

}
