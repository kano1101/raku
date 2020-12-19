#!/bin/zsh
SCRIPT_DIR=$(dirname "$0")
cd $SCRIPT_DIR
ruby $SCRIPT_DIR/app/lib/relist.rb
