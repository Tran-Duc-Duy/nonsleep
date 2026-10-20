#!/bin/sh
# Runs the test suite. With full Xcode, plain `swift test` is enough; with only the
# Command Line Tools, swift-testing lives outside the default search paths.
set -eu
cd "$(dirname "$0")/.."

developer="$(xcode-select -p)"
case "$developer" in
*CommandLineTools*)
    frameworks="$developer/Library/Developer/Frameworks"
    libs="$developer/Library/Developer/usr/lib"
    exec swift test \
        -Xswiftc -F -Xswiftc "$frameworks" \
        -Xlinker -rpath -Xlinker "$frameworks" \
        -Xlinker -rpath -Xlinker "$libs" "$@"
    ;;
*)
    exec swift test "$@"
    ;;
esac
