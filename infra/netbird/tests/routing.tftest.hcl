mock_provider "netbird" {
  mock_data "netbird_peer" {
    defaults = {
      name      = "OPNsense.localdomain"
      connected = false
      ip        = "100.82.29.142"
    }
  }
}

run "offline_identity_can_plan" {
  command = plan

  assert {
    condition     = !data.netbird_peer.north_york_router.connected && netbird_network_router.north_york.enabled
    error_message = "An offline approved peer must not itself block the recovery plan."
  }
}

run "wrong_identity_is_refused" {
  command = plan

  override_data {
    target = data.netbird_peer.north_york_router
    values = {
      name      = "unexpected-peer"
      connected = false
      ip        = "100.82.29.142"
    }
  }

  expect_failures = [netbird_network_router.north_york]
}
