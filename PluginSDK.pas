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

unit PluginSDK;

interface

uses
  System.SysUtils;

const
  { vlType Constants }
  GetVBProject = 1;
  SetVBProject = 2;
  GetFileName = 3;              // (v3.5+)
  IsNativeCompilation = 4;      // (v3.5+)
  ClearAllBuffers = 5;          // Required if your plugin decompiles a new language and needs to clear all structures (v3.9+)
  GetCompiler = 6;              // 1 - VB, 2 - .NET, 3 - Delphi, 4 - Unknown (v3.9+)
  IsPacked = 7;                 // 1 - Packed, 0 - Not packed (v3.9+)
  SetStackCheckBoxValue = 8;    // 0 - Unchecked, 1 - Checked (v3.9+)
  SetAnalyzerCheckBoxValue = 9; // 0 - Unchecked, 1 - Checked (v3.9+)
  GetVBFormName = 10;
  SetVBFormName = 11;
  GetVBForm = 12;
  SetVBForm = 13;
  GetVBFormCount = 14;
  GetSubMain = 20;
  SetSubMain = 21;
  GetModuleName = 30;
  SetModuleName = 31;
  GetModule = 32;
  SetModule = 33;
  GetModuleStringReferences = 34;
  SetModuleStringReferences = 35;
  GetModuleCount = 36;
  GetModuleFunctionName = 40;
  SetModuleFunctionName = 41;
  GetModuleFunctionAddress = 42;
  SetModuleFunctionAddress = 43;
  GetModuleFunction = 44;
  SetModuleFunction = 45;
  GetModuleFunctionStrRef = 46;
  SetModuleFunctionStrRef = 47;
  GetModuleFunctionCount = 48;
  GetActiveText = 50;
  SetActiveText = 51;
  GetActiveDisasmText = 52;       // (v9.4+)
  SetActiveDisasmText = 53;       // (v9.4+)
  SetActiveTextLine = 54;
  GetActiveModuleCoordinats = 55; // (v3.5+)
  GetVBDecompilerPath = 56;       // (v3.5+)
  GetModuleFunctionCode = 57;     // In "fast decompilation" mode (v3.5+)
  SetStatusBarText = 58;          // (v3.5+)
  GetFrxIconCount = 60;           // (v5.0+)
  GetFrxIconOffset = 61;          // (v5.0+)
  GetFrxIconSize = 62;            // (v5.0+)
  GetModuleFunctionDisasm = 70;   // (v9.4+)
  SetModuleFunctionDisasm = 71;   // (v9.4+)
  UpdateAll = 100;

type
  TVBDPluginEngine = function(vlType: Integer; vlNumber: Integer; vlFnNumber: Integer; vlNewValue: Pointer): Pointer; stdcall;

var
  PluginEngine: TVBDPluginEngine = nil;

function GetString(vlType: Integer; vlNumber: Integer = 0; vlFnNumber: Integer = 0): string;
function GetInteger(vlType: Integer; vlNumber: Integer = 0; vlFnNumber: Integer = 0): Int64;
procedure SetString(vlType: Integer; const vlNewValue: string; vlNumber: Integer = 0; vlFnNumber: Integer = 0);

implementation

function GetString(vlType: Integer; vlNumber: Integer; vlFnNumber: Integer): string;
var
  Res: Pointer;
begin
  if Assigned(PluginEngine) then
  begin
    Res := PluginEngine(vlType, vlNumber, vlFnNumber, nil);
    if Res <> nil then
      Result := string(PWideChar(Res))
    else
      Result := '';
  end
  else
    Result := '';
end;

function GetInteger(vlType: Integer; vlNumber: Integer; vlFnNumber: Integer): Int64;
var
  S: string;
begin
  S := GetString(vlType, vlNumber, vlFnNumber);
  if S = '' then
    Exit(0);
  if not TryStrToInt64(S, Result) then
    Result := 0;
end;

procedure SetString(vlType: Integer; const vlNewValue: string; vlNumber: Integer; vlFnNumber: Integer);
var
  AnsiTemp: AnsiString;
begin
  if Assigned(PluginEngine) then
  begin
    AnsiTemp := AnsiString(vlNewValue);
    PluginEngine(vlType, vlNumber, vlFnNumber, PAnsiChar(AnsiTemp));
  end;
end;

end.
