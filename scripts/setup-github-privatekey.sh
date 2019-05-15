#!/usr/bin/env bash
mkdir -p ~/.ssh
echo "$(GITHUB_KEY)" > ~/.ssh/id_rsa
echo "Setting up appropriate permissiions for ssh key"
chmod 0600 ~/.ssh/id_rsa
ls -al ~/.ssh
echo "Attempting key scan"
ssh-keyscan github.com github.com >> ~/.ssh/known_hosts
ssh-keygen -F github.com -f  ~/.ssh/known_hosts # verifies key is correctly installed
git config --global user.name $(GITHUB_USERNAME)
git config --global url."git@github.com:".insteadOf "https://github.com/"