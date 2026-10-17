#!/usr/bin/env bash
# Creates two Redshift Serverless workgroups (producer and consumer) in the default VPC
# and writes their endpoints and namespace ids to lab.env. Run teardown.sh when you are done.
set -euo pipefail

REGION=${REGION:-us-east-1}
NAME=${NAME:-dbt-datashare-lab}
BASE_RPU=${BASE_RPU:-4}
MY_IP=${MY_IP:-$(curl -s https://checkip.amazonaws.com)}
ADMIN_USER=awsadmin
ADMIN_PW=${ADMIN_PW:-Aa1$(python3 -c 'import secrets,string;print("".join(secrets.choice(string.ascii_letters+string.digits) for _ in range(20)))')}
TAG_KEY=Project

export AWS_DEFAULT_REGION=$REGION
VPC=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)
# Serverless needs subnets in at least 3 AZs, take the first three default subnets by AZ name
SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC Name=default-for-az,Values=true \
  --query 'sort_by(Subnets,&AvailabilityZone)[:3].SubnetId' --output text)

SG=$(aws ec2 create-security-group --group-name "$NAME" --description "$NAME" --vpc-id "$VPC" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=$TAG_KEY,Value=$NAME}]" \
  --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 5439 --cidr "$MY_IP/32" >/dev/null

for role in producer consumer; do
  aws redshift-serverless create-namespace --namespace-name "$NAME-$role" --db-name dev \
    --admin-username "$ADMIN_USER" --admin-user-password "$ADMIN_PW" --tags key=$TAG_KEY,value=$NAME >/dev/null
  aws redshift-serverless create-workgroup --workgroup-name "$NAME-$role" --namespace-name "$NAME-$role" \
    --base-capacity "$BASE_RPU" --publicly-accessible --security-group-ids "$SG" --subnet-ids $SUBNETS \
    --tags key=$TAG_KEY,value=$NAME >/dev/null
done

for role in producer consumer; do
  until [ "$(aws redshift-serverless get-workgroup --workgroup-name "$NAME-$role" --query 'workgroup.status' --output text)" = AVAILABLE ]; do
    sleep 10
  done
done

{
  echo "REGION=$REGION"
  echo "NAME=$NAME"
  echo "SG=$SG"
  echo "ADMIN_USER=$ADMIN_USER"
  echo "ADMIN_PW=$ADMIN_PW"
  for role in producer consumer; do
    up=$(echo $role | tr a-z A-Z)
    echo "${up}_HOST=$(aws redshift-serverless get-workgroup --workgroup-name "$NAME-$role" --query 'workgroup.endpoint.address' --output text)"
    echo "${up}_NAMESPACE=$(aws redshift-serverless get-namespace --namespace-name "$NAME-$role" --query 'namespace.namespaceId' --output text)"
  done
} > lab.env
echo "ready, see lab.env"
