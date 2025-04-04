# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  self,
  inputs,
  ...
}:
let
  system = "x86_64-linux";
  nixMods = inputs.self.nixosModules;

  laptop-configuration = import ./mkLaptopConfiguration.nix { inherit inputs; };
  installer-config = import ./mkInstaller.nix { inherit lib inputs; };

  # create a configuration for each live image
  target-configs = [
    (laptop-configuration "fmo-alienware-m18-r2-debug" [
      nixMods.hardware-alienware-m18-r2
      nixMods.fmo-profile
      {
        ghaf.profiles.debug.enable = true;
        fmo.personalize.debug.enable = true;
      }
    ])
    (laptop-configuration "fmo-dell-7230-debug" [
      nixMods.hardware-dell-latitude-7230
      nixMods.fmo-profile
      {
        ghaf.profiles.debug.enable = true;
        fmo.personalize.debug.enable = true;
      }
    ])
    # based on the wifi PCI address 71:00.0
    (laptop-configuration "fmo-dell-7330-71-debug" [
      nixMods.hardware-dell-latitude-7330-71
      nixMods.fmo-profile
      {
        ghaf.profiles.debug.enable = true;
        fmo.personalize.debug.enable = true;
      }
    ])
    # based on the wifi PCI address 72:00.0
    (laptop-configuration "fmo-dell-7330-72-debug" [
      nixMods.hardware-dell-latitude-7330-72
      nixMods.fmo-profile
      {
        ghaf.profiles.debug.enable = true;
        fmo.personalize.debug.enable = true;
      }
    ])
    (laptop-configuration "fmo-lenovo-x1-gen11-debug" [
      nixMods.hardware-lenovo-x1-carbon-gen11
      nixMods.fmo-profile
      {
        ghaf.profiles.debug.enable = true;
        fmo.personalize.debug.enable = true;
      }
    ])
    (laptop-configuration "fmo-demo-tower-mk1-debug" [
      nixMods.hardware-demo-tower-mk1
      nixMods.fmo-profile
      {
        ghaf.profiles.debug.enable = true;
        fmo.personalize.debug.enable = true;
      }
    ])

    #
    # Release Builds
    #
    # TODO: enable in a later release
    #
    # (laptop-configuration "fmo-alienware-m18-r2-release" [
    #   nixMods.hardware-alienware-m18-r2
    #   nixMods.fmo-profile
    #   {
    #     ghaf.profiles.release.enable = true;
    #   }
    # ])
    # (laptop-configuration "fmo-dell-7230-release" [
    #   nixMods.hardware-dell-latitude-7230
    #   nixMods.fmo-profile
    #   {
    #     ghaf.profiles.release.enable = true;
    #   }
    # ])
    # (laptop-configuration "fmo-dell-7330-release" [
    #   nixMods.hardware-dell-latitude-7330
    #   nixMods.fmo-profile
    #   {
    #     ghaf.profiles.release.enable = true;
    #   }
    # ])
    # (laptop-configuration "fmo-lenovo-x1-gen11-release" [
    #   nixMods.hardware-lenovo-x1-carbon-gen11
    #   nixMods.fmo-profile
    #   {
    #     ghaf.profiles.release.enable = true;
    #   }
    # ])
  ];

  # create an installer for each target
  target-installers = map (
    t: installer-config t.name (self.packages.x86_64-linux.${t.name} + "/disk1.raw.zst") [ ]
  ) target-configs;

  # the overall outputs. Both the live image and an installer for it.
  targets = target-configs ++ target-installers;
in
{
  flake = {
    nixosConfigurations = builtins.listToAttrs (map (t: lib.nameValuePair t.name t.hostConfig) targets);
    packages.${system} = builtins.listToAttrs (map (t: lib.nameValuePair t.name t.package) targets);
  };
}
