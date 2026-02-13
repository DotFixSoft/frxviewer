{
    FRXViewer Plugin for VB Decompiler
    Copyright (c) 2001 - 2026 Sergey Chubchenko (DotFix Software). All rights reserved.

    Website: https://www.vb-decompiler.org
    Support: admin@vb-decompiler.org

    License:
        Licensed under the MIT License.
        See DotFix_Software_Plugin_License.txt file in the project root
        for full license information.
}

unit fmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.ImgList, PluginSDK,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, Vcl.Imaging.GIFImg,
  System.IOUtils, System.Math, System.StrUtils,
  System.Win.Registry, System.IniFiles,
  Vcl.Themes, Vcl.Styles;

type
  TfrmMain = class(TForm)
    lblTitle: TLabel;
    lvImages: TListView;
    pnlPreview: TPanel;
    imgPreview: TImage;
    StatusBar: TStatusBar;
    Splitter1: TSplitter;
    pnlSaveButton: TPanel;
    btnSaveToFile: TButton;
    SaveDialog: TSaveDialog;
    procedure SetStatusText(sText: string; Index: integer = 1);
    procedure FormCreate(Sender: TObject);
    procedure ApplyDarkMode;
    procedure FormShow(Sender: TObject);
    procedure lvImagesSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure btnSaveToFileClick(Sender: TObject);
    procedure StatusBarDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
  private
    FSourceFile: string;
    FImagesLoaded: Boolean;
    FCurrentIndex: Integer;
    FCurrentOffset: Int64;
    FCurrentSize: Int64;
    FCurrentFormat: string;
    FUseDarkMode: Boolean;
    procedure LoadImages;
    function DetectAndLoadImage(Stream: TStream; DestBitmap: TBitmap): Boolean;
    procedure ScaleImageToPreview(SourceGraphic: TGraphic; IsIcon: Boolean);
    function LoadBestIconFromStream(Stream: TStream; Icon: TIcon): Boolean;
    function DetectImageFormat(const Header: array of Byte): string;
    function ShouldUseDarkMode: Boolean;
    function GetBackgroundColor: TColor;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

const
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;

function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD; pvAttribute: Pointer; cbAttribute: DWORD): HRESULT; stdcall; external 'dwmapi.dll';
function SetWindowTheme(hwnd: HWND; pszSubAppName: LPCWSTR; pszSubIdList: LPCWSTR): HRESULT; stdcall; external 'uxtheme.dll';

procedure TfrmMain.SetStatusText(sText: string; Index: integer = 1);
begin
  if StatusBar.Panels.Count > Index then begin
    // Unfortunately, this is the only way to avoid glitches with the
    // status bar display if the decompiler is running on a Steam Deck console
    StatusBar.StyleElements := StatusBar.StyleElements - [seClient];
    StatusBar.Panels[Index].Text := '';
    StatusBar.Panels[Index].Text := sText;
    StatusBar.Update;
    StatusBar.StyleElements := StatusBar.StyleElements + [seClient];
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Form setup
  Self.Width := 1000;
  Self.Height := 700;
  Self.Position := poScreenCenter;
  Self.Constraints.MinWidth := 800;
  Self.Constraints.MinHeight := 600;

  // Initialize current values
  FCurrentIndex := -1;
  FCurrentOffset := 0;
  FCurrentSize := 0;
  FCurrentFormat := '';
  FSourceFile := GetString(GetFileName);

  // Determine theme
  FUseDarkMode := ShouldUseDarkMode;
  if FUseDarkMode then
  begin
    ApplyDarkMode();
  end;

  // ListView setup with thumbnails
  lvImages.Align := alLeft;
  lvImages.Width := 250;
  lvImages.ViewStyle := vsIcon;
  if lvImages.LargeImages = nil then
    lvImages.LargeImages := TImageList.Create(Self);
  lvImages.LargeImages.Width := 64;
  lvImages.LargeImages.Height := 64;
  lvImages.LargeImages.ColorDepth := cd32Bit;
  lvImages.LargeImages.DrawingStyle := dsTransparent;

  // Splitter setup
  Splitter1.Align := alLeft;
  Splitter1.Width := 5;
  Splitter1.Left := lvImages.Left + lvImages.Width + 1;

  // Preview panel setup
  pnlPreview.Align := alClient;
  pnlPreview.BevelOuter := bvNone;
  pnlPreview.Color := GetBackgroundColor;

  // Image component for preview
  imgPreview.Align := alClient;
  imgPreview.Center := True;
  imgPreview.Proportional := True;
  imgPreview.Stretch := False;

  // Button panel setup
  pnlSaveButton.Align := alBottom;
  pnlSaveButton.Height := 40;
  pnlSaveButton.BevelOuter := bvNone;

  // Button setup
  btnSaveToFile.Enabled := False;

  // StatusBar initialization
  SetStatusText('Active image', 0);
  SetStatusText('');
