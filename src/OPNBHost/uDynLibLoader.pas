unit uDynLibLoader;

interface

uses
  System.SysUtils;

type
  TDynLibHandle = NativeUInt;

function LoadDynLib(const LibName: string; Check: boolean=false): TDynLibHandle;
function GetDynProc(Lib: TDynLibHandle; const ProcName: PAnsiChar): Pointer;
procedure FreeDynLib(Lib: TDynLibHandle);
function IsLibraryFile(const FileName: string): Boolean;

implementation

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}

{$IFDEF MACOS}
  Posix.Dlfcn,
{$ENDIF}

{$IFDEF LINUX}
  Posix.Dlfcn,
{$ENDIF}

{$IFDEF ANDROID}
  Posix.Dlfcn,
{$ENDIF}
  uUtility;

function LoadDynLib(const LibName: string; Check: boolean): TDynLibHandle;
begin
{$IFDEF MSWINDOWS}
  Result := TDynLibHandle(LoadLibrary(PChar(LibName)));
{$ELSE}
  Result := TDynLibHandle(dlopen(PAnsiChar(AnsiString(LibName)), RTLD_NOW));
{$ENDIF}
  if (Check) then
    if (Result=0) then
      try
        RaiseLastOSError;
      except
        on E: Exception do
          RaiseException('Error loading library: %s Error: %s',[LibName, E.Message]);
      end;
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
