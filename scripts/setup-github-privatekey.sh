#!/usr/bin/env bash
# setup env with GITHUB_KEY with github private key and GITHUB_USER_NAME, with username to set agent with credentials.
mkdir -p ~/.ssh
echo "${GITHUB_KEY}" > ~/.ssh/id_rsa
echo "Setting up appropriate permissiions for ssh key"
chmod 0600 ~/.ssh/id_rsa
ls -al ~/.ssh
echo "Attempting key scan"
ssh-keyscan github.com github.com >> ~/.ssh/known_hosts
ssh-keygen -F github.com -f  ~/.ssh/known_hosts # verifies key is correctly installed
git config --global user.name ${GITHUB_USER_NAME}
git config --global user.email ${GITHUB_USER_EMAIL}
git config --global url."git@github.com:".insteadOf "https://github.com/"