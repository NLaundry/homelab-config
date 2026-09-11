{ config, lib, pkgs, ... }:

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
          allow.dns = [ "*.laundrylab.internal" ];
          allowWildcardNames = false;
        };
        provisioners = [
          {
            type = "ACME";
            name = "services";
            challenges = [ "http-01" ];
            claims = {
              minTLSCertDuration = "5m";
              defaultTLSCertDuration = "168h";
              maxTLSCertDuration = "168h";
              enableSSHCA = false;
              disableRenewal = false;
              allowRenewalAfterExpiry = false;
            };
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
        /var/lib/step-ca ${../../../infra/certificates/laundrylab-root-ca.crt} \
        "$CREDENTIALS_DIRECTORY/intermediate_password" ${pkgs.openssl}/bin/openssl \
        --mount /var
    '';
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      StateDirectoryMode = "0700";
      UnsetEnvironment = [ "STEP_CA_TOKEN" ];
      # Use the immutable module-generated configuration directly. The checker
      # validates commissioned state but never assembles or mutates config.
      ExecStart = lib.mkForce [
        ""
        "${config.services.step-ca.package}/bin/step-ca /etc/smallstep/ca.json --password-file \${CREDENTIALS_DIRECTORY}/intermediate_password"
      ];
      Restart = "on-failure";
      RestartSec = 30;
    };
    unitConfig.StartLimitBurst = 3;
    unitConfig.StartLimitIntervalSec = 300;
  };
}
