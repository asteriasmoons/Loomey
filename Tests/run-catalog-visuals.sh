#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
output="${1:-/tmp/loomey-catalog-visuals}"
mkdir -p "$output/CatalogVisuals.app"
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
SDKROOT="$sdk" xcrun --sdk iphonesimulator swiftc -parse-as-library -swift-version 5 -default-isolation MainActor -target arm64-apple-ios27.0-simulator -sdk "$sdk" \
  Lumey/Theme/AppTheme.swift Lumey/Theme/LumeyThemeSystem.swift \
  Lumey/Theme/BubblyIconMaterial.swift \
  Lumey/Models/AutomaticBookCatalog.swift \
  Lumey/Services/AutomaticBookCatalogService.swift Lumey/Services/CatalogCoverLoader.swift \
  Lumey/Services/AutomaticCatalogPersistence.swift Lumey/Services/CatalogNetworkPolicy.swift \
  Lumey/Services/LumeyRecommendationCollectionsService.swift Lumey/Services/RecommendationBookDetailService.swift \
  Lumey/Data/KeychainHelper.swift Lumey/Views/Home/AutomaticCatalogShelf.swift \
  Tests/CatalogVisuals.swift -o "$output/CatalogVisuals.app/CatalogVisuals"
cp Tests/CatalogVisuals-Info.plist "$output/CatalogVisuals.app/Info.plist"
if [[ -f /tmp/loomey-catalog-build/Build/Products/Debug-iphonesimulator/Lumey.app/Assets.car ]]; then
  cp /tmp/loomey-catalog-build/Build/Products/Debug-iphonesimulator/Lumey.app/Assets.car "$output/CatalogVisuals.app/Assets.car"
fi
codesign --force --sign - "$output/CatalogVisuals.app"
for device in C00E5EDB-4979-485F-8845-668511750D1F 0A8B570E-5418-4DED-A963-77C725606C53; do
  xcrun simctl boot "$device" 2>/dev/null || true
  xcrun simctl bootstatus "$device" -b
  xcrun simctl install "$device" "$output/CatalogVisuals.app"
  xcrun simctl launch --terminate-running-process "$device" im.lystaria.CatalogVisuals
  sleep 4
  xcrun simctl io "$device" screenshot "$output/$device.png"
  xcrun simctl terminate "$device" im.lystaria.CatalogVisuals
done
