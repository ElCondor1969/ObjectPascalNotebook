unit uMemoryMatrices;

interface

uses
  Classes, uBaseLibrary;

function InstantiateMatrix(const NumRows, NumCols: integer; Initialize:boolean=false; Value: float=0): integer;
procedure FreeMatrix(const MatrixHandle: integer);
procedure ReadMatrixInfo(const MatrixHandle: integer; var NumRows, NumCols: integer);
function ReadMatrix(const MatrixHandle: integer): TArrayVariantArray;
procedure WriteMatrix(const MatrixHandle: integer; Data: TArrayVariantArray);
procedure RandomizeMatrix(const MatrixHandle: integer; Bias: float=0.5);
function MulMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
function TransposeMatrix(const MatrixHandle: integer): integer;
function AddMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
function SubMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
function HadamardMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
function ScaleMatrix(const MatrixHandle: integer; S: float): integer;
implementation

const
  LibGUID='{2970D979-84FB-4B42-B730-F596BEC20E2F}';

function InstantiateMatrix(const NumRows, NumCols: integer; Initialize:boolean; Value: float):integer;
var
  Args: TVariantArray;
begin
  Args.Push(NumRows);
  Args.Push(NumCols);
  Args.Push(Initialize);
  Args.Push(Value);
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'InstantiateMatrix',Args);
end;

procedure FreeMatrix(const MatrixHandle: integer);
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandle);
  __LibInterface_InvokeLibProc(LibGUID,0,'FreeMatrix',Args);
end;

procedure ReadMatrixInfo(const MatrixHandle: integer; var NumRows, NumCols: integer);
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandle);
  Args.Push(0);
  Args.Push(0);
  __LibInterface_InvokeLibProc(LibGUID, 0, 'ReadMatrixInfo', Args);
  NumRows:=Args[1];
  NumCols:=Args[2];
end;

function ReadMatrix(const MatrixHandle: integer): TArrayVariantArray;
var Value: TVariantArray;
    k, RowsNum, ColsNum: integer;
    Args: TVariantArray;
begin
  Args.Push(MatrixHandle);
  Args.Push(0);
  Args.Push(0);
  Value:=__VariantToArray(__LibInterface_InvokeLibProc(LibGUID, 0, 'ReadMatrix', Args)).Map(VarToFloat);
  RowsNum:=Args[1];
  ColsNum:=Args[2];
  for k:=0 to RowsNum-1 do
    Result.Push(Value.Copy(k*ColsNum,ColsNum));
end;

procedure WriteMatrix(const MatrixHandle: integer; Data: TArrayVariantArray);
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandle);
  Args.Push(__ArrayToVariant(__ArrayVariantArrayToVariantArray(Data)));
  __LibInterface_InvokeLibProc(LibGUID, 0, 'WriteMatrix' , Args);
end;

procedure RandomizeMatrix(const MatrixHandle: integer; Bias: float=0.5);
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandle);
  Args.Push(Bias);
  __LibInterface_InvokeLibProc(LibGUID, 0, 'RandomizeMatrix', Args);
end;

function MulMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandleA);
  Args.Push(MatrixHandleB);
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'MulMatrices',Args);
end;

function TransposeMatrix(const MatrixHandle: integer): integer;
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandle);
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'TransposeMatrix',Args);
end;

function AddMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandleA);
  Args.Push(MatrixHandleB);
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'AddMatrices',Args);
end;

function SubMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandleA);
  Args.Push(MatrixHandleB);
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'SubMatrices',Args);
end;

function HadamardMatrices(const MatrixHandleA, MatrixHandleB: integer): integer;
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandleA);
  Args.Push(MatrixHandleB);
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'HadamardMatrices',Args);
end;

function ScaleMatrix(const MatrixHandle: integer; S: float): integer;
var
  Args: TVariantArray;
begin
  Args.Push(MatrixHandle);
  Args.Push(S);
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'ScaleMatrix',Args);
end;

end.
