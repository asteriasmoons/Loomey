# Loomey Multi-Source Recommendation Engine

Updated 2026-10-23. The backend is a newly built independent subsystem, integrated with the existing Automatic Book Catalogs UI. This is a source/automated-verification report, not a deployment or live-device acceptance report.

## What Changed

The former active path relied on bookdatabase.io for matching, discovery, full details and subscription eligibility. That single-provider dependency is no longer the catalog engine. The existing router and maintenance now use the new `vox-api/src/services/loomeyRecommendations` subsystem. Its normalization, candidate generation, strategies, scoring, deduplication, diversification and category cache do not call the retired recommendation code.

Hardcover, Google Books and Open Library independently discover and identify books. bookdatabase.io remains an optional metadata/image supplement through its existing low-level protocol client, not a prerequisite for generation. No additional backend/server or project dependency was added. No provider's personalized recommendation endpoint or AI service is used.

Integration testing also caught and corrected two pipeline failures: flat Google categories could erase Loomey's explicitly stored themes, and shallow per-category truncation could starve seven globally deduplicated sections despite sufficient candidates. The new profile retains explicit genre/theme distinctions and category pools are large enough for cross-category allocation.

## User Experience And Lifecycle

1. Normal active startup observes existing SwiftData books/sessions. Only Finished books send interests, ratings, favorites, activity and series. Topics, tags and tropes already stored on those books supply thematic interests. Archived/DNF overrides remain unchanged.
2. Protected atomic disk snapshots are validated and published immediately. Opening Automatic Book Catalogs does not initiate an independent generation job or clear saved rows.
3. Missing, stale or changed Finished profiles trigger a deduplicated background request from the application lifecycle. The new backend returns saved rows while generating/replenishing only affected categories. Fresh identical inputs do not regenerate.
4. Backend progress is saved per category. The app merges partial updates without removing valid cached rows, and publishes metadata before cover prefetch finishes. A failed provider/category/image is not an empty whole-screen success or a reason to erase other categories.
5. The existing vertical category sections, horizontal carousels, complete multiline titles/authors and detail sheet remain. Real full-size associated covers are preferred; multiple associated provider URLs can fall back independently. Failed image bytes are not saved as covers.
6. Backend independent metadata/category retention is seven days, normal refresh six hours; failed refresh retry five minutes. The app respects server/category expiry and retains the same independent-data bound. Licensed supplements have their own at-most-24-hour expiry. Cover bytes retain the existing 24-hour/80-entry/64-MB disk and 24-MB memory bounds.
7. Foreground and relevant Finished changes resume preparation. iOS suspension is not assumed to permit background execution. An already-started backend job can continue without navigation/polling; a process restart can interrupt in-flight work but completed categories remain saved.

All owned statuses supply exclusion identities, including incomplete ISBN-only owned records. Backend matching uses namespaced provider/work identifiers, valid equivalent ISBNs and normalized actual title/author aliases. iOS validates ownership and cross-category identities again. No existing Book UUID, reading state, library association, stored metadata or Collections data is migrated/deleted.

The seven original names remain: You Might Also Like; Based on Your Favorite Genres; Explore Similar Themes; Discover New Authors; More From Authors You Read; Related Books; Discover Something New. Each has its own strategy, score adjustments and saved pool. Series recommendations belong in existing Related Books/You Might Also Like, not a new duplicate section. No unrelated books are added to fill sparse categories.

Saving a recommendation still uses the existing library-save UI. Independent saved metadata is returned directly when available. An older compatible cached card can send its identity for lookup by the new provider adapters; that lookup does not become a Finished-book signal. Licensed supplemental fields are not permanently copied into the library.

## Configuration

Set `HARDCOVER_API_TOKEN` on the existing backend. Reuse `GOOGLE_BOOKS_API_KEY` and `BOOKDATABASE_API_KEY`. Set `OPEN_LIBRARY_CONTACT_EMAIL` for identified Open Library use. The existing Mongo connection is unchanged. `BOOKDATABASE_SUBSCRIPTION_EXPIRES_AT` is optional, not required. Missing/disabled bookdatabase.io does not disable independent recommendations. No provider credential or Apple sign-in requirement was added to iOS.

The [backend implementation guide](/Users/asteriasmoons/Desktop/vox-api/AUTOMATIC_BOOK_CATALOGS.md) documents exact queries, category qualifications/weights, quotas, cache retention, licensing, endpoints and official sources.

## Network And Verification Boundary

HTTPS and standard trust validation remain mandatory. Node provider failures are isolated with bounded retries, timeouts, budgets and rate cooldowns. URLSession errors are mapped to useful feature-level messages; cached results remain usable. Associated cover fallbacks work independently of metadata. Diagnostics use `[LoomeyCatalog]` and correlated trace IDs without keys or raw library data.

The deployed certificate/handshake cause of the reported TLS failure has not been established. Production HTTPS, credentials, provider permission/coverage, actual images, startup/CloudKit timing and rendered iPhone/iPad interactions remain unverified. No certificate bypass, ATS weakening, app launch, simulator boot, live provider/database/device test, SSH or deployment was performed.

Final automated verification on the implementation source:

