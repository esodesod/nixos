# man 5 configuration.nix or nixos-help
{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "freshrss";
  networking.hostId = "a4457b42";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "no";
  users.users.esod = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILEvF7PEBh7El5JdDfpG23V+phQctUK2k3jgZZWx7pX0 esod_ed25519" ];
    isNormalUser = true;
    description = "Espen";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
  };
  users.users.promtail = {
    extraGroups = [ "docker" "systemd-journal"];
  };
  programs.fish = {
    enable = true;
    shellInit = ''
  fish_vi_key_bindings
    '';
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    btop
    dig
    fzf
    git
    grc
    htop
    jq
    lazygit
    lsof
    nvd
    openssl
    parted
    pciutils
    ripgrep
    tmux
    unzip
    vim
    wget
    yazi
    zoxide
  ];
  virtualisation.docker.enable = true;
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
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  }; 
  services.qemuGuest.enable = true;
  services.promtail.enable = true;
  services.promtail.configFile = "/etc/promtail/promtail-prod.yml";
  services.promtail.extraFlags = [ "--client.external-labels=host=freshrss" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.05";
}
