Create a dedicated Linux/KVM testing and CI host for the homelab. Move NixOS VM test execution off the physical NAS when the additional infrastructure is justified. A NixOS builder VM on Proxmox with nested virtualization is a likely option, but the durable requirement is a replaceable Linux/KVM remote builder rather than a specific host.

Until then, the physical NAS is the remote builder for NixOS VM tests.
