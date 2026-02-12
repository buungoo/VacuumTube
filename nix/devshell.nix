{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nodejs
          electron
        ];

        env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
      };
    };
}
