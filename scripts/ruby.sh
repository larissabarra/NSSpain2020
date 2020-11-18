#!/usr/bin/env bash

# Keep-alive: update existing `sudo` time stamp until `osxprep.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Step 1: Installing Ruby
if [[ "$(ruby -v)" == *"2.4.2"* ]]; then
    echo -e "${GREEN}Ruby is installed and on correct version 2.4.2${NC}"
else
    echo "------------------------------"
    echo "Instaling and setting the Ruby Version 2.4.2"
    sudo -v
    rbenv install -s 2.4.2
    rbenv global 2.4.2
    sudo chown -R "$(whoami)" /Library/Ruby/Gems/*
    rbenv exec gem install bundler
fi