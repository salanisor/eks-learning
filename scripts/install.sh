sudo dnf install -y dnf-plugins-core
sudo dnf config-manager addrepo --from-repofile="https://rpm.releases.hashicorp.com/fedora/hashicorp.repo"
sudo dnf -y install terraform
terraform version

