#!/bin/bash

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
  echo "Usage: format.sh <file-path>"
  exit 1
fi

EXT="${FILE_PATH##*.}"

case "$EXT" in
  qml)
    /usr/lib/qt6/bin/qmlformat -i "$FILE_PATH"
    ;;
  kdl)
    npx kdlfmt format "$FILE_PATH"
    ;;
  json | md | sh | toml | css | scss)
    npx prettier --write "$FILE_PATH"
    ;;
  *)
    echo "Unsupported file type: $EXT"
    exit 1
    ;;
esac
