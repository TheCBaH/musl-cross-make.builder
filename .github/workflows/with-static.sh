#!/bin/sh
set -eu
#set -x
exec make static.image_run CMD="$@"
