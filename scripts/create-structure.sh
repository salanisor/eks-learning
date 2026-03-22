mkdir -p ../terraform/modules/{vpc,eks,iam}
mkdir -p ../terraform/environments/dev
mkdir -p ../manifests/apps
mkdir -p ../docs/phases
touch ../terraform/environments/dev/{main.tf,variables.tf,outputs.tf,terraform.tfvars}
touch ../terraform/versions.tf
