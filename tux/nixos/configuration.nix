# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tux"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  # services.xserver.enable = true;

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
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
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
		  options= [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
	  }
	  ];
  }
  ];

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
	  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
		  config.allowUnfree = true;
	  };
    };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    _1password-cli
    _1password-gui
    appimage-run
    btop
    cargo
    curl
    devenv
    dig
    discord
    dunst
    fastfetch
    ffmpeg
    fish
    gcc
    ghostty
    git
    glxinfo
    gnumake
    google-chrome
    grim
    htop
    kitty
    lmstudio
    # logseq
    ly
    mako
    neofetch
    nextcloud-client
    nodejs_23
    nvd
    nvtopPackages.nvidia
    # ollama
    openssl
    pciutils
    python312
    python312Packages.pip
    ripgrep
    slurp
    spotify
    tiny-dfr
    todoist-electron
    unstable.cudaPackages.cuda_nvcc
    unstable.cudaPackages.cudatoolkit
    unstable.cudaPackages.cudnn
    unstable.fzf
    unstable.neovim
    unstable.obsidian
    unzip
    vim
    waybar
    wezterm
    wget
    wl-clipboard
    wofi
    # testing mediaplayer.py for waybar
    playerctl
    python312Packages.pygobject3
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

  # gnome-keyring suggested for Sway. See https://wiki.nixos.org/wiki/Sway
  services.gnome.gnome-keyring.enable = true;

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


# Netdata
# Enable netdata modern web ui (unfree). See https://wiki.nixos.org/wiki/Netdata
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
    19999 # netdata
  ];

  # Logseq bruker EOL-versjon av Electron
  # nixpkgs.config.permittedInsecurePackages = [
  #   "electron-27.3.11"
  # ];

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
  (nerdfonts.override { fonts = [ "ComicShannsMono" ]; })
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

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
	    version = "570.133.07";
	    sha256_64bit = "sha256-LUPmTFgb5e9VTemIixqpADfvbUX1QoTT2dztwI3E3CY=";
	    sha256_aarch64 = "sha256-yTovUno/1TkakemRlNpNB91U+V04ACTMwPEhDok7jI0=";
	    openSha256 = "sha256-9l8N83Spj0MccA8+8R1uqiXBS0Ag4JrLPjrU3TaXHnM=";
	    settingsSha256 = "sha256-XMk+FvTlGpMquM8aE8kgYK2PIEszUZD2+Zmj2OpYrzU=";
	    persistencedSha256 = "sha256-G1V7JtHQbfnSRfVjz/LE2fYTlh9okpCbE4dfX9oYSg8=";
    };
  };

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

}
