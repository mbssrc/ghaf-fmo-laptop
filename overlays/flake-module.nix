# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  flake.overlays = {
    custom-packages = import ./custom-packages;
  };
}
