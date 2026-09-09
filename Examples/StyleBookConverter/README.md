# StyleBookConverter

One-shot tool that rewrites `.fmx` / `.dfm` files so every
`TStyleBook` component (with its hex-encoded `ResourcesBin` blocks)
becomes a `TZxStyleBook` with readable `StyleText = (...)` items.

## Building

```
build.bat
```

Requires a RAD Studio 23.0 installation. The script invokes `dcc64` via
`rsvars.bat` and produces `StyleBookConverter.exe` in this directory.

The converter registers a wide set of FMX/Skia/Zx units at startup so that
`TStyleStreaming.LoadFromStream` can resolve every style component class
referenced in the binary blobs it decodes. If a file contains style objects
from a unit not listed in `StyleBookConverter.dpr`'s `uses` clause, the tool
prints `[WARN] Class X not found` for that block and leaves it unconverted —
add the missing unit and rebuild.

## Usage

```
StyleBookConverter.exe [--dry-run] <file-or-glob> [<file-or-glob> ...]
```

Examples:

```
StyleBookConverter.exe --dry-run Z:\NEXTORE.App\Core\source\NXT.App.Styles.dfm
StyleBookConverter.exe C:\Work\repo\**\*.fmx
```

A run prints per-file progress and a final tally. `--dry-run` parses and
converts in memory but does not overwrite the source files.

## What it does

1. Reads the file as text.
2. Renames the class token `TStyleBook` to `TZxStyleBook` at component headers.
3. For each `ResourcesBin = { hex... }` block it finds:
   - Decodes the hex payload to bytes.
   - Feeds them through `TStyleStreaming.LoadFromStream` to reconstruct the
     `TStyleContainer` tree.
   - Re-emits via `TStyleStreaming.SaveToStream(..., TStyleFormat.Text)`.
   - Writes a DFM `StyleText = ( 'line1' 'line2' ... )` property in place.
4. Writes the result back (unless `--dry-run`).

The round trip is lossless: every byte of style state survives because the
tool hands the data straight through FMX's own binary↔text converters
(`ObjectTextToBinary` / `ObjectBinaryToText`).

## Benchmark observations

Converting `NXT.App.Styles.dfm` (two `TStyleBook` instances, ~1.5 MB):

| Aspect | Binary (before) | Text (after) |
|---|---|---|
| File size | 1 506 331 bytes | 1 655 052 bytes (+9.9%) |
| Decode time | — | < 0.5 s end-to-end |
| ResourcesBin blocks | 2 | 0 |
| StyleText blocks | 0 | 2 |
| Human-readable style diffs | no | yes |
| Embedded PNG data | hex | still hex (inside `TImage.MultiResBitmap`) |

The ~10% size increase is accounted for by quoting overhead (`'…'`),
per-line indentation, and the line-break encoding. The majority of the file
bytes are the PNG image payloads embedded inside `TImage.MultiResBitmap`
properties — those remain hex because that's how FMX serializes image
resources in both formats. The *style structure* becomes fully
diff-friendly; only image changes still show as opaque blobs, which is the
same behavior as any hand-authored FMX form with embedded images.

Put a `BENCHMARK.md` alongside this file once end-to-end timings (build
time, cold start, DFM load time) are collected per the plan.