end;

procedure TfrmMain.StatusBarDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
var
  TextRect: TRect;
  TextFlags: Cardinal;
begin
  // Dark panel background
  StatusBar.Canvas.Brush.Color := $1E1E1E;
  StatusBar.Canvas.FillRect(Rect);

  // Light text
  StatusBar.Canvas.Font.Color := $E0E0E0;
  StatusBar.Canvas.Font.Name := 'Segoe UI';
  StatusBar.Canvas.Font.Size := 8;

  // Draw text with padding
  TextRect := Rect;
  InflateRect(TextRect, -5, 0);
  TextFlags := DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS;
  DrawText(StatusBar.Canvas.Handle, PChar(Panel.Text), Length(Panel.Text), TextRect, TextFlags);

  // Draw thin separator line between panels
  if Panel.Index < StatusBar.Panels.Count - 1 then
  begin
    StatusBar.Canvas.Pen.Color := $404040;
    StatusBar.Canvas.MoveTo(Rect.Right - 1, Rect.Top + 2);
    StatusBar.Canvas.LineTo(Rect.Right - 1, Rect.Bottom - 2);
  end;
end;

procedure TfrmMain.ApplyDarkMode;
var
  DarkMode: Integer;
begin
  // 1. Dark window title bar (Windows 10 1809+)
  DarkMode := 1;
  DwmSetWindowAttribute(Self.Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, @DarkMode, SizeOf(DarkMode));

  // 2. Form colors
  Self.Color := $2B2B2B;
  Self.Font.Color := clWhite;

  // 3. Label
  lblTitle.Font.Color := $E0E0E0;

  // 4. ListView - dark theme with dark scrollbars
  lvImages.Color := $1E1E1E;
  lvImages.Font.Color := $E0E0E0;
  SetWindowTheme(lvImages.Handle, 'DarkMode_Explorer', nil);

  // Dark background for icons in ListView
  if Assigned(lvImages.LargeImages) then
  begin
    lvImages.LargeImages.BkColor := $1E1E1E;
    lvImages.LargeImages.DrawingStyle := dsTransparent;
  end;

  // 5. Splitter
  Splitter1.Color := $3C3C3C;

  // 6. Preview panel
  pnlPreview.Color := $252526;
  pnlPreview.BevelOuter := bvNone;
  pnlPreview.ParentBackground := False;

  // 8. Button panel
  pnlSaveButton.Color := $2B2B2B;
  pnlSaveButton.ParentBackground := False;

  // 9. Button
  btnSaveToFile.Font.Color := $E0E0E0;
  SetWindowTheme(btnSaveToFile.Handle, 'DarkMode_Explorer', nil);

  // 10. StatusBar - fully custom
  StatusBar.Color := $1E1E1E;
  StatusBar.Font.Color := $E0E0E0;
  StatusBar.SimplePanel := False;

  // Make StatusBar panels owner-draw for custom rendering
  if StatusBar.Panels.Count > 0 then
  begin
    StatusBar.Panels[0].Style := psOwnerDraw;
    StatusBar.Panels[0].Bevel := pbNone;
    if StatusBar.Panels.Count > 1 then
    begin
      StatusBar.Panels[1].Style := psOwnerDraw;
      StatusBar.Panels[1].Bevel := pbNone;
    end;
  end;

  // Connect StatusBar drawing handler
  StatusBar.OnDrawPanel := StatusBarDrawPanel;

  // 11. SaveDialog - dark theme
  SetWindowTheme(SaveDialog.Handle, 'DarkMode_Explorer', nil);

  // Repaint all
  Self.Invalidate;
  Self.Repaint;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  if not FImagesLoaded then
  begin
    FSourceFile := GetString(GetFileName);
    if FileExists(FSourceFile) then
    begin
      SetStatusText(Format('Reading from: %s', [ExtractFileName(FSourceFile)]));
      LoadImages;
    end
    else
    begin
      SetStatusText('File not found or not opened in a decompiler.');
    end;
    FImagesLoaded := True;
  end;
