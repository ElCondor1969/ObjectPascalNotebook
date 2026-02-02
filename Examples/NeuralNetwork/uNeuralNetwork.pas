unit uNeuralNetwork;

interface

uses
  Classes, uBaseLibrary;

type
  TTensor = integer;

  TActivationFunction = class(TObject)
    function Activate(x: float): float; virtual; abstract;
    function Derivative(y: float): float; virtual; abstract;
  end;

  TTensorView=class(TObject)
  protected
    function GetTensor: TTensor; virtual; abstract;
    procedure SetTensor(const Tensor: TTensor); virtual; abstract;
    function GetDims: array of integer; virtual; abstract;
  public
    function ToOutput(BlockName: string=''): string;
    function ReadData: TFloatArray; virtual; abstract;
    procedure WriteData(Data: TFloatArray); virtual; abstract;
    property Tensor: TTensor read GetTensor write SetTensor;
    property Dims: array of integer read GetDims;
    // Coors -> [Row, Col]
    function GetValue(Data: TFloatArray; Coors: array of integer): float; 
    procedure SetValue(Data: TFloatArray; Coors: array of integer; Value: float); 
  end;

  TTensorOperations=class(TObject)
  public
    // [Number of rows, Number of columns, ...]
    function InstantiateTensor(Dims:array of integer):TTensor; virtual; abstract;
    procedure FreeTensor(const Tensor:TTensor); virtual; abstract;
    function GetTensorView(const Tensor:TTensor): TTensorView; virtual; abstract;
    procedure TensRandomize(const MM: TTensor; Bias: float=0.5); virtual; abstract;
    function TensMul(const AA, BB: TTensor): TTensor; virtual; abstract;
    function TensTranspose(const MM: TTensor): TTensor; virtual; abstract;
    function TensAdd(const AA, BB: TTensor): TTensor; virtual; abstract;
    function TensSub(const AA, BB: TTensor): TTensor; virtual; abstract;
    function TensHadamard(const AA, BB: TTensor): TTensor; virtual; abstract;
    function TensScale(const MM: TTensor; S: float): TTensor; virtual; abstract;
    function TensApply(const MM: TTensor; Act: TActivationFunction): TTensor; virtual; abstract;
    function TensDerivative(const MM: TTensor; Act: TActivationFunction): TTensor; virtual; abstract;
  end;

  TLayer = class(TObject)
  private
    FInputSize: integer;
    FOutputSize: integer;
    FActivation: TActivationFunction;
    FTensOp: TTensorOperations;
  protected
    W: TTensor;
    B: TTensor;
    A: TTensor;
    Delta: TTensor;
  public
    constructor Create(InputSize, OutputSize: Integer; Activation: TActivationFunction; TensOp: TTensorOperations);
    destructor Destroy; override;
    procedure Reset;
    function Forward(const Input: TTensor): TTensor;
  end;

  TNeuralNetwork = class;

  TNeuralLog = procedure(NN: TNeuralNetwork; const Msg: string; const Tensor: TTensor; TOP: TTensorOperations);

  TNeuralNetwork = class(TObject)
  private
    FActivation: TActivationFunction;
    FTensOp: TTensorOperations;
    FLayers: array of TLayer;
    FLearningRate: float;
    FLoss: float;
    FNeuralLog: TNeuralLog;
  public
    constructor Create(const InputSize: integer; const Sizes: array of Integer; Activation: TActivationFunction; TensOp: TTensorOperations; LearningRate: float);
    destructor Destroy; override;
    procedure SetNeuralLog(const NeuralLog: TNeuralLog);
    procedure AddLayers(const Sizes: array of Integer; Activation: TActivationFunction);
    function Predict(const Input: TTensor): TTensor;
    procedure Train(const Input, Target: TTensor);
    property Loss: float read FLoss;
  end;

  function DimsToString(Dims: array of integer): string;

implementation

