{
    FRXViewer Plugin for VB Decompiler and DE Decompiler
    Copyright (c) 2001 - 2026 Sergey Chubchenko (DotFix Software). All rights reserved.

    VB Decompiler: https://www.vb-decompiler.org
    DE Decompiler: https://www.de-decompiler.com
    Support: admin@vb-decompiler.org

    License:
        Licensed under the MIT License.
        See DotFix_Software_Plugin_License.txt file in the project root
        for full license information.
}

unit modFrxImageList;

// Decode each stored native list once in the plugin. The host only exposes
// original file ranges and metadata; Windows preserves native masks and alpha.
interface

uses System.SysUtils, System.Classes, Vcl.Graphics, Winapi.CommCtrl;

type
  TFrxImageListInfo = record
    Count, Width, Height, Flags: Integer;
    MaskOffset, MaskSize: Int64;
  end;

  TFrxImageList = class
  private
    FHandle: HIMAGELIST;
    FInfo: TFrxImageListInfo;
  public
    constructor Create(Stream: TStream; ColorOffset, ColorSize: Int64; const Info: TFrxImageListInfo);
    destructor Destroy; override;
    function Icon(Index: Integer): Vcl.Graphics.TIcon;
    property Count: Integer read FInfo.Count;
    property Width: Integer read FInfo.Width;
    property Height: Integer read FInfo.Height;
  end;

function ParseFrxImageListInfo(const Text: string; out Info: TFrxImageListInfo): Boolean;

implementation

uses Winapi.Windows, Winapi.ActiveX;

function ParseFrxImageListInfo(const Text: string; out Info: TFrxImageListInfo): Boolean;
var Parts: TArray<string>;
begin
  Info := Default(TFrxImageListInfo);
  Parts := Text.Split([';']);
  Result := (Length(Parts) = 7) and (Parts[0] = 'IL1');
  if not Result then Exit;
  Result := TryStrToInt(Parts[1], Info.Count) and TryStrToInt(Parts[2], Info.Width) and
    TryStrToInt(Parts[3], Info.Height) and TryStrToInt(Parts[4], Info.Flags) and
    TryStrToInt64(Parts[5], Info.MaskOffset) and TryStrToInt64(Parts[6], Info.MaskSize);
  if not Result then Exit;
  Result := (Info.Count > 0) and (Info.Count <= 8192) and
    (Info.Width > 0) and (Info.Width <= 512) and (Info.Height > 0) and (Info.Height <= 512) and
    (Info.Flags >= 0) and (Info.Flags <= High(Word)) and
    (Info.MaskOffset >= 0) and (Info.MaskSize >= 0) and
    (((Info.Flags and 1) = 0) or ((Info.MaskOffset > 0) and (Info.MaskSize >= 54)));
end;

constructor TFrxImageList.Create(Stream: TStream; ColorOffset, ColorSize: Int64; const Info: TFrxImageListInfo);
var
  Header: array[0..27] of Byte;
  Memory: TMemoryStream;
  Adapter: IStream;
  ColorWidth, ColorHeight, MaskWidth, MaskHeight, NativeWidth, NativeHeight: Integer;

  function WordAt(Offset: Integer): Word;
  begin
    Move(Header[Offset], Result, SizeOf(Result));
  end;

  procedure AppendBitmap(Offset, Count: Int64; out Width, Height: Integer);
  var
    Bytes: TBytesStream;
    BitmapHeader: TBitmapInfoHeader;
    Bits: Cardinal;
    Expected: Int64;
  begin
    if (Offset < 0) or (Count < 54) or (Offset > Stream.Size) or
      (Count > Stream.Size - Offset) or (Count > 128 * 1024 * 1024) then
      raise EReadError.Create('Invalid ImageList bitmap range');
    Bytes := TBytesStream.Create;
    try
      Stream.Position := Offset; Bytes.CopyFrom(Stream, Count);
      if (Bytes.Bytes[0] <> $42) or (Bytes.Bytes[1] <> $4D) then
        raise EReadError.Create('Invalid ImageList bitmap signature');
      Move(Bytes.Bytes[14], BitmapHeader, SizeOf(BitmapHeader));
      Move(Bytes.Bytes[10], Bits, SizeOf(Bits));
      with BitmapHeader do begin
        if (biSize <> 40) or (biPlanes <> 1) or (biCompression <> BI_RGB) or
          not (biBitCount in [1, 4, 8, 16, 24, 32]) or
          (biWidth < 1) or (biWidth > 8192) or (biHeight < 1) or
          (biHeight > 8192) or (Int64(biWidth) * biHeight > 16 * 1024 * 1024) or
          (Bits < 54) or (Bits > Count) then raise EReadError.Create('Unsupported ImageList bitmap geometry');
        Expected := Int64(Bits) + ((Int64(biWidth) * biBitCount + 31) div 32) * 4 * biHeight;
        if Expected > Count then raise EReadError.Create('Truncated ImageList bitmap pixels');
        Width := biWidth; Height := biHeight;
      end;
      // Old streams can store bfSize=40: validate pixels using DIB geometry,
      // then preserve the native stream bytes for ImageList_Read.
      Bytes.Position := 0; Memory.CopyFrom(Bytes, Count);
    finally Bytes.Free; end;
  end;

