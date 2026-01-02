library SimpleCalculator;

uses
  System.SysUtils,
  System.JSON,
  System.Classes,
  System.StrUtils,
  uLibInterface,
  uUnitBuilder,
  uUtility,
  uCalculator in 'uCalculator.pas';

{$R *.res}

(*
function GetUnitCalculatorDefinition: string;
var Definition, ClassDef, Method, Parameter: TJSONObject;
    Classes, Methods, Parameters: TJSONArray;
begin
  Definition:=TJSONObject.Create;
  try
    Classes:=WriteJSONValue(Definition,'Classes',TJSONArray.Create);

    // TCalculator
    ClassDef:=AddJSONElement(Classes,TJSONObject.Create);
    WriteJSONValue(ClassDef,'Name','TCalculator');
    WriteJSONValue(ClassDef,'QualifiedName','uCalculator.TCalculator');
    
    // Methods
    Methods:=WriteJSONValue(ClassDef,'Methods',TJSONArray.Create);

    // Add
    Method:=AddJSONElement(Methods,TJSONObject.Create);
    WriteJSONValue(Method,'Kind','function');
    WriteJSONValue(Method,'Name','Add');
    WriteJSONValue(Method,'ReturnType','float');
    Parameters:=WriteJSONValue(Method,'Parameters',TJSONArray.Create);
    Parameter:=AddJSONElement(Parameters,TJSONObject.Create);
    WriteJSONValue(Parameter,'Kind','');
    WriteJSONValue(Parameter,'Name','Value1');
    WriteJSONValue(Parameter,'Type','float');
    Parameter:=AddJSONElement(Parameters,TJSONObject.Create);
    WriteJSONValue(Parameter,'Kind','');
    WriteJSONValue(Parameter,'Name','Value2');
    WriteJSONValue(Parameter,'Type','float');

    // Mul
    Method:=AddJSONElement(Methods,TJSONObject.Create);
    WriteJSONValue(Method,'Kind','function');
    WriteJSONValue(Method,'Name','Mul');
    WriteJSONValue(Method,'ReturnType','float');
    Parameters:=WriteJSONValue(Method,'Parameters',TJSONArray.Create);
    Parameter:=AddJSONElement(Parameters,TJSONObject.Create);
    WriteJSONValue(Parameter,'Kind','');
    WriteJSONValue(Parameter,'Name','Value1');
    WriteJSONValue(Parameter,'Type','float');
    Parameter:=AddJSONElement(Parameters,TJSONObject.Create);
    WriteJSONValue(Parameter,'Kind','');
    WriteJSONValue(Parameter,'Name','Value2');
    WriteJSONValue(Parameter,'Type','float');

    // GetMemory
    Method:=AddJSONElement(Methods,TJSONObject.Create);
    WriteJSONValue(Method,'Kind','function');
    WriteJSONValue(Method,'Name','GetMemory');
    WriteJSONValue(Method,'ReturnType','float');

    // SetMemory
    Method:=AddJSONElement(Methods,TJSONObject.Create);
    WriteJSONValue(Method,'Kind','procedure');
    WriteJSONValue(Method,'Name','SetMemory');
    Parameters:=WriteJSONValue(Method,'Parameters',TJSONArray.Create);
    Parameter:=AddJSONElement(Parameters,TJSONObject.Create);
    WriteJSONValue(Parameter,'Kind','');
    WriteJSONValue(Parameter,'Name','Value');
    WriteJSONValue(Parameter,'Type','float');

    Result:=Definition.ToString;
  finally
    Definition.Free;
  end;
end;
*)

function GetUnitCalculatorDefinition: string;
var
  UnitBuilder: TUnitBuilder;
begin
  UnitBuilder:=TUnitBuilder.Create('uCalculator');
  try
    UnitBuilder.
      AddClass('TCalculator').
        AddMethod('Add','float').
          AddParameter('Value1','float').
          AddParameter('Value2','float').
        AddMethod('Mul','float').
          AddParameter('Value1','float').
          AddParameter('Value2','float').
        AddMethod('GetMemory','float').
        AddMethod('SetMemory').
          AddParameter('Value','float');

    Result:=UnitBuilder.ToString;
  finally
    UnitBuilder.Free;
  end;
end;

function InstantiateClassObjectImpl(Context: NativeInt; const AClassName, AConstructorName: PChar; const ParameterValues:array of variant): NativeInt; cdecl;
begin
  if (SameText(AClassName,'uCalculator.TCalculator')) then
    Result:=NativeInt(TCalculator.Create)
  else
    RaiseException('Unknown class');
end;

procedure DestructorClassObjectImpl(Context, Instance: NativeInt; const AClassName, ADestructorName: PChar); cdecl;
begin
  DestroyObject(Instance);
end;

function InvokeClassMethodImpl(Context, Instance: NativeInt; const AClassName, AMethodName: PChar; const ParameterValues:array of variant): Variant; cdecl;
begin
  if (SameText(AClassName,'uCalculator.TCalculator')) then
    begin
      if (SameText(AMethodName,'Add')) then
        Result:=TCalculator(Instance).Add(ParameterValues[0],ParameterValues[1])
      else if (SameText(AMethodName,'Mul')) then
        Result:=TCalculator(Instance).Mul(ParameterValues[0],ParameterValues[1])
      else if (SameText(AMethodName,'GetMemory')) then
        Result:=TCalculator(Instance).GetMemory
      else if (SameText(AMethodName,'SetMemory')) then
        TCalculator(Instance).SetMemory(ParameterValues[0])
      else
        RaiseException('Unknown method');
    end
  else
    RaiseException('Unknown class');
end;

procedure LibInit(const ALibInterface: PLibInterface); cdecl;
var
  UnitDefinition: string;
begin
  UnitDefinition:=GetUnitCalculatorDefinition;
  ALibInterface^.InstantiateClassObject:=InstantiateClassObjectImpl;
  ALibInterface^.DestructorClassObject:=DestructorClassObjectImpl;
  ALibInterface^.InvokeClassMethod:=InvokeClassMethodImpl;
  ALibInterface^.CreateUnitByDef(ALibInterface.Context,ALibInterface.Namespace,'uCalculator',PChar(UnitDefinition));
end;

procedure LibFree(const ALibInterface: PLibInterface); cdecl;
begin
end;

exports
  LibInit,
  LibFree;

begin
end.
