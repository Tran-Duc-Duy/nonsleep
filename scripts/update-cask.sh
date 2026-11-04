#!/bin/sh
# Points Casks/nonsleep.rb at a published release, taking the checksum from that release's
# SHA256SUMS.txt so `brew install --cask` verifies the same bytes the workflow attested.
#   scripts/update-cask.sh v0.3.0
set -eu
cd "$(dirname "$0")/.."

version="${1:?usage: update-cask.sh VERSION}"
version="${version#v}"
base="https://github.com/Tran-Duc-Duy/nonsleep/releases/download/v$version"

sums="$(curl -fsSL "$base/SHA256SUMS.txt")" ||
    { echo "update-cask: no SHA256SUMS.txt for v$version" >&2; exit 1; }

sha="$(printf '%s\n' "$sums" | awk -v file="NonSleep-$version-macOS.zip" '$2 == file { print $1 }')"
[ -n "$sha" ] || { echo "update-cask: SHA256SUMS.txt has no NonSleep-$version-macOS.zip" >&2; exit 1; }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
sed -e "s|^  version \".*\"$|  version \"$version\"|" \
    -e "s|^  sha256 \".*\"$|  sha256 \"$sha\"|" \
    Casks/nonsleep.rb > "$tmp"
mv "$tmp" Casks/nonsleep.rb
trap - EXIT

echo "Casks/nonsleep.rb → $version ($sha)"
