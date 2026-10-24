# Reading Preferences And PostgreSQL Recommendations

## Selection Catalog Update

Favorite Fiction Genres, Favorite Nonfiction Genres and Current Interests now use expandable, accent-filled cards. Their headers show the selection count; the custom chevron expands wrapping chips and the existing addwavy button opens the searchable multiselect sheet. The chip viewport is capped at four chip-row heights plus row spacing, not four selections. Extra chips scroll inside the card. Genre cards use primary; interests use secondary; recommendation style remains indicators. Shared material components, the custom category slider and the two-plus-one style layout are unchanged.

Current interests are chosen from the new themes, tropes and subjects catalog instead of entered as free text. Previously saved custom interests remain in both the picker and the saved configuration, even when they are not catalog options. Witchcraft is included in nonfiction choices and category matching on iOS and the backend.

Selection-count caps are removed from the picker, Swift normalization/persistence and Vox API validation. All selected values are retained in JSON, preference fingerprints and recommendation scoring. Existing per-label text sanitation and bounded provider request budgets remain; these do not truncate saved selections. No storage schema or account synchronization change is required. Deploy the matching API update before relying on more than the former 64 genres or 20 interests per list.

Verification for this update is source review only. Regression tests were updated for uncapped selections, persistent round trips, legacy interests and Witchcraft but were not run. No builds, compilation checks, simulators, application launches, live services or deployment were performed. The older verification results below predate this update and do not verify the new dropdown interactions.

## Reader Experience

Settings contains a Reading Preferences entry using the existing settings card and adaptive sheet/full-screen presentation. The editor includes Fiction, Nonfiction or Both; independent searchable fiction/nonfiction genre and current-interest multiselects; and Follow My Preferences, Blend My Interests or Surprise Me.

Genre choices reuse `ReadingGenresData`, including its subgenres. Switching categories does not delete the other category's favorites. Current interests are separate from favorites. Save commits the draft; closing without saving discards it. Use Reading History Only clears just reading preferences, not the library, account, saved catalogs, reading statuses or other settings.

## Persistence And Account Scope

The existing `UserSettings` SwiftData model has two additive attributes: default-empty `readingPreferencesJSON` and optional `readingPreferencesUpdatedAt`. No new model container, database, login or authentication requirement was introduced. This is the existing private `iCloud.im.lystaria.Lumey` CloudKit store, so preferences follow the same iCloud account and device synchronization rules as the library. They also save locally without network access.

The preference-specific timestamp selects the latest value when CloudKit delivers duplicate settings records. Reset writes a newer empty value, so an older configured record cannot restore cleared preferences. Unrelated changes to settings timestamps cannot override reading preferences. Unchanged values do not cause another save. Save failures retain the draft and restore only the changed settings fields, without rolling back unrelated library edits.

