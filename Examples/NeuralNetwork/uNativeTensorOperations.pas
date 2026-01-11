unit uNativeTensorOperations;

interface

uses 
  Classes, uBaseLibrary, uNeuralNetwork;

type
  TNativeTensorOperations=class(TTensorOperations)
  public
    function InstantiateTensor(Dims:array of integer):TTensor; override;
    procedure FreeTensor(const Tensor:TTensor); override;
    function GetTensorView(const Tensor:TTensor): TTensorView; override;
    procedure TensRandomize(const MM: TTensor; Bias: float=0.5); override;
    function TensMul(const AA, BB: TTensor): TTensor; override;
    function TensTranspose(const MM: TTensor): TTensor; override;
    function TensAdd(const AA, BB: TTensor): TTensor; override;
    function TensSub(const AA, BB: TTensor): TTensor; override;
    function TensHadamard(const AA, BB: TTensor): TTensor; override;
    function TensScale(const MM: TTensor; S: Double): TTensor; override;
    function TensApply(const MM: TTensor; Act: TActivationFunction): TTensor; override;
    function TensDerivative(const MM: TTensor; Act: TActivationFunction): TTensor; override;
  end;

implementation

type
  TMatrix=array of array of float;

  TMatrixEntry=record
    Freed: boolean;
    Dims: array of integer;
    Matrix: TMatrix
  end;

  TMatrixDict=array [integer] of TMatrixEntry;

  TNativeTensorView=class(TTensorView)
  private
    FTensor: TTensor;
  protected
    function GetTensor: TTensor; override;
    procedure SetTensor(const Tensor: TTensor); override;
    function GetDims: array of integer; override;
    function GetValue(Coors: array of integer): float; override;
    procedure SetValue(Coors: array of integer; Value: float); override;
  public
    constructor Create(const Tensor: TTensor); 
  end;

var
  MatrixDict: TMatrixDict;
  DictIndex: integer:=0;

function SameDims(Dims1, Dims2: array of integer): boolean;
begin
  Result:=(Length(Dims1)=Length(Dims2));
  if (Result) then
    for var k:=0 to High(Dims1) do
      if (Dims1[k]<>Dims2[k]) then
        begin
          Result:=false;
          Exit;
        end;
end;

{ TNativeTensorView }

constructor TNativeTensorView.Create(const Tensor: TTensor);
begin
  Self.Tensor:=Tensor;
end;

function TNativeTensorView.GetTensor: TTensor;
begin
  Result:=FTensor;
end;

procedure TNativeTensorView.SetTensor(const Tensor: TTensor);
begin
  if (FTensor<>0) then
    begin
      var MatrixEntry:=MatrixDict[FTensor]; 
      MatrixEntry.Freed:=true;
      MatrixDict[FTensor]:=MatrixEntry;
    end;
  if (Tensor<>0) then
    FTensor:=Tensor;
end;

function TNativeTensorView.GetDims: array of integer;
begin
  Result:=MatrixDict[FTensor].Dims;
end;

function TNativeTensorView.GetValue(Coors: array of integer): float;
begin
  Result:=MatrixDict[FTensor].Matrix[Coors[0]-1][Coors[1]-1];
end;

procedure TNativeTensorView.SetValue(Coors: array of integer; Value: float);
begin
  MatrixDict[FTensor].Matrix[Coors[0]-1][Coors[1]-1]:=Value;
end;

{ TNativeTensorOperations }

function TNativeTensorOperations.InstantiateTensor(Dims: array of integer): TTensor;
var Matrix: TMatrix;
    MatrixEntry: TMatrixEntry;
begin
  // For now we manage up to matrix tensor.
  if (Dims.Length=0) or (Dims.Length>2) then
    RaiseException('Dimensions over the limits');
  
  for var k:=0 to High(MatrixDict.Keys) do
    begin
      var Idx:=MatrixDict.Keys[k];
      MatrixEntry:=MatrixDict[Idx];
      if MatrixEntry.Freed and SameDims(MatrixEntry.Dims,Dims) then
        begin
          MatrixEntry.Freed:=false;
          MatrixDict[Idx]:=MatrixEntry;
          Result:=Idx;
          Exit;
        end;
    end;

  Result:=DictIndex;
  DictIndex+=1;
  Matrix.SetLength(Dims[0]);
  for var k:=0 to Dims[0]-1 do
    Matrix[k].SetLength(Dims[1]);
  MatrixEntry.Freed:=false;
  MatrixEntry.Dims:=Dims.Copy;
  MatrixEntry.Matrix:=Matrix;
  MatrixDict[Result]:=MatrixEntry;
end;

procedure TNativeTensorOperations.FreeTensor(const Tensor: TTensor);
var MatrixEntry: TMatrixEntry;
begin
  if (Tensor<>0) then
    begin
      MatrixEntry:=MatrixDict[Tensor];
      MatrixEntry.Freed:=true;
      MatrixDict[Tensor]:=MatrixEntry;
    end;
