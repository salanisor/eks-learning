# Karpenter Node Scaling Strategy

This document describes the recommended Karpenter configuration for this
platform. It is intended for platform engineers deploying or maintaining
the cluster infrastructure.

---

## Background

This cluster runs as a shared utility platform where application teams may
not have defined resource requests, limits, or PodDisruptionBudgets on their
workloads. The Karpenter configuration is designed to be safe and
burst-capable without requiring teams to make changes to their deployments.

---

## NodePool Architecture

Two NodePools are used to separate system and workload concerns:
system-nodepool    → on-demand only, t3.medium/large
→ for kube-system, argocd, external-secrets, monitoring
→ consolidation disabled
workload-nodepool  → mixed on-demand + spot
→ for tenant namespaces
→ consolidation enabled but conservative
→ disruption budget: only 1 node at a time

### Why two NodePools?

System components like CoreDNS, ArgoCD, and ESO must remain stable at all
times. Running them on Spot instances risks interruption at the worst possible
moment. The system NodePool uses on-demand instances only and never
consolidates — these nodes stay up as long as the cluster is running.

Tenant workloads run on the workload NodePool which mixes on-demand and Spot
instances. Spot instances are up to 70% cheaper than on-demand and are
appropriate for stateless application workloads that can tolerate occasional
node replacement.

---

## Platform-Level Protections

The following protections are applied at the platform level to compensate
for teams that have not defined resource requests, limits, or PDBs.

### Karpenter consolidation policy
consolidateAfter: 30m    ← do not consolidate too aggressively
expireAfter: 720h        ← nodes live up to 30 days before rotation

Waiting 30 minutes before consolidating gives burst traffic time to subside
before Karpenter removes nodes. Node expiry after 30 days ensures nodes are
regularly rotated for security patching without manual intervention.

### Default resource requests via LimitRange
cpu: 100m                ← applied at namespace level automatically
memory: 128Mi            ← applied to any container without explicit requests

LimitRange is the key protection for teams without resource requests. If a
team deploys a container without setting CPU or memory requests, Kubernetes
automatically applies the namespace default. This ensures Karpenter always
has accurate data for bin-packing decisions and never over-provisions nodes
due to unschedulable pods with no resource information.

LimitRange is applied to every tenant namespace automatically via the team
Terraform module — teams do not need to configure anything.

### Default PodDisruptionBudget enforcement
minAvailable: 1          ← auto-applied to all deployments via policy

A policy engine (OPA/Kyverno — Phase 6) enforces a minimum PDB on all
deployments. This ensures Karpenter never drains a node in a way that takes
a team's entire application offline, even if the team has only one replica
and no PDB defined.

---

## Burst Traffic Handling

The workload NodePool is configured for burst tolerance:
workload-nodepool:
limits:
cpu: 100              ← cap total CPU Karpenter can provision
disruption:
consolidationPolicy: WhenUnderutilized
consolidateAfter: 30m ← wait 30 min before removing nodes
budgets:
- nodes: 10%        ← never remove more than 10% of nodes at once

During a traffic burst Karpenter provisions new nodes within 60-90 seconds.
After the burst subsides it waits 30 minutes before consolidating — providing
enough buffer for traffic patterns that spike and recover quickly.

The 10% budget on node removal means that on a 10-node cluster Karpenter
will remove at most 1 node at a time during consolidation, giving workloads
time to reschedule gracefully.

---

## Summary — What Platform Teams Must Do

| Action | Owner | When |
|---|---|---|
| Deploy system NodePool | Platform | Cluster setup |
| Deploy workload NodePool | Platform | Cluster setup |
| Apply LimitRange to tenant namespaces | Platform (automated via team module) | Team onboarding |
| Configure consolidation policy | Platform | Cluster setup |
| Enforce PDB policy via OPA/Kyverno | Platform | Phase 6 |

## Summary — What Application Teams Must Do

Nothing. The platform handles node scaling, resource defaults, and
disruption protection automatically. Teams can optionally define their
own resource requests, limits, and PDBs to override the platform defaults
for more precise control.

---

## OpenShift Parallel

This pattern mirrors the OpenShift machine autoscaler experience where
teams deploy workloads without thinking about nodes. Karpenter handles
node lifecycle the same way — teams see their pods scheduled and running,
the underlying node management is invisible to them.

The key difference from OpenShift is that Karpenter is more aggressive
about cost optimization via Spot instances and consolidation. The
conservative settings in this configuration bring the behavior closer
to what OpenShift teams are used to.

---

## Phase 6 Additions

The following items are planned for Phase 6 production hardening:

- OPA/Kyverno policy to enforce minimum PDB on all deployments
- Migration from Option A (Karpenter alongside fixed nodes) to Option B
  (Karpenter owns all nodes) once NodePool configuration is validated
- Spot interruption handling via SQS and Node Termination Handler
- Graviton (ARM) instance support in the workload NodePool for
  additional cost savings

---

## Phase 6 — System/Workload Node Separation

Before enabling the system NodePool taint the following platform
components need CriticalAddonsOnly tolerations added via their
Helm values:

| Component | Namespace | Method |
|---|---|---|
| ArgoCD | argocd | Helm values — tolerations block |
| External Secrets Operator | external-secrets | Helm values — tolerations block |
| ExternalDNS | external-dns | Helm values — tolerations block |
| metrics-server | kube-system | Helm values — tolerations block |
| AWS Load Balancer Controller | kube-system | Helm values — tolerations block |
| CloudWatch Observability Controller | amazon-cloudwatch | EKS addon configuration |
| cert-manager | cert-manager | Helm values — tolerations block |

DaemonSets (aws-node, kube-proxy, eks-pod-identity-agent,
cloudwatch-agent, fluent-bit) run on all nodes by design and
do not require toleration changes.

Once all Deployment tolerations are updated, enable the system
NodePool taint:
```yaml
spec:
  template:
    spec:
      taints:
        - key: CriticalAddonsOnly
          effect: NoSchedule
```

And add nodeSelector to all tenant deployment templates:
```yaml
nodeSelector:
  node-type: workload
```
