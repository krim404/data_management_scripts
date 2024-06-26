#!/bin/bash

smbconf="/etc/samba/smb.conf"
shares=()
in_share_block=false

# Shares aus der smb.conf auslesen
while IFS= read -r line; do
  if [[ $line =~ ^\[.*\]$ ]]; then
    in_share_block=true
    share=$(echo $line | cut -d '[' -f2 | cut -d ']' -f1)
    share_path=""
  elif [[ $in_share_block = true ]]; then
    if [[ $line =~ ^path\ =\ (.*) ]]; then
      share_path="${BASH_REMATCH[1]}/.recycle/"
    elif [[ $line =~ ^vfs\ objects\ =\ recycle ]]; then
      if [ -e "$share_path" ]; then
         shares+=("$share_path")
      fi
    fi
  fi
done < "$smbconf"

for share in "${shares[@]}"; do
  find $share* -type f -atime +14 -exec rm -rf '{}' \; 2> /dev/null
  find $share -depth -type d -empty -exec rmdir {} \; 2> /dev/null
done
