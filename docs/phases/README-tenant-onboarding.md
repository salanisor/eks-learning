# Tenant Onboarding Guide

This guide walks through onboarding a new application team onto the EKS cluster.
Everything is templated — adding a team requires changes in two places only.

---

## Prerequisites

- AWS CLI configured with admin access
- Terraform installed and initialized
- kubectl configured for the cluster
- Access to the GitHub repository

---

## Step 1 — Create the application secret in AWS Secrets Manager

Secrets follow this naming convention:
eks-learning/{environment}/{team-name}/{secret-name}

Create the secret for your team:
```bash
aws secretsmanager create-secret \
  --name eks-learning/dev/{team-name}/db-credentials \
  --secret-string '{"username":"youruser","password":"yourpassword"}' \
  --region us-east-1
```

Replace `{team-name}` with your team name (e.g. `orders`, `inventory`).

> The IAM policy scoping means ESO can only read secrets under
> `eks-learning/dev/{team-name}/*` — no other team can read your secrets.

---

## Step 2 — Add the team module to Terraform

Edit `terraform/environments/dev/main.tf` and add a new module block:
```hcl
module "team_{team_name}" {
  source = "../../modules/team"

  cluster_name   = var.cluster_name
  team_name      = "{team-name}"
  environment    = "dev"
  aws_account_id = "684177687615"
  repo_url       = var.github_repo_url
  ingress_order  = {unique-number}   # e.g. 40, 50, 60 — must be unique per team
  domain_name    = var.domain_name

  # Optional: enable resource quota
  enable_resource_quota          = true
  resource_quota_cpu_requests    = "2"
  resource_quota_cpu_limits      = "4"
  resource_quota_memory_requests = "2Gi"
  resource_quota_memory_limits   = "4Gi"
  resource_quota_pods            = "10"

  # IAM permissions for the application workload
  app_policy_statements = [
    {
      Sid    = "AllowReadOnlyS3Access"
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = "*"
    }
  ]
}
```

Also add the team name to the `teams` list in the `local_file` appproject resource:
```hcl
resource "local_file" "appproject" {
  content = templatefile("${path.module}/../../templates/gitops/appproject.yaml.tpl", {
    teams = ["test-app", "payments", "{team-name}"]
  })
  filename = "${path.module}/../../../gitops/bootstrap/base/projects.yaml"
}
```

---

## Step 3 — Apply Terraform
```bash
cd terraform/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Terraform will automatically generate all GitOps manifests under
`gitops/tenants/dev/{team-name}/` including:

| File | Purpose |
|---|---|
| `namespace.yaml` | Kubernetes namespace with labels |
| `serviceaccount.yaml` | Service account for the workload |
| `deployment.yaml` | Default nginx deployment |
| `service.yaml` | ClusterIP service |
| `ingress.yaml` | ALB ingress with `{team-name}.keights.net` hostname |
| `networkpolicy.yaml` | Default deny-all with safe egress rules |
| `clustersecretstore.yaml` | ESO store scoped to team IAM role |
| `externalsecret.yaml` | Syncs `db-credentials` from Secrets Manager |
| `resourcequota.yaml` | Resource limits (if enabled) |

And in `gitops/clusters/dev/`:

| File | Purpose |
|---|---|
| `{team-name}-application.yaml` | ArgoCD Application definition |

---

## Step 4 — Commit and push
```bash
cd ~/git/eks-learning
git add .
git commit -m "feat: onboard {team-name} team"
git push origin main
```

---

## Step 5 — Apply the updated AppProject to ArgoCD
```bash
kubectl apply -f gitops/bootstrap/base/projects.yaml
```

---

## Step 6 — Apply the ArgoCD Application
```bash
kubectl apply -f gitops/clusters/dev/{team-name}-application.yaml
```

ArgoCD will automatically:
- Create the namespace
- Deploy the workload
- Sync the secret from Secrets Manager
- Provision the ALB ingress
- Create the DNS record in Route53

---

## Step 7 — Verify the onboarding
```bash
# Check ArgoCD synced the application
kubectl get applications -n argocd

# Check pods are running
kubectl get pods -n {team-name}

# Check secret was synced from Secrets Manager
kubectl get secret db-credentials -n {team-name}
kubectl get externalsecret -n {team-name}

# Check ingress and DNS
kubectl get ingress -n {team-name}
curl -v http://{team-name}.keights.net

# Check resource quota (if enabled)
kubectl describe resourcequota {team-name}-quota -n {team-name}

# Check network policies
kubectl get networkpolicy -n {team-name}
```

---

## Network policy defaults

Every team namespace gets these network policies automatically:

| Policy | Purpose |
|---|---|
| `default-deny-all` | Blocks all ingress and egress by default |
| `allow-same-namespace` | Pods within the same namespace can talk to each other |
| `allow-alb-ingress` | ALB can reach pods on port 80 |
| `allow-dns-egress` | Pods can reach CoreDNS for name resolution |
| `allow-pod-identity-egress` | Pods can reach Pod Identity Agent for AWS credentials |
| `allow-aws-api-egress` | Pods can reach AWS APIs on port 443 |

Inter-namespace traffic is blocked by default. If a team needs to
communicate with another namespace, a specific NetworkPolicy must be
added explicitly.

---

## Secret path convention

All secrets follow this structure:
eks-learning/{environment}/{team-name}/{secret-name}

Each team's ESO role can only read secrets under their own path.
A compromised pod in `payments` cannot read secrets from `orders`.

To add additional secrets for a team, create them in Secrets Manager
following the path convention and add entries to the `ExternalSecret`
in `gitops/tenants/dev/{team-name}/externalsecret.yaml`.

---

## Ingress order reference

Each team must have a unique `ingress_order` value. Lower numbers
have higher ALB rule priority.

| Team | Ingress Order |
|---|---|
| argocd | 10 |
| test-app | 20 |
| payments | 30 |
| next team | 40 |

---

## Offboarding a team

To remove a team from the cluster:
```bash
# 1. Delete the ArgoCD application
kubectl delete application {team-name} -n argocd

# 2. Remove the module block from terraform/environments/dev/main.tf

# 3. Remove the team from the appproject teams list in main.tf

# 4. Apply Terraform
cd terraform/environments/dev
terraform apply

# 5. Delete the secret from Secrets Manager
aws secretsmanager delete-secret \
  --secret-id eks-learning/dev/{team-name}/db-credentials \
  --force-delete-without-recovery \
  --region us-east-1

# 6. Remove the gitops tenant directory
rm -rf gitops/tenants/dev/{team-name}
rm gitops/clusters/dev/{team-name}-application.yaml

# 7. Commit and push
git add .
git commit -m "chore: offboard {team-name} team"
git push origin main
```
