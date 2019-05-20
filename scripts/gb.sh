#!/bin/bash
set -euo pipefail

if [[ -z "${GREEN_BERET_HOME+x}" ]]; then
    echo 'Please source `environment`'
	exit 1
fi

command=$1

GREEN_BERET_DNS=$(aws ec2 describe-instances --instance-ids $GREEN_BERET_INSTANCE_ID | jq -r .Reservations[0].Instances[0].PublicDnsName)

if [[ $command == "login" ]]; then
    if [[ ! -e ${GREEN_BERET_ID} ]]; then
        key=$(aws secretsmanager get-secret-value --secret-id ${GREEN_BERET_SECRET_ID} || exit 1)
        echo $key | jq -r .SecretString > ${GREEN_BERET_ID}
        chmod 400 ${GREEN_BERET_ID}
    fi
    
    if [[ -e ${GREEN_BERET_ID} ]]; then
        # ssh -i $GREEN_BERET_ID -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -o "LogLevel ERROR" ubuntu@$GREEN_BERET_DNS
        mosh --ssh="ssh -i $GREEN_BERET_ID -o \"UserKnownHostsFile /dev/null\" -o \"StrictHostKeyChecking no\" -o \"LogLevel ERROR\"" ubuntu@$GREEN_BERET_DNS
	else
        echo "Unable to locate identity file"
    fi
elif [[ $command == "start" ]]; then
    aws ec2 start-instances --instance-ids $GREEN_BERET_INSTANCE_ID
elif [[ $command == "stop" ]]; then
    aws ec2 stop-instances --instance-ids $GREEN_BERET_INSTANCE_ID
elif [[ $command == "state" ]]; then
    aws ec2 describe-instances --instance-ids $GREEN_BERET_INSTANCE_ID | jq .Reservations[0].Instances[0].State
fi
