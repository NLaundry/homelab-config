data "netbird_peer" "north_york_router" {
  id = "dae4tpjl0ubs73b6migg"
}

resource "netbird_group" "ny_access" {
  name = "NY-Access"
  peers = [
    "dae1nojl0ubs738pvj90", # iPhone-me
    "dae59crl0ubs73beq440", # Nathans-MacBook-Pro.local
  ]
}

resource "netbird_network_router" "north_york" {
  network_id = netbird_network.north_york.id
  peer       = data.netbird_peer.north_york_router.id
  enabled    = true
  masquerade = true
  metric     = 100

  lifecycle {
    precondition {
      condition     = data.netbird_peer.north_york_router.connected && data.netbird_peer.north_york_router.name == "OPNsense.localdomain"
      error_message = "The selected North York OPNsense peer must be connected and match its approved identity."
    }
  }
}

resource "netbird_policy" "ny_access" {
  name    = "NY-Access to North York LAN"
  enabled = true

  rule {
    name          = "NY-Access to North York LAN"
    action        = "accept"
    enabled       = true
    bidirectional = false
    protocol      = "all"
    sources       = [netbird_group.ny_access.id]
    destinations  = [netbird_group.north_york_lan_resources.id]
  }
}