Synchronization is opportunistic rather than guaranteed while suspended. No live CloudKit synchronization or production schema migration was tested. See [Apple's SwiftData synchronization documentation](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices).

## Request And Catalog Lifecycle

1. The existing root `AutomaticCatalogPreparation` observes both library signals and synced preferences, independent of navigation.
2. Matching saved catalogs are published immediately. Changing preferences invalidates request freshness, not the saved catalog files.
3. Active startup, relevant data changes, foregrounding and the existing foreground refresh timer prepare missing/stale recommendations. iOS suspension is not relied on.
4. The existing POST `/api/books/automatic-catalogs` receives optional `preferences` alongside `books`, including on progressive polls. Only Finished books send positive historical signals; all library statuses remain exclusions.
5. Previously saved results remain available during refresh/network failure if they satisfy the newly selected category and Follow My Preferences restrictions. Incompatible cards are hidden, not shown as matching the new selections.
6. Preference-aware snapshots survive relaunches and do not refetch identical fresh requests. Reset omits `preferences`, restoring the original history-only wire format.

The seven existing vertically stacked catalog sections and horizontal carousels remain intact. Readers with preferences but no Finished books can receive genre/theme/discovery sections. Author/related sections are not fabricated without supporting reading history. A section remains absent when insufficient usable data exists.

## Backend Integration

The existing Vox engine now reads the PostgreSQL book knowledge catalog before external discovery. It uses existing authors, editions, provider IDs, genres, subjects, tags, series and related-work tables. Read queries do not enqueue jobs, start the worker, collect provider books or alter PostgreSQL data. The existing shared pool is reused.

Follow My Preferences requires a selected genre/current-interest match when supplied and downweights historical evidence; history cannot override explicit selections. Blend My Interests combines them with Finished history. Surprise Me permits broader category-level discovery while retaining Fiction/Nonfiction selection. Specific category selections are enforced for every section, including client-side cached results. Primary genre classifications take precedence over subjects, so a novel about history does not become nonfiction.

Provider/work identifiers, normalized ISBN variants and title/author comparisons deduplicate PostgreSQL and external editions. Existing library books remain excluded. Author/series/genre diversification and cross-section deduplication remain active. Suitable stored results avoid external provider calls; underfilled sections retain Hardcover, Google Books and Open Library fallback, with the existing optional bookdatabase.io supplement.

See [the Vox API report](/Users/asteriasmoons/Desktop/Lumey/VOX_API_READING_PREFERENCES.md) for the exact request, SQL boundaries, cache policy, deployment requirements and complete backend file manifest.

## Verification

- 124 backend automated tests passed: preference parsing/modes, original history-only behavior, all-status exclusion, PostgreSQL query construction/normalization, injected PostgreSQL-to-engine pipeline, seven populated fixture sections, provider fallback, persistent caches, route forwarding, metadata/covers, idle pool errors and failure preservation.
- 89 Swift catalog contract checks passed using mocked URLSession responses and temporary catalog/cover storage, including preference serialization, freshness, startup preparation, cache restoration, TLS failure retention and category filtering.
- 42 reading preference checks passed using the actual SwiftData model/service and an isolated local store with CloudKit disabled, including closing/reopening the store, reset precedence, required genre choices and preservation of unrelated settings.
- `npm run build` passed in Vox API.
- Generic arm64 iOS Simulator-target Debug compilation passed with signing disabled. No simulator was booted and no application was launched.

The PostgreSQL tests inject pool responses; they do not execute against a running database. Actual PostgreSQL permissions, schema/data coverage, query plans/latency, live provider responses, CloudKit synchronization and rendered device interactions remain unverified. No live database/device/SSH tests or deployments were performed. Passing these checks does not prove the complete production browsing flow.

## Release Requirements

Release the updated iOS app and deploy the matching Vox API code when authorized. The API service needs its existing `BOOK_KNOWLEDGE_DATABASE_URL` and existing SSL configuration, plus the existing migrated `bk_*` schema. Missing/unavailable PostgreSQL falls back to external sources. No new PostgreSQL migration, dependency, preference database or provider credential is required by this change.

Include the two new SwiftData attributes in the existing CloudKit production schema as part of the normal release process. No schema promotion was performed here. Keep the existing weekly Railway worker and its ten-minute maximum unchanged; recommendation reads are independent of `BOOK_KNOWLEDGE_ENABLED` and do not start ingestion.

## Files Created In Loomey

| File | Purpose |
| --- | --- |
| `Lumey/Models/ReadingPreferences.swift` | Codable categories, styles, normalized favorites/current interests and defensive matching. |
| `Lumey/Services/ReadingPreferencesStore.swift` | Reuse the synced settings record, save/reset, duplicate record selection and localized save recovery. |
| `Lumey/Views/Home/ReadingPreferencesSheet.swift` | Functional preference editor and searchable genre multiselect. |
| `Lumey/Data/ReadingInterestsData.swift` | Structured themes, tropes and subjects for the current-interest multiselect. |
| `Tests/ReadingPreferencesContracts.swift` | Real isolated SwiftData persistence and preference contracts. |
| `Tests/run-reading-preferences-contracts.sh` | Standalone automated preference contract runner. |
| `READING_PREFERENCES.md` | Experience, synchronization, integration, verification and file manifest. |

## Files Modified In Loomey

| File | Purpose |
| --- | --- |
| `Lumey/Models/UserSettings.swift` | Add the two CloudKit-compatible persistent preference attributes. |
| `Lumey/Data/ReadingGenresData.swift` | Derive fiction/nonfiction preference choices from the existing taxonomy. |
| `Lumey/Views/Home/SettingsView.swift` | Add the existing-style settings entry and adaptive editor presentation. |
| `Lumey/Models/AutomaticBookCatalog.swift` | Optional preference request field and defensive response/category filtering. |
| `Lumey/Services/AutomaticBookCatalogService.swift` | Preference-aware requests, fingerprints, retries and retained cache validation; support preference-only discovery. |
| `Lumey/Views/Home/AutomaticCatalogPreparation.swift` | Observe synced preference changes during the existing application lifecycle. |
| `Lumey/Views/Home/HomeAutomaticCatalogsSection.swift` | Allow the existing loading/empty view for preference-only users without altering carousels. |
| `Tests/AutomaticCatalogContracts.swift` | Preference/network/cache regression coverage. |
| `Tests/run-automatic-catalog-contracts.sh` | Include the new Foundation preference contract in the existing runner. |

All pre-existing unrelated dirty files were left unchanged by this task. Collections, book detail views, existing library data, authentication, account services, app navigation, the SwiftData container and worker infrastructure were intentionally preserved.
