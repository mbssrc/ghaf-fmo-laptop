# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ inputs, ... }:
{
  flake.nixosModules = {
    hardware-dell-latitude-7230.imports = [
      inputs.ghaf.nixosModules.hardware-dell-latitude-7230
      ./resources/dell-latitude-7230.nix
      ./definition/dell-latitude-7230.nix
      ./definition/external-usb.nix
    ];
    hardware-alienware-m18-r2.imports = [
      inputs.ghaf.nixosModules.hardware-alienware-m18-r2
      ./resources/alienware-m18-r2.nix
      ./definition/external-usb.nix
    ];
    hardware-dell-latitude-7330.imports = [
      inputs.ghaf.nixosModules.hardware-dell-latitude-7330
      ./resources/dell-latitude-7330.nix
      ./definition/external-usb.nix
    ];
    hardware-lenovo-x1-carbon-gen11.imports = [
      inputs.ghaf.nixosModules.hardware-lenovo-x1-carbon-gen11
      ./resources/lenovo-x1-carbon-gen11.nix
      ./definition/external-usb.nix
    ];
  };
}
