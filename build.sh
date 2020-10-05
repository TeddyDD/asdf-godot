#!/bin/sh

set -eu

mkdir -p deploy

go get
go build
./asdf-godot | sort -V >deploy/godot-versions.txt
