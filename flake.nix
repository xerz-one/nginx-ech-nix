{
  inputs = {
    sysrepo.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, sysrepo, ... }@inputs:
  with builtins // sysrepo.lib;
  let 
    forAllSystems = f: genAttrs systems.flakeExposed (system: f system);
  in
  {
    packages = forAllSystems (
      system:
      let
        pkgs = import sysrepo { inherit system; };
        final = self.packages.${system};
      in
      {
        openssl = pkgs.openssl.overrideAttrs (final: prev: {
          patches = prev.patches ++ filesystem.listFilesRecursive ./patches/openssl;
        });

        nginx = (pkgs.nginx.override {
          openssl = final.openssl;
        }).overrideAttrs (final: prev: {
          patches = prev.patches ++ filesystem.listFilesRecursive ./patches/nginx;
        });

        default = final.nginx;
      }
    );
  };
}
