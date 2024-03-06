#!/bin/bash

AZUREPAT=$AZUREPAT
AZUSERNAME=$AZUSERNAME
AZUSERPASSWORD=$AZUSERPASSWORD
AZUSER_EMAIL=$AZUSER_EMAIL
AZORG=$AZORG
AZPROJECT=$AZPROJECT
AZREPO="https://$AZUSERNAME:$AZUREPAT@dev.azure.com/$AZORG/$AZPROJECT/_git/pbi-cicd-test"
CLIENT_ID=$CLIENT_ID
TENANT_ID=$TENANT_ID

# Remove Git information (for fresh git start)
rm -rf Brain-Squeezes/.git

# Fetch the changes from Azure DevOps to ensure we have latest
git fetch --unshallow

# Pull changes from Azure DevOps if its exiting branch and have commits on it
git pull $AZREPO

# Set Git user identity
git config --global user.email "$AZUSER_EMAIL"
git config --global user.name "$AZUSERNAME"

# Add all changes into stage, commit, and push to Azure DevOps
git add .
git commit -m "Sync from GitHub to Azure DevOps"
git push --force $AZREPO


token_response=$(curl --location 'https://login.windows.net/common/oauth2/token' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'client_id=$CLIENT_ID' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'resource=https://analysis.windows.net/powerbi/api' \
    --data-urlencode 'username=$AZUSER_EMAIL' \
    --data-urlencode 'password=$AZUSERPASSWORD' \
    --data-urlencode 'tenant_id=$TENANT_ID')

access_token=$(echo "$response" | grep -o '"access_token":"[^"]*' | awk -F'"' '{print $4}')

# Get status of the workspace
status_response=$(curl -s -X GET \
  -H "Authorization: Bearer $access_token" \
  https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/git/status)

# Extract parameters using Bash string manipulation
workspaceHead=$(echo "$status_response" | grep -o '"workspaceHead":"[^"]*' | sed 's/"workspaceHead":"//')
remoteCommitHash=$(echo "$status_response" | grep -o '"remoteCommitHash":"[^"]*' | sed 's/"remoteCommitHash":"//')

# Update the workspace from git
update_response=$(curl -X POST \
  -H "Authorization: Bearer $access_token" \
  -H "Content-Type: application/json" \
  -d '{"remoteCommitHash": "'"$remoteCommitHash"'", "workspaceHead": "'"$workspaceHead"'"}' \
  https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/git/updateFromGit)

# Output the response of the second request
echo "$update_response"