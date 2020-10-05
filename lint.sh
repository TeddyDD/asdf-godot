#!/bin/sh

set -eu

shellcheck -x bin/* \
	lib/utils.sh \
	build.sh \
	lint.sh
