unit uActivationFunctions;

interface

uses Classes, uNeuralNetwork;

type
  TSigmoidActivation = class(TActivationFunction)
  public
    function Activate(x: float): float; override;
    function Derivative(y: float): float; override;
  end;

implementation

{ TSigmoidActivation }

function TSigmoidActivation.Activate(x: float): float;
begin
  Result := 1.0 / (1.0 + Exp(-x));
end;

function TSigmoidActivation.Derivative(y: float): float;
begin
  Result := y * (1.0 - y);
end;

end.
