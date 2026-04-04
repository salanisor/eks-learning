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