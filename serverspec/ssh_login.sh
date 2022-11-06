#!/bin/bash -xe

# Get the public IP address of the specified EC2 instance.
TARGET_IP=$(
  aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=ec2-raisetech" \
  --query "Reservations[*].Instances[*].[PublicIpAddress]" \
  --output text
)

# Describes the specified key pairs of all of your key pairs.
KEYPAIR_NAME=$(
  aws ec2 describe-key-pairs \
  --key-names CFnKeyPair \
  --query "KeyPairs[].KeyPairId" \
  --output text
)

# Get the private key pair stored in the SSM Parameter Store
if [ -z "$KEYPAIR_NAME" ]; then
  echo "Error: Couldn't find the KeyPair!"
else
  PRIVATE_KEY=$(
    aws ssm get-parameter \
    --name /ec2/keypair/${KEYPAIR_NAME} --with-decryption \
    --query Parameter.Value \
    --output text
  )
fi

# ssh-add to add the private key into the SSH authentication agent.
if [ -z "$PRIVATE_KEY" ]; then
  echo "Error: Couldn't get the private key!"
else
  echo "${PRIVATE_KEY}" | ssh-add -
fi

if [ $# = 1 ] && [ $1 = "login" ]; then
  ssh ec2-user@${TARGET_IP}
fi
