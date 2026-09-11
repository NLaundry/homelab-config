{ config, lib, pkgs, ... }:

let
  # The verified existing operator has an encryptedKey. No public-only fallback
  # is permitted for this deployment. Only dummy/no-payload authorities use none.
  requireOperatorPayload = true;
  publicConfig = "/etc/smallstep/ca.json";
  runtimeConfig = "/run/step-ca/ca.json";
in
{
  # Ciphertext and its dedicated guest identity are provisioned privately into
  # the persistent /var volume. Neither is a build-time filesystem input.
  sops = {
    useSystemdActivation = true;
    validateSopsFiles = false;
    age = {
      keyFile = "/var/lib/sops-nix/keys.txt";
      generateKey = false;
      sshKeyPaths = [];
    };
    gnupg.sshKeyPaths = [];
    secrets.step-ca-intermediate-password = {
      sopsFile = "/var/lib/sops-nix/step-ca.yaml";
      key = "intermediate_password";
      mode = "0400";
      restartUnits = [ "step-ca.service" ];
    };
  };

  services.step-ca = {
    enable = true;
    address = "0.0.0.0";
    port = 443;
    openFirewall = false;
    # Public policy is declared here only. The native module generates JSON and
    # sets the effective address from address/port; it never initializes a CA.
    settings = {
      root = "/var/lib/step-ca/certs/root_ca.crt";
      crt = "/var/lib/step-ca/certs/intermediate_ca.crt";
      key = "/var/lib/step-ca/secrets/intermediate_ca_key";
      dnsNames = [ "ca.laundrylab.internal" ];
      commonName = "ca.laundrylab.internal";
      db = {
        type = "badgerv2";
        dataSource = "/var/lib/step-ca/db";
      };
      authority = {
        enableAdmin = false;
        claims.enableSSHCA = false;
        policy.x509 = {
          allow.dns = [ "ca.laundrylab.internal" "opnsense.ny.laundrylab.internal" ];
          allowWildcardNames = false;
        };
        provisioners = [
          {
            type = "JWK";
            name = "laundrylab-admin";
            key = builtins.fromJSON (builtins.readFile ../../certificates/laundrylab-operator-jwk.json);
          }
          {
            type = "ACME";
            name = "opnsense";
            challenges = [ "http-01" ];
            claims = {
              minTLSCertDuration = "5m";
              defaultTLSCertDuration = "168h";
              maxTLSCertDuration = "168h";
              enableSSHCA = false;
              disableRenewal = true;
              allowRenewalAfterExpiry = false;
            };
            options.x509.templateFile = ./opnsense.tpl;
          }
        ];
      };
    };
    intermediatePasswordFile = config.sops.secrets.step-ca-intermediate-password.path;
  };
  networking.firewall.allowedTCPPorts = [ 443 ];

  systemd.services.step-ca = {
    requires = [ "sops-install-secrets.service" ];
    after = [ "sops-install-secrets.service" ];
    unitConfig.RequiresMountsFor = [ "/var/lib/step-ca" ];
    environment.STEPPATH = "/var/lib/step-ca";
    preStart = ''
      ${pkgs.python3}/bin/python3 ${./check-state.py} \
        /var/lib/step-ca ${../../certificates/laundrylab-root-ca.crt} \
        "$CREDENTIALS_DIRECTORY/intermediate_password" ${pkgs.openssl}/bin/openssl \
        --mount /var --public-config ${publicConfig} \
        --payload-mode ${if requireOperatorPayload then "required" else "none"} \
        ${lib.optionalString requireOperatorPayload "--runtime-config ${runtimeConfig}"}
    '';
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      StateDirectoryMode = "0700";
      RuntimeDirectory = "step-ca";
      RuntimeDirectoryMode = "0700";
      UnsetEnvironment = [ "STEP_CA_TOKEN" ];
      # Preserve native credentials and public-only execution when explicitly
      # selected, but assemble the required private field in /run for this CA.
      # The old persistent config/ca.json is never read or modified.
      ExecStart = lib.mkIf requireOperatorPayload (lib.mkForce [
        ""
        "${config.services.step-ca.package}/bin/step-ca ${runtimeConfig} --password-file \${CREDENTIALS_DIRECTORY}/intermediate_password"
      ]);
      Restart = "on-failure";
      RestartSec = 30;
    };
    unitConfig.StartLimitBurst = 3;
    unitConfig.StartLimitIntervalSec = 300;
  };
}
