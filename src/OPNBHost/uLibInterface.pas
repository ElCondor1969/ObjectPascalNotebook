unit uLibInterface;

interface

uses
  uDynLibLoader;

type
  TInvokeLibProc = function(Context, Instance: NativeInt; const ProcName: PChar; var Args: array of variant): variant; cdecl;
  TPostMessage = procedure(Context: NativeInt; const Key: variant; const Parameters: array of variant); cdecl;
  PPostMessge = ^TPostMessage;

  PLibInterface = ^TLibInterface;
  TLibInterface = record
    Version: Integer;
    Context: NativeInt;
    Namespace: PChar;
    ExecutionPath: PChar;
    LibHandle: TDynLibHandle;
    LibGUID: PChar;
    InvokeLibProc: TInvokeLibProc;
    PostMessage: TPostMessage;
  end;

  TLibInit = procedure(const LibInterface: PLibInterface); cdecl;
  TLibFree = procedure(const LibInterface: PLibInterface); cdecl;

implementation

end.
