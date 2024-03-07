#!/bin/bash

AZORG=$AZORG
AZPROJECT=$AZPROJECT
AZUREPAT=$AZUREPAT
AZUSERNAME=$AZUSERNAME
AZUSER_EMAIL=$AZUSER_EMAIL
AZREPO="https://$AZUSERNAME:$AZUREPAT@dev.azure.com/$AZORG/$AZPROJECT/_git/pbi-cicd-test"


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
