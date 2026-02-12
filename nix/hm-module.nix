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
        isLinux = pkgs.stdenv.hostPlatform.isLinux;

        wrappedPackage =
          if cfg.electronFlags == [ ] then
            vacuumtubePackage
          else
            vacuumtubePackage.overrideAttrs (old: {
              installPhase = old.installPhase + ''
                wrapProgram $out/bin/vacuumtube \
                  ${lib.concatMapStringsSep " " (f: "--add-flags '${f}'") cfg.electronFlags}
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

          electronFlags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = lib.literalExpression ''
              [
                # Enable hardware-accelerated video decode on NVIDIA GPUs
                "--enable-features=AcceleratedVideoDecodeLinuxZeroCopyGL,AcceleratedVideoDecodeLinuxGL,VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs"
              ]
            '';
            description = "Extra flags to pass to the Electron binary.";
          };
        };

        config = lib.mkIf cfg.enable {
          home.packages = [ wrappedPackage ];
        };
      };
  };
}
