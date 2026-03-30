# CrispySquares — Design Spec

A macOS menu bar utility that improves display rendering quality on 1080p/non-Retina screens through font smoothing controls, gamma curve editing, and ICC profile management.

## Overview

### Problem

macOS looks bad on 1080p displays. Apple removed subpixel antialiasing in Mojave (and the rendering code entirely in Catalina), leaving non-Retina users with thin, blurry text. The remaining `AppleFontSmoothing` defaults key has minimal effect on macOS 14+. No existing open-source tool provides a good UI for the display adjustments that actually help.

### Solution

CrispySquares is an interactive control panel with live preview that bundles the three techniques that actually work on modern macOS:

1. **Font smoothing controls** — expose the remaining `AppleFontSmoothing` settings with per-app overrides
2. **Gamma curve editor** — interactive Bezier curve editor for reshaping gamma to make text bolder/crisper
3. **ICC profile management** — bake gamma curves into ICC profiles for persistence across sleep/wake

A future v2 adds HiDPI virtual display scaling (the most impactful technique, but also the most complex).

### Non-Goals

- **Full-display post-processing** (sharpening filters on screen content) — not viable due to compositing feedback loops and input latency
- **Subpixel antialiasing restoration** — the rendering code was removed from macOS in Catalina; no API or defaults key brings it back
- **App Store distribution** — all useful display APIs require a non-sandboxed app
- **Custom text rasterization** (FreeType/HarfBuzz) — out of scope; this is a system-level tool, not a text renderer

### Target Audience

macOS users with external 1080p/non-Retina displays who want sharper, bolder text and better overall rendering quality. Distributed as an open-source GitHub project.

## Technology

- **Language:** Swift
- **UI Framework:** SwiftUI with AppKit bridging where needed (menu bar, gamma table APIs)
- **Minimum macOS:** 13.0 (Ventura) for `SMAppService` login item API and `MenuBarExtra`
- **Build:** Xcode project, no SPM dependencies for v1 (all APIs are system frameworks)
- **Distribution:** GitHub releases, notarized `.dmg`. Non-sandboxed (required for display APIs).

## Architecture

### App Structure

Menu bar utility (`MenuBarExtra`) with a settings window.

- **Menu bar icon** — click to open/close the settings window. Right-click or long-press for quick actions (Reset All, Quit).
- **Settings window** — `NavigationSplitView` with sidebar navigation. System Settings visual style.
  - Sidebar items: Font Smoothing, Gamma & Color, ICC Profiles, HiDPI Scaling (greyed, v2)
  - Detail area: module-specific controls
  - Preview pane: always-visible right panel showing sample text rendered with current settings

### Key Services

#### DisplayManager

Shared service that enumerates connected displays and notifies modules on changes.

- Uses `CGGetActiveDisplayList` to enumerate displays
- Registers `CGDisplayReconfigurationCallBack` for plug/unplug events
- Listens for `NSWorkspace.didWakeNotification` for sleep/wake
- Publishes display list as `@Published` property for SwiftUI binding
- Each module receives the currently selected display and operates on it
- v2 extension point: `DisplayManager` will also manage virtual displays

#### GammaEngine

Manages gamma table reads/writes and ICC profile generation.

- Reads current gamma via `CGGetDisplayTransferByTable`
- Writes gamma for live preview via `CGSetDisplayTransferByTable`
- Generates ICC profiles from Bezier curves using `ColorSyncProfileCreate` with custom TRC data
- Installs profiles via `ColorSyncDeviceSetCustomProfiles`
- Re-applies on wake/reconfiguration events
- Provides `CGDisplayRestoreColorSyncSettings()` for reset

#### ConfigStore

Persistence layer using `Codable` + JSON.

- App config: `~/Library/Application Support/CrispySquares/config.json`
- ICC profiles: `~/Library/ColorSync/Profiles/CrispySquares-*.icc`
- Stores: per-display gamma curve control points, per-app font smoothing overrides, profile assignments, window state

## Module Specs

### 1. Font Smoothing

**Purpose:** Expose the remaining font smoothing controls with a good UI and live preview.

**Controls:**
- Global `AppleFontSmoothing` toggle: off (0) vs light (1) / medium (2) / strong (3)
  - Written via `UserDefaults.standard` for the global domain
  - Requires logout to take full system-wide effect; preview pane shows immediate difference
- Per-app overrides: table of apps with individual smoothing values
  - App picker populated from `/Applications` (bundle ID + display name)
  - Written via `defaults write <bundle-id> AppleFontSmoothing -int <n>`
  - App must be relaunched for the override to take effect

**Preview pane:**
- Side-by-side before/after rendering of sample text
- "Before" uses current system settings; "After" renders with chosen smoothing level
- Renders using `NSTextField` in a `NSHostingView` with `CGContextSetShouldSmoothFonts` applied to the backing layer's context
- Sample text at 10pt, 12pt, 14pt, 18pt — paragraph text, code snippet, UI labels

**Caveat banner:** "Font smoothing has limited effect on macOS 14+. For the most impactful improvement, use the Gamma & Color module."

### 2. Gamma & Color

**Purpose:** Interactive gamma curve editing with live display preview. The highest-impact v1 feature.

