- name: Run TFLint
        run: tflint --recursive --config $(pwd)/.tflint.hcl
        working-directory: terraform

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_required_version" {
  enabled = false
}

rule "terraform_required_providers" {
  enabled = false
}
