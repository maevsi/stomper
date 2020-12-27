#!/bin/sh

# Get this script's directory
THIS=$(dirname "$(readlink -f "$0")")

mkdir -p "$THIS/../dist/email-templates/"

cp "$THIS/../assets/" "$THIS/../dist/" -R
find "$THIS/../src/email-templates/" -maxdepth 1 -type f -name '*.mjml' -exec mjml -o "$THIS/../dist/email-templates/" -r {} \;