end;

procedure TfrmMain.LoadImages;
var
  Count: Int64;
  I: Integer;
  Offset, Size: Int64;
  FileStream: TFileStream;
  MemStream: TMemoryStream;
  Bmp: TBitmap;
  Item: TListItem;
  IconIdx: Integer;
begin
  Count := GetInteger(GetFrxIconCount);
  if Count <= 0 then
  begin
    ShowMessage('No FRX icons found.');
    Application.Terminate;
    Exit;
  end;

  try
    FileStream := TFileStream.Create(FSourceFile, fmOpenRead or fmShareDenyNone);
  except
    on E: Exception do
    begin
      ShowMessage('Cannot open source file: ' + FSourceFile + sLineBreak + E.Message);
      Application.Terminate;
      Exit;
    end;
  end;

  try
    MemStream := TMemoryStream.Create;
    Bmp := TBitmap.Create;
    try
      lvImages.Items.BeginUpdate;
      try
        for I := 0 to Count - 1 do
        begin
          Offset := GetInteger(GetFrxIconOffset, I);
          Size := GetInteger(GetFrxIconSize, I);
          if (Size > 8) and (Offset > 0) and (Offset + Size <= FileStream.Size) then
          begin
            FileStream.Position := Offset + 8;
            MemStream.Clear;
            MemStream.CopyFrom(FileStream, Size - 8);
            MemStream.Position := 0;
            if DetectAndLoadImage(MemStream, Bmp) then
            begin
              IconIdx := lvImages.LargeImages.Add(Bmp, nil);
              Item := lvImages.Items.Add;
              Item.Caption := Format('%d (%d)', [I, Offset]);
              Item.ImageIndex := IconIdx;
              Item.Data := Pointer(I);
            end;
          end;
        end;
      finally
        lvImages.Items.EndUpdate;
      end;
    finally
      Bmp.Free;
      MemStream.Free;
    end;
  finally
    FileStream.Free;
  end;
end;

function TfrmMain.DetectAndLoadImage(Stream: TStream; DestBitmap: TBitmap): Boolean;
var
  StartPos: Int64;
  Header: array[0..7] of Byte;
  Graphic: TGraphic;
  TempBmp: TBitmap;
  ThumbSize: Integer;
  Icon: TIcon;
  IconBmp: TBitmap;
  DstRect: TRect;
  Scale: Double;
