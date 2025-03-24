# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

# NATS configuration fails due to certs do not exist during the build stage
# Need to investigate if it is possible to use .overlay here
# Copied from nixpkgs/nixos/modules/services/networking/nats.nix
# JIRA ticker to track: FMO-108

{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.fmo-nats-server;

  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkMerge
    types
    optionalAttrs
    literalExpression
    ;

  format = pkgs.formats.json { };

  configFile = format.generate "nats.conf" cfg.settings;

  validateConfig =
    _file:
    pkgs.runCommand "validate-nats-conf"
      {
        nativeBuildInputs = [ pkgs.nats-server ];
      }
      ''
        # nats-server --config "${configFile}" -t
        ln -s "${configFile}" "$out"
      '';
in
{

  ### Interface

  options = {
    services.fmo-nats-server = {
      enable = mkEnableOption "NATS messaging system";

      user = mkOption {
        type = types.str;
        default = "nats";
        description = "User account under which NATS runs.";
      };

      group = mkOption {
        type = types.str;
        default = "nats";
        description = "Group under which NATS runs.";
      };

      serverName = mkOption {
        default = "nats";
        example = "n1-c3";
        type = types.str;
        description = ''
          Name of the NATS server, must be unique if clustered.
        '';
      };

      jetstream = mkEnableOption "JetStream";

      port = mkOption {
        default = 4222;
        type = types.port;
        description = ''
          Port on which to listen.
        '';
      };

      dataDir = mkOption {
        default = "/var/lib/nats";
        type = types.path;
        description = ''
          The NATS data directory. Only used if JetStream is enabled, for
          storing stream metadata and messages.

          If left as the default value this directory will automatically be
          created before the NATS server starts, otherwise the sysadmin is
          responsible for ensuring the directory exists with appropriate
          ownership and permissions.
        '';
      };

      settings = mkOption {
        default = { };
        inherit (format) type;
        example = literalExpression ''
          {
            jetstream = {
              max_mem = "1G";
              max_file = "10G";
            };
          };
        '';
        description = ''
          Declarative NATS configuration. See the
          [
          NATS documentation](https://docs.nats.io/nats-server/configuration) for a list of options.
        '';
      };
    };
  };

  ### Implementation

  config = mkIf cfg.enable {
    services.fmo-nats-server.settings = {
      server_name = cfg.serverName;
      inherit (cfg) port;
      jetstream = optionalAttrs cfg.jetstream { store_dir = cfg.dataDir; };
    };

    systemd.services.fmo-nats-server = {
      description = "NATS messaging system";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = mkMerge [
        (mkIf (cfg.dataDir == "/var/lib/nats") {
          StateDirectory = "nats";
          StateDirectoryMode = "0750";
        })
        {
          Type = "simple";
          ExecStart = "${pkgs.nats-server}/bin/nats-server -c ${validateConfig configFile}";
          ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
          ExecStop = "${pkgs.coreutils}/bin/kill -SIGINT $MAINPID";
          Restart = "on-failure";

          User = cfg.user;
          Group = cfg.group;

          # Hardening
          CapabilityBoundingSet = "";
          LimitNOFILE = 800000; # JetStream requires 2 FDs open per stream.
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          PrivateUsers = true;
          ProcSubset = "pid";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          ReadOnlyPaths = [ ];
          ReadWritePaths = [ cfg.dataDir ];
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          UMask = "0077";
        }
      ];
    };

    users.users = mkIf (cfg.user == "nats") {
      nats = {
        description = "NATS daemon user";
        isSystemUser = true;
        inherit (cfg) group;
        home = cfg.dataDir;
      };
    };

    users.groups = mkIf (cfg.group == "nats") { nats = { }; };
  };

}
