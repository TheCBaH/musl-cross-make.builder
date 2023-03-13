#!/bin/sh
set -eu
set -x
cmd="$@"
exec make static.image_run CMD="$cmd"