begin
  Result := False;
  StartPos := Stream.Position;
  try
    if Stream.Read(Header, 8) <> 8 then Exit;
    Stream.Position := StartPos;
    ThumbSize := lvImages.LargeImages.Width;

    // Special handling for icons
    if (Header[0] = 0) and (Header[1] = 0) then
    begin
      Icon := TIcon.Create;
      try
        try
          Icon.LoadFromStream(Stream);
        except
          // If failed - parse compound icon
          Stream.Position := StartPos;
          if not LoadBestIconFromStream(Stream, Icon) then
            Exit;
        end;

        // Convert icon to bitmap for proper scaling
        IconBmp := TBitmap.Create;
        try
          IconBmp.PixelFormat := pf32bit;
          IconBmp.SetSize(Icon.Width, Icon.Height);
          IconBmp.Canvas.Brush.Color := GetBackgroundColor;
          IconBmp.Canvas.FillRect(Rect(0, 0, Icon.Width, Icon.Height));
          IconBmp.Canvas.Draw(0, 0, Icon);

          // Now scale bitmap
          TempBmp := TBitmap.Create;
          try
            TempBmp.PixelFormat := pf32bit;
            TempBmp.SetSize(ThumbSize, ThumbSize);
            TempBmp.Canvas.Brush.Color := GetBackgroundColor;
            TempBmp.Canvas.FillRect(Rect(0, 0, ThumbSize, ThumbSize));

            // Calculate proportional scaling
            Scale := Min(ThumbSize / IconBmp.Width, ThumbSize / IconBmp.Height);
            DstRect := Rect(0, 0, Round(IconBmp.Width * Scale), Round(IconBmp.Height * Scale));

            // Center
            OffsetRect(DstRect, (ThumbSize - DstRect.Width) div 2, (ThumbSize - DstRect.Height) div 2);

            SetStretchBltMode(TempBmp.Canvas.Handle, HALFTONE);
            SetBrushOrgEx(TempBmp.Canvas.Handle, 0, 0, nil);
            TempBmp.Canvas.StretchDraw(DstRect, IconBmp);

            DestBitmap.Assign(TempBmp);
            Result := True;
          finally
            TempBmp.Free;
          end;
        finally
          IconBmp.Free;
        end;
      finally
        Icon.Free;
      end;
      Exit;
    end;

    // For other formats
    if (Header[0] = $42) and (Header[1] = $4D) then
      Graphic := TBitmap.Create
    else if (Header[0] = $89) and (Header[1] = $50) and (Header[2] = $4E) and (Header[3] = $47) then
      Graphic := TPngImage.Create
    else if (Header[0] = $FF) and (Header[1] = $D8) then
      Graphic := TJPEGImage.Create
    else if (Header[0] = $47) and (Header[1] = $49) and (Header[2] = $46) then
      Graphic := TGIFImage.Create
    else
      Exit;

    try
      Graphic.LoadFromStream(Stream);
      TempBmp := TBitmap.Create;
      try
        TempBmp.PixelFormat := pf32bit;
        TempBmp.SetSize(ThumbSize, ThumbSize);
        TempBmp.Canvas.Brush.Color := GetBackgroundColor;
        TempBmp.Canvas.FillRect(Rect(0, 0, ThumbSize, ThumbSize));

        // Proportional scaling
        Scale := Min(ThumbSize / Graphic.Width, ThumbSize / Graphic.Height);
        DstRect := Rect(0, 0, Round(Graphic.Width * Scale), Round(Graphic.Height * Scale));
        OffsetRect(DstRect, (ThumbSize - DstRect.Width) div 2, (ThumbSize - DstRect.Height) div 2);

        SetStretchBltMode(TempBmp.Canvas.Handle, HALFTONE);
        SetBrushOrgEx(TempBmp.Canvas.Handle, 0, 0, nil);
        TempBmp.Canvas.StretchDraw(DstRect, Graphic);

        DestBitmap.Assign(TempBmp);
        Result := True;
      finally
        TempBmp.Free;
      end;
    finally
      Graphic.Free;
    end;
  except
    Result := False;
  end;
end;

procedure TfrmMain.ScaleImageToPreview(SourceGraphic: TGraphic; IsIcon: Boolean);
const
  MIN_UPSCALE_SIZE = 128;
var
  ScaledBmp: TBitmap;
  IconBmp: TBitmap;
  DstWidth, DstHeight: Integer;
  Scale: Double;
  NeedsUpscale: Boolean;
