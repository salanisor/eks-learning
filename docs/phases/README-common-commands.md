# Check addon is running
kubectl get pods -n amazon-cloudwatch

# Check node IAM policy attached
aws iam list-attached-role-policies \
  --role-name eks-learning-node-role \
  --query 'AttachedPolicies[*].PolicyName' \
  --output table

# Check alarms created
aws cloudwatch describe-alarms \
  --alarm-name-prefix eks-learning \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' \
  --output table \
  --region us-east-1

# Sping things down
Step 1 — Remove Kubernetes resources first to clean up ALBs and DNS:
bashkubectl delete ingress -n test-app test-app 2>/dev/null || true
kubectl delete ingress -n payments payments 2>/dev/null || true
kubectl delete ingress -n argocd argocd 2>/dev/null || true
kubectl delete applications -n argocd --all 2>/dev/null || true
kubectl delete nodeclaims --all 2>/dev/null || true

# Give time for ALBs and Karpenter nodes to clean up
sleep 60

# Verify Karpenter nodes are gone
kubectl get nodes
Step 2 — Verify ALBs are removed:
bashaws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code]' \
  --output table --region us-east-1

# Step 3 — Terraform destroy:
bashcd terraform/environments/dev
terraform destroy -auto-approve

# Step 4 — Final commit:
bashcd ~/git/eks-learning
git add .
git commit -m "chore: end of phase 5 session - spinning down to reduce cost"
git push origin main

# Step 5 — Verify nothing billable remains:
bashaws eks list-clusters --region us-east-1
aws ec2 describe-nat-gateways \
  --filter Name=state,Values=available \
  --query 'NatGateways[*].[NatGatewayId,State]' \
  --output table --region us-east-1
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code]' \
  --output table --region us-east-1