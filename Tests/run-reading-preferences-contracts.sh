#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
output="$(mktemp -d /tmp/loomey-reading-preferences-tests.XXXXXX)"
trap 'rm -rf "$output"' EXIT
xcrun swiftc -parse-as-library \
  Lumey/Models/UserSettings.swift \
  Lumey/Models/ReadingPreferences.swift \
  Lumey/Data/ReadingGenresData.swift \
  Lumey/Data/ReadingInterestsData.swift \
  Lumey/Services/ReadingPreferencesStore.swift \
  Tests/ReadingPreferencesContracts.swift \
  -o "$output/ReadingPreferencesContracts"
"$output/ReadingPreferencesContracts"