begin
  if SourceGraphic = nil then Exit;

  // Check if upscaling needed
  NeedsUpscale := (SourceGraphic.Width < MIN_UPSCALE_SIZE) and
                  (SourceGraphic.Height < MIN_UPSCALE_SIZE);

  if NeedsUpscale then
  begin
    // Upscale to 128px on larger side
    if SourceGraphic.Width > SourceGraphic.Height then
      Scale := MIN_UPSCALE_SIZE / SourceGraphic.Width
    else
      Scale := MIN_UPSCALE_SIZE / SourceGraphic.Height;

    DstWidth := Round(SourceGraphic.Width * Scale);
    DstHeight := Round(SourceGraphic.Height * Scale);

    ScaledBmp := TBitmap.Create;
    try
      ScaledBmp.PixelFormat := pf32bit;
      ScaledBmp.SetSize(DstWidth, DstHeight);

      // If icon, convert to bitmap first
      if IsIcon and (SourceGraphic is TIcon) then
      begin
        IconBmp := TBitmap.Create;
        try
          IconBmp.PixelFormat := pf32bit;
          IconBmp.SetSize(SourceGraphic.Width, SourceGraphic.Height);
          IconBmp.Canvas.Brush.Color := GetBackgroundColor;
          IconBmp.Canvas.FillRect(Rect(0, 0, SourceGraphic.Width, SourceGraphic.Height));
          IconBmp.Canvas.Draw(0, 0, SourceGraphic);

          // High quality scaling
          SetStretchBltMode(ScaledBmp.Canvas.Handle, HALFTONE);
          SetBrushOrgEx(ScaledBmp.Canvas.Handle, 0, 0, nil);
          ScaledBmp.Canvas.StretchDraw(Rect(0, 0, DstWidth, DstHeight), IconBmp);
        finally
          IconBmp.Free;
        end;
      end
      else
      begin
        // High quality scaling for regular graphics
        SetStretchBltMode(ScaledBmp.Canvas.Handle, HALFTONE);
        SetBrushOrgEx(ScaledBmp.Canvas.Handle, 0, 0, nil);
        ScaledBmp.Canvas.StretchDraw(Rect(0, 0, DstWidth, DstHeight), SourceGraphic);
      end;

      // Now use TImage for centering
      imgPreview.Picture.Graphic := nil;
      imgPreview.Stretch := False;
      imgPreview.Center := True;
      imgPreview.Picture.Assign(ScaledBmp);
    finally
      ScaledBmp.Free;
    end;
  end
  else
  begin
    // Large image - fit to panel
    imgPreview.Picture.Graphic := nil;
    imgPreview.Center := False;
    imgPreview.Stretch := True;
    imgPreview.Proportional := True;
    imgPreview.Picture.Assign(SourceGraphic);
  end;
end;

procedure TfrmMain.lvImagesSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  Idx: Integer;
  Offset, Size: Int64;
  FileStream: TFileStream;
  MemStream: TMemoryStream;
  Header: array[0..7] of Byte;
  Graphic: TGraphic;
  Icon: TIcon;
  FormatExt: string;
begin
  if (not Selected) or (Item = nil) then
  begin
    imgPreview.Picture := nil;
    btnSaveToFile.Enabled := False;
    FCurrentIndex := -1;
    Exit;
  end;

  Idx := Integer(Item.Data);
  Offset := GetInteger(GetFrxIconOffset, Idx);
  Size := GetInteger(GetFrxIconSize, Idx);
  if (Size <= 8) or (Offset <= 0) then Exit;

  FileStream := nil;
  MemStream := nil;
  Graphic := nil;
  try
    FileStream := TFileStream.Create(FSourceFile, fmOpenRead or fmShareDenyNone);
    MemStream := TMemoryStream.Create;

    FileStream.Position := Offset + 8;
    MemStream.CopyFrom(FileStream, Size - 8);
    MemStream.Position := 0;

    FillChar(Header, SizeOf(Header), 0);
    if MemStream.Read(Header, 8) <> 8 then Exit;
    MemStream.Position := 0;

    // Detect format
    FormatExt := DetectImageFormat(Header);

    // Save current parameters for Save button
    FCurrentIndex := Idx;
    FCurrentOffset := Offset + 8;
    FCurrentSize := Size - 8;
    FCurrentFormat := FormatExt;
    btnSaveToFile.Enabled := True;

    try
      // Special handling for icons and cursors
      if (Header[0] = 0) and (Header[1] = 0) then
      begin
        Icon := TIcon.Create;
        try
          try
            Icon.LoadFromStream(MemStream);
          except
            // If compound icon/cursor - parse
            MemStream.Position := 0;
            if not LoadBestIconFromStream(MemStream, Icon) then begin
              SetStatusText('Failed to load compound icon/cursor');
              Exit;
            end;
          end;

          if StatusBar.Panels.Count >= 2 then
            SetStatusText(Format('Image %d: %dx%d px | Size: %d bytes | Offset: $%X | Type: %s',
              [Idx, Icon.Width, Icon.Height, Size, Offset, UpperCase(FormatExt)]));

          ScaleImageToPreview(Icon, True);
        finally
          Icon.Free;
        end;
        Exit;
      end;

      // Other formats
      if (Header[0] = $42) and (Header[1] = $4D) then
        Graphic := TBitmap.Create
      else if (Header[0] = $89) and (Header[1] = $50) and (Header[2] = $4E) and (Header[3] = $47) then
        Graphic := TPngImage.Create
      else if (Header[0] = $FF) and (Header[1] = $D8) then
        Graphic := TJPEGImage.Create
      else if (Header[0] = $47) and (Header[1] = $49) and (Header[2] = $46) then
        Graphic := TGIFImage.Create
      else
      begin
        imgPreview.Picture := nil;
        SetStatusText(Format('Unknown format: %2X %2X %2X %2X',
          [Header[0], Header[1], Header[2], Header[3]]));
        Exit;
      end;

      Graphic.LoadFromStream(MemStream);
      SetStatusText(Format('Image %d: %dx%d px | Size: %d bytes | Offset: $%X | Type: %s',
        [Idx, Graphic.Width, Graphic.Height, Size, Offset, UpperCase(FormatExt)]));

      ScaleImageToPreview(Graphic, False);
    except
      on E: Exception do
      begin
        imgPreview.Picture := nil;
        SetStatusText('Load error: ' + E.Message);
      end;
    end;
  finally
    if Assigned(Graphic) then
      Graphic.Free;
    if Assigned(MemStream) then
      MemStream.Free;
    if Assigned(FileStream) then
      FileStream.Free;
  end;
