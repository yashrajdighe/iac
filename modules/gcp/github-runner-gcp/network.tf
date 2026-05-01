###############################################################################
# Networking helpers.
#
# Runner VMs are provisioned with an ephemeral external IP (public VMs only),
# so this module does NOT create a Cloud Router / Cloud NAT. We do not manage
# the VPC or subnetwork either - those are caller-owned.
#
# All firewall rules are scoped to the runner network tag so they only apply
# to runner VMs created by this module:
#   - default-deny ingress (defense in depth; runners only need outbound)
#   - allow egress to github.com / ghcr.io / GCS / Google APIs / DNS
###############################################################################

resource "google_compute_firewall" "runner_deny_ingress" {
  project   = var.project_id
  name      = "${var.prefix}-runner-deny-ingress"
  network   = var.network
  direction = "INGRESS"
  priority  = 1000

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.runner_network_tag]

  description = "Default-deny ingress for ephemeral runner VMs. Outbound-only workloads."
}

resource "google_compute_firewall" "runner_allow_egress" {
  project   = var.project_id
  name      = "${var.prefix}-runner-allow-egress"
  network   = var.network
  direction = "EGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["443", "80"]
  }
  allow {
    protocol = "udp"
    ports    = ["53", "443"]
  }
  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = [local.runner_network_tag]

  description = "Egress to GitHub, container registries, GCS, Google APIs and DNS."
}
