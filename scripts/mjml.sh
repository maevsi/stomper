#!/bin/sh

# Get this script's directory
THIS=$(dirname "$(readlink -f "$0")")

find "$THIS/../src/email-templates/" -maxdepth 1 -type f -name '*.mjml' -exec "$THIS/../node_modules/.bin/mjml" -o "$THIS/../src/email-templates/" -r {} \;
