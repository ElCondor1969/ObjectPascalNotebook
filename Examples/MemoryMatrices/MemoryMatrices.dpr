library MemoryMatrices;

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

function InstantiateMatrix(RowsNum, ColsNum: integer; Initialize:boolean=false; Value: double=0):integer;
var
  k: integer;
  Found: boolean;
  MatrixEntry: TMatrixEntry;
begin
  Found:=false;
  for k in MatrixDict.Keys.ToArray do
    begin
      MatrixEntry:=MatrixDict[k];
      if MatrixEntry.Freed and (MatrixEntry.RowsNum=RowsNum) and (MatrixEntry.ColsNum=ColsNum) then
        begin
          MatrixEntry.Freed:=false;
          MatrixDict.AddOrSetValue(k, MatrixEntry);
          Result:=k;
          Found:=true;
          Break;
        end;
    end;
  if (not(Found)) then
    begin
      MatrixEntry.Freed:=false;
      MatrixEntry.RowsNum:=RowsNum;
      MatrixEntry.ColsNum:=ColsNum;
      SetLength(MatrixEntry.Matrix, RowsNum*ColsNum);
      Inc(MatrixDictIndex);
      MatrixDict.AddOrSetValue(MatrixDictIndex, MatrixEntry);
      Result:=MatrixDictIndex;
    end;
  if (Initialize) then
    for k:=0 to High(MatrixEntry.Matrix) do
      MatrixEntry.Matrix[k]:=Value;
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

procedure RandomizeMatrix(const MatrixHandle: integer; Bias: double);
var
  k: integer;
  MatrixEntry: TMatrixEntry;
begin
  if MatrixDict.TryGetValue(MatrixHandle,MatrixEntry) then
    for k:=0 to High(MatrixEntry.Matrix) do
      MatrixEntry.Matrix[k]:=Random-Bias
  else
    RaiseException('Matrix not found');
end;

function MulMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
var
  i, h, k, Idx, Idx1: integer;
  MatrixEntryA, MatrixEntryB, MatrixEntryC: TMatrixEntry;
begin
  if not MatrixDict.TryGetValue(MatrixHandleA,MatrixEntryA) then
    RaiseException('Matrix A not found');
  if not MatrixDict.TryGetValue(MatrixHandleB,MatrixEntryB) then
    RaiseException('Matrix B not found');
  if (MatrixEntryA.ColsNum<>MatrixEntryB.RowsNum) then
    RaiseException('The matrix dimensions are not compatible with the operation');
  Result:=InstantiateMatrix(MatrixEntryA.RowsNum,MatrixEntryB.ColsNum);
  MatrixEntryC:=MatrixDict[Result];
  for k:=0 to MatrixEntryA.RowsNum-1 do
    for h:=0 to MatrixEntryB.ColsNum-1 do
      begin
        Idx:=k*MatrixEntryC.ColsNum+h;
        Idx1:=k*MatrixEntryA.ColsNum;
        MatrixEntryC.Matrix[Idx]:=0;
        for i:=0 to MatrixEntryA.ColsNum-1 do
          MatrixEntryC.Matrix[Idx]:=
            MatrixEntryC.Matrix[Idx]+
            MatrixEntryA.Matrix[Idx1+i]*
            MatrixEntryB.Matrix[i*MatrixEntryB.ColsNum+h];
      end;
end;

function TransposeMatrix(const MatrixHandle: integer): integer;
var
  k, h: integer;
  MatrixEntry, MatrixEntryR: TMatrixEntry;
begin
  if MatrixDict.TryGetValue(MatrixHandle,MatrixEntry) then
    begin
      Result:=InstantiateMatrix(MatrixEntry.ColsNum,MatrixEntry.RowsNum);
      MatrixEntryR:=MatrixDict[Result];
      for k:=0 to MatrixEntry.RowsNum-1 do
        for h:=0 to MatrixEntry.ColsNum-1 do
          MatrixEntryR.Matrix[h*MatrixEntryR.ColsNum+k]:=MatrixEntry.Matrix[k*MatrixEntry.ColsNum+h];
    end
  else
    RaiseException('Matrix not found');
end;

function AddMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
var
  h, k, Idx: integer;
  MatrixEntryA, MatrixEntryB, MatrixEntryC: TMatrixEntry;
begin
  if not MatrixDict.TryGetValue(MatrixHandleA,MatrixEntryA) then
    RaiseException('Matrix A not found');
  if not MatrixDict.TryGetValue(MatrixHandleB,MatrixEntryB) then
    RaiseException('Matrix B not found');
  if ((MatrixEntryA.RowsNum<>MatrixEntryB.RowsNum) or
      (MatrixEntryA.ColsNum<>MatrixEntryB.ColsNum)) then
    RaiseException('The matrix dimensions are not compatible with the operation');
  Result:=InstantiateMatrix(MatrixEntryA.RowsNum,MatrixEntryB.ColsNum);
  MatrixEntryC:=MatrixDict[Result];
  for k:=0 to MatrixEntryA.RowsNum-1 do
    begin
      Idx:=k*MatrixEntryA.ColsNum;
      for h:=0 to MatrixEntryA.ColsNum-1 do
        MatrixEntryC.Matrix[Idx+h]:=
          MatrixEntryA.Matrix[Idx+h]+
          MatrixEntryB.Matrix[Idx+h];
    end;
end;

function SubMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
var
  h, k, Idx: integer;
  MatrixEntryA, MatrixEntryB, MatrixEntryC: TMatrixEntry;
begin
  if not MatrixDict.TryGetValue(MatrixHandleA,MatrixEntryA) then
    RaiseException('Matrix A not found');
  if not MatrixDict.TryGetValue(MatrixHandleB,MatrixEntryB) then
    RaiseException('Matrix B not found');
  if ((MatrixEntryA.RowsNum<>MatrixEntryB.RowsNum) or
      (MatrixEntryA.ColsNum<>MatrixEntryB.ColsNum)) then
    RaiseException('The matrix dimensions are not compatible with the operation');
  Result:=InstantiateMatrix(MatrixEntryA.RowsNum,MatrixEntryB.ColsNum);
  MatrixEntryC:=MatrixDict[Result];
  for k:=0 to MatrixEntryA.RowsNum-1 do
    begin
      Idx:=k*MatrixEntryA.ColsNum;
      for h:=0 to MatrixEntryA.ColsNum-1 do
        MatrixEntryC.Matrix[Idx+h]:=
          MatrixEntryA.Matrix[Idx+h]-
          MatrixEntryB.Matrix[Idx+h];
    end;
end;

function HadamardMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
var
  h, k, Idx: integer;
  MatrixEntryA, MatrixEntryB, MatrixEntryC: TMatrixEntry;
begin
  if not MatrixDict.TryGetValue(MatrixHandleA,MatrixEntryA) then
    RaiseException('Matrix A not found');
  if not MatrixDict.TryGetValue(MatrixHandleB,MatrixEntryB) then
    RaiseException('Matrix B not found');
  if ((MatrixEntryA.RowsNum<>MatrixEntryB.RowsNum) or
      (MatrixEntryA.ColsNum<>MatrixEntryB.ColsNum)) then
    RaiseException('The matrix dimensions are not compatible with the operation');
  Result:=InstantiateMatrix(MatrixEntryA.RowsNum,MatrixEntryB.ColsNum);
  MatrixEntryC:=MatrixDict[Result];
  for k:=0 to MatrixEntryA.RowsNum-1 do
    begin
      Idx:=k*MatrixEntryA.ColsNum;
      for h:=0 to MatrixEntryA.ColsNum-1 do
        MatrixEntryC.Matrix[Idx+h]:=
          MatrixEntryA.Matrix[Idx+h]*
          MatrixEntryB.Matrix[Idx+h];
    end;
end;

function ScaleMatrix(const MatrixHandle: integer; S: double): integer;
var
  k: integer;
  MatrixEntry, MatrixEntryR: TMatrixEntry;
begin
  if MatrixDict.TryGetValue(MatrixHandle,MatrixEntry) then
    begin
      Result:=InstantiateMatrix(MatrixEntry.RowsNum,MatrixEntry.ColsNum);
      MatrixEntryR:=MatrixDict[Result];
      for k:=0 to High(MatrixEntryR.Matrix) do
        MatrixEntryR.Matrix[k]:=MatrixEntry.Matrix[k]*S;
    end
  else
    RaiseException('Matrix not found');
end;

function InvokeLibProcImpl(Context, Instance: NativeInt; const ProcName: PChar; var Args:array of variant): Variant; cdecl;
begin
  if (SameText(ProcName,'InstantiateMatrix')) then
    Result:=InstantiateMatrix(Args[0],Args[1],Args[2],Args[3])
  else if (SameText(ProcName,'FreeMatrix')) then
    FreeMatrix(Args[0])
  else if (SameText(ProcName,'ReadMatrixInfo')) then
    ReadMatrixInfo(Args[0], Args[1], Args[2])
  else if (SameText(ProcName,'ReadMatrix')) then
    Result:=ReadMatrix(Args[0], Args[1], Args[2])
  else if (SameText(ProcName,'WriteMatrix')) then
    WriteMatrix(Args[0],Args[1])
  else if (SameText(ProcName,'RandomizeMatrix')) then
    RandomizeMatrix(Args[0],Args[1])
  else if (SameText(ProcName,'MulMatrices')) then
    Result:=MulMatrices(Args[0],Args[1])
  else if (SameText(ProcName,'TransposeMatrix')) then
    Result:=TransposeMatrix(Args[0])
  else if (SameText(ProcName,'AddMatrices')) then
    Result:=AddMatrices(Args[0],Args[1])
  else if (SameText(ProcName,'SubMatrices')) then
    Result:=SubMatrices(Args[0],Args[1])
  else if (SameText(ProcName,'HadamardMatrices')) then
    Result:=HadamardMatrices(Args[0],Args[1])
  else if (SameText(ProcName,'ScaleMatrix')) then
    Result:=ScaleMatrix(Args[0],Args[1])
  else
    RaiseException('Proc "%s" unknown',[ProcName]);
end;

procedure LibInit(const ALibInterface: PLibInterface); cdecl;
begin
  with ALibInterface^ do
    begin
      LibGUID:='{2970D979-84FB-4B42-B730-F596BEC20E2F}';
      InvokeLibProc:=InvokeLibProcImpl;
    end;
  MatrixDict:=TDictionary<integer, TMatrixEntry>.Create;
end;

procedure LibFree(const ALibInterface: PLibInterface); cdecl;
begin
  FreeMatrixDict;
end;

exports
  LibInit,
  LibFree;

begin
  Randomize;
  MatrixDict:=nil;
  MatrixDictIndex:=0;
end.
