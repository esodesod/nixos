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
      netbootxyz.enable = true;
    };
    efi = {
      canTouchEfiVariables = true;
      # custom EFI partition created by macOS installer (contains firmware for Apple MBP 2017 touchbar, etc.)
      efiSysMountPoint = "/boot";
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

  # security.sudo.extraRules = [{
  #   users = [ "esod" ];
  #   commands = [{
  #     command = "ALL";
  #     options =
  #       [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
  #   }];
  # }];

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
    appimage-run
    bluetui
    bluez
    bluez-tools
    brightnessctl
    btop
    cargo
    cryptsetup
    curl
    dig
    discord
    dmidecode
    dunst
    efibootmgr
    efivar
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
    logseq
    lsof
    ly
    # mako
    nextcloud-client
    nix-search-tv
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
    virt-viewer
    vivaldi
    waybar
    wezterm
    wget
    wirelesstools # iwconfig, iw
    wl-clipboard
    wofi
    xdg-utils
    xfce.thunar
    xfce.tumbler
    yubikey-manager # provides ykman
    zotero
    zoxide
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

  # 1Password to unlock extensions on custom chrome-based browsers
  # https://wiki.nixos.org/wiki/1Password
  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        vivaldi-bin
      '';
      mode = "0755";
    };
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
    package = pkgs.netdata.override { withCloudUi = true; };
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

  # bluetooth (airpods, etc.)
  hardware.bluetooth.enable = true;

  # pki
  security.pki.certificates = [''
    -----BEGIN CERTIFICATE-----
    MIIDHzCCAgegAwIBAgIQIQ0OxDVplJtKhNjbm78GaTANBgkqhkiG9w0BAQsFADAi
    MSAwHgYDVQQDExdlc29kLm5vIFByaW1hcnkgUm9vdCBDQTAeFw0xNTExMjAxMjUx
    NTdaFw0zMDExMjAxMzAxNTdaMCIxIDAeBgNVBAMTF2Vzb2Qubm8gUHJpbWFyeSBS
    b290IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAotuiSbSnSxEb
    PrhUDQ76FQhn8I7TSPHZgQxRc9u0a9S8Gzdu26U0c5W5yBICmNWtIoHhidbxZnud
    0sBCGSb947Oru79n1EuW1/LdDUDDPVflWGxP7Iz+kuTQ28klaybnlI+Bv7XOWmLR
    sDDt2Vb4QgfkfU6TsDtTPEdHQFqpPUhyZUB3nq+wt5v6mRWwHdY64WKA8Uiyxgr9
    bC0J1oqsDGQraHzymu98N7IUrBvX6oEFc84gZiG6ijNfe947mO7liLrWhXHHNQc/
    72uLaiCljdVm+nPvtX5w7tqCs8JLZzjsU++vv2CMcKMQoZo5aZSYtMk11oH4bqdC
    08FBAd0SUQIDAQABo1EwTzALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAd
    BgNVHQ4EFgQUzaSv2KPTloe7ty0QCDgZ0e1yfE4wEAYJKwYBBAGCNxUBBAMCAQAw
    DQYJKoZIhvcNAQELBQADggEBAIQsjhWLXezy14/pzXdXnPPtdPQ6Tfx2D4qVfAEv
    0iWNr4G5KWg5JPBBaPnEmxZnkDnZzbomlhvrvO54fVYcIpZ3o7OPkC8u6d0u927H
    B+8Z4AyAmjvL51i1Fd24nZBUtKI9oEDPtUNic7ISnY06lFmGJNqcrpwq10OQlBS8
    J9C6g6U3ht3FrTfXP+voLzUVRbtNhhUffc9X/QlDxhKIMgtLtV/icmmcGh0il1hk
    9KxSNmoTrh8AZRw/dx2t1AW0kyC8bAn9C5KSBilCZiCdu68kXEph9a97EoeIEPYU
    FCvNV4NbtoSslIIUlnzTQKNG4cvETSTRdWv1lrJhswR91GI=
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIEdDCCA1ygAwIBAgITMgAAAAo4gUsobh8qfAAAAAAACjANBgkqhkiG9w0BAQsF
    ADAiMSAwHgYDVQQDExdlc29kLm5vIFByaW1hcnkgUm9vdCBDQTAeFw0xNTExMjQy
    MTQ2MTNaFw0yNTExMjQyMTU2MTNaMEwxFTATBgoJkiaJk/IsZAEZFgVsb2NhbDEU
    MBIGCgmSJomT8ixkARkWBGVzb2QxHTAbBgNVBAMTFGVzb2Qubm8gSXNzdWluZyBD
    QTAxMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2LP0eS8xGPAd35SH
    IRpWhQKv7aBvNNr9N5w8Rw5HIPOFCIwJLMvQ+u5IETR1A6kWYfY+eofGloUepcom
    Um8ujlN0+bOXuyBWTrHIBrgItyx5FHSjQqWtxUpn78q7E/YCAUyTIs98jeI3YJFN
    0yD6H1EPr2Fc0FhSZRX6d+Zv/R+us6pVwuNnHpmrjrHX6ot1oKhqjggtI3rl7pz7
    txHsyWwRIDfeOzB/mXCQk4TKIdR108/L6d2eq+k5QlY11IOsifinycmcl5S9YBi8
    u7Ux8zYznf1xnzEaYY08yWwvQm9MZFJw2oz8VwHBST0ykbhSOVbBbGnLW1ZMShVy
    LgX4zwIDAQABo4IBdzCCAXMwEgYJKwYBBAGCNxUBBAUCAwQABDAjBgkrBgEEAYI3
    FQIEFgQUa3630eU85mB674Y3rtfGgfBt550wHQYDVR0OBBYEFJdKMKZZHYOSwC2y
    L36tvbfU/1uZMBEGA1UdIAQKMAgwBgYEVR0gADAZBgkrBgEEAYI3FAIEDB4KAFMA
    dQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAW
    gBTNpK/Yo9OWh7u3LRAIOBnR7XJ8TjA/BgNVHR8EODA2MDSgMqAwhi5odHRwOi8v
    cGtpLmVzb2Qubm8vZXNvZC1uby1wcmltYXJ5LXJvb3QtY2EuY3JsMGsGCCsGAQUF
    BwEBBF8wXTAfBggrBgEFBQcwAYYTaHR0cDovL29jc3AuZXNvZC5ubzA6BggrBgEF
    BQcwAoYuaHR0cDovL3BraS5lc29kLm5vL2Vzb2Qtbm8tcHJpbWFyeS1yb290LWNh
    LmNydDANBgkqhkiG9w0BAQsFAAOCAQEALcsL+pczrUumeBBZ9w9lG0vOnqXY7vCx
    aURvPF4Q0UBYMM1VDyxp3Pj5raJ82SjyH+ehQ1cRMRlKj6jW7aqcA1KKqy8mmsoS
    jKHeR/YyZShu9EAkocTgYsM5hTEd0hRcKvV/v0M/PIVhQ/87arvyGB2o1X3NfhRi
    qSz0L8eVhgppRTQAJSxGy6wHeFdtc3+iO2PcA+6iJbM4dn49zUORLkkuU/54buSw
    FsJ/acXF0mBeSAHclJ9zB3AZR5d6W/xL/LIFEkd8B6s6k0yFQ3AAcZV7PWru/LQ2
    WUe6xzVctVFkTiIRDvCMqLB8aF/7AY5e2i2cSUS/U+JLNsS9rjllxQ==
    -----END CERTIFICATE-----
  ''];
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "esod" ];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  # yubikey
  # https://joinemm.dev/blog/yubikey-nixos-guide#sources 

  services = {
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
  };

  security.pam = {
    u2f = {
      enable = true;
      settings = {
        cue = true;
        cue_prompt = " Touch the Yubikey to continue...";
        interactive = false;
        origin = "pam://yubi";

        # generated with pamu2fcfg -n -o pam://yubi
        authfile = pkgs.writeText "u2f-mappings" (lib.concatStrings [
          "esod:TF+zGxo13aIMTY+scorTCd/b6+UbtAPEIcMcXTpl3N3OfR/pzkjM+bBahN7zpuK7yPFctbLUtB/JZfSZFdQCwQ==,7ePwfuqkOw4CutSU8rNE1UW/RMw/ceyHufQ0umuk9dodHdht1FhSQAWzioEnYW1FcjC+bIuc8L4bM7PvbFtgTQ==,es256,+presence" # nano
        ]);
      };
    };

    services = {
      sudo.u2fAuth = true;
      login.u2fAuth = false;
    };
  };

}
