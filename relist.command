#!/bin/zsh
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
ruby $SCRIPT_DIR/app/lib/relist.rb
