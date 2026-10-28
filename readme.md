# FRX Image Viewer Plugin for VB Decompiler and DE Decompiler

A native Delphi plugin for [**VB Decompiler**](https://www.vb-decompiler.org) and [**DE Decompiler**](https://www.de-decompiler.com) that previews and extracts embedded images, icons, and cursors registered by the host. It supports Visual Basic 5.0/6.0 and .NET graphics through VB Decompiler, and binary Delphi DFM graphics through DE Decompiler with DFM image registration.

## Overview

The viewer uses the shared plugin API of both products to locate original image bytes in the opened executable or DLL. It provides a thumbnail gallery, previews, and image export directly from the **Plugins** menu. With the optional host extensions, native Delphi ImageLists also appear as individual icons with their original masks and alpha transparency.

## Key Features

### 🖼️ Comprehensive Image Support
- **Multiple Format Detection**: Automatically identifies and loads BMP, PNG, JPEG, GIF, ICO, and CUR files
- **Icon & Cursor Handling**: Intelligently parses compound icon/cursor files and extracts the highest resolution variant
- **Smart Scaling**: Automatically upscales small icons (below 128px) for better visibility while preserving quality using HALFTONE interpolation

### 🎨 Modern UI Experience
- **Dark Mode Support**: Integrates with the shared VB Decompiler / DE Decompiler theme system
  - Automatically detects the active color scheme from decompiler settings
  - Applies consistent dark styling to all UI elements including window title bar, scrollbars, and controls
- **Live Preview**: Side-by-side thumbnail gallery and full-size preview panel
- **Responsive Layout**: Resizable splitter between gallery and preview with minimum window constraints

### 💾 Export Capabilities
- **Export Workflow**: Quick extraction of individual images with proper file extensions
- **Format Preservation**: Saves images in their original format (ICO, PNG, BMP, JPG, GIF, CUR)
- **Smart File Naming**: Auto-generates filenames based on image index and format

### 🔍 Technical Information Display
- **Detailed Metadata**: Shows dimensions, file size, byte offset, and format for each image
- **Error Handling**: Clear error messages for corrupted or unsupported image data

## Installation

1. Download the latest release of `FRXViewer.dll`
2. Copy the DLL to the `plugins` subdirectory of your VB Decompiler or DE Decompiler installation. Match the DLL architecture to the host application, not to the inspected file.
3. Restart the corresponding decompiler
4. The plugin will appear in the **Plugins** menu as "FRX Image Viewer"

## Usage

### Viewing FRX Resources

1. Open the executable or DLL in [**VB Decompiler**](https://www.vb-decompiler.org) for VB/.NET, or [**DE Decompiler**](https://www.de-decompiler.com) for Delphi. Decode its forms so that the host registers their images.
2. Navigate to **Plugins → FRX Image Viewer** in the main menu
3. The plugin window will display the original images registered by the host.

### Interface Layout

```
┌─────────────────────────────────────────────┐
│ FRX Image Viewer                            │
├──────────┬──────────────────────────────────┤
│          │                                  │
│ Thumbnail│            Preview Panel         │
│ Gallery  │          (Full-size image)       │
│ (64x64)  │                                  │
│          │                                  │
├──────────┴──────────────────────────────────┤
│                              [Save to File] │
├─────────────────────────────────────────────┤
│ Status: Image 5: 32x32px | Size: 1.2KB ...  │
└─────────────────────────────────────────────┘
```

### Extracting Images

1. Click on any thumbnail in the left panel to preview it
2. Click the **"Save to File"** button at the bottom
3. Choose the destination folder and filename
4. Standalone pictures retain their original bytes and format. Individual ImageList icons are exported as ICO files with transparency.

## Technical Details

### Supported Image Formats

| Format | Extension |             Description            |
|--------|-----------|------------------------------------|
| Bitmap |  `.bmp`  | Windows Device Independent Bitmap   |
| PNG    |  `.png`  | Portable Network Graphics           |
| JPEG   |  `.jpg`  | Joint Photographic Experts Group    |
| GIF    |  `.gif`  | Graphics Interchange Format         |
| Icon   |  `.ico`  | Windows Icon (single or compound)   |
| Cursor |  `.cur`  | Windows Cursor (single or compound) |

### Image Processing Features

- **HALFTONE Scaling**: Uses high-quality bi-cubic interpolation for smooth upscaling
- **Aspect Ratio Preservation**: Maintains original proportions in all scaling operations
- **Transparent Background Support**: Correctly renders 32-bit alpha channel in PNG and ICO files
- **Compound Icon Parsing**: Extracts the largest resolution from multi-resolution icon files

### Dark Mode Implementation

The plugin implements a manual dark theme without relying on VCL Styles to ensure stability in DLL context:

- Reads the active color scheme from the registry settings shared by VB Decompiler and DE Decompiler
- Parses theme configuration from `.ini` files
- Applies custom colors to all UI elements
- Uses Windows DWM API for native dark title bar (Windows 10 1809+)
- Applies `DarkMode_Explorer` theme to native controls for consistent dark scrollbars

## System Requirements

- **VB Decompiler**: Version 5.0 or higher for the original image API
- **DE Decompiler**: A build with binary DFM image registration; individual ImageList icons require optional command 63
- **Optional SDK extensions**: Commands 63 and 64 are described in [SDK_ADDITIONS_26_6.md](SDK_ADDITIONS_26_6.md); older hosts retain the original whole-image behavior
- **Operating System**: Windows 10/11
- **Architecture**: x86 and x86-64; the plugin must match the host

## Development

### Building from Source

**Requirements:**
- Embarcadero Delphi
- The shared VB Decompiler / DE Decompiler Plugin SDK included in this repository

**Build Steps:**
1. Clone the repository
2. Open `FRXViewer.dpr` in Delphi
3. Ensure `PluginSDK.pas` and `modFrxImageList.pas` are in the project directory
4. Compile as a 32-bit or 64-bit DLL matching your VB Decompiler or DE Decompiler host
5. Output: `FRXViewer.dll`

### Project Structure

```
FRXViewer/
├── FRXViewer.dpr # Main DLL entry point
├── fmMain.pas # Main form implementation
├── fmMain.dfm # Form visual designer file
├── PluginSDK.pas # Shared VB Decompiler / DE Decompiler SDK interface
├── modFrxImageList.pas # Native Delphi ImageList decoding
├── SDK_ADDITIONS_26_6.md # Optional host commands and compatibility
├── DotFix_Software_Plugin_License.txt # License
└── README.md # This file
```

### Plugin SDK Integration

The plugin uses the standard interface shared by VB Decompiler and DE Decompiler.
The historical `VBDecompiler...` export names and `GetVBDecompilerPath` SDK name
remain unchanged for binary compatibility with existing hosts:

```delphi
// Exported functions
VBDecompilerPluginName   // Returns plugin name
VBDecompilerPluginAuthor // Returns author information
VBDecompilerPluginLoad   // Main plugin entry point

// SDK Functions Used
GetFileName              // Retrieves currently opened file path
GetVBDecompilerPath      // Gets decompiler installation directory
GetFrxIconCount          // Returns number of FRX resources
GetFrxIconOffset         // Gets byte offset for specific resource
GetFrxIconSize           // Gets size in bytes for specific resource
GetFrxImageListInfo      // Optional: native ImageList metadata (command 63)
GetProductName          // Optional: loaded product name (command 64)
```

## Troubleshooting

### Plugin doesn't appear in menu

- Verify DLL is in the correct plugins directory

- Check compatibility with your VB Decompiler or DE Decompiler build

- Ensure DLL architecture matches the host application (32-bit vs 64-bit)

### Images not loading

- Confirm the opened file contains form images supported and registered by its host

- Check that the file and its forms have been decoded successfully in VB Decompiler or DE Decompiler

- Verify file isn't locked by another process

### Dark mode not working

- Dark mode requires Windows 10 version 1809 or newer

- Check that the active decompiler theme is configured correctly

- Verify the theme INI files exist in the host installation's `colors` directory

### Known Limitations

- StatusBar panel borders remain light gray in dark mode (Windows control limitation)

- Very large images may experience performance delays

- Animated GIFs display only the first frame

## Changelog

Version 1.2.0 (2026-10-28)

- Compatibility with latest VB Decompiler and DE Decompiler through the shared SDK
- Individual Delphi ImageList icons with native masks and alpha transparency
- Optional product-name detection with fallback for older hosts
- Headers and documentation link to both supported products

Version 1.1.0 (2026-06-16)

- Fix for plugin loading if the previous opening was on a file without images.

Version 1.0.0 (2026-02-13)

Initial release

- Full FRX resource detection and extraction
- Dark mode support with automatic theme detection
- High-quality image scaling with HALFTONE interpolation
- Compound icon/cursor parsing
- Support for BMP, PNG, JPEG, GIF, ICO, CUR formats

## License

This project is licensed under the MIT License - see the [LICENSE](DotFix_Software_Plugin_License.txt) file for details.

### Attribution Requirement

If you modify or redistribute this plugin, you MUST:
1. Keep the original copyright notice in all source files
2. Credit the original author (Sergey Chubchenko / DotFix Software) in your 
   documentation, about form and any modified versions
3. Include a link to the DotFix Software website: https://www.dotfixsoft.com
4. Include a link to the original repository: https://github.com/DotFixSoft/frxviewer

## Author

Sergey Chubchenko (DotFix Software)
GitHub: https://github.com/DotFixSoft

Products: [VB Decompiler](https://www.vb-decompiler.org) and [DE Decompiler](https://www.de-decompiler.com)


⭐ If you find this plugin useful, please consider starring the repository!



## Optional host extensions (26.6)

The updated viewer can split native Delphi DFM ImageLists into individual gallery
icons, preview each icon, and export it as an ICO with transparency. The host
continues to return original image offsets through commands 60–62. Optional
command 63 supplies cell dimensions, count and mask information; the plugin
validates the source and decodes each native list using Windows common controls.
Independent PNG/ICO/BMP collection pictures remain ordinary image entries.

On older hosts, missing metadata keeps the original whole-picture behavior.
Optional command 64 supplies the loaded VB/DE Decompiler product name for error
messages; SDK export names and the shared theme registry path remain unchanged.

See [SDK_ADDITIONS_26_6.md](SDK_ADDITIONS_26_6.md) for command parameters, response
formats, offset adjustments and Delphi examples. No managed runtime or components
from the inspected executable are loaded. The inspected file is never executed.
