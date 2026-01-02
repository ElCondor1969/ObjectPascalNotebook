unit uSimpleCalculator;

interface

uses
  Classes;

type
  TSimpleCalculator=class(TObject)
  private
    FAccumulator: float;
    FOperation: string;
    FResult: float;
    function Calculate(Value: float): float;
  public
    constructor Create;
    procedure Reset;
    procedure InputNumber(Value: float);
    procedure InputOperation(Value: string);
    property Result: float read FResult;
  end;

implementation
{ TSimpleCalculator }

constructor TSimpleCalculator.Create;
begin
  Reset;
end;

procedure TSimpleCalculator.Reset;
begin
  FAccumulator:=0;
  FOperation:='';
  FResult:=0;
end;

procedure TSimpleCalculator.InputNumber(Value: float);
begin
  if (FOperation<>'') then
    begin
      FAccumulator:=Calculate(Value);
      FResult:=FAccumulator;
      FOperation:='';
    end
  else
    FAccumulator:=Value;
end;

procedure TSimpleCalculator.InputOperation(Value: string);
begin
  FOperation:=Value;
end;

function TSimpleCalculator.Calculate(Value: float): float;
begin
  case FOperation of
    '+': Result:=FAccumulator+Value;
    '-': Result:=FAccumulator-Value;
    '*': Result:=FAccumulator*Value;
    '/': Result:=FAccumulator/Value;
  else
    RaiseException('Invalid operation');
  end;
end;

end.
