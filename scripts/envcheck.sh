#!/usr/bin/env bash

# Terminate the script if has any error
set -e

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

env_variables=(MATCH_PASSWORD FASTLANE_USER FASTLANE_PASSWORD)

# Step 1: Checking the enviroment variables
echo "------------------------------"
echo "Checking environment variables."
for var in ${env_variables[*]}; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Variable $var is not set.${NC}"
        exit 1
    else
        echo -e "${GREEN}Variable $var is set.${NC}"
    fi
done

# Step 2: Check if the Xcode is present
if [[ "$(xcodebuild -version)" == *"12.1"* ]]; then
    echo -e "${GREEN}Xcode is on the version 12.1${NC}"
else
   echo -e "${RED}You need to upgrade your Xcode to version 12.1 or higher${NC}"
   exit 1 
fi

# Step 3: Check RBENV
echo "------------------------------"
echo "Checking RBENV."
if [[ "$(which ruby)" == *".rbenv"* ]]; then
    echo -e "${GREEN}Ruby is set to use RBENV${NC}"
else
   echo -e "${RED}You need to use Ruby on the RBENV${NC}"
   exit 1 
fi