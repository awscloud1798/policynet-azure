package main

import rego.v1

open_sources := {"*", "Internet", "0.0.0.0/0"}

deny contains msg if {
  r := input.resource_changes[_]
  r.type == "azurerm_network_security_rule"
  r.change.after.direction == "Inbound"
  r.change.after.access == "Allow"
  ports := array.concat([r.change.after.destination_port_range], object.get(r.change.after, "destination_port_ranges", []))
  ports[_] == "22"
  open_sources[r.change.after.source_address_prefix]
  msg := sprintf("%s opens SSH to %s", [r.address, r.change.after.source_address_prefix])
}
