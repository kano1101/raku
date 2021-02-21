#!/bin/sh
SCRIPT_DIR="$(dirname "$0")"
cd "$SCRIPT_DIR"
ruby "$SCRIPT_DIR/app/lib/rakuma.rb"
