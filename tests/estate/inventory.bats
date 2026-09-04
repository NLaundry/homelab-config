#!/usr/bin/env bats

setup() {
  ROOT="${HOMELAB_ROOT:-$(cd "$BATS_TEST_DIRNAME/../.." && pwd)}"
  INVENTORY="$ROOT/estate.yaml"
}

@test "estate.yaml is a readable inventory of the current homelab" {
  run yq eval -e '
    .version == 1 and
    (.sites | type == "!!map") and
    (.hosts | type == "!!map") and
    (.services | type == "!!map")
  ' "$INVENTORY"
  [ "$status" -eq 0 ]

  while IFS= read -r site; do
    run yq eval -e ".sites | has(\"$site\")" "$INVENTORY"
    [ "$status" -eq 0 ]
  done < <(yq eval -r '.hosts[].site' "$INVENTORY")

  while IFS= read -r host; do
    run yq eval -e ".hosts | has(\"$host\")" "$INVENTORY"
    [ "$status" -eq 0 ]
  done < <(yq eval -r '.services[].host' "$INVENTORY")

  run yq eval -e '
    (.sites | has("home")) and
    .hosts.nas.site == "home" and
    .hosts.nas.hostname == "NASty" and
    .hosts.nas.addresses.lan == "10.10.10.11" and
    .hosts.nas.storage.pools[0] == "mediaBin" and
    .hosts.nas.storage.pools[1] == "smolBoy" and
    (.hosts.nas.storage.pools | length) == 2 and
    .services."file-sharing".host == "nas"
  ' "$INVENTORY"
  [ "$status" -eq 0 ]
}
