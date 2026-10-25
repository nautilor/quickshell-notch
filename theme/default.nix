# The GTK 3, GTK 4 and Kvantum themes for one accent colour.
#   import ./theme { inherit pkgs; accent = "cyan"; }
# Accents: cyan, blue, purple, pink, coral, amber, green (the swatches of the shell's Accent colour setting).
{ pkgs, accent ? "cyan" }:
let
  accents = [ "cyan" "blue" "purple" "pink" "coral" "amber" "green" ];
  dir = ./. + "/${accent}";
in
assert pkgs.lib.assertMsg (builtins.elem accent accents)
  "quickshell-notch theme: unknown accent \"${accent}\", choose one of ${builtins.concatStringsSep ", " accents}";
pkgs.runCommand "quickshell-notch-theme-${accent}"
{
  meta.description = "GTK 3/4 and Kvantum themes matching quickshell-notch (${accent})";
} ''
  themes=$out/share/themes/QuickshellNotch
  mkdir -p $out/share/themes $out/share/Kvantum $out/share/quickshell-notch

  # GTK 3 and 4: adw-gtk3 with the accent's colours and shapes appended
  cp -r ${pkgs.adw-gtk3}/share/themes/adw-gtk3-dark $themes
  chmod -R u+w $themes
  sed -i 's/adw-gtk3-dark/QuickshellNotch/g; s/adw-gtk3/QuickshellNotch/g' $themes/index.theme
  for f in gtk.css gtk-dark.css; do
    cat ${dir}/gtk-3.0.css >> $themes/gtk-3.0/$f
    cat ${dir}/gtk-4.0.css >> $themes/gtk-4.0/$f
  done

  # libadwaita apps ignore theme folders: this one goes to ~/.config/gtk-4.0/gtk.css
  cp ${dir}/libadwaita.css $out/share/quickshell-notch/gtk4-user.css

  # Kvantum
  mkdir -p $out/share/Kvantum/QuickshellNotch
  cp ${dir}/QuickshellNotch.kvconfig ${dir}/QuickshellNotch.svg $out/share/Kvantum/QuickshellNotch/
''
