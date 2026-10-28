# VB Decompiler / DE Decompiler Plugin SDK additions in version 26.6

These optional, read-only additions extend the shared `PluginEngine` callback of
[VB Decompiler](https://www.vb-decompiler.org) and
[DE Decompiler](https://www.de-decompiler.com).
The callback signature and existing command numbers do not change. Call it on
the application's main thread, as required by the existing SDK.

## Existing graphics commands: unchanged

| Command | SDK name | Index | Result |
| --- | --- | --- | --- |
| 60 | `GetFrxIconCount` | Unused | Number of registered original images |
| 61 | `GetFrxIconOffset` | Image index | Legacy adjusted file offset |
| 62 | `GetFrxIconSize` | Image index | Legacy adjusted byte count |

Image indexes are zero-based. Results are decimal strings. The returned pointer
belongs to the host and remains valid only until the next callback; copy the
string immediately, as the SDK's `GetString` does.

The original image bytes are read from the executable/DLL returned by command 3:

```pascal
Offset := GetInteger(GetFrxIconOffset, ImageIndex);
Size := GetInteger(GetFrxIconSize, ImageIndex);
FileStream.Position := Offset + 8;
ImageStream.CopyFrom(FileStream, Size - 8);
```

For an image whose actual file offset is `P` and actual byte count is `N`, the
host returns `P - 8` and `N + 8`. These adjusted values do not imply that there is
a real FRX header at that location in a Delphi executable. They preserve the
established reader contract. Each resulting payload starts with the picture's
own BMP/PNG/JPEG/GIF/ICO/CUR signature. DFM property prefixes and ImageList
container headers are excluded.

DE Decompiler registers images from binary DFM values during form decoding.
Separate encoded pictures in collection items receive separate entries. For
classic native ImageLists, the original color bitmap sheet and optional mask
are standalone bitmap entries. Existing plugins can display/export those sheets.
Their individual cells require the optional metadata below.

## Command 63: `GetFrxImageListInfo`

- `vlType` / `strCode`: `63`.
- `vlNumber` / `strIndex`: an existing image index from commands 60–62.
- `vlFnNumber` and the input pointer: unused; pass `0` and `nil`.
- Available for recognized Delphi/Free Pascal DFM ImageList color bitmaps.

The result is an empty string for an ordinary image, an unsupported stream, or
a host without this command. Invalid indexes return the existing `Error` result.
Treat any empty, `Error`, malformed or unknown-version reply as unsupported and
keep the original picture-reading behavior.

The current `IL1` implementation recognizes native stream version `$0101`
with BMP sheets. Unsupported variants keep the whole-picture fallback wherever
ordinary image entries are available.

A recognized list returns:

```text
IL1;<Count>;<Width>;<Height>;<Flags>;<MaskOffset>;<MaskSize>
```

All numeric fields are decimal, separated by semicolons:

| Field | Meaning |
| --- | --- |
| `Count` | Number of logical images, excluding spare capacity |
| `Width`, `Height` | Cell dimensions in pixels |
| `Flags` | Original native ImageList flags; bit 0 indicates a mask, color format `$20` indicates `ILC_COLOR32` |
| `MaskOffset` | **Actual** file offset of the mask BMP signature; no `+8` adjustment |
| `MaskSize` | **Actual** mask BMP byte count; no `-8` adjustment |

`MaskOffset` and `MaskSize` are zero when no mask is present. The color bitmap
still comes from commands 61–62, using their original `+8` / `-8` rule. Command
63 returns metadata only; it does not change image indexes or expose containers
through the original image commands.

For cell `K`, use logical top-left coordinates:

```pascal
Columns := ColorBitmap.Width div CellWidth;
X := (K mod Columns) * CellWidth;
Y := (K div Columns) * CellHeight;
```

Require `0 <= K < Count`, validate dimensions and file ranges, and account for
bottom-up DIB scanlines. Apply the corresponding one-bit mask or the premultiplied
alpha channel. Older 32-bit lists can have an entirely zero alpha channel;
the mask remains the fallback for those cells.

The updated FRXViewer performs splitting only when opened. After validating
the bitmap ranges and geometry, it uses the stock Windows ImageList decoder
once for each gallery list, previews individual cells, and exports each cell as
an ICO with the original masks/alpha. The host does not rasterize cells or duplicate picture bytes.

Example discovery:

```pascal
InfoText := GetString(GetFrxImageListInfo, ImageIndex);
if ParseFrxImageListInfo(InfoText, Info) then begin
  ColorOffset := GetInteger(GetFrxIconOffset, ImageIndex) + 8;
  ColorSize := GetInteger(GetFrxIconSize, ImageIndex) - 8;
  Images := TFrxImageList.Create(FileStream, ColorOffset, ColorSize, Info);
  try
    Icon := Images.Icon(0);
    try
      Icon.SaveToFile('Image_0.ico');
    finally
      Icon.Free;
    end;
  finally
    Images.Free;
  end;
end;
```

`ParseFrxImageListInfo` and `TFrxImageList` are supplied in the updated plugin's
`modFrxImageList.pas`. While enumerating a list, suppress its mask's normal gallery
entry by comparing its actual image offset with `MaskOffset`.

## Command 64: `GetProductName`

- `vlType` / `strCode`: `64`.
- All other arguments: unused; pass `0`, `0`, `nil`.
- Result: `VB Decompiler` or `DE Decompiler`, taken from the loaded product
  identity, independently of the compiler/language of the inspected file.

Use this value in user-facing messages. Keep SDK export names, registry paths
and existing localization keys unchanged. The updated SDK's
`DecompilerProductName` helper validates the reply and falls back to
`VB Decompiler` for older hosts:

```pascal
MessageText := Format('No file loaded in %s.', [DecompilerProductName]);
```

## Compatibility

- Existing plugins: no changes required for the original picture entries.
- Updated FRXViewer + older host: original whole-image behavior is retained.
- Updated FRXViewer + current DE host: recognized native lists are split into
  individual icons; independently encoded collection pictures stay ordinary entries.
- VB6/.NET graphics: original commands and extraction paths are retained.
- The new calls are getters. They do not modify code, forms, the opened file or
  the decompiler's current selection.

Reference reader: [DotFixSoft/frxviewer](https://github.com/DotFixSoft/frxviewer/blob/main/fmMain.pas).
