# Wine MR kit — uxtheme immersive-color-set exports

Everything needed to open the merge request on `gitlab.winehq.org/wine/wine`.
The change itself is in **`uxtheme-immersive-color.patch`** (applies cleanly to
current master; verified).

## Files changed
- `dlls/uxtheme/uxtheme.spec` — add ordinals 94, 95, 96, 98, 100
- `dlls/uxtheme/system.c` — implementations (semi-stubs)
- `dlls/uxtheme/tests/system.c` — `test_GetImmersiveColors` conformance test

## Apply it on your fork
```bash
# in your up-to-date wine master checkout (your gitlab fork)
git checkout -b uxtheme-immersive-colors
git apply /path/to/uxtheme-immersive-color.patch
git add dlls/uxtheme/uxtheme.spec dlls/uxtheme/system.c dlls/uxtheme/tests/system.c
git commit -s        # paste the commit message below; -s adds your Signed-off-by
git push <your-fork> uxtheme-immersive-colors
# then open the MR on gitlab.winehq.org and paste the description below
```

## Suggested commit message (Wine style)
```
uxtheme: Add immersive color set exports (ordinals 94-100).

These undocumented uxtheme exports back the OS dark-mode probe used by .NET
applications. uxtheme already exports the dark-mode toggle group (132-138);
this adds the immersive-color-set family in the same style:

  94  GetImmersiveColorSetCount
  95  GetImmersiveColorFromColorSetEx
  96  GetImmersiveColorTypeFromName
  98  GetImmersiveUserColorSetPreference
  100 GetImmersiveColorNamedTypeByIndex

Rhinoceros 8/9 resolves GetImmersiveColorFromColorSetEx and
GetImmersiveUserColorSetPreference by name, plus ordinals 96 and 100, and
requires all of them to be present. When they are missing it falls back to a
managed callback that re-enters the probe, recursing until the stack overflows
on launch.

GetImmersiveColorFromColorSetEx follows AppsUseLightTheme so callers that
inspect a foreground colour get a result consistent with the active theme; the
remaining functions are stubs pending the full immersive-colour tables.
```
(Signatures are sourced from reverse-engineering references — see below — as
these APIs are undocumented by Microsoft. Add a `Co-authored-by`/attribution
trailer only if you want; Wine doesn't require one.)

## MR description (paste into GitLab)
> **uxtheme: add the immersive-color-set exports (ord 94–100)**
>
> Wine's `uxtheme` exports the dark-mode *toggle* group (ordinals
> 104/132/133/135/136/137/138) but not the immersive-*color-set* family. On
> master, `git grep` finds no reference to `GetImmersiveColorFromColorSetEx`,
> `GetImmersiveColorTypeFromName`, `GetImmersiveUserColorSetPreference`, or
> `GetImmersiveColorNamedTypeByIndex` anywhere in the tree.
>
> **Why it matters:** Rhinoceros 8/9 (.NET 8/10) probes OS dark mode via
> `RhinoCore.dll!RhOSInDarkMode`, which `LoadLibrary("uxtheme")`s and resolves
> these four (95 and 98 by name; 96 and 100 by ordinal). It requires all four
> non-NULL; when any is missing it falls back to a managed callback that
> re-enters the probe — an unbounded native↔managed recursion that overflows
> the stack before the main window appears. Adding the exports lets the probe
> complete normally. (Verified: with these exports, Rhino 8 launches and the
> 32-bit installer runs without the stack workarounds previously needed.)
>
> `GetImmersiveColorFromColorSetEx` is implemented to follow
> `AppsUseLightTheme` (mirroring the existing `ShouldAppsUseDarkMode`), so apps
> that read a foreground colour honour the user's light/dark setting. The other
> three are `FIXME` stubs pending the full colour tables, consistent with the
> existing dark-mode stubs. A conformance test exercises all four.
>
> Signatures derived from reverse-engineering references (these are undocumented
> by Microsoft).

## RE sources for the signatures
- https://www.quppa.net/blog/2013/01/02/retrieving-windows-8-theme-colours/
- https://gist.github.com/smourier/d9de36c49e19aa9923d5143965057405  (ordinal 100)
- https://github.com/pbatard/list-immersive-colors
- https://github.com/MahdiSafsafi/ImmersiveColors

## Likely review points (be ready for these)
- **Undocumented APIs**: maintainers are cautious. Justification (a major
  commercial app fails to launch) + existing dark-mode-stub precedent are the
  case. They may ask for the colour to vary by `color_type`, or prefer a plainer
  stub — be flexible.
- **name vs `-noname`**: 95/98 are name-exported (apps resolve by name), 94/96/100
  by ordinal. If a reviewer has a real-Windows export dump showing different, defer.
- **Test assertions are loose** on purpose (values are theme/version dependent);
  the test proves the exports resolve and are callable on both Wine and Windows.
