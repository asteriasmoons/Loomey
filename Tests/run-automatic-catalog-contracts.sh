#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
output="$(mktemp -d /tmp/loomey-catalog-tests.XXXXXX)"
trap 'rm -rf "$output"' EXIT
xcrun swiftc -parse-as-library \
  Lumey/Models/ReadingPreferences.swift \
  Lumey/Models/AutomaticBookCatalog.swift \
  Lumey/Services/AutomaticBookCatalogService.swift \
  Lumey/Services/AutomaticCatalogPersistence.swift \
  Lumey/Services/CatalogNetworkPolicy.swift \
  Lumey/Services/CatalogCoverLoader.swift \
  Lumey/Services/LumeyRecommendationCollectionsService.swift \
  Lumey/Services/RecommendationBookDetailService.swift \
  Lumey/Data/KeychainHelper.swift \
  Tests/AutomaticCatalogContracts.swift \
  -o "$output/AutomaticCatalogContracts"
"$output/AutomaticCatalogContracts"
