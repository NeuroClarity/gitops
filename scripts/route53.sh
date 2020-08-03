#!/usr/bin/env bash
set -e

# HOSTED_ZONE=Z1X6EH6Y718AC7
# KUB_SVC=prod-wind-service
# DNS_NAME=wind.prod.syntheticb.io
# ENV=prod

if [ -z "$HOSTED_ZONE" ]
then
  echo "\$HOSTED_ZONE cannot be empty"
  exit 1
fi

if [ -z "$KUB_SVC" ]
then
  echo "\$KUB_SVC cannot be empty"
  exit 1
fi

if [ -z "$DNS_NAME" ]
then
  echo "\$DNS_NAME cannot be empty"
  exit 1
fi

if [ -z "$ENV" ]
then
  echo "\$ENV cannot be empty"
  exit 1
fi

echo -e "Getting AWS DNSName for: \n\t'$KUB_SVC'\n"

AWS_DNS_NAME=`kubectl get services --output json --namespace ${ENV} | \
  jq '.items[] | select(.metadata.name=="'${KUB_SVC}'") | .status.loadBalancer.ingress[0].hostname' | \
  cut -d\" -f2`

if [ -z "$AWS_DNS_NAME" ]
then
  echo "\$AWS_DNS_NAME cannot be empty"
  exit 1
fi

echo -e "Getting Load Balancer Hosted Zone for: \n\t'$AWS_DNS_NAME'\n"

LB_HOSTED_ZONE=`aws elb describe-load-balancers --region us-west-2 --output=json | \
  jq '.LoadBalancerDescriptions[] | select(.DNSName=="'${AWS_DNS_NAME}'") | .CanonicalHostedZoneNameID' | \
  cut -d\" -f2`

echo -e "Hosted Zone: \n\t'$LB_HOSTED_ZONE'\n"

TIME_STAMP=`date -u +%Y%m%d_%H%M%S`
CHANGE_COMMENT="User '$USER' updated at UTC time: $TIME_STAMP"

# aws route53 change-resource-record-sets --hosted-zone-id "${HOSTED_ZONE}" \
#   --change-batch '{
#   "Comment": "'"$CHANGE_COMMENT"'",
#   "Changes": [
#     {
#       "Action": "UPSERT",
#       "ResourceRecordSet": {
#         "Name": "'${DNS_NAME}'.",
#         "Type": "A",
#         "AliasTarget": {
#           "HostedZoneId": "'${LB_HOSTED_ZONE}'",
#           "DNSName": "dualstack.'${AWS_DNS_NAME}'",
#           "EvaluateTargetHealth": false
#         }
#       }
#     }
#   ]
# }'


