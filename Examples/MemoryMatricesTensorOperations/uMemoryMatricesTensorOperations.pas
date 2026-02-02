unit uMemoryMatricesTensorOperations;

interface

uses 
  Classes, uBaseLibrary, uNeuralNetwork;

type
  TMemoryMatricesTensorOperations=class(TTensorOperations)
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
    function TensScale(const MM: TTensor; S: float): TTensor; override;
    function TensApply(const MM: TTensor; Act: TActivationFunction): TTensor; override;
    function TensDerivative(const MM: TTensor; Act: TActivationFunction): TTensor; override;
  end;

implementation

uses
  uMemoryMatrices;

type
  TMemoryMatricesTensorView=class(TTensorView)
  private
    FTensor: TTensor;
  protected
    function GetTensor: TTensor; override;
    procedure SetTensor(const Tensor: TTensor); override;
    function GetDims: array of integer; override;
  public
    constructor Create(const Tensor: TTensor); 
    function ReadData: TFloatArray; override;
    procedure WriteData(Data: TFloatArray); override;
  end;

{ TMemoryMatricesTensorView }

constructor TMemoryMatricesTensorView.Create(const Tensor: TTensor);
begin
  Self.Tensor:=Tensor;
end;

function TMemoryMatricesTensorView.GetTensor: TTensor;
begin
  Result:=FTensor;
end;

procedure TMemoryMatricesTensorView.SetTensor(const Tensor: TTensor);
begin
  if (FTensor<>0) then
    FreeMatrix(FTensor);
  FTensor:=Tensor;
end;

function TMemoryMatricesTensorView.GetDims: array of integer;
var
  NumRows, NumCols: integer;
begin
  ReadMatrixInfo(FTensor, NumRows, NumCols);
  Result:=[NumRows, NumCols];
end;

function TMemoryMatricesTensorView.ReadData: TFloatArray;
var
  NumRows, NumCols: integer;
begin
  ReadMatrixInfo(FTensor, NumRows, NumCols);
  var Data:=ReadMatrix(FTensor);
  for var k:=0 to NumRows-1 do
    for var Value in Data[k] do
      Result.Push(Value);
end;
    
procedure TMemoryMatricesTensorView.WriteData(Data: TFloatArray);
var
  NumRows, NumCols: integer;
  MatrixData: TArrayVariantArray;
begin
  ReadMatrixInfo(FTensor, NumRows, NumCols);
  MatrixData.SetLength(NumRows);
  for var k:=0 to NumRows-1 do
    MatrixData[k]:=Data.Copy(k*NumCols,NumCols);
  WriteMatrix(FTensor, MatrixData);
end;

{ TMemoryMatricesTensorOperations }

function TMemoryMatricesTensorOperations.InstantiateTensor(Dims: array of integer): TTensor;
begin
  // For now we manage up to matrix tensor.
  if (Dims.Length=0) or (Dims.Length>2) then
    RaiseException('Dimensions over the limits');
  
  Result:=InstantiateMatrix(Dims[0], Dims[1]);
end;

procedure TMemoryMatricesTensorOperations.FreeTensor(const Tensor: TTensor);
begin
  FreeMatrix(Tensor);
end;

function TMemoryMatricesTensorOperations.GetTensorView(const Tensor:TTensor): TTensorView;
begin
  Result:=new TMemoryMatricesTensorView(Tensor);
end;

procedure TMemoryMatricesTensorOperations.TensRandomize(const MM: TTensor; Bias: float);
begin
  RandomizeMatrix(MM, Bias);
end;

function TMemoryMatricesTensorOperations.TensMul(const AA, BB: TTensor): TTensor;
begin
  Result:=MulMatrices(AA, BB);
end;

function TMemoryMatricesTensorOperations.TensTranspose(const MM: TTensor): TTensor;
begin
  Result:=TransposeMatrix(MM);
end;

function TMemoryMatricesTensorOperations.TensAdd(const AA, BB: TTensor): TTensor;
begin
  Result:=AddMatrices(AA, BB);
end;

function TMemoryMatricesTensorOperations.TensSub(const AA, BB: TTensor): TTensor;
begin
  Result:=SubMatrices(AA, BB);
end;

function TMemoryMatricesTensorOperations.TensHadamard(const AA, BB: TTensor): TTensor;
begin
  Result:=HadamardMatrices(AA, BB);
end;

function TMemoryMatricesTensorOperations.TensScale(const MM: TTensor; S: float): TTensor;
begin
  Result:=ScaleMatrix(MM, S);
end;

function TMemoryMatricesTensorOperations.TensApply(const MM: TTensor; Act: TActivationFunction): TTensor;
var
  NumRows, NumCols: integer;
begin
  ReadMatrixInfo(MM, NumRows, NumCols);
  Result:=InstantiateMatrix(NumRows, NumCols);
  var Data:=ReadMatrix(MM);
  for var i := 0 to NumRows-1 do
    for var j := 0 to NumCols-1 do
      Data[i][j] := Act.Activate(Data[i][j]);
  WriteMatrix(Result, Data);
end;

function TMemoryMatricesTensorOperations.TensDerivative(const MM: TTensor; Act: TActivationFunction): TTensor;
var
  NumRows, NumCols: integer;
begin
  ReadMatrixInfo(MM, NumRows, NumCols);
  Result:=InstantiateMatrix(NumRows, NumCols);
  var Data:=ReadMatrix(MM);
  for var i := 0 to NumRows-1 do
    for var j := 0 to NumCols-1 do
      Data[i][j] := Act.Derivative(Data[i][j]);
  WriteMatrix(Result, Data);
end;

end.