end;

function TfrmMain.LoadBestIconFromStream(Stream: TStream; Icon: TIcon): Boolean;
type
  TIconDirEntry = packed record
    bWidth: Byte;
    bHeight: Byte;
    bColorCount: Byte;
    bReserved: Byte;
    wPlanes: Word;
    wBitCount: Word;
    dwBytesInRes: DWORD;
    dwImageOffset: DWORD;
  end;

  TIconDir = packed record
    idReserved: Word;
    idType: Word;
    idCount: Word;
  end;

var
  IconDir: TIconDir;
  Entries: array of TIconDirEntry;
  I, BestIdx: Integer;
  BestSize, CurrentSize: Integer;
  StartPos: Int64;
  IconStream: TMemoryStream;
begin
  Result := False;
  StartPos := Stream.Position;
  try
    // Read ICO/CUR header
    if Stream.Read(IconDir, SizeOf(TIconDir)) <> SizeOf(TIconDir) then
      Exit;

    // Check signature (1 = ICO, 2 = CUR)
    if (IconDir.idReserved <> 0) or
       ((IconDir.idType <> 1) and (IconDir.idType <> 2)) or
       (IconDir.idCount = 0) then
    begin
      Stream.Position := StartPos;
      Exit;
    end;

    // Read all icon/cursor entries
    SetLength(Entries, IconDir.idCount);
    for I := 0 to IconDir.idCount - 1 do
    begin
      if Stream.Read(Entries[I], SizeOf(TIconDirEntry)) <> SizeOf(TIconDirEntry) then
      begin
        Stream.Position := StartPos;
        Exit;
      end;
    end;

    // Find icon with maximum resolution
    BestIdx := 0;
    BestSize := 0;
    for I := 0 to High(Entries) do
    begin
      // bWidth/bHeight = 0 means 128x128
      CurrentSize := IfThen(Entries[I].bWidth = 0, 128, Entries[I].bWidth) *
                     IfThen(Entries[I].bHeight = 0, 128, Entries[I].bHeight);
      if CurrentSize > BestSize then
      begin
        BestSize := CurrentSize;
        BestIdx := I;
      end;
    end;

    // Create new stream with single selected icon
    IconStream := TMemoryStream.Create;
    try
      // Write header with single icon (force ICO type = 1)
      IconDir.idType := 1;
      IconDir.idCount := 1;
      IconStream.Write(IconDir, SizeOf(TIconDir));

      // Copy selected icon entry with adjusted offset
      Entries[BestIdx].dwImageOffset := SizeOf(TIconDir) + SizeOf(TIconDirEntry);
      IconStream.Write(Entries[BestIdx], SizeOf(TIconDirEntry));

      // Copy icon data
      Stream.Position := StartPos + Entries[BestIdx].dwImageOffset;
      IconStream.CopyFrom(Stream, Entries[BestIdx].dwBytesInRes);

      // Load icon from new stream
      IconStream.Position := 0;
      Icon.LoadFromStream(IconStream);
      Result := True;
    finally
      IconStream.Free;
    end;
  except
    Stream.Position := StartPos;
    Result := False;
  end;
