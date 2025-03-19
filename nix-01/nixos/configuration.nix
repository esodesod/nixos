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
  # OS settings
  networking.hostName = "nix-01";
  networking.networkmanager.enable = true; 
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "no";

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

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # QEMU Guest Agent
  services.qemuGuest.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    btop
    cargo
    dig
    fzf
    gcc
    git
    gnumake
    htop
    neovim
    nodejs_23
    nvd
    openssl
    ripgrep
    tcpdump
    unzip
    vim
    wget
    k9s
    minikube
    kubectl
  ];

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Environment variables
  environment.variables = {
    MANPAGER = "nvim +Man!";
  };


  # Shells
  programs.zsh.enable = true;
  programs.fish = {
	  enable = true;
	  shellInit = ''
		  fish_vi_key_bindings
		  '';
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
    6666 # nvim remote testing
  ];

  # Fonts
  fonts.packages = with pkgs; [
          (nerdfonts.override { fonts = [ "ComicShannsMono" ]; })
  ];

  system.stateVersion = "24.11"; # Did you read the comment?
}
