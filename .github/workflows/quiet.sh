#!/bin/sh
set -eu
#set -x
tmp_stdout=$(mktemp)
tmp_stderr=$(mktemp)
if "$@" >$tmp_stdout 2>$tmp_stderr ; then
    rc=$?
else
    rc=$?
    echo "::error :: command='$@' rc=$rc"
    echo "::group::stderr tail"
    tail -20 $tmp_stderr
    echo "::group::stdout tail"
    tail -20 $tmp_stdout
fi
echo "::group::stderr"
cat $tmp_stderr
echo "::group::stdout"
cat $tmp_stdout
echo "::endgroup::"
rm $tmp_stderr $tmp_stdout
exit $rc
