#!/bin/sh

set -e

if [ "$NODE_ENV" != "production" ]; then
	yarn install
fi

exec "$@"
