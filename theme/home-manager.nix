# Home Manager module: installs the quickshell-notch GTK 3/4 and Kvantum themes and selects them.
#   imports = [ inputs.quickshell-notch.homeManagerModules.theme ];
#   programs.quickshellNotchTheme.enable = true;
self:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.quickshellNotchTheme;
  theme = import ./default.nix { inherit pkgs; inherit (cfg) accent; };
  name = "QuickshellNotch";
in
{
  options.programs.quickshellNotchTheme = {
    enable = lib.mkEnableOption "the quickshell-notch GTK and Qt (Kvantum) themes";
    accent = lib.mkOption {
      type = lib.types.enum [ "cyan" "blue" "purple" "pink" "coral" "amber" "green" ];
      default = "cyan";
      description = "Accent colour, the same swatches as Accent colour in the shell settings.";
    };
    gtk.enable = lib.mkOption { type = lib.types.bool; default = true; description = "Select the GTK 3 and GTK 4 theme."; };
    qt.enable = lib.mkOption { type = lib.types.bool; default = true; description = "Select the Kvantum theme for Qt apps."; };
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = theme;
      description = "The generated theme package.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.gtk.enable {
      gtk = {
        enable = true;
        theme = { inherit name; package = theme; };
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        # libadwaita apps ignore theme folders and read ~/.config/gtk-4.0/gtk.css, written below
        gtk4.theme = null;
        gtk4.extraConfig.gtk-theme-name = name;
      };
      xdg.configFile."gtk-4.0/gtk.css".source = "${theme}/share/quickshell-notch/gtk4-user.css";
      dconf.settings."org/gnome/desktop/interface" = {
        gtk-theme = name;
        color-scheme = "prefer-dark";
      };
    })
    (lib.mkIf cfg.qt.enable {
      qt = {
        enable = true;
        platformTheme.name = "kvantum";
        style.name = "kvantum";
      };
      xdg.configFile."Kvantum/${name}".source = "${theme}/share/Kvantum/${name}";
      xdg.configFile."Kvantum/kvantum.kvconfig".text = "[General]\ntheme=${name}\n";
    })
  ]);
}