**Curve editor:**
- Photoshop-style Bezier curve visualization (input signal on X, output brightness on Y)
- Draggable control points — user reshapes the curve by dragging
- Linear reference line (dashed diagonal) shown for comparison
- Per-channel editing: "All" (linked R/G/B), or individual R, G, B curves
- Curve rendered in an `NSView` subclass using Core Graphics drawing (SwiftUI `Canvas` may not be precise enough for curve interaction)

**Simplified controls (alongside curve):**
- **Gamma** slider/input — single value (default 2.2), modifies curve shape parametrically. Lower gamma (e.g. 1.8) = bolder text.
- **Contrast boost** — percentage slider that applies an S-curve to the midtone region
- **Black point** — minimum output value (default 0.0)
- **White point** — maximum output value (default 1.0)
- Sliders modify the curve in real-time; curve visualization updates instantly

**Presets:**
- Built-in: "Bold Text" (gamma 1.8), "High Contrast" (S-curve), "Warm Reading" (slight warm shift + gamma 1.9), "sRGB Standard" (gamma 2.2 reset)
- User-defined: save current curve as a named preset
- Presets stored in `config.json`

**Live preview flow:**
1. User drags curve or adjusts slider
2. `GammaEngine` calls `CGSetDisplayTransferByTable` with the new curve — display updates instantly
3. User sees the effect on their actual screen content in real-time
4. When satisfied, user clicks "Apply"
5. `GammaEngine` bakes the curve into an ICC profile and installs it via `ColorSyncDeviceSetCustomProfiles`
6. The ICC profile persists across sleep/wake cycles

**Safety:**
- "Keep these settings?" confirmation dialog with 15-second countdown after applying
- If user doesn't confirm, auto-revert via `CGDisplayRestoreColorSyncSettings()`
- Global keyboard shortcut (Cmd+Shift+Escape) to reset all displays immediately

### 3. ICC Profiles

**Purpose:** Management UI for ICC profiles created by the Gamma module.

**Profile list:**
- Shows profiles in `~/Library/ColorSync/Profiles/` prefixed with "CrispySquares-"
- Each entry shows: profile name, which display it's assigned to (if any), creation date
- Active profile highlighted

**Actions:**
- **Create from current gamma** — snapshots the gamma curve editor state into a named `.icc` file
- **Import** — file picker for external `.icc` files, copies to the profiles directory with the app prefix
- **Export** — saves a selected profile to a user-chosen location for sharing
- **Assign to display** — dropdown of connected displays (from `DisplayManager`), assigns via `ColorSyncDeviceSetCustomProfiles`
- **Delete** — removes the `.icc` file and unassigns from any display
- **Restore defaults** — resets selected display to factory profile via `CGDisplayRestoreColorSyncSettings()`

### 4. HiDPI Scaling (v2 — Not Implemented)

**v1 artifact:** Greyed-out sidebar item with "Coming Soon" label.

**v2 scope (documented for architectural planning):**
- Create virtual display at 2x resolution using `CGVirtualDisplay` (macOS 14+ public API)
- Mirror physical display to virtual display
- macOS renders at Retina quality, compositor downscales to native resolution
- UI: display picker, resolution selector, enable/disable toggle, status indicator
- Requires macOS 14+ (Sonoma)

**v1 architectural preparation:**
- `DisplayManager` service designed from the start to accommodate virtual displays
- Settings window sidebar structure supports adding new modules

## System Integration

### Launch at Login

- Register via `SMAppService.loginItem(identifier:)` (macOS 13+)
- On launch, `GammaEngine` reads saved config and re-applies ICC profiles to each display
- App starts in background (menu bar only), no window shown on login

### Wake/Sleep Handling

- `NSWorkspace.didWakeNotification` — re-apply gamma tables immediately, verify ICC profiles are still assigned
- `CGDisplayReconfigurationCallBack` — update `DisplayManager` display list, re-apply profiles to any recognized displays
- Handle Night Shift / True Tone interactions — these reset gamma tables; re-apply after a short delay (500ms debounce)

### Safety Reset

- **Global shortcut:** `Cmd+Shift+Escape` to reset all displays via `CGDisplayRestoreColorSyncSettings()`
- **Timeout guard:** 15-second countdown dialog after applying new gamma settings; auto-revert if unconfirmed
- **Menu bar "Reset All":** always accessible, bypasses the settings window

### Config Storage

| Data | Location |
|------|----------|
| App settings | `~/Library/Application Support/CrispySquares/config.json` |
| ICC profiles | `~/Library/ColorSync/Profiles/CrispySquares-*.icc` |
| Login item | Managed by `SMAppService` |

Config uses `Codable` with `JSONEncoder`/`JSONDecoder`. New fields use default values for forward compatibility.

## Versioning Plan

### v1 (This Spec)
- Font Smoothing module
- Gamma & Color module with curve editor and live preview
- ICC Profile management
- Menu bar utility with settings window
- Launch at login, wake/sleep handling, safety reset
- macOS 13+ (Ventura)

### v2 (Future)
- HiDPI virtual display scaling via `CGVirtualDisplay`
- Requires macOS 14+ (Sonoma) for the public API
- Extends `DisplayManager` with virtual display lifecycle management

## Open Questions

None — all design decisions have been validated during brainstorming.
