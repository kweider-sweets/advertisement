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
