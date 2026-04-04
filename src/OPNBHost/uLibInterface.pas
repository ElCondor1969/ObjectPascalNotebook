unit uLibInterface;

interface

uses
  System.Classes,
  uDynLibLoader;

const
  // Host commands.
  COMHOST_LOADLIBRARY=0;
  COMHOST_UNLOADLIBRARY=1;
  COMHOST_POSTMESSAGE=2;

type
  TInvokeLibProc = function(Context, Instance: NativeInt; const ProcName: PChar; var Args: array of variant): variant; cdecl;
  TInvokeHostProc = function(Context: NativeInt; const Command: variant; var Args: array of variant): variant; cdecl;
  TSynchronize = procedure(AProcedure: TThreadProcedure); cdecl;

  PLibInterface = ^TLibInterface;
  TLibInterface = record
    Version: Integer;
    Context: NativeInt;
    Namespace: PChar;
    ExecutionPath: PChar;
    LibHandle: TDynLibHandle;
    LibGUID: PChar;
    InvokeLibProc: TInvokeLibProc;
    InvokeHostProc: TInvokeHostProc;
    Synchronize: TSynchronize;
  end;

  TLibInit = procedure(const LibInterface: PLibInterface); cdecl;
  TLibFree = procedure(const LibInterface: PLibInterface); cdecl;

implementation

end.
