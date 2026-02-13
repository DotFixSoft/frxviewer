# FRX Image Viewer Plugin for VB Decompiler

A native Delphi plugin for VB Decompiler that provides advanced viewing and extraction capabilities for embedded FRX resources (images, icons, and cursors) found in Visual Basic 5.0/6.0 applications.

## Overview

When decompiling Visual Basic 6 applications, FRX files contain valuable embedded resources such as form images, icons, buttons, and cursors. While VB Decompiler can detect these resources, extracting and viewing them traditionally requires manual hex editing or external tools. This plugin solves that problem by providing an integrated, user-friendly interface directly within VB Decompiler.

## Key Features

### 🖼️ Comprehensive Image Support
- **Multiple Format Detection**: Automatically identifies and loads BMP, PNG, JPEG, GIF, ICO, and CUR files
- **Icon & Cursor Handling**: Intelligently parses compound icon/cursor files and extracts the highest resolution variant
- **Smart Scaling**: Automatically upscales small icons (below 128px) for better visibility while preserving quality using HALFTONE interpolation

### 🎨 Modern UI Experience
- **Dark Mode Support**: Seamlessly integrates with VB Decompiler's theme system
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
2. Copy the DLL to VB Decompiler's plugins directory:

C:\Program Files (x86)\VB Decompiler\plugins\

3. Restart VB Decompiler
4. The plugin will appear in the **Plugins** menu as "FRX Image Viewer"

## Usage

### Viewing FRX Resources

1. Open a Visual Basic 6 compiled executable (.exe) in VB Decompiler
2. Navigate to **Plugins → FRX Image Viewer** in the main menu
3. The plugin window will open, automatically scanning for embedded FRX resources

### Interface Layout

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


### Extracting Images

1. Click on any thumbnail in the left panel to preview it
2. Click the **"Save to File"** button at the bottom
3. Choose the destination folder and filename
4. The image will be saved in its original format with the correct extension

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

- Reads VB Decompiler's active color scheme from Windows Registry
- Parses theme configuration from `.ini` files
- Applies custom colors to all UI elements
- Uses Windows DWM API for native dark title bar (Windows 10 1809+)
- Applies `DarkMode_Explorer` theme to native controls for consistent dark scrollbars

## System Requirements

- **VB Decompiler**: Version 5.0 or higher
- **Operating System**: Windows 10/11
- **Architecture**: x86 и x86-64

## Development

### Building from Source

**Requirements:**
- Embarcadero Delphi
- VB Decompiler Plugin SDK

**Build Steps:**
1. Clone the repository
2. Open `FRXViewer.dpr` in Delphi
3. Ensure `PluginSDK.pas` is in the project directory
4. Compile as 32-bit or 64-bit DLL (match your VB Decompiler version)
5. Output: `FRXViewer.dll`

### Project Structure

FRXViewer/
├── FRXViewer.dpr # Main DLL entry point
├── fmMain.pas # Main form implementation
├── fmMain.dfm # Form visual designer file
├── PluginSDK.pas # VB Decompiler SDK interface
├── DotFix_Software_Plugin_License.txt # License
└── README.md # This file


### Plugin SDK Integration

The plugin uses VB Decompiler's standard plugin interface:

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
```

## Troubleshooting

### Plugin doesn't appear in menu

- Verify DLL is in the correct plugins directory

- Check VB Decompiler version compatibility

- Ensure DLL architecture matches VB Decompiler (32-bit vs 64-bit)

### Images not loading

- Confirm the executable contains FRX resources

- Check if the file is opened successfully in VB Decompiler

- Verify file isn't locked by another process

### Dark mode not working

- Dark mode requires Windows 10 version 1809 or newer

- Check if VB Decompiler theme is properly configured

- Verify color scheme INI files exist in VB Decompiler\colors\ directory

### Known Limitations

- StatusBar panel borders remain light gray in dark mode (Windows control limitation)

- Very large images may experience performance delays

- Animated GIFs display only the first frame

## Changelog

Version 1.0.0 (2026-02-13)

Initial release

- Full FRX resource detection and extraction
- Dark mode support with automatic theme detection
- High-quality image scaling with HALFTONE interpolation
- Compound icon/cursor parsing
- Support for BMP, PNG, JPEG, GIF, ICO, CUR formats

## License

This project is licensed under the MIT License - see the [DOTFIX_LICENSE.TXT](LICENSE) file for details.

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

⭐ If you find this plugin useful, please consider starring the repository!