end;

function TfrmMain.DetectImageFormat(const Header: array of Byte): string;
begin
  // Check file signatures
  if (Header[0] = 0) and (Header[1] = 0) then
  begin
    // Check type: 1 = ICO, 2 = CUR
    if (Header[2] = 1) and (Header[3] = 0) then
      Result := 'ico'
    else if (Header[2] = 2) and (Header[3] = 0) then
      Result := 'cur'
    else
      Result := 'ico'; // Default
  end
  else if (Header[0] = $42) and (Header[1] = $4D) then
    Result := 'bmp'
  else if (Header[0] = $89) and (Header[1] = $50) and (Header[2] = $4E) and (Header[3] = $47) then
    Result := 'png'
  else if (Header[0] = $FF) and (Header[1] = $D8) then
    Result := 'jpg'
  else if (Header[0] = $47) and (Header[1] = $49) and (Header[2] = $46) then
    Result := 'gif'
  else
    Result := 'bin'; // Unknown format
end;

procedure TfrmMain.btnSaveToFileClick(Sender: TObject);
var
  FileStream: TFileStream;
  OutStream: TFileStream;
  DefaultFileName: string;
  FilterIndex: Integer;
  Fmt: string;
begin
  if FCurrentIndex < 0 then Exit;

  // Generate default filename
  DefaultFileName := Format('Image_%d.%s', [FCurrentIndex, FCurrentFormat]);

  // Set correct filter
  Fmt := LowerCase(FCurrentFormat);
  if Fmt = 'bmp' then
    FilterIndex := 1
  else if Fmt = 'png' then
    FilterIndex := 2
  else if (Fmt = 'jpg') or (Fmt = 'jpeg') then
    FilterIndex := 3
  else if Fmt = 'gif' then
    FilterIndex := 4
  else if Fmt = 'ico' then
    FilterIndex := 5
  else if Fmt = 'cur' then
    FilterIndex := 6
  else
    FilterIndex := 7;

  SaveDialog.FileName := DefaultFileName;
  SaveDialog.FilterIndex := FilterIndex;

  if SaveDialog.Execute then
  begin
    try
      FileStream := TFileStream.Create(FSourceFile, fmOpenRead or fmShareDenyNone);
      try
        OutStream := TFileStream.Create(SaveDialog.FileName, fmCreate);
        try
          FileStream.Position := FCurrentOffset;
          OutStream.CopyFrom(FileStream, FCurrentSize);
          SetStatusText('Saved to: ' + ExtractFileName(SaveDialog.FileName));
        finally
          OutStream.Free;
        end;
      finally
        FileStream.Free;
      end;
    except
      on E: Exception do
        ShowMessage('Save error: ' + E.Message);
    end;
  end;
end;

function TfrmMain.ShouldUseDarkMode: Boolean;
var
  Reg: TRegistry;
  ColorScheme, DecompilerPath, IniFilePath: string;
  IniFile: TIniFile;
begin
  Result := False;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('Software\VB and VBA Program Settings\VB Decompiler\Options') then
    begin
      if Reg.ValueExists('CustomColorScheme') then
      begin
        ColorScheme := Reg.ReadString('CustomColorScheme');
        DecompilerPath := GetString(GetVBDecompilerPath);
        if DecompilerPath <> '' then
        begin
          IniFilePath := IncludeTrailingPathDelimiter(DecompilerPath) + 'colors\' + ColorScheme + '.ini';
          if FileExists(IniFilePath) then
          begin
            IniFile := TIniFile.Create(IniFilePath);
            try
              Result := IniFile.ReadInteger('Colors', 'UseDarkMode', 0) = 1;
            finally
              IniFile.Free;
            end;
          end;
        end;
      end;
    end;
  finally
    Reg.Free;
  end;
end;

function TfrmMain.GetBackgroundColor: TColor;
begin
  if FUseDarkMode then
    Result := $252526
  else
    Result := clWhite;
end;

end.
