#!/usr/bin/env bash

# Keep-alive: update existing `sudo` time stamp until `osxprep.sh` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

GREEN='\033[0;32m'
NC='\033[0m' # No Color

if type xcode-select >&- && xpath=$(xcode-select --print-path) && test -d "${xpath}" && test -x "${xpath}" ; then
   echo -e "${GREEN}Xcode Command Line Tools Already Installed${NC}"
else
    echo "------------------------------"
    echo "Installing Xcode Command Line Tools."
    xcode-select --install
fi