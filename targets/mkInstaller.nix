# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#

# TODO: remove this file when the installer is exported from Ghaf
# Installer
{
  lib,
  inputs,
  ...
}:
let
  system = "x86_64-linux";
  mkInstaller =
    name: imagePath: extraModules:
    let
      hostConfiguration = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (
            { pkgs, modulesPath, ... }:
            {
              imports = [
                "${toString modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
              ];

              environment.sessionVariables = {
                IMG_PATH = imagePath;
              };

              systemd.services.wpa_supplicant.wantedBy = lib.mkForce [ "multi-user.target" ];
              systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

              isoImage.isoBaseName = lib.mkForce "ghaf";
              networking.hostName = "ghaf-installer";

              environment.systemPackages = [
                inputs.ghaf.packages.x86_64-linux.ghaf-installer
                inputs.ghaf.packages.x86_64-linux.hardware-scan
              ];

              services.getty = {
                greetingLine = ''<<< Welcome to the Ghaf installer >>>'';
                helpLine = lib.mkAfter ''

                  To run the installer, type
                  `sudo ghaf-installer` and select the installation target.
                '';
              };

              isoImage.squashfsCompression = "zstd -Xcompression-level 3";

              # NOTE: Stop nixos complains about "warning:
              # mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash."
              # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/installation-device.nix#L112
              boot.swraid.mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";
            }
          )
        ] ++ extraModules;
      };
    in
    {
      inherit hostConfiguration;
      name = "${name}-installer";
      package = hostConfiguration.config.system.build.isoImage;
    };
in
mkInstaller
