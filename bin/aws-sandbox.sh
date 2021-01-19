#!/usr/bin/env bash

AWS_PROFILE="sandbox"
CURRENT_AWS_USER=$(aws sts get-caller-identity --output json | jq -r '.Arn' | cut -f 2 -d '/')
TEMP_ROLE_FILE="/tmp/role.txt"

# Please specify the required software here.
REQUIRED_SOFTWARE=(aws jq)

fail () {
  printf "\r\033[2K[ \033[0;31m\u2718 FAIL\033[0m ] %s\n" "$1"
  echo ""
  exit
}

# Sanity check.
for i in "${REQUIRED_SOFTWARE[@]}"; do
  echo "Check the availibility of ${i}"

  REQUIRED_BINARY=$(command -v "$i")
  if ! [[ -x "${REQUIRED_BINARY}" ]]; then
    fail "${i} is not installed..."
  fi
done

# Create the file with 066 permissions.
umask 077 && touch ${TEMP_ROLE_FILE}

read -rp "Please enter AWS ID: " aws_id

aws sts assume-role --role-arn "arn:aws:iam::$aws_id:role/fullaccess" --role-session-name "${CURRENT_AWS_USER}" > ${TEMP_ROLE_FILE}

aws configure set aws_access_key_id "$( (jq .Credentials.AccessKeyId | xargs) < ${TEMP_ROLE_FILE} )" --profile ${AWS_PROFILE}
aws configure set aws_secret_access_key "$( (jq .Credentials.SecretAccessKey | xargs) < ${TEMP_ROLE_FILE} )" --profile ${AWS_PROFILE}
aws configure set aws_session_token "$( (jq .Credentials.SessionToken | xargs) < ${TEMP_ROLE_FILE} )" --profile ${AWS_PROFILE}

rm -f ${TEMP_ROLE_FILE}
