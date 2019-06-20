#!/bin/sh

set -eu

mkdir -p deploy

GO111MODULE=on
export GO111MODULE
go get
go build
./asdf-godot | sort -V > deploy/godot-versions.txt
