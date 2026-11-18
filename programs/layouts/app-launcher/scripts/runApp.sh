#!/bin/bash

if [[ "${1}" = "" ]]; then
  exit 1
fi

if [[ "$(dirname "${1}")" != "/usr/share/applications" && "$(dirname "${1}")" != "$HOME/.local/share/applications" ]]; then
  exit 1
fi

dex "${1}" 
exit 0
