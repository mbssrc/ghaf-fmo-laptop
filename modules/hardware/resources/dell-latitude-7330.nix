# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# This file specifies resource usage across Ghaf, as different
# hardware has different requirements.
#
# Dell Latitude 7330 (11th Gen Intel(R) Core(TM) i5-1145G7)
#    RAM:                  16 GB
#    Cache:                8 MB
#    Total Cores           4
#    Total Threads         8
#    Processor Base Power  12 W
#    Maximum Turbo Power   28 W
#
# Resource allocation:
#    Net VM:     1 vcpu    512 MB
#    Audio VM:   1 vcpu    384 MB
#    Admin VM:   1 vcpu    512 MB
#    Gui VM:     2 vcpu    2047 MB
#    Zathura VM: 1 vcpu    512 MB
#    Chrome VM:  2 vcpu    4095 MB
#    Docker VM:  2 vcpu    2047 MB
#    (Msg VM:    1 vcpu    512 MB)
#
# Memory ballooning is enabled in Ghaf.
#
{ lib, ... }:
let
  inherit (lib) mkForce;
in
{
  config = {

    # Gui VM
    microvm.vms.gui-vm.config.config.microvm = {
      mem = mkForce 2047;
      vcpu = mkForce 2;
    };

    # Docker VM
    ghaf.virtualization.microvm.appvm.vms.docker = {
      ramMb = mkForce 2047;
      cores = mkForce 2;
      balloonRatio = mkForce 4;
    };

    # Msg VM
    ghaf.virtualization.microvm.appvm.vms.msg = {
      ramMb = mkForce 512;
      cores = mkForce 1;
      balloonRatio = mkForce 4;
    };

    # Chrome VM
    ghaf.virtualization.microvm.appvm.vms.chrome = {
      ramMb = mkForce 4096;
      cores = mkForce 2;
      balloonRatio = mkForce 4;
    };

    # Zathura VM
    ghaf.virtualization.microvm.appvm.vms.zathura = {
      ramMb = mkForce 512;
      cores = mkForce 1;
      balloonRatio = mkForce 2;
    };

  };
}
