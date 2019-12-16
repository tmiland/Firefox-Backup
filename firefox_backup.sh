#!/usr/bin/env bash


## Author: Tommy Miland (@tmiland) - Copyright (c) 2019


######################################################################
####                     Firefox Backup.sh                        ####
####            Script to backup your firefox profile             ####
####                   Maintained by @tmiland                     ####
######################################################################


version='1.0.0'

#------------------------------------------------------------------------------#
#
# MIT License
#
# Copyright (c) 2019 Tommy Miland
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#------------------------------------------------------------------------------#
#
# Script credits:
# Mozilla Firefox profile (w/ bookmarks, history and addons) backup Bash script
# for Mac OS X  - https://gist.github.com/PMK/22a0fde46bf497fd7d732baa07504071
# ghacks user.js - https://github.com/ghacksuserjs/ghacks-user.js
#

readonly CURRDIR=$(pwd)

sfp=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || greadlink -f "${BASH_SOURCE[0]}" 2>/dev/null)
if [ -z "$sfp" ]; then sfp=${BASH_SOURCE[0]}; fi
readonly SCRIPT_DIR=$(dirname "${sfp}")

# Icons used for printing
ARROW='➜'
DONE='✔'
ERROR='✗'
WARNING='⚠'
# Colors used for printing
RED='\033[0;31m'
BLUE='\033[0;34m'
BBLUE='\033[1;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
DARKORANGE="\033[38;5;208m"
CYAN='\033[0;36m'
DARKGREY="\033[48;5;236m"
NC='\033[0m' # No Color
# Text formatting used for printing
BOLD="\033[1m"
DIM="\033[2m"
UNDERLINED="\033[4m"
INVERT="\033[7m"
HIDDEN="\033[8m"

DEST=$1

if [ -z "$DEST" ]; then
  DEST=${CURRDIR}
fi

if [ ! -d "$DEST" ]; then
  mkdir $DEST
fi

readIniFile () { # expects one argument: absolute path of profiles.ini
  declare -r inifile="$1"
  declare -r tfile=$(mktemp)

  if [ $(grep '^\[Profile' "$inifile" | wc -l) == "1" ]; then ### only 1 profile found
    grep '^\[Profile' -A 4 "$inifile" | grep -v '^\[Profile' > $tfile
  else
    grep -E -v '^\[General\]|^StartWithLastProfile=|^IsRelative=' "$inifile"
    echo -e "${GREEN}"
    read -p 'Select the profile number ( 0 for Profile0, 1 for Profile1, etc ) : ' -r
    echo -e "\n${NC}"
    if [[ $REPLY =~ ^(0|[1-9][0-9]*)$ ]]; then
      grep '^\[Profile'${REPLY} -A 4 "$inifile" | grep -v '^\[Profile'${REPLY} > $tfile
      if [[ "$?" != "0" ]]; then
        echo -e "${RED}${ERROR}Profile${REPLY} does not exist!${NC}" && exit 1
      fi
    else
      echo -e "${RED}${ERROR} Invalid selection!${NC}" && exit 1
    fi
  fi

  declare -r profpath=$(grep '^Path=' $tfile)
  declare -r pathisrel=$(grep '^IsRelative=' $tfile)

  rm "$tfile"

  # update global variable
  if [[ ${pathisrel#*=} == "1" ]]; then
    PROFILE_PATH="$(dirname "$inifile")/${profpath#*=}"
    PROFILE_ID="${profpath#*=}"
  else
    PROFILE_PATH="${profpath#*=}"
  fi
}

getProfilePath() {
  declare -r f1=~/Library/Application\ Support/Firefox/profiles.ini
  declare -r f2=~/.mozilla/firefox/profiles.ini

  local ini=''
  if [[ -f "$f1" ]]; then
    ini="$f1"
  elif [[ -f "$f2" ]]; then
    ini="$f2"
  else
    echo -e "${RED}${ERROR}Error: Sorry, -l is not supported for your OS${NC}"
    exit 1
  fi
  readIniFile "$ini" # updates PROFILE_PATH or exits on error
}

backupProfile() {
  BACKUP_FILE_NAME=${PROFILE_ID}-$(date +"%Y-%m-%d_%H%M").tar.gz

  tar -zcf $BACKUP_FILE_NAME $PROFILE_PATH > /dev/null 2>&1
  
  mv $BACKUP_FILE_NAME $DEST

  echo -e "${GREEN}${DONE} Done! ${NC}"
  echo ""
  echo -e "${ORANGE}${ARROW} Firefox profile successfully backed up to $DEST ${NC}"
  echo ""
}

getProfilePath # updates PROFILE_PATH or exits on error
backupProfile