function DimsToString(Dims: array of integer): string;
begin
  Result:=' ';
  for var k:=0 to High(Dims) do
    Result+=IntToStr(Dims[k]);
  Result:=Format('[%s]',[Result]);
end;

{ TTensorView }

function TTensorView.GetValue(Data: TFloatArray; Coors: array of integer): float; 
begin
  Result:=Data[(Coors[0]-1)*Dims[1]+(Coors[1]-1)];
end;

procedure TTensorView.SetValue(Data: TFloatArray; Coors: array of integer; Value: float);
begin
  Data[(Coors[0]-1)*Dims[1]+(Coors[1]-1)]:=Value;
end;

function TTensorView.ToOutput(BlockName: string=''): string;
begin
  var Data := ReadData;
  var Output:='<table style="border-collapse:collapse; text-align:center; border:1px solid black;">';
  for var k:=1 to Dims[0] do
    begin
      Output+='<tr>';
      for var j:=1 to Dims[1] do
        Output+=Format('<td style="padding:8px; border:1px solid black;">%g</td>',[GetValue(Data,[k,j])]);
      Output+='</tr>';
    end;
  Output+='</table>';
  Result:=TConsole.WriteBlock(Output,BlockName);
end;

{ TLayer }

constructor TLayer.Create(InputSize, OutputSize: Integer; Activation: TActivationFunction; TensOp: TTensorOperations);
begin
  FInputSize := InputSize;
  FOutputSize := OutputSize;
  FActivation := Activation;
  FTensOp := TensOp;
  W:=FTensOp.InstantiateTensor([OutputSize, InputSize]);
  B:=FTensOp.InstantiateTensor([OutputSize, 1]);
  Reset;
end;

destructor TLayer.Destroy;
begin
  FTensOp.FreeTensor(W);
  FTensOp.FreeTensor(B);
  FTensOp.FreeTensor(A);
  FTensOp.FreeTensor(Delta);
  inherited;
end;

procedure TLayer.Reset;
begin
  FTensOp.TensRandomize(B);
  FTensOp.TensRandomize(W);
end;

function TLayer.Forward(const Input: TTensor): TTensor;
var Z1, Z2: TTensor;
begin
  Z1 := -1;
  Z2 := -1;
  try
    Z1 := FTensOp.TensMul(W, Input);
    Z2 := FTensOp.TensAdd(Z1, B);
    FTensOp.FreeTensor(A);
    A := FTensOp.TensApply(Z2, FActivation);
    Result := A;
  finally
    FTensOp.FreeTensor(Z1);
    FTensOp.FreeTensor(Z2);
  end;
end;

{ TNeuralNetwork }

constructor TNeuralNetwork.Create(const InputSize: integer; const Sizes: array of Integer; Activation: TActivationFunction; TensOp: TTensorOperations; LearningRate: float);
begin
  FActivation := Activation;
  FTensOp := TensOp;
  FLearningRate := LearningRate;
  FLayers.Push(new TLayer(InputSize, Sizes[0], Activation, FTensOp));
  if (Length(Sizes)>1) then
    AddLayers(Sizes.Copy(1), Activation);
end;

destructor TNeuralNetwork.Destroy;
var
  k: integer;
begin
  for k:=0 to High(FLayers) do
    FLayers[k]:=nil;
  FLayers.Clear;
  inherited;
end;

procedure TNeuralNetwork.SetNeuralLog(const NeuralLog: TNeuralLog);
begin
  FNeuralLog := NeuralLog;
end;

procedure TNeuralNetwork.AddLayers(const Sizes: array of Integer; Activation: TActivationFunction);
var
  i: integer;
  LastLayer: TLayer;
begin
  LastLayer:=FLayers[High(FLayers)];
  for i := 0 to High(Sizes) do
    begin
      LastLayer:=new TLayer(LastLayer.FOutputSize, Sizes[i], Activation, FTensOp);
      FLayers.Push(LastLayer);
    end;
