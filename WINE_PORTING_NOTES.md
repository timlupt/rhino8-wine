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

> **Note:** An earlier version of this patch also reserved 512 MB for native 64-bit stacks. Testing confirmed this is not required — Rhino launches and runs correctly with default stack sizes. The 512 MB reservation has been removed.

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
