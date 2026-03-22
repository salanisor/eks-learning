#!/usr/bin/env bash
set -euo pipefail

# ── EKS Learning — Fedora 43 tool installer ──────────────────────────────────
# Installs: AWS CLI, kubectl, eksctl, Terraform, tfenv, Helm
# Usage: chmod +x eks-tools-setup.sh && ./eks-tools-setup.sh
# ─────────────────────────────────────────────────────────────────────────────

TERRAFORM_VERSION="1.7.5"
KUBECTL_VERSION="v1.29.3"
EKSCTL_VERSION="latest"
HELM_VERSION="latest"

echo "──────────────────────────────────────────"
echo " EKS tools installer — Fedora 43"
echo "──────────────────────────────────────────"

# ── System dependencies ───────────────────────────────────────────────────────
echo ""
echo "▸ Installing system dependencies..."
sudo dnf install -y \
  curl \
  unzip \
  tar \
  git \
  jq \
  openssl \
  python3-pip

# ── AWS CLI v2 ────────────────────────────────────────────────────────────────
echo ""
echo "▸ Installing AWS CLI v2..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/awscliv2
sudo /tmp/awscliv2/aws/install --update
rm -rf /tmp/awscliv2 /tmp/awscliv2.zip
echo "  AWS CLI: $(aws --version)"

# ── kubectl ───────────────────────────────────────────────────────────────────
echo ""
echo "▸ Installing kubectl ${KUBECTL_VERSION}..."
curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
  -o /tmp/kubectl
sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
rm /tmp/kubectl
echo "  kubectl: $(kubectl version --client --short 2>/dev/null)"

# ── eksctl ────────────────────────────────────────────────────────────────────
echo ""
echo "▸ Installing eksctl..."
EKSCTL_URL="https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz"
curl -fsSL "${EKSCTL_URL}" -o /tmp/eksctl.tar.gz
tar -xzf /tmp/eksctl.tar.gz -C /tmp
sudo install -o root -g root -m 0755 /tmp/eksctl /usr/local/bin/eksctl
rm /tmp/eksctl.tar.gz /tmp/eksctl
echo "  eksctl: $(eksctl version)"

# ── tfenv + Terraform ─────────────────────────────────────────────────────────
echo ""
echo "▸ Installing tfenv..."
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv 2>/dev/null \
  || git -C ~/.tfenv pull

# Add tfenv to PATH for this session and permanently
export PATH="$HOME/.tfenv/bin:$PATH"

SHELL_RC=""
if [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
fi

if [ -n "$SHELL_RC" ]; then
  grep -q 'tfenv/bin' "$SHELL_RC" \
    || echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> "$SHELL_RC"
fi

echo "▸ Installing Terraform ${TERRAFORM_VERSION} via tfenv..."
tfenv install "${TERRAFORM_VERSION}"
tfenv use "${TERRAFORM_VERSION}"
echo "  Terraform: $(terraform version -json | jq -r '.terraform_version')"

# ── Helm ──────────────────────────────────────────────────────────────────────
echo ""
echo "▸ Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
  | bash
echo "  Helm: $(helm version --short)"

# ── .terraform-version pin ───────────────────────────────────────────────────
echo ""
echo "▸ Writing .terraform-version pin..."
echo "${TERRAFORM_VERSION}" > ~/.terraform-version

# ── Verification summary ──────────────────────────────────────────────────────
echo ""
echo "──────────────────────────────────────────"
echo " Install complete — versions installed"
echo "──────────────────────────────────────────"
echo "  AWS CLI   : $(aws --version 2>&1 | cut -d' ' -f1)"
echo "  kubectl   : $(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)"
echo "  eksctl    : $(eksctl version)"
echo "  Terraform : $(terraform version -json | jq -r '.terraform_version')"
echo "  Helm      : $(helm version --short | cut -d' ' -f1)"
echo ""
echo "  Run 'source ~/.bashrc' (or ~/.zshrc) to reload PATH"
echo "──────────────────────────────────────────"
