# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ../../fmo/fmo-nats-server
  ];

  config = {
    # Packages
    environment.systemPackages = [
      pkgs.vim
      pkgs.tcpdump
      pkgs.gpsd
      pkgs.natscli
      pkgs.nats-top
      pkgs.nats-server
    ];

    # Use givc service management
    givc.appvm.enable = mkForce false;
    givc.sysvm = {
      enable = true;
      inherit (config.microvm.vms.msg-vm.config.config.givc.appvm)
        debug
        admin
        tls
        transport
        ;
      services = [ "fmo-nats-server.service" ];
    };

    # MicroVM
    microvm = {
      # TODO Should we use storagevm instead?
      volumes = [
        {
          image = "/persist/tmp/msgvm_internal.img";
          mountPoint = "/var/lib/internal";
          size = 10240;
          autoCreate = true;
          fsType = "ext4";
        }
        {
          image = "/persist/tmp/msgvm_var.img";
          mountPoint = "/var";
          size = 10240;
          autoCreate = true;
          fsType = "ext4";
        }
      ]; # microvm.volumes

      shares = [
        {
          source = "/persist/vms_shares/common";
          mountPoint = "/var/vms_share/common";
          tag = "common_share_msgvm";
          proto = "virtiofs";
          socket = "common_share_msgvm.sock";
        }
        {
          source = "/persist/vms_shares/msgvm";
          mountPoint = "/var/vms_share/host";
          tag = "msgvm_share";
          proto = "virtiofs";
          socket = "msgvm_share.sock";
        }
        {
          source = "/run/certs/nats/server";
          mountPoint = "/var/lib/nats/certs";
          tag = "nats_certs";
          proto = "virtiofs";
          socket = "nats_certs.sock";
        }
        {
          source = "/run/certs/nats/ca";
          mountPoint = "/var/lib/nats/ca";
          tag = "nats_ca";
          proto = "virtiofs";
          socket = "nats_ca.sock";
        }
      ]; # microvm.shares

    }; # microvm

    # Services
    services = {
      avahi = {
        enable = true;
        nssmdns4 = true;
        ipv4 = true;
        ipv6 = false;
        publish.enable = true;
        publish.domain = true;
        publish.addresses = true;
        publish.workstation = true;
        domainName = "msgvm";
        hostName = "m1";
      }; # services.avahi

      # NATS server
      fmo-nats-server = {
        enable = true;
        port = 4222;

        settings = {
          # Monitoring endpoints
          http = 8222;

          tls = {
            # Path to the server certificate and private key
            cert_file = "/var/lib/nats/certs/server.crt";
            key_file = "/var/lib/nats/certs/server.key";

            # Path to the CA certificate
            ca_file = "/var/lib/nats/ca/ca.crt";

            # Require client certificate verification
            verify_and_map = true;
          };

          # Logs config
          log_file = "/var/lib/nats/nats-server.log";
          logtime = true;
        };
      }; # services.nats-server
    }; # services

    # TODO why is this here?
    networking.firewall.enable = false;
  }; # config
}