end;

function TNeuralNetwork.Predict(const Input: TTensor): TTensor;
var
  i: Integer;
begin
  Result := Input;
  for i := 0 to High(FLayers) do
    begin
      Result := FLayers[i].Forward(Result);
      if Assigned(FNeuralLog) then
        FNeuralLog(Self, 'Output layer '+IntToStr(i), Result, FTensOp);
    end;
end;

procedure TNeuralNetwork.Train(const Input, Target: TTensor);
var
  L, i: Integer;
  PrevA, Z1, Z2, Z3, Z4: TTensor;
begin
  Predict(Input);
  L := High(FLayers);
  Z1 := -1; 
  Z2 := -1; 
  try
    Z1 := FTensOp.TensSub(Target, FLayers[L].A);
    FLoss:=0;
    for var Value in FTensOp.GetTensorView(Z1).ReadData do
      FLoss+=Sqr(Value); 
    Z2 := FTensOp.TensDerivative(FLayers[L].A, FLayers[L].FActivation);
    FTensOp.FreeTensor(FLayers[L].Delta);
    FLayers[L].Delta := FTensOp.TensHadamard(Z1,Z2);
    if Assigned(FNeuralLog) then
      FNeuralLog(Self, 'Delta layer  '+IntToStr(L), FLayers[L].Delta, FTensOp);
  finally
    FTensOp.FreeTensor(Z1);
    FTensOp.FreeTensor(Z2);
  end;

  for i := L-1 downto 0 do
    try
      Z1 := -1;
      Z2 := -1;
      Z3 := -1;
      Z1 := FTensOp.TensTranspose(FLayers[i+1].W);
      Z2 := FTensOp.TensMul(Z1, FLayers[i+1].Delta);
      Z3 := FTensOp.TensDerivative(FLayers[i].A, FLayers[i].FActivation);
      FTensOp.FreeTensor(FLayers[i].Delta);
      FLayers[i].Delta := FTensOp.TensHadamard(Z2,Z3);
      if Assigned(FNeuralLog) then
        FNeuralLog(Self, 'Delta layer '+IntToStr(i), FLayers[i].Delta, FTensOp);
    finally
      FTensOp.FreeTensor(Z1);
      FTensOp.FreeTensor(Z2);
      FTensOp.FreeTensor(Z3);
    end;

  for i := 0 to L do
    begin
      if i = 0 then
        PrevA := Input
      else
        PrevA := FLayers[i - 1].A;

      try
        Z1 := -1;
        Z2 := -1;
        Z3 := -1;
        Z4 := -1;
        Z1 := FTensOp.TensTranspose(PrevA);
        Z2 := FTensOp.TensMul(FLayers[i].Delta, Z1);
        Z3 := FTensOp.TensScale(Z2, FLearningRate);
        Z4 := FTensOp.TensAdd(FLayers[i].W, Z3);
        FTensOp.FreeTensor(FLayers[i].W);
        FLayers[i].W := Z4;
        if Assigned(FNeuralLog) then
          FNeuralLog(Self, 'Weights layer '+IntToStr(i), FLayers[i].W, FTensOp);
      finally
        FTensOp.FreeTensor(Z1);
        FTensOp.FreeTensor(Z2);
        FTensOp.FreeTensor(Z3);
      end;

      try
        Z1 := -1;
        Z2 := -1;
        Z1 := FTensOp.TensScale(FLayers[i].Delta, FLearningRate);
        Z2 := FTensOp.TensAdd(FLayers[i].B, Z1);
        FTensOp.FreeTensor(FLayers[i].B);
        FLayers[i].B := Z2;
        if Assigned(FNeuralLog) then
          FNeuralLog(Self, 'Bias layer '+IntToStr(i), FLayers[i].B, FTensOp);
      finally
        FTensOp.FreeTensor(Z1);
      end;
    end;
end;

initialization
  Randomize;
end.