- Backend tests: 102 passed, 0 failed, 0 skipped across `tests/loomey-recommendations.test.mjs` and `tests/automatic-catalogs.test.mjs` (47 new-engine tests and 55 retained provider regressions). Network responses and storage were isolated test fixtures, not production services.
- Swift contracts: 73 checks passed using the actual Foundation models/services, injected URLProtocol responses and temporary persistence, including cache restoration, library exclusions, cover fallback and network failure handling.
- Backend compilation: `npm run build` passed.
- iOS compilation: the Lumey Debug build passed for a generic arm64 iOS Simulator destination with code signing disabled. No simulator was booted or application launched.
- Hardcover schema validation: all three query documents and 17 generated variable sets passed against the published GraphQL schema, including numeric tag IDs, English editions, ISBN, author, series and related-work queries. This was offline schema validation, not an authenticated provider request.

Passing these checks does not establish the full real-network browsing flow. The production and device verification boundaries above still apply.

## Files Created In vox-api

| File | Purpose |
| --- | --- |
| `src/services/loomeyRecommendations/types.ts` | Independent engine book/profile/provider/category contracts and errors. |
| `src/services/loomeyRecommendations/normalization.ts` | New title/author/ISBN normalization, namespaced identity matching, metadata precedence and merging. |
| `src/services/loomeyRecommendations/repository.ts` | Own temporary persistence, shared request deduplication, leases and Mongo rate/daily reservations using the existing connection. |
| `src/services/loomeyRecommendations/transport.ts` | Independent HTTPS provider transport, credentials, bounded retries, cooldowns, budgets and safe diagnostics. |
| `src/services/loomeyRecommendations/strategies.ts` | Finished profile, author/series/interest/relationship plans, category scoring and author/series/genre diversification. |
| `src/services/loomeyRecommendations/catalogCache.ts` | Independent normalized records, per-category pools, retained failures, ownership filtering and global allocation. |
| `src/services/loomeyRecommendations/engine.ts` | New end-to-end discovery/enrichment/job orchestration and independent detail/library metadata. |
| `src/services/loomeyRecommendations/index.ts` | Production wiring of the new subsystem inside the existing backend. |
| `src/services/loomeyRecommendations/providers/hardcover.ts` | Schema-based GraphQL discovery, English editions, authors, series, tags and related-work IDs. |
| `src/services/loomeyRecommendations/providers/googleBooks.ts` | Google discovery, identifiers, descriptions, subtitles and image enrichment. |
| `src/services/loomeyRecommendations/providers/openLibrary.ts` | Open Library work/edition/author/subject discovery and verified-edition cover fallback. |
| `src/services/loomeyRecommendations/providers/bookDatabase.ts` | Optional low-level integration supplement with separate temporary licensed data. |
| `tests/loomey-recommendations.test.mjs` | New engine/provider/cache/failure tests and a complete mocked multi-adapter pipeline. |

## Files Modified In vox-api

| File | Purpose |
| --- | --- |
| `src/routes/automaticCatalogs.ts` | Switch active catalogs/details to the new engine; retain paths/limits; add identity-bearing POST library-metadata compatibility. |
| `src/services/automaticCatalogMaintenance.ts` | Stop invoking the old engine; isolate supplementary provider maintenance and revocation cleanup. |
| `AUTOMATIC_BOOK_CATALOGS.md` | Current new-engine architecture, configuration, lifecycle, provider references and limits. |

## Files Modified In Lumey

| File | Purpose |
| --- | --- |
| `Lumey/Models/AutomaticBookCatalog.swift` | Multi-provider aliases/covers, existing Finished series payload, engine version, scoped source removal and temporary metadata expiry. |
| `Lumey/Services/AutomaticBookCatalogService.swift` | Keep compatible disk rows during engine transition; publish before prefetch; scoped provider failure handling; independent metadata lookup for saving cards. |
| `Lumey/Services/CatalogCoverLoader.swift` | Associated multi-provider fallbacks, cancellation and scoped licensed-image removal without invalidating catalogs. |
| `Lumey/Views/Home/AutomaticCatalogPreparation.swift` | Forward existing Finished series, topics, tags and tropes through the existing root preparation hook. |
| `Lumey/Views/Home/AutomaticCatalogShelf.swift` | Pass associated cover alternatives through the existing carousel; preserve layout and interactions. |
| `Lumey/Views/Home/RecommendedBookDetailSheet.swift` | Use the same cover alternatives and identity-bearing independent library save; preserve detail UI/navigation. |
| `Tests/AutomaticCatalogContracts.swift` | Mocked multi-source decoding, restart cache, Finished fields, owned exclusions, cover/TLS fallback, scoped revocation and save contracts. |
| `AUTOMATIC_BOOK_CATALOGS.md` | This cross-project manifest and verification report. |

Existing startup/root wiring, persistent snapshot infrastructure and catalog view ownership were reused unchanged. Retired backend algorithm files were not renamed/wrapped/reused as the new engine. Collections, Book persistence/schema, goals, ratings, reading history, app authentication, unrelated search/recommendation endpoints and pre-existing dirty work were intentionally left untouched in this implementation.
