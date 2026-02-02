unit uOpenBLASLib;

interface

uses
  Classes, uBaseLibrary;

procedure SetNumThreads(num_threads: integer); 
function GetNumThreads: integer; 
function GetNumProcs: integer; 
function GetConfig: string; 
function GetCorename: string;
function InstantiateMatrix(const NumRows, NumCols: integer): integer;
procedure FreeMatrix(const MatrixHandle: integer);
procedure ReadMatrixInfo(const MatrixHandle: integer; var NumRows, NumCols: integer);
function ReadMatrix(const MatrixHandle: integer): TArrayVariantArray;
procedure WriteMatrix(const MatrixHandle: integer; Data: TArrayVariantArray);
function dgemm(MatrixA, MatrixB, MatrixC: integer; 
               Alpha: float = 1; Beta: float = 0; TransposeA, TransposeB: boolean = false): integer;

implementation

const
  LibGUID='{E458D5CF-8E01-4093-A20C-0EF47BB12605}';

procedure SetNumThreads(num_threads: integer);
var
  Args: TVariantArray;
begin
  Args.Push(num_threads);
  __LibInterface_InvokeLibProc(LibGUID,0,'SetNumThreads',Args);
end;

function GetNumThreads: integer;
var
  Args: TVariantArray;
begin
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'GetNumThreads',Args);
end;

function GetNumProcs: integer;
var
  Args: TVariantArray;
begin
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'GetNumProcs',Args);
end;

function GetConfig: string;
var
  Args: TVariantArray;
begin
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'GetConfig',Args);
end;

function GetCorename: string;
var
  Args: TVariantArray;
begin
  Result:=__LibInterface_InvokeLibProc(LibGUID,0,'GetCorename',Args);
end;

function InstantiateMatrix(const NumRows, NumCols: integer):integer;
var
  Args: TVariantArray;
begin
  Args.Push(NumRows);
  Args.Push(NumCols);
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

function dgemm(MatrixA, MatrixB, MatrixC: integer; Alpha, Beta: float; TransposeA, TransposeB: boolean): integer;
var
  Args: TVariantArray;
begin
  Args.Push(MatrixA);
  Args.Push(MatrixB);
  Args.Push(MatrixC);
  Args.Push(Alpha);
  Args.Push(Beta);
  Args.Push(TransposeA);
  Args.Push(TransposeB);
  Result:=__LibInterface_InvokeLibProc(LibGUID, 0, 'dgemm', Args);  
end;

end.
