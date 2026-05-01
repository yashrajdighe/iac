###############################################################################
# Cross-variable preconditions that don't fit inside a single variable's
# `validation` block.
###############################################################################

check "zones_belong_to_region" {
  assert {
    condition = alltrue([
      for z in var.zones : startswith(z, "${var.region}-")
    ])
    error_message = "Every zone in var.zones must belong to var.region (zone format <region>-<letter>). Got region=${var.region}, zones=${jsonencode(var.zones)}."
  }
}

check "image_pins_present" {
  assert {
    condition = !contains([
      for img in values(local.resolved_images) : strcontains(img, "0000000000000000000000000000000000000000000000000000000000000000")
    ], true)
    error_message = "One or more control-plane images still use the placeholder digest. Build & push images via services/cloudbuild.yaml, then update locals.control_plane_images in main.tf or pass digest-pinned images via the *_image inputs."
  }
}
