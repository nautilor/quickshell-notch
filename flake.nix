{
  description = "quickshell-notch: a Boring Notch style island, lock screen and greetd login screen for Hyprland";

  # no inputs: the module uses the pkgs of the configuration that imports it
  outputs = { self }: {
    # the GTK 3/4 and Kvantum themes for a given pkgs: lib.mkTheme pkgs { accent = "cyan"; }
    lib.mkTheme = pkgs: { accent ? "cyan" }: import ./theme/default.nix { inherit pkgs accent; };

    # GTK and Qt themes for Home Manager
    homeManagerModules.theme = import ./theme/home-manager.nix self;

    nixosModules = rec {
      # login screen for greetd (Hyprland as the greeter compositor)
      greeter = { lib, ... }: {
        imports = [ ./greeter/nixos.nix ];
        # the repo itself is the source of greeter.qml, and its pictures are the defaults
        services.quickshellNotchGreeter = {
          src = lib.mkDefault self;
          wallpaper = lib.mkDefault (self + "/assets/wallpaper.png");
          avatars = lib.mkDefault { };
        };
      };
      default = greeter;
    };
  };
}
