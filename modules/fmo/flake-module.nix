# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  flake.nixosModules = {
    fmo-services.imports = [
      ./dci-service
      ./dynamic-portforwarding-service
      ./fmo-certs-distribution-host
      ./fmo-dci-passthrough
      ./registration-agent-laptop
      ./fmo-nats-server
      ./fmo-update-hostname
      ./fmo-update-ipaddress
    ];
  };
}
