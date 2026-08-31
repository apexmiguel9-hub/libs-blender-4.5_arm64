#!/bin/bash
# Build XML2 (libxml2) for Android ARM64
# Alias - uses LibXML script
exec "$(dirname "$0")/build-LibXML.sh" "$@"
