#!/usr/bin/env bash
# Deletes everything setup.sh created, then lists whatever still carries the project tag.
set -euo pipefail
cd "$(dirname "$0")"
. "${LAB_ENV:-./lab.env}"
export AWS_DEFAULT_REGION=$REGION

for role in producer consumer; do
  aws redshift-serverless delete-workgroup --workgroup-name "$NAME-$role" >/dev/null
done
for role in producer consumer; do
  while aws redshift-serverless get-workgroup --workgroup-name "$NAME-$role" >/dev/null 2>&1; do sleep 10; done
  aws redshift-serverless delete-namespace --namespace-name "$NAME-$role" >/dev/null
done
for role in producer consumer; do
  while aws redshift-serverless get-namespace --namespace-name "$NAME-$role" >/dev/null 2>&1; do sleep 10; done
done
# the security group stays attached to the workgroup network interfaces for a short while
for i in $(seq 1 30); do
  aws ec2 delete-security-group --group-id "$SG" 2>/dev/null && break
  sleep 10
done

echo "left over with tag Project=$NAME:"
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values="$NAME" \
  --query 'ResourceTagMappingList[].ResourceARN' --output text
