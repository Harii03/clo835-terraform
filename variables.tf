cat > variables.tf << 'EOF'
variable "region"        { type = string, default = "us-east-1" }
variable "key_pair_name" { type = string, description = "EC2 key pair name" }
EOF
