{
  description = "VacuumTube an unofficial wrapper of YouTube Leanback";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          pkgs,
          system,
          self',
          ...
        }:
        let
          isLinux = pkgs.stdenv.hostPlatform.isLinux;
        in
        {
          packages = {
            vacuumtube = pkgs.buildNpmPackage {
              pname = "vacuumtube";
              version = "1.5.7";

              src = ./.;

              npmDepsHash = "sha256-D8rBbV/w3jGbBktwoypMx1twKx62h6kH3dVi/y9sOZw=";

              env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

              nativeBuildInputs =
                with pkgs;
                [
                  makeWrapper
                ]
                ++ pkgs.lib.optionals isLinux [
                  copyDesktopItems
                ];

              buildInputs =
                with pkgs;
                [
                  electron
                ]
                ++ pkgs.lib.optionals isLinux [
                  libva
                ];

              desktopItems = pkgs.lib.optionals isLinux [
                (pkgs.makeDesktopItem {
                  name = "vacuumtube";
                  desktopName = "VacuumTube";
                  comment = "YouTube for TV, on your PC";
                  exec = "vacuumtube %U";
                  icon = "vacuumtube";
                  categories = [
                    "AudioVideo"
                    "Video"
                  ];
                  keywords = [
                    "YouTube"
                    "YT"
                  ];
                })
              ];

              dontNpmBuild = true;

              installPhase = ''
                runHook preInstall

                mkdir -p $out/lib/vacuumtube
                cp -r node_modules $out/lib/vacuumtube/
                cp -r assets config.js index.js package.json preload locale $out/lib/vacuumtube/

                mkdir -p $out/bin
                makeWrapper ${pkgs.electron}/bin/electron $out/bin/vacuumtube \
                  --add-flags $out/lib/vacuumtube \
                  ${pkgs.lib.optionalString isLinux ''
                    --set-default LIBVA_DRIVERS_PATH "/run/opengl-driver/lib/dri" \
                    --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.libva ]}"
                  ''}

                ${pkgs.lib.optionalString isLinux ''
                  install -Dm644 assets/icon.svg $out/share/icons/hicolor/scalable/apps/vacuumtube.svg
                ''}

                runHook postInstall
              '';

              meta = with pkgs.lib; {
                description = "YouTube for TV, on your PC";
                license = licenses.mit;
                mainProgram = "vacuumtube";
              };
            };

            default = self'.packages.vacuumtube;
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              nodejs
              electron
            ];

            env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
          };
        };
    };
}
