{ self, ... }:
{
  flake.homeManagerModules = {
    vacuumtube = self.homeManagerModules.default;

    default =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.programs.vacuumtube;
        vacuumtubePackage = self.packages.${pkgs.stdenv.hostPlatform.system}.vacuumtube;

        allFlags =
          cfg.electronFlags
          ++ lib.optionals (cfg.enableFeatures != [ ]) [
            "--enable-features=${builtins.concatStringsSep "," cfg.enableFeatures}"
          ];

        wrappedPackage =
          if allFlags == [ ] then
            vacuumtubePackage
          else
            vacuumtubePackage.overrideAttrs (old: {
              installPhase = old.installPhase + ''
                wrapProgram $out/bin/vacuumtube \
                  ${lib.concatMapStringsSep " " (f: "--add-flags '${f}'") allFlags}
              '';
            });
      in
      {
        options.programs.vacuumtube = {
          enable = lib.mkEnableOption "YouTube for TV, on your PC";

          package = lib.mkOption {
            type = lib.types.package;
            default = vacuumtubePackage;
            description = "The VacuumTube package to use.";
          };

          enableFeatures = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = lib.literalExpression ''
              [
                # Enable hardware-accelerated video decode on NVIDIA GPUs
                "AcceleratedVideoDecodeLinuxZeroCopyGL"
                "AcceleratedVideoDecodeLinuxGL"
                "VaapiIgnoreDriverChecks"
                "VaapiOnNvidiaGPUs"
              ]
            '';
            description = "Chromium features to enable via --enable-features.";
          };

          electronFlags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "--ignore-gpu-blocklist" ];
            description = "Extra flags to pass to the Electron binary.";
          };
        };

        config = lib.mkIf cfg.enable {
          home.packages = [ wrappedPackage ];
        };
      };
  };
}
