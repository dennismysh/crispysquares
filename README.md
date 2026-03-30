# CrispySquares

A macOS menu bar utility that improves display rendering quality on 1080p and non-Retina screens.

macOS removed subpixel antialiasing in Mojave and the rendering code entirely in Catalina, leaving non-Retina users with thin, blurry text. CrispySquares gives you the tools that actually work on modern macOS to make your display look better.

## Features

### Font Smoothing
- Global `AppleFontSmoothing` control (off / light / medium / strong)
- Per-app overrides for individual applications
- Side-by-side preview at multiple font sizes

### Gamma & Color
- Interactive Bezier curve editor for reshaping display gamma
- Sliders for gamma, contrast boost, black point, and white point
- Live display preview — changes apply to your actual screen as you drag
- Built-in presets: Bold Text, High Contrast, Warm Reading, sRGB Standard
- Save and load custom presets
- 15-second safety timeout after applying (auto-reverts if not confirmed)

### ICC Profiles
- Create ICC profiles from your current gamma settings
- Import and export `.icc` files
- Assign profiles to specific displays
- Restore display defaults with one click

### System Integration
- Menu bar app — runs silently in the background
- Launch at login
- Re-applies gamma settings after sleep/wake
- Global reset shortcut (Cmd+Shift+Escape)

## Requirements

- macOS 13.0 (Ventura) or later
- Non-sandboxed (required for display APIs)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) for building

## Building

```bash
# Install xcodegen if you don't have it
brew install xcodegen

# Generate Xcode project and build
xcodegen generate
xcodebuild build -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build

# Run the app
open .build/Build/Products/Debug/CrispySquares.app
```

## Running Tests

```bash
xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build
```

## How It Works

CrispySquares uses three techniques that actually improve rendering on modern macOS:

1. **Font smoothing controls** — the `AppleFontSmoothing` defaults key still has a residual effect (mainly off vs on) on macOS 14+. CrispySquares exposes this with per-app granularity.

2. **Gamma table manipulation** — `CGSetDisplayTransferByTable` lets you reshape the display's transfer function in real-time. Steepening the midtone region makes text appear bolder and crisper. CrispySquares provides an interactive curve editor for this.

3. **ICC profile persistence** — raw gamma tables get reset on sleep/wake. CrispySquares bakes your gamma curve into an ICC profile saved to `~/Library/ColorSync/Profiles/` so your settings survive.

## Roadmap

- **v2: HiDPI Virtual Display** — create a virtual display at 2x resolution using `CGVirtualDisplay` (macOS 14+), mirror the physical display to it, and get Retina-quality rendering downscaled to your 1080p panel. This is the single most impactful technique (similar to BetterDisplay) and the architecture is already prepared for it.

## Project Structure

```
Sources/CrispySquares/
├── CrispySquaresApp.swift          # Menu bar app entry point
├── Models/                         # Data types
│   ├── GammaCurve.swift            # Bezier curve math + gamma table generation
│   ├── Preset.swift                # Built-in and custom presets
│   ├── DisplayInfo.swift           # Display metadata
│   └── AppConfig.swift             # Persistence types
├── Services/                       # Core logic
│   ├── DisplayManager.swift        # Display enumeration + change events
│   ├── GammaEngine.swift           # Gamma tables, ICC profiles, live preview
│   ├── ConfigStore.swift           # JSON persistence
│   └── FontSmoothingService.swift  # AppleFontSmoothing defaults
└── Views/                          # SwiftUI interface
    ├── SettingsWindow.swift         # Main settings window
    ├── FontSmoothingView.swift      # Font smoothing module
    ├── GammaColorView.swift         # Gamma & color module
    ├── CurveEditorNSView.swift      # Core Graphics curve editor
    ├── ICCProfilesView.swift        # ICC profile management
    └── ...
```

## License

MIT
