# KWEIDER Screen Control — Stable Baseline

Baseline date: 21 October 2026

This branch is the cleaned development baseline for the KWEIDER street-display control system.

## Approved entry points

- `screen-control-stable.html` — the only Screen Control entry point.
- `screen-export-production.html` — the only Production MP4 exporter exposed to the operator.

## Active internal dependency chain

`screen-control-stable.html`
→ `screen-admin-secure-v2.html`
→ `screen-admin-linked-bg.html`
→ `screen-admin-cinematic-unified.html`
→ `screen-admin.html` + `winter-luxury-v3.html` + `index.html`

Production export:

`screen-export-production.html`
→ `screen-export-production-v8.html` as the internal deterministic rendering core only.

`screen-export-production-v8.html` is retained strictly as an internal base renderer. It is not an operator-facing exporter and must not be linked from the control UI.

## Stable features at this baseline

- Supabase secure admin, Draft / Published data and version history.
- Advertisement visibility, duration and drag-and-drop order control.
- Product image positioning and zoom.
- Global or per-ad background control including Luxury Cream `#E9DCC4`.
- Independent typography sizes and text colours.
- Image Motion and Cinematic Scene FX controls.
- Live-layout preview and unified Cinematic Preview using saved Draft visual settings.
- Unified Production MP4 exporter using the same saved Draft visual settings.
- Deterministic rendering with the zero-black / no-freeze transition behaviour retained.

## Development rule

Do not create numbered wrapper chains such as V21 → V22 → V23 or multiple competing exporter buttons. Future changes must extend the approved entry points and shared data model directly.

Before a major development phase, create a checkpoint branch from this baseline. Do not modify `main` unless explicitly approved.

## Archive

The complete pre-cleanup state is preserved in:

`archive/screen-control-baseline-2026-10-21`

Pre-cleanup checkpoint commit:

`face634c76171d4e069d8b6eaea2467c4a28576f`

## Design studio extension (21 October 2026)

The approved entry point now uses the direct canvas editor and shared design engine.
See `DESIGN_STUDIO.md` for the current dependency graph, data compatibility and verification.
The earlier nested iframe chain above describes the preserved pre-extension baseline.
