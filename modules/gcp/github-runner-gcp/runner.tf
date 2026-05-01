###############################################################################
# Runner instance template.
#
# Each scale-up call uses this template as the source for `instances.insert`
# and overrides the machine type + name + the `runner_jit_config` metadata
# attribute. The template itself does NOT carry the JIT config (that's
# per-instance) but does carry:
#   - the runner SA + scope
#   - the boot disk + image family
#   - the network/subnetwork + tags + (no) external IP
#   - Shielded VM + Spot scheduling
#   - the startup script that boots the runner from the GCS-cached tarball
###############################################################################

locals {
  runner_startup_script = templatefile("${path.module}/scripts/runner_startup.sh.tftpl", {
    runner_binaries_bucket        = google_storage_bucket.runner_binaries.name
    runner_binaries_latest_object = local.runner_binaries_latest_object
  })
}

resource "google_compute_instance_template" "runner" {
  project      = var.project_id
  name_prefix  = local.instance_template_name_prefix
  region       = var.region
  description  = "Template for ephemeral GitHub Actions runner VMs (managed by github-runner-gcp)."
  machine_type = element(var.machine_types, 0)

  tags = [local.runner_network_tag]

  labels = local.runner_labels

  metadata = {
    enable-oslogin                    = "FALSE"
    block-project-ssh-keys            = "TRUE"
    serial-port-logging-enable        = "TRUE"
    google-logging-enabled            = "TRUE"
    google-monitoring-enabled         = "TRUE"
    runner_idle_self_destruct_minutes = tostring(var.runner_idle_self_destruct_minutes)
    startup-script                    = local.runner_startup_script
  }

  disk {
    source_image = local.runner_image
    auto_delete  = true
    boot         = true
    disk_type    = coalesce(var.disk.type, "pd-balanced")
    disk_size_gb = coalesce(var.disk.size_gb, 100)

    dynamic "disk_encryption_key" {
      for_each = var.kms_key_self_link != null ? [1] : []
      content {
        kms_key_self_link = var.kms_key_self_link
      }
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    # Public VMs only: every runner gets an ephemeral external IP so it can
    # reach github.com without depending on Cloud NAT in the VPC.
    access_config {
      network_tier = "STANDARD"
    }
  }

  scheduling {
    automatic_restart           = false
    on_host_maintenance         = "TERMINATE"
    preemptible                 = var.instance_target_capacity_type == "spot"
    provisioning_model          = var.instance_target_capacity_type == "spot" ? "SPOT" : "STANDARD"
    instance_termination_action = var.instance_target_capacity_type == "spot" ? "DELETE" : null
  }

  service_account {
    email  = google_service_account.runner.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = var.shielded_vm
    enable_vtpm                 = var.shielded_vm
    enable_integrity_monitoring = var.shielded_vm
  }

  confidential_instance_config {
    enable_confidential_compute = false
  }

  lifecycle {
    create_before_destroy = true
  }
}
