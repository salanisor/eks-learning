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
kubectl delete ingress -n test-app test-app 2>/dev/null || true
kubectl delete ingress -n payments payments 2>/dev/null || true
kubectl delete ingress -n argocd argocd 2>/dev/null || true
kubectl delete applications -n argocd --all 2>/dev/null || true
kubectl delete nodeclaims --all 2>/dev/null || true

# Give time for ALBs and Karpenter nodes to clean up
sleep 60

# Verify Karpenter nodes are gone
kubectl get nodes