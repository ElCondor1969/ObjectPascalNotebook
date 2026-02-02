library OpenBLASLib;

uses
  System.SysUtils,
  System.JSON,
  System.Classes,
  System.StrUtils,
  System.Variants,
  System.Types,
  System.TypInfo,
  Generics.Collections,
  uLibInterface,
  LibCBLAS,
  uUtility;

{$R *.res}

type
  TMatrixEntry=record
    Freed: boolean;
    RowsNum: integer;
    ColsNum: integer;
    Matrix: array of double;
  end;

var
  MatrixDict: TDictionary<integer, TMatrixEntry>;
  MatrixDictIndex: integer;

procedure FreeMatrixDict;
var k:integer;
begin
  if (Assigned(MatrixDict)) then
    try
      for k in MatrixDict.Keys.ToArray do
        MatrixDict.Remove(k);
    finally
      MatrixDict.Free;
    end;
end;

function InstantiateMatrix(RowsNum, ColsNum: integer):integer;
var
  k:integer;
  MatrixEntry: TMatrixEntry;
begin
  for k in MatrixDict.Keys.ToArray do
    begin
      MatrixEntry:=MatrixDict[k];
      if MatrixEntry.Freed and (MatrixEntry.RowsNum=RowsNum) and (MatrixEntry.ColsNum=ColsNum) then
        begin
          Result:=k;
          Exit;
        end;
    end;
  MatrixEntry.Freed:=false;
  MatrixEntry.RowsNum:=RowsNum;
  MatrixEntry.ColsNum:=ColsNum;
  SetLength(MatrixEntry.Matrix, RowsNum*ColsNum);
  Inc(MatrixDictIndex);
  MatrixDict.AddOrSetValue(MatrixDictIndex, MatrixEntry);
  Result:=MatrixDictIndex;
end;

procedure FreeMatrix(const MatrixHandle: integer);
var
  MatrixEntry: TMatrixEntry;
begin
  if MatrixDict.TryGetValue(MatrixHandle,MatrixEntry) then
    begin
      MatrixEntry.Freed:=true;
      MatrixDict.AddOrSetValue(MatrixHandle,MatrixEntry);
    end;
end;

procedure ReadMatrixInfo(const MatrixHandle: integer; out RowsNum, ColsNum: variant);
var
  MatrixEntry: TMatrixEntry;
begin
  if MatrixDict.TryGetValue(MatrixHandle,MatrixEntry) then
    begin
      RowsNum:=MatrixEntry.RowsNum;
      ColsNum:=MatrixEntry.ColsNum;
    end
  else
    RaiseException('Matrix not found');
end;

function ReadMatrix(const MatrixHandle: integer; out RowsNum, ColsNum: variant): variant;
var
  MatrixEntry: TMatrixEntry;
begin
  if MatrixDict.TryGetValue(MatrixHandle,MatrixEntry) then
    begin
      DynArrayToVariant(Result,Pointer(MatrixEntry.Matrix),TypeInfo(TDoubleDynArray));
      RowsNum:=MatrixEntry.RowsNum;
      ColsNum:=MatrixEntry.ColsNum;
    end
  else
    RaiseException('Matrix not found');
end;

procedure WriteMatrix(const MatrixHandle: integer; Data: variant);
var
  MatrixEntry: TMatrixEntry;
begin
  if MatrixDict.TryGetValue(MatrixHandle,MatrixEntry) then
    begin
      DynArrayFromVariant(Pointer(MatrixEntry.Matrix),Data,TypeInfo(TDoubleDynArray));
      MatrixDict.AddOrSetValue(MatrixHandle,MatrixEntry);
    end
  else
    RaiseException('Matrix not found');
end;

function dgemm(MatrixA, MatrixB, MatrixC: integer; Alpha, Beta: double; TransposeA, TransposeB: boolean): integer;
var
  MatrixEntryA, MatrixEntryB, MatrixEntryC: TMatrixEntry;
  CBLASTransposeA, CBLASTransposeB: Tcblas_TRANSPOSE;
