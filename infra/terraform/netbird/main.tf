locals {
  estate_path = coalesce(var.estate_file, "${path.root}/../../estate.yaml")
  estate      = yamldecode(file(local.estate_path))

  north_york = one([
    for site_key, site in local.estate : site
    if site_key == "north-york" && try(site.name, null) == "North York"
  ])
  north_york_lan_cidr = local.north_york.networks.lan.cidr
}

resource "netbird_network" "north_york" {
  name        = "North York"
  description = "North York site network managed by OpenTofu."

  lifecycle {
    precondition {
      condition     = local.north_york_lan_cidr == "10.10.10.0/24"
      error_message = "estate.yaml must contain the North York LAN boundary 10.10.10.0/24."
    }
  }
}

resource "netbird_group" "north_york_lan_resources" {
  name  = "North York LAN Resources"
  peers = []
}

resource "netbird_network_resource" "north_york_lan" {
  network_id  = netbird_network.north_york.id
  name        = "North York LAN"
  description = "North York LAN managed by OpenTofu."
  address     = local.north_york_lan_cidr
  groups      = [netbird_group.north_york_lan_resources.id]
  enabled     = true
}
