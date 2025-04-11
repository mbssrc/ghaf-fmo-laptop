# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  config,
  ...
}:
let
  cfg = config.services.fmo-firewall;

  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    optionalAttrs
    concatMapStringsSep
    ;

  mkFirewallRules =
    {
      dip,
      sport,
      dport,
      proto,
    }:
    ''
      iptables -t nat -A PREROUTING -p ${proto} --dport ${sport} -j DNAT --to-destination ${dip}:${dport}
      iptables -t nat -A POSTROUTING -p ${proto} --dport ${sport} -j MASQUERADE
    '';

in
{
  options.services.fmo-firewall = {
    enable = mkEnableOption "fmo-firewall";

    mtu = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        MTU for the external network interfaces.
      '';
    };

    configuration = mkOption {
      type = types.listOf types.attrs;
      description = ''
        List of
          {
            dip = destanation IP address,
            sport = source port,
            dport = destanation port,
            proto = protocol (udp, tcp)
          }
      '';
    };
  };

  config = mkIf cfg.enable {

    networking.firewall = {
      enable = true;
      extraCommands = ''
        ${concatMapStringsSep "\n" (
          rule:
          mkFirewallRules {
            inherit (rule) dip;
            inherit (rule) sport;
            inherit (rule) dport;
            inherit (rule) proto;
          }
        ) cfg.configuration}
      '';
    };

    # Set all IF MTUs for NetworkManager network interfaces
    environment.etc."NetworkManager/dispatcher.d/99-mtu" = optionalAttrs (cfg.mtu != null) {
      text = ''
        #!/bin/sh
        IFACE="$1"
        STATUS="$2"
        case "$STATUS" in
          up)
            ip link set dev "$IFACE" mtu ${toString cfg.mtu}
          ;;
        esac
      '';
      mode = "0700";
    };

  };
}
