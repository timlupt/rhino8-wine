# Wine MR kit — uxtheme immersive-color-set exports

Everything needed to open the merge request on `gitlab.winehq.org/wine/wine`.
The change itself is in **`uxtheme-immersive-color.patch`** (applies cleanly to
current master; verified).

## Files changed
- `dlls/uxtheme/uxtheme.spec` — add ordinals 95, 96, 98, 100
- `dlls/uxtheme/system.c` — implementations (one semi-stub + three stubs)
- `dlls/uxtheme/tests/system.c` — `test_GetImmersiveColors` conformance test

(Ordinal 94 / `GetImmersiveColorSetCount` was deliberately left out — Wine's
rule is "don't add a function unless some app calls it," and Rhino only uses
95/96/98/100.)

## Apply it on your fork
```bash
# in your up-to-date wine master checkout (your gitlab fork)
git checkout -b uxtheme-immersive-colors
git apply /path/to/uxtheme-immersive-color.patch
git config user.name "Your Real Name"    # must match your GitLab profile exactly
git config user.email "you@example.com"
git add dlls/uxtheme/uxtheme.spec dlls/uxtheme/system.c dlls/uxtheme/tests/system.c
git commit -s        # -s adds your Signed-off-by; paste the message below
git pull --rebase origin master          # ensure it's on current master
git push origin uxtheme-immersive-colors:uxtheme-immersive-colors
# then open the MR in the GitLab UI and paste the description below
```

## Commit message (Wine format — paste into `git commit`)
```
uxtheme: Add immersive color set exports.

These undocumented exports back the OS dark-mode probe used by .NET
applications. uxtheme already exports the dark-mode toggle group
(ordinals 132-138); add the immersive-color-set family in the same
style:

  95  GetImmersiveColorFromColorSetEx
  96  GetImmersiveColorTypeFromName
  98  GetImmersiveUserColorSetPreference
  100 GetImmersiveColorNamedTypeByIndex

Rhinoceros 8/9 resolves GetImmersiveColorFromColorSetEx and
GetImmersiveUserColorSetPreference by name, plus ordinals 96 and 100,
and requires all of them to be present. When they are missing it falls
back to a managed callback that re-enters the probe, recursing until
the stack overflows on launch.

Make GetImmersiveColorFromColorSetEx follow AppsUseLightTheme so callers
that inspect a foreground colour get a result consistent with the active
theme; the others are stubs pending the full colour tables.
```
- First line: `component: imperative sentence.` ≤72 chars, ends with a period
  (it becomes a release-note line). Body wrapped at 72, imperative mood.
- **You are the sole author — no co-author trailer.** (Wine keeps the submitter
  as author.)
- Optional: add a `Wine-Bug: https://bugs.winehq.org/show_bug.cgi?id=NNNN` line
  if you file/find a relevant Bugzilla entry (not required).

## MR description (paste into GitLab)
> **uxtheme: add the immersive-color-set exports (ord 95/96/98/100)**
>
> Wine's `uxtheme` exports the dark-mode *toggle* group (ordinals
> 104/132/133/135/136/137/138) but not the immersive-*color-set* family. On
> master (11.11), `git grep` finds no reference to
> `GetImmersiveColorFromColorSetEx`, `GetImmersiveColorTypeFromName`,
> `GetImmersiveUserColorSetPreference`, or `GetImmersiveColorNamedTypeByIndex`
> anywhere in the tree.
>
> **Why it matters:** Rhinoceros 8/9 (.NET 8/10) probes OS dark mode via
> `RhinoCore.dll!RhOSInDarkMode`, which `LoadLibrary`s `uxtheme` and resolves
> these (95 and 98 by name; 96 and 100 by ordinal). It requires all four
> non-NULL; when any is missing it falls back to a managed callback that
> re-enters the probe — an unbounded native↔managed recursion that overflows
> the stack before the main window appears. Adding the exports lets the probe
> complete normally. (Verified: with these exports, Rhino 8 installs and
> launches under Wine with no other workarounds.)
>
> `GetImmersiveColorFromColorSetEx` follows `AppsUseLightTheme` (mirroring the
> existing `ShouldAppsUseDarkMode`), so apps that read a foreground colour
> honour the user's light/dark setting. The other three are `FIXME` stubs
> pending the full colour tables, consistent with the existing dark-mode stubs.
> A conformance test exercises all four.
>
> Signatures derived from reverse-engineering references (these are undocumented
> by Microsoft).

## RE sources for the signatures
- https://www.quppa.net/blog/2013/01/02/retrieving-windows-8-theme-colours/
- https://gist.github.com/smourier/d9de36c49e19aa9923d5143965057405  (ordinal 100)
- https://github.com/pbatard/list-immersive-colors
- https://github.com/MahdiSafsafi/ImmersiveColors

## Pre-submit checklist (from Wine's Submitting-Patches guide)
- [ ] `git config user.name` is your **real name**, matching your GitLab profile exactly.
- [ ] Clean-room: you have **not** studied leaked/Microsoft Windows source (our
      signatures came only from the public RE references above).
- [ ] `git pull --rebase` onto current master right before pushing.
- [ ] Builds with no new compiler warnings (`-Werror`).
- [ ] `make -C dlls/uxtheme/tests test` passes (our `test_GetImmersiveColors` runs).
- [ ] Committed with `git commit -s` (Signed-off-by present).

## Likely review discussion (be ready, not blocking)
- **Undocumented APIs:** maintainers are cautious; the justification (a major
  commercial app fails to launch) + the existing dark-mode-stub precedent are the
  case. Be flexible if they want changes.
- **Theme-aware `GetImmersiveColorFromColorSetEx`:** "simplest code possible"
  might prompt "just stub it." Defensible (Rhino calls it; it's barely more code
  and actually correct) — but be ready to fall back to a plain stub if asked.
- **Test in the same commit:** the guide prefers tests in a separate, earlier
  commit with `todo_wine`. Our test `win_skip`s when the exports are absent (it
  doesn't *fail*), so `todo_wine` doesn't apply, and adding exports is a new
  feature (for which test-first "is not really necessary"). Same-commit is
  defensible; split if a reviewer prefers.
- **Updating after review:** amend/rebase the existing commit and **force-push**
  the branch — don't stack a fixup commit on top.