begin
  inherited Create;
  FInfo := Info;
  if (Info.Count < 1) or (Info.Count > 8192) or (Info.Width < 1) or (Info.Width > 512) or
    (Info.Height < 1) or (Info.Height > 512) or (ColorOffset < 28) or
    (ColorOffset > Stream.Size) then raise EReadError.Create('Invalid ImageList metadata');
  Stream.Position := ColorOffset - 28; Stream.ReadBuffer(Header, SizeOf(Header));
  if (WordAt(0) <> $4C49) or (WordAt(2) <> $0101) or (WordAt(4) <> Info.Count) or
    (WordAt(6) < Info.Count) or (WordAt(6) > 8192) or (WordAt(8) > 8192) or (WordAt(10) <> Info.Width) or
    (WordAt(12) <> Info.Height) or (WordAt(18) <> Info.Flags) then
    raise EReadError.Create('ImageList metadata differs from the opened file');
  Memory := TMemoryStream.Create;
  try
    Memory.WriteBuffer(Header, SizeOf(Header));
    AppendBitmap(ColorOffset, ColorSize, ColorWidth, ColorHeight);
    if (ColorWidth mod Info.Width <> 0) or (ColorHeight mod Info.Height <> 0) or
      (Int64(Info.Count) > Int64(ColorWidth div Info.Width) * (ColorHeight div Info.Height)) then
      raise EReadError.Create('ImageList count exceeds the stored bitmap');
    if (Info.Flags and 1) <> 0 then begin
      if (Info.MaskOffset <> ColorOffset + ColorSize) then raise EReadError.Create('Noncontiguous ImageList mask');
      AppendBitmap(Info.MaskOffset, Info.MaskSize, MaskWidth, MaskHeight);
      if (MaskWidth <> ColorWidth) or (MaskHeight <> ColorHeight) then
        raise EReadError.Create('ImageList mask dimensions differ');
    end;
    Memory.Position := 0;
    Adapter := TStreamAdapter.Create(Memory, soReference) as IStream;
    FHandle := ImageList_Read(Adapter);
    if (FHandle = 0) or (ImageList_GetImageCount(FHandle) <> Info.Count) or
      not ImageList_GetIconSize(FHandle, NativeWidth, NativeHeight) or
      (NativeWidth <> Info.Width) or (NativeHeight <> Info.Height) then
      raise EReadError.Create('Windows could not decode the stored ImageList');
  finally Adapter := nil; Memory.Free; end;
end;

destructor TFrxImageList.Destroy;
begin
  if FHandle <> 0 then ImageList_Destroy(FHandle);
  inherited;
end;

function TFrxImageList.Icon(Index: Integer): Vcl.Graphics.TIcon;
begin
  if (Index < 0) or (Index >= Count) then raise ERangeError.Create('Invalid ImageList image index');
  Result := Vcl.Graphics.TIcon.Create;
  try
    Result.Handle := ImageList_GetIcon(FHandle, Index, ILD_TRANSPARENT);
    if Result.Handle = 0 then RaiseLastOSError;
  except Result.Free; raise; end;
end;

end.
