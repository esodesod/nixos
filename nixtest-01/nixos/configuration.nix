# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # https://discourse.nixos.org/t/setting-sys-module-hid-apple-parameters-fnmode-to-0-at-boot/15570
  boot.extraModprobeConfig = ''
	  options hid_apple iso_layout=1
  '';
  boot.kernelModules = [ "hid_apple" ];

  # https://github.com/NixOS/nixpkgs/issues/20906
  boot.kernelParams = [ "hid_apple.iso_layout=1" ];


  networking.hostName = "nixtest-01"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
  # services.xserver.exportConfiguration = true;
  # # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # faster repeat key rate
  services.xserver.displayManager.sessionCommands = ''
    xset r rate 200 40
    xrandr --output Virtual-1 --mode 3840x2160
    xrandr --dpi 192
  '';

  # i3
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      dmenu
      i3status
      i3lock
      i3blocks
    ];
  };

  # not available on arm (yet)
  # services.xserver.videoDrivers = [
  #  "vmware"
  # ];


  # T E S T
  # programs.hyprland = {
  #  enable = true;
  #  withUWSM = true; # recommended for most users
  #   # xwayland.enable = true; # Xwayland can be disabled.
  #   # systemd.setPath.enable = true;
  # };
  # programs.waybar.enable = true;
  #
  # xdg.portal = {
  #   enable = true;
  #   extraPortals = [
  #     pkgs.xdg-desktop-portal-gtk
  #     # inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
  #   ];
  # };
  #


  # environment.sessionVariables = {
  # # If your cursor becomes invisible
  # WLR_NO_HARDWARE_CURSORS = "1";
  # # Hint electron apps to use wayland
  # NIXOS_OZONE_WL = "1";
  # WLR_RENDERER_ALLOW_SOFTWARE= "1";
  # };


  # LD
  # programs.nix-ld.enable = true;
  # programs.nix-ld.libraries = with pkgs; [
  # ];


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "no";
    variant = "mac";
    model = "apple";
    # model = "pc105";
  };

  # Configure console keymap
  console.keyMap = "no";

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.esod = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILEvF7PEBh7El5JdDfpG23V+phQctUK2k3jgZZWx7pX0 esod_ed25519" ];
    isNormalUser = true;
    description = "Espen";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
    packages = with pkgs; [
      kdePackages.kate
      #  thunderbird
    ];
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

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    neovim
    git
    htop
    btop
    fzf
    dig
    ripgrep
    open-vm-tools
    wezterm
    kitty	
    wofi
    dolphin
    gtk3
    gnumake
    unzip
    gcc
    nerdfonts
    cargo
    nodejs_22
    nvd
    tmux
    xclip
    xsel
    xorg.xev
    obsidian
    mesa-demos
  ];

  # Docker
  virtualisation.docker.enable = true;

  # VMware Guest
  virtualisation.vmware.guest.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "cpu_vulnerabilities"
      "ethtool"
    ];
    openFirewall = true;
  };
  services.prometheus.exporters.process = {
    enable = true;
    port = 9256;
    openFirewall = true;
    settings.process_names = [
      { name = "{{.Comm}}"; cmdline = [ ".+" ]; }
    ];
  };

  # shells
  programs.zsh.enable = true;
  programs.fish.enable = true;

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
  system.stateVersion = "24.11"; # Did you read the comment?

}
