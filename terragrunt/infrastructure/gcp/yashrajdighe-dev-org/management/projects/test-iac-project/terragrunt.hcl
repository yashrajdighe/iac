include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${find_in_parent_folders("modules")}/gcp/gcp_project"
}

dependency "gcp_folder" {
  config_path = "../../folders/test-folder"

  mock_outputs = {
    id = "gcp-folder-id"
  }
}

dependencies {
  paths = ["../../folders/test-folder"]
}

inputs = {
  name       = "just-another-test-project"
  project_id = "just-another-test-project-${dependency.gcp_folder.outputs.id}"
  folder_id  = dependency.gcp_folder.outputs.id
}
