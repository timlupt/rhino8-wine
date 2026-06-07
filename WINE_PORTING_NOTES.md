# Rhino 8 on Linux via Wine — Porting Notes

Detailed writeup of every problem encountered getting Rhinoceros 8 running under Wine 11.9. For setup instructions see [README.md](README.md).

---

## What Was Changed and Why

### Problem 1: Immediate Crash — Stack Overflow

**Symptom:** Rhino crashed on startup before showing any UI. Wine logged a STATUS_STACK_OVERFLOW exception.

**Root cause:** .NET 8's CLR uses WoW64 (32-bit subsystem) for some initialization. Wine's default WoW64 thread stacks are 1 MB, which is insufficient for the .NET 8 CLR bootstrap call depth on Wine. The overflow occurs in a 32-bit thread before Rhino's main window appears.

**Fix — Raise WoW64 32-bit stack minimum to 8 MB** (`dlls/ntdll/unix/thread.c` → `init_thread_stack`):

```c
if (reserve_size < 8 * 1024 * 1024) reserve_size = 8 * 1024 * 1024;
```

This applies only to the WoW64 (32-bit) stack path and does not affect native 64-bit threads.

**Defensive fix — Clamp VirtualQuery AllocationBase** (`dlls/ntdll/unix/virtual.c` → `fill_basic_memory_info`):

.NET also reads stack size via `VirtualQuery`/`NtQueryVirtualMemory` to calibrate its maximum recursion depth. If Wine reports a stack larger than Windows' typical 1 MB, .NET calibrates aggressively and can overflow. Clamping `AllocationBase` to `StackBase − 1 MB` makes `VirtualQuery` report a 1 MB window regardless of actual reserved size:

```c
char *clamped = (char *)teb->Tib.StackBase - (1 * 1024 * 1024);
if (clamped > (char *)teb->DeallocationStack &&
    (char *)info->AllocationBase <= (char *)teb->DeallocationStack + host_page_size)
    info->AllocationBase = clamped;
```

This is a no-op for standard 1 MB stacks (where `clamped == DeallocationStack`) but protects against PE headers that request larger stacks.

> **A red herring — the opaque `virtual_setup_exception` crash:** While chasing this, a *different*-looking crash sometimes appeared instead of a clean `STATUS_STACK_OVERFLOW`:
>
> ```
> err:virtual:virtual_setup_exception stack overflow 4672 bytes addr 0x6ffffff85ebe stack 0x7ffffe0ffdc0 (0x7ffffe100000-0x7ffffe101000-0x7ffffe200000)
> ```
>
> This is *not* a normal overflow delivery — it's Wine's own signal handler double-faulting while trying to build the exception frame, because whatever was overflowing blew straight through the guard page *and* the small "guaranteed region" beneath it (just one host page, ~4 KB) before Wine could catch it. The result is an opaque internal abort with no managed stack trace — which looks exactly like "the stack is too small."
>
> It wasn't. The actual cause of *that* overflow was the dark-mode mutual-recursion bug described in Problem 2 below — hundreds of thousands of frames deep, recursing fast enough to blow through everything before an exception frame could be set up. We initially chased it as a stack-*sizing* problem: forcing native 64-bit stacks to reserve 512 MB and moving the guard page to `+64 KB` (instead of the default ~4 KB) didn't fix anything by itself, but it gave the runaway recursion enough room that the resulting `STATUS_STACK_OVERFLOW` could finally be delivered *cleanly* — complete with a full managed stack trace pointing straight at `Rhino.Runtime.AdvancedSettings.get_DarkMode()` ↔ `RHC_RhOSInDarkMode`. That trace is what led to the real fix in Problem 2.
>
> Once the recursion itself is eliminated by the binary patch in Problem 2, there's nothing left to overflow any stack — Wine's normal default native stack size is sufficient, and no 512 MB reservation or guard-page repositioning is needed. (Confirmed on Arch: with only the WoW64 8 MB fix above plus the DLL patch from Problem 2 — and none of the 512 MB/guard-page changes — Rhino launches cleanly.)
>
> If you ever see `virtual_setup_exception stack overflow ... bytes` rather than a clean, managed `STATUS_STACK_OVERFLOW` with a stack trace, treat it as a symptom of runaway recursion *somewhere upstream* rather than a sign that stacks need to be bigger — the fix is to find and stop the recursion, not to give it more room to run in.

---

### Problem 2: Dark Mode Mutual Recursion — 254,955 Frames Deep

**Symptom:** Rhino crashed with a stack trace showing Rhino's own code: `Rhino.Runtime.AdvancedSettings.get_DarkMode()` (C#) calling P/Invoke to `RHC_RhOSInDarkMode` in `rhcommon_c.dll`, which called back into .NET managed code, which called `get_DarkMode()` again. 254,955 frames deep.

**Root cause:** On Windows, `RHC_RhOSInDarkMode` detects the dark mode setting via Windows APIs that don't exist on Wine. Wine's stub returns something that caused the function to re-invoke the managed callback instead of returning a result.

**Fix:** Binary-patched `rhcommon_c.dll`. The export `RHC_RhOSInDarkMode` at file offset `0xdff50` (RVA `0xe0b50`) was a JMP thunk:

```
before: 48 ff 25 19 8d 08 00 cc   (JMP [rip+...])
after:  31 c0 c3 90 90 90 90 cc   (xor eax,eax; ret; nop*4)
```

Always returns 0 (light mode), breaking the recursion. Back up the DLL before patching.

---

### Problem 3: No X11 Display

**Symptom:** Rhino exited silently with "no driver could be loaded."

**Root cause:** The `DISPLAY` environment variable wasn't set.

**Fix:** Added `DISPLAY="${DISPLAY:-:0}"` to the launch script.

---

### Problem 4: Licensing — Port 1717 Never Bound

**Symptom:** The OAuth login flow opened Firefox. After logging in to McNeel's servers, Firefox redirected to `http://127.0.0.1:1717/` to deliver the auth token — and got "Firefox can't connect to the server."

**Investigation:** Enabled `WINEDEBUG=+http` and confirmed Rhino was correctly calling `HttpAddUrlToUrlGroup` with `http://127.0.0.1:1717/`. Wine has a real implementation of the Windows HTTP Server API: `httpapi.dll` → `IOCTL_HTTP_ADD_URL` → `http.sys` kernel driver in `winedevice.exe`. Added instrumentation to Wine's `http_add_url` confirming the ioctl reached the driver and `bind()`/`listen()` was being attempted — but the socket never appeared.

**Root cause:** Stale `http.sys` state. Between Rhino restarts, only Rhino was being killed while the wineserver (and the `winedevice.exe` running `http.sys`) stayed alive. The old `http.sys` retained state from the previous run that interfered with the new run's port binding.

**Fix:** Kill the wineserver completely before launching (`wineserver -k`). This terminates the old `http.sys` winedevice. When Rhino launches fresh, a new `http.sys` starts with clean state, port 1717 binds, and the OAuth callback completes. The `--fresh` flag in `run-rhino.sh` does this automatically.

---

## Summary of Source Changes

| File | Change |
|------|--------|
| `dlls/ntdll/unix/thread.c` | Raise WoW64 32-bit stack minimum to 8 MB for .NET 8 CLR bootstrap |
| `dlls/ntdll/unix/virtual.c` | Clamp VirtualQuery AllocationBase to report at most 1 MB of stack |
| `dlls/wintrust/wintrust_main.c` | Override Authenticode result to S_OK (Wine lacks MS CA root store needed to verify Microsoft signatures) |

All changes are in `rhino8-wine.patch`.
