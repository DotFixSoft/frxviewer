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

library FRXViewer;



uses
  System.Classes,
  Winapi.Windows,
  System.SysUtils,
  Vcl.Forms,
  System.IOUtils,
  PluginSDK in 'PluginSDK.pas',
  fmMain in 'fmMain.pas' {frmMain};

{$R *.res}

var
  IsFirstLoad: Boolean = True;

// Standard exported functions
procedure VBDecompilerPluginName(VBDecompilerHWND: Integer; RichTextBoxHWND: Integer; Buffer: PAnsiChar; Void: Integer); export; stdcall;
var
  S: AnsiString;
begin
  S := 'FRX Image Viewer'#0;
  Move(S[1], Buffer^, Length(S));
end;

procedure VBDecompilerPluginAuthor(VBDecompilerHWND: Integer; RichTextBoxHWND: Integer; Buffer: PAnsiChar; Void: Integer); export; stdcall;
var
  S: AnsiString;
begin
  S := 'Sergey Chubchenko (DotFix Software)'#0;
  Move(S[1], Buffer^, Length(S));
end;

procedure VBDecompilerPluginLoad(VBDecompilerHWND: DWORD; RichTextBoxHWND: DWORD; Buffer: Pointer; E: Pointer); export; stdcall;
var
  SourceFile: string;
  LocalForm: TfrmMain;
begin
  // Initialize engine
  PluginSDK.PluginEngine := PluginSDK.TVBDPluginEngine(E);

  if Assigned(PluginSDK.PluginEngine) then begin
    // Check for opened file
    SourceFile := GetString(GetFileName);
    if SourceFile = '' then
    begin
      MessageBox(VBDecompilerHWND, 'No file loaded in VB Decompiler.', 'Plugin Error', MB_ICONERROR);
      Exit;
    end;

    if IsFirstLoad then begin
      IsFirstLoad := False;
      Application.Initialize;
      Application.Title := 'FRX Image Viewer';
    end;

    // Always update Application.Handle (may change after theme switch)
    Application.Handle := VBDecompilerHWND;

    // Create form each time
    LocalForm := TfrmMain.Create(Application);
    try
      if GetInteger(GetFrxIconCount) > 0 then
        LocalForm.ShowModal
      else
        MessageBox(VBDecompilerHWND, 'No FRX icons found.', 'FRX Image Viewer', MB_ICONINFORMATION);
    finally
      LocalForm.Free;
    end;
  end;
end;

exports
  VBDecompilerPluginName,
  VBDecompilerPluginLoad,
  VBDecompilerPluginAuthor;

begin
end.
