# Known Issues - Rhino 8 on Wine

## Summary

Rhino 8 works well on Wine with the patches in this repo. Most functionality works including:
- Main Rhino UI (MFC)
- 3D modeling and rendering  
- Grasshopper
- Layer panel and properties (WPF)
- Color picker dialogs (WPF)
- Toolbar actions
- MCP server integration
- Plugin installation via Yak

## Minor Issues

### Initial Wine Prefix Creation Warnings

When creating a new Wine prefix, you'll see harmless warnings:
```
err:ole:StdMarshalImpl_MarshalInterface Failed to create ifstub
err:setupapi:do_file_copyW Unsupported style(s) 0x10
```

**These are normal and can be ignored.** They don't affect Rhino functionality.

### Font Installation Warning

**Do NOT manually copy fonts to `C:\windows\Fonts`.** This causes Wine DirectWrite to deadlock during startup.

**Use the built-in font fix instead:**
- Registers system fonts via `Z:\` paths (Wine's Unix filesystem access)
- Enabled by default in `[fixes.fonts]` config
- Safe and doesn't cause deadlock

**Technical details:** Copying TTF files into the Wine prefix causes `dwrite_file:localfontfilestream` to hang while holding ntdll's `loader_section` critical section, deadlocking all threads.

## Getting Help

If you encounter issues:

1. **Check logs:**
   ```bash
   nix run .#run -- --debug          # Full debug mode
   nix run .#analyze-crash            # Analyze last crash
   ```

2. **Logs location:**
   - `~/.local/share/wineprefixes/rhino8/logs/`

3. **Report issues:**
   - GitHub: Issues with debug logs and reproduction steps
