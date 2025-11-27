# NixOS configuration.nix for esod.no > tux
# Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  unstable = import <unstable> {
    config.allowUnfree = true;
    config.cudaSupport = true;
  };
in


  {
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tux";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the KDE Plasma Desktop Environment.
  services.desktopManager.plasma6.enable = true;

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
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.esod = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILEvF7PEBh7El5JdDfpG23V+phQctUK2k3jgZZWx7pX0 esod_ed25519" ];
    isNormalUser = true;
    description = "Espen";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
  }; 

  security.sudo.extraRules= [
    {  users = [ "esod" ];
      commands = [
	{ command = "ALL" ;
	  options= [ "NOPASSWD" ]; # no sudo password (until using YubiKey)
	}
      ];
    }
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # packages
  environment.systemPackages = with pkgs; [
    appimage-run
    btop
    cargo
    curl
    devenv
    dig
    discord
    dmidecode
    dunst
    efibootmgr
    efivar
    fastfetch
    ffmpeg
    fish
    flameshot
    gcc
    ghostty
    git
    glxinfo
    gnumake
    google-chrome
    grc
    grim
    htop
    hyprpaper
    killall
    kitty
    lazygit
    lm_sensors
    lmstudio
    lsof
    ly
    mako
    neofetch
    nextcloud-client
    nix-search-tv
    nodejs_24
    nvd
    nvtopPackages.nvidia
    openssl
    parted
    pciutils
    playerctl # mediaplayer.py for waybar
    python312
    python312Packages.pip
    ripgrep
    slurp
    spotify
    tiny-dfr
    tmux
    todoist-electron
    unstable.cudaPackages.cuda_nvcc
    unstable.cudaPackages.cudatoolkit
    unstable.cudaPackages.cudnn
    unstable.fzf
    unstable.obsidian
    unzip
    vim
    virt-viewer
    vivaldi
    waybar
    wezterm
    wget
    wl-clipboard
    wofi
    xdg-utils
    xfce.thunar
    xfce.tumbler
    zoxide
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "24.11";

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Shells
  programs.zsh.enable = true;
  programs.fish = {
    enable = true;
    shellInit = ''
  fish_vi_key_bindings
    '';
  };

  # enable Sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraOptions = ["--unsupported-gpu"];
  };

  # kanshi systemd service
  systemd.user.services.kanshi = {
    description = "kanshi daemon";
    environment = {
      WAYLAND_DISPLAY="wayland-1";
      DISPLAY = ":0";
    }; 
    serviceConfig = {
      Type = "simple";
      ExecStart = ''${pkgs.kanshi}/bin/kanshi -c kanshi_config_file'';
    };
  };

  # Docker
  virtualisation.docker.enable = true;

  # Prometheus Node Exporter
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "cpu_vulnerabilities"
      "ethtool"
    ];
    openFirewall = true;
  };

  # Prometheus Process Exporter
  services.prometheus.exporters.process = {
    enable = true;
    port = 9256;
    openFirewall = true;
    settings.process_names = [
      { name = "{{.Comm}}"; cmdline = [ ".+" ]; }
    ];
  };


  # Netdata: enable netdata modern web ui (unfree). See https://wiki.nixos.org/wiki/Netdata
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "netdata"
  ];
  services.netdata.package = pkgs.netdata.override {
    withCloudUi = true;
  };

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
    8000 # My WhisperX backend API
    1234 # LM Studio "OpenAI" API
    19999 # Netdata
  ];

  # Enables the 1Password CLI
  programs._1password = { enable = true; };

  # Enables the 1Password desktop app
  programs._1password-gui = {
    enable = true;

    # this makes system auth etc. work properly
    polkitPolicyOwners = [ "esod" ];
  };

  # # ssh_config and ForwardAgent
  # programs.ssh.extraConfig = "ForwardAgent Yes";

  # Remap CAPS-lock to ESC (due to TouchBar not working yet)
  # services.udev.extraHwdb = ''
  # evdev:atkbd:*
  # KEYBOARD_KEY_3a=esc
  # '';
  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.comic-shanns-mono
  ];

  # override currency to dollar
  # services.xserver.xkb.extraLayouts.no = {
  #   description = "override currency to dollar";
  #   languages   = [ "no" ];
  #   symbolsFile = /home/esod/.xkb_symbols/custom;
  # };

  # NVIDIA GeForce RTX 5090
  hardware.graphics.enable = true;
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use open source kernel module (of nvidia, not nouveau" open source driver)
    # See https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    open = true;

    # Enable the Nvidia settings menu, accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Use production version
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  hardware.nvidia-container-toolkit.enable = true;

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

  # keyring
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.ly.enableGnomeKeyring = true;

  # cache for CUDA packages
  nix.settings = {
    substituters = [
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  # also enable cudaSupport
  nixpkgs.config.cudaSupport = true;

}