end;

function TNativeTensorOperations.GetTensorView(const Tensor:TTensor): TTensorView;
begin
  Result:=new TNativeTensorView(Tensor);
end;

procedure TNativeTensorOperations.TensRandomize(const MM: TTensor; Bias: float);
var
  i, j: Integer;
  M: TMatrix;
begin
  M:=MatrixDict[MM].Matrix;
  for i := 0 to High(M) do
    for j := 0 to High(M[i]) do
      M[i][j] := Random-Bias;
end;

function TNativeTensorOperations.TensMul(const AA, BB: TTensor): TTensor;
var
  i, j, k: Integer;
  A, B, R: TMatrix;
begin
  A:=MatrixDict[AA].Matrix;
  B:=MatrixDict[BB].Matrix;
  if (Length(A[0])<>Length(B)) then
    RaiseException('Multiplication impossible by tensor''s dimensions');
  Result:=InstantiateTensor([Length(A), Length(B[0])]);
  R:=MatrixDict[Result].Matrix;
  for i := 0 to High(A) do
    for j := 0 to High(B[0]) do
      begin
        R[i][j] := 0;
        for k := 0 to High(B) do
          R[i][j] := R[i][j] + A[i][k] * B[k][j];
      end;
end;

function TNativeTensorOperations.TensTranspose(const MM: TTensor): TTensor;
var
  i, j: Integer;
  M, R: TMatrix;
begin
  M:=MatrixDict[MM].Matrix;
  Result:=InstantiateTensor([Length(M[0]), Length(M)]);
  R:=MatrixDict[Result].Matrix;
  for i := 0 to High(M) do
    for j := 0 to High(M[i]) do
      R[j][i] := M[i][j];
end;

function TNativeTensorOperations.TensAdd(const AA, BB: TTensor): TTensor;
var
  i, j: Integer;
  A, B, R: TMatrix;
begin
  A:=MatrixDict[AA].Matrix;
  B:=MatrixDict[BB].Matrix;
  Result:=InstantiateTensor([Length(A), Length(A[0])]);
  R:=MatrixDict[Result].Matrix;
  for i := 0 to High(A) do
    for j := 0 to High(A[i]) do
      R[i][j] := A[i][j] + B[i][j];
end;

function TNativeTensorOperations.TensSub(const AA, BB: TTensor): TTensor;
var
  i, j: Integer;
  A, B, R: TMatrix;
begin
  A:=MatrixDict[AA].Matrix;
  B:=MatrixDict[BB].Matrix;
  Result:=InstantiateTensor([Length(A), Length(A[0])]);
  R:=MatrixDict[Result].Matrix;
  for i := 0 to High(A) do
    for j := 0 to High(A[i]) do
      R[i][j] := A[i][j] - B[i][j];
end;

function TNativeTensorOperations.TensHadamard(const AA, BB: TTensor): TTensor;
var
  i, j: Integer;
  A, B, R: TMatrix;
begin
  A:=MatrixDict[AA].Matrix;
  B:=MatrixDict[BB].Matrix;
  Result:=InstantiateTensor([Length(A), Length(A[0])]);
  R:=MatrixDict[Result].Matrix;
  for i := 0 to High(A) do
    for j := 0 to High(A[i]) do
      R[i][j] := A[i][j] * B[i][j];
end;

function TNativeTensorOperations.TensScale(const MM: TTensor; S: Double): TTensor;
var
  i, j: Integer;
  M, R: TMatrix;
begin
  M:=MatrixDict[MM].Matrix;
  Result:=InstantiateTensor([Length(M), Length(M[0])]);
  R:=MatrixDict[Result].Matrix;
  for i := 0 to High(M) do
    for j := 0 to High(M[i]) do
      R[i][j] := M[i][j] * S;
end;

function TNativeTensorOperations.TensApply(const MM: TTensor; Act: TActivationFunction): TTensor;
var
  i, j: Integer;
  M, R: TMatrix;
begin
  M:=MatrixDict[MM].Matrix;
  Result:=InstantiateTensor([Length(M), Length(M[0])]);
  R:=MatrixDict[Result].Matrix;
  for i := 0 to High(M) do
    for j := 0 to High(M[i]) do
      R[i][j] := Act.Activate(M[i][j]);
end;

function TNativeTensorOperations.TensDerivative(const MM: TTensor; Act: TActivationFunction): TTensor;
var
  i, j: Integer;
  M, R: TMatrix;
begin
  M:=MatrixDict[MM].Matrix;
  Result:=InstantiateTensor([Length(M), Length(M[0])]);
  R:=MatrixDict[Result].Matrix;
  for i := 0 to High(M) do
    for j := 0 to High(M[i]) do
      R[i][j] := Act.Derivative(M[i][j]);
end;

end.
