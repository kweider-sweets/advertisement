# KWEIDER design studio — 21 October 2026

Development branch: `development/screen-next`. Production `main` is not changed.
Checkpoint before implementation: `f8c98dd4e41aa23852363f68ca3cff4db7bd794b`.

The approved operator entry remains `screen-control-stable.html`. It now directly loads
`screen-studio.js`, `screen-baseline.js`, and `screen-design-engine.js`, replacing the nested
iframe editing surface. Earlier admin files are retained for baseline/export compatibility.

The editor and approved `screen-export-production.html` use the identical deterministic
`KweiderDesign.render()` canvas engine. The internal v8 core still handles H.264 encoding,
playlist preflight, and screen cropping. No additional numbered wrapper chain is introduced.

Per-ad layout is persisted under `content.visual.layers`; existing content and unknown
fields are preserved. Layer defaults are horizontal at zero degrees. Existing `visual.fontSizes`,
`visual.colors`, `zoom`, `x`, and `y` are accepted for compatibility. Layout positions and
sizes use the fixed installation canvas of 2160×1920 (two 1080×1920 screens).

Supported controls: content, dimensions, position, drag/resize, typography, colours,
solid/gradient/image backgrounds, extra text/images, opacity, rounded image clipping,
brightness/contrast/saturation, shadows, layer visibility/locking/order, motion, entry/exit
and delay, schedule, duration, transition duration, duplication, undo/redo, draft recovery,
version restore, secure save/publish, production export. All mutations remain per-ad.

Save uses an optimistic draft version predicate to reject overwriting another browser's
newer draft. New ads use INSERT rather than silent upsert. Uploads use unique storage paths.
Publication uses the existing RLS-protected RPC and immutable public image paths.
No database schema or policies were changed, and no user advertisement was saved or published
by the implementation process. Physical display wiring remains as previously configured;
this development editor does not change production playback automatically.

Validation: `node tests/screen-design.test.cjs`, syntax checks, and browser demo inspection.
Authenticated save, publication, and actual H.264 output require an authorised admin session;
these should not be represented as tested without one. Demo mode cannot save or publish.

## Motion and inspector extension — 22 October 2026

- Independent entrance, exit, delay, easing, distance, strength and cycle duration per text/image layer.
- Entrance styles: instant, fade, rise/drop, horizontal slides, depth zoom, directional reveals and focus.
- Continuous image styles: push/pull, horizontal/vertical drift, float, breathe, depth drift and gold halo.
- No new motion applies rotation. Explicit operator rotation remains available and all previous tools remain.
- Scene controls include separate image/scene strengths, gallery lighting, scene push/pan and text stagger.
- Ready-made Quiet Luxury / Elegant Reveal / Street Attraction / Floating Display / Static presets.
- Explicit newline-separated text can be split into independently editable layers; the original is hidden,
  retained, and recoverable through undo. Auto-wrapped lines can first be separated with Enter.
- Inspector navigation: Element, Content & Playback, Background, Scene, All Tools. Compact layer picker;
  advanced controls and layer management remain available in collapsible sections.
- The editor/exporter still share the same deterministic renderer. Motion functions are tested across
  every entrance/continuous-motion combination, including independent timing and still-preview bypass.
- Browser demo validation covered selecting presets, preview playback, tabs and multiline splitting.
  Authenticated save/publication and an actual MP4 encode remain unverified without an admin session.
