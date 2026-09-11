# Private suffix routing only; public DNS stays with the client's own resolver.
resource "netbird_nameserver_group" "north_york" {
  name                   = "North York private DNS"
  description            = "Private laundrylab.internal resolution through the North York router"
  enabled                = true
  groups                 = [netbird_group.ny_access.id]
  domains                = ["laundrylab.internal"]
  primary                = false
  search_domains_enabled = false

  nameservers = [{
    ip      = data.netbird_peer.north_york_router.ip
    ns_type = "udp"
    port    = 53
  }]

  lifecycle {
    precondition {
      condition     = !contains(netbird_group.ny_access.peers, data.netbird_peer.north_york_router.id)
      error_message = "The router must not receive its own DNS distribution."
    }
  }
}
