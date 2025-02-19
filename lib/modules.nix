{ lib, ... }:
with builtins; with lib; {

  findNixosModules = flake:
    if pathExists "${flake}/nixos-modules" then
      findModules flake "${flake}/nixos-modules"
    else
      findModules flake "${flake}/modules";

  findDarwinModules = flake:
    findModules flake "${flake}/darwin-modules";

  findModules = flake: modulesPath:
    mapListToAttrs
      (file:
        nameValuePair'
          (removeSuffix ".nix" (removePrefix "${modulesPath}/" file))
          (import file)
      )
      (find ".nix" modulesPath);

  # Takes a path to an option, a description of a module and that module and wraps the module, so that it may be enabled by setting the newly created option to true
  mkEnableableModule = optionPath: description: module: (
    let
      evaluated = module { inherit config lib pkgs modulesPath; };
    in
    { ... }: {
      options = recursiveUpdate
        evaluated.options
        (setAttrByPath optionPath (mkEnableOption description));

      config = mkIf (getAttrFromPath optionPath config) evaluated.config;
    }
  );

}
