cat > providers.tf <<'HCL'
provider "aws" {
  region = var.region
}
HCL