begin
  if not MatrixDict.TryGetValue(MatrixA,MatrixEntryA) then
    RaiseException('Matrix A not found');
  if not MatrixDict.TryGetValue(MatrixB,MatrixEntryB) then
    RaiseException('Matrix B not found');
  if (MatrixC=0) then
    begin
      MatrixC:=InstantiateMatrix(MatrixEntryA.RowsNum, MatrixEntryB.ColsNum);
      MatrixEntryC:=MatrixDict[MatrixC];
    end
  else
    if not MatrixDict.TryGetValue(MatrixC,MatrixEntryC) then
      RaiseException('Matrix C not found');
  Result:=MatrixC;
  if (TransposeA) then
    CBLASTransposeA:=cblasTrans
  else
    CBLASTransposeA:=cblasNoTrans;
  if (TransposeB) then
    CBLASTransposeB:=cblasTrans
  else
    CBLASTransposeB:=cblasNoTrans;
  CBLAS.dgemm(
    cblasRowMajor,
    CBLASTransposeA,
    CBLASTransposeB,
    MatrixEntryA.RowsNum,
    MatrixEntryB.ColsNum,
    MatrixEntryA.ColsNum,
    Alpha,
    @MatrixEntryA.Matrix[0],
    MatrixEntryA.ColsNum,
    @MatrixEntryB.Matrix[0],
    MatrixEntryB.ColsNum,
    Beta,
    @MatrixEntryC.Matrix[0],
    MatrixEntryC.ColsNum
  );
end;

function InvokeLibProcImpl(Context, Instance: NativeInt; const ProcName: PChar; var Args:array of variant): Variant; cdecl;
begin
  if (SameText(ProcName,'SetNumThreads')) then
    CBLAS.openblas_set_num_threads(Args[0])
  else if (SameText(ProcName,'GetNumThreads')) then
    Result:=CBLAS.openblas_get_num_threads
  else if (SameText(ProcName,'GetNumProcs')) then
    Result:=CBLAS.openblas_get_num_procs
  else if (SameText(ProcName,'GetConfig')) then
    Result:=Copy(CBLAS.openblas_get_config,1,MaxInt)
  else if (SameText(ProcName,'GetCorename')) then
    Result:=Copy(CBLAS.openblas_get_corename,1,MaxInt)
  else if (SameText(ProcName,'InstantiateMatrix')) then
    Result:=InstantiateMatrix(Args[0],Args[1])
  else if (SameText(ProcName,'FreeMatrix')) then
    FreeMatrix(Args[0])
  else if (SameText(ProcName,'ReadMatrixInfo')) then
    ReadMatrixInfo(Args[0], Args[1], Args[2])
  else if (SameText(ProcName,'ReadMatrix')) then
    Result:=ReadMatrix(Args[0], Args[1], Args[2])
  else if (SameText(ProcName,'WriteMatrix')) then
    WriteMatrix(Args[0],Args[1])
  else if (SameText(ProcName,'dgemm')) then
    Result:=dgemm(Args[0],Args[1],Args[2],Args[3],Args[4],Args[5],Args[6])
  else
    RaiseException('Proc "%s" unknown',[ProcName]);
end;

procedure LibInit(const ALibInterface: PLibInterface); cdecl;
begin
  LoadLibCBLAS(IncludeTrailingPathDelimiter(ALibInterface.ExecutionPath)+cDefaultLibCBLASdll);
  with ALibInterface^ do
    begin
      LibGUID:='{E458D5CF-8E01-4093-A20C-0EF47BB12605}';
      InvokeLibProc:=InvokeLibProcImpl;
    end;
  MatrixDict:=TDictionary<integer, TMatrixEntry>.Create;
end;

procedure LibFree(const ALibInterface: PLibInterface); cdecl;
begin
  FreeMatrixDict;
  FreeLibCBLAS;
end;

exports
  LibInit,
  LibFree;

begin
  MatrixDict:=nil;
  MatrixDictIndex:=0;
end.
