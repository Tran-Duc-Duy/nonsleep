#!/bin/sh
# Prints the CHANGELOG.md section for a version (with or without a leading "v").
# Exits 1 if the section is missing, so a release can't ship without notes.
#   scripts/release-notes.sh v0.1.0
set -eu
cd "$(dirname "$0")/.."

version="${1:?usage: release-notes.sh VERSION}"
version="${version#v}"

notes="$(awk -v version="$version" '
    $0 ~ "^## \\[" version "\\]" { found = 1; next }
    found && /^## \[/ { exit }
    found && /^\[[^]]+\]: / { exit }
    found { print }
    END { if (!found) exit 1 }
' CHANGELOG.md)" || { echo "release-notes: no '## [$version]' section in CHANGELOG.md" >&2; exit 1; }

printf '%s\n' "$notes" | sed -e '/./,$!d'
