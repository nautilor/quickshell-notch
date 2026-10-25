{
  description = "quickshell-notch: a Boring Notch style island, lock screen and greetd login screen for Hyprland";

  # no inputs: the module uses the pkgs of the configuration that imports it
  outputs = { self }: {
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
