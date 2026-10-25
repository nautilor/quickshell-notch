# NixOS module for the quickshell-notch login screen.
# From the flake: imports = [ inputs.quickshell-notch.nixosModules.greeter ];  (see README, "Set it up (NixOS)")
# Without the flake: imports = [ ./path/to/quickshell-notch/greeter/nixos.nix ];
# and set  services.quickshellNotchGreeter.src  if the repo is not at ../ (the default).
{ config, lib, pkgs, ... }:
let
  cfg = config.services.quickshellNotchGreeter;
  # the whole repo is copied to the Nix store so the greeter user can read it
  src = builtins.path { path = cfg.src; name = "quickshell-notch"; };
  greeterJson = pkgs.writeText "greeter.json" (builtins.toJSON {
    inherit (cfg) hue user session;
    wallpaper = if cfg.wallpaper == null then "" else "${cfg.wallpaper}";
    avatars = lib.mapAttrs (_: p: "${p}") cfg.avatars;
  });
  hyprConf = pkgs.writeText "greeter-hyprland.lua" ''
    hl.config({
      misc = { disable_hyprland_logo = true, disable_splash_rendering = true, force_default_wallpaper = 0 },
      animations = { enabled = false },
    })
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
    hl.on("hyprland.start", function()
      hl.exec_cmd("sh -c 'QS_GREETER_CONFIG=${greeterJson} ${pkgs.quickshell}/bin/quickshell -p ${src}/greeter.qml; ${pkgs.hyprland}/bin/hyprctl dispatch \"hl.dsp.exit()\"'")
    end)
  '';
in
{
  options.services.quickshellNotchGreeter = {
    enable = lib.mkEnableOption "the quickshell-notch greetd login screen";
    src = lib.mkOption { type = lib.types.path; default = ../.; description = "Path of the quickshell-notch repository."; };
    wallpaper = lib.mkOption { type = lib.types.nullOr lib.types.path; default = null; description = "Background image."; };
    avatars = lib.mkOption { type = lib.types.attrsOf lib.types.path; default = { }; description = "Picture per user name, e.g. { alice = ./profile.png; }."; };
    hue = lib.mkOption { type = lib.types.float; default = 0.53; description = "Accent hue, 0 to 1."; };
    user = lib.mkOption { type = lib.types.str; default = ""; description = "User selected at first start."; };
    session = lib.mkOption { type = lib.types.str; default = "Hyprland"; description = "Session name selected at first start."; };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;   # provides the Hyprland session and binary

    services.greetd = {
      enable = true;
      settings.default_session = {
        user = "greeter";
        command = "${pkgs.hyprland}/bin/Hyprland --config ${hyprConf}";
      };
    };

    # remembers the last user and session
    systemd.tmpfiles.rules = [ "d /var/cache/quickshell-notch 0755 greeter greeter -" ];

    # the text and icons use this font
    fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  };
}
