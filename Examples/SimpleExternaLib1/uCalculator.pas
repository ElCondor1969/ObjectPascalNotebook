unit uCalculator;

interface

uses
  Classes;

type
  TCalculator=class(TObject)
  private
    FMemory: double;
  public
    function Add(Value1,Value2:double):double;
    function Mul(Value1,Value2:double):double;
    function GetMemory:double;
    procedure SetMemory(Value: double);
  end;

implementation

{ TCalculator }

function TCalculator.Add(Value1, Value2: double): double;
begin
  Result:=Value1 + Value2;
end;

function TCalculator.GetMemory: double;
begin
  Result:= FMemory;
end;

function TCalculator.Mul(Value1, Value2: double): double;
begin
  Result:=Value1 * Value2;
end;

procedure TCalculator.SetMemory(Value: double);
begin
  FMemory:= Value;
end;

end.
