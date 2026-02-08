unit uDynLibLoader;

interface

uses
  System.SysUtils;

type
  TDynLibHandle = NativeUInt;

function LoadDynLib(const LibName: string): TDynLibHandle;
function GetDynProc(Lib: TDynLibHandle; const ProcName: PAnsiChar): Pointer;
procedure FreeDynLib(Lib: TDynLibHandle);
function IsLibraryFile(const FileName: string): Boolean;

implementation

{$IFDEF MSWINDOWS}
uses Winapi.Windows;
{$ENDIF}

{$IFDEF MACOS}
uses Posix.Dlfcn;
{$ENDIF}

{$IFDEF LINUX}
uses Posix.Dlfcn;
{$ENDIF}

{$IFDEF ANDROID}
uses Posix.Dlfcn;
{$ENDIF}

function LoadDynLib(const LibName: string): TDynLibHandle;
begin
{$IFDEF MSWINDOWS}
  Result := TDynLibHandle(LoadLibrary(PChar(LibName)));
{$ELSE}
  Result := TDynLibHandle(dlopen(PAnsiChar(AnsiString(LibName)), RTLD_NOW));
{$ENDIF}
end;

function GetDynProc(Lib: TDynLibHandle; const ProcName: PAnsiChar): Pointer;
begin
{$IFDEF MSWINDOWS}
  Result := GetProcAddress(HMODULE(Lib), ProcName);
{$ELSE}
  Result := dlsym(Pointer(Lib), ProcName);
{$ENDIF}
end;

procedure FreeDynLib(Lib: TDynLibHandle);
begin
{$IFDEF MSWINDOWS}
  FreeLibrary(TDynLibHandle(Lib));
{$ELSE}
  dlclose(Pointer(Lib));
{$ENDIF}
end;

function IsLibraryFile(const FileName: string): Boolean;
begin
  Result := False;
{$IFDEF MSWINDOWS}
  Result := SameText(ExtractFileExt(FileName), '.dll');
{$ENDIF}
{$IFDEF MACOS}
  Result := SameText(ExtractFileExt(FileName), '.dylib');
{$ENDIF}
{$IFDEF LINUX}
  Result := SameText(ExtractFileExt(FileName), '.so');
{$ENDIF}
{$IFDEF ANDROID}
  Result := SameText(ExtractFileExt(FileName), '.so');
{$ENDIF}  
end;

end.
