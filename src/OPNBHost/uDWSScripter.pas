unit uDWSScripter;

interface

uses
  System.Classes, System.SysUtils, System.IOUtils, System.StrUtils, Variants, System.Types, System.RTTI, System.TypInfo,
  System.JSON, Generics.Collections, dwsComp, dwsExprs, dwsCompiler, dwsFunctions, dwsSymbols, dwsDataContext, dwsInfo, uLibInterface;

function InstantiateClassObjectImpl(Context: NativeInt; const AClassName, AConstructorName: PChar; const ParameterValues:array of variant): NativeInt; cdecl;
procedure DestructorClassObjectImpl(Context, Instance: NativeInt; const AClassName, ADestructorName: PChar); cdecl;
function InvokeClassMethodImpl(Context, Instance: NativeInt; const AClassName, AMethodName: PChar; const ParameterValues:array of variant): Variant; cdecl;

implementation

uses
  uUtility, uScriptExecuter;

function InstantiateClassObjectImpl(Context:NativeInt; const AClassName, AConstructorName: PChar; const ParameterValues:array of variant): NativeInt;
var
  k: integer;
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiMethod: TRttiMethod;
  Instance: TObject;
  Args: array of TValue;
begin
  RttiContext := TRttiContext.Create;
  try
    RttiType := RttiContext.FindType(AClassName);
    if RttiType = nil then
      RaiseException('Class not found: %s', [AClassName]);
    for RttiMethod in RttiType.GetMethods do
      if (RttiMethod.IsConstructor) and SameText(RttiMethod.Name,AConstructorName) then
        begin
          SetLength(Args, Length(ParameterValues));
          for k:=0 to High(Args) do
            Args[k]:=TValue.FromVariant(ParameterValues[k]);
          Instance := RttiMethod.Invoke(RttiType.AsInstance.MetaclassType, Args).AsObject;
          Result := NativeInt(Instance);
          Exit;
        end;
    RaiseException('Constructor not found: %s.%s', [AClassName, AConstructorName]);
  finally
    RttiContext.Free;
  end;
end;

procedure DestructorClassObjectImpl(Context, Instance: NativeInt; const AClassName, ADestructorName: PChar);
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiMethod: TRttiMethod;
begin
  RttiContext := TRttiContext.Create;
  try
    RttiType := RttiContext.FindType(AClassName);
    if RttiType = nil then
      RaiseException('Class not found: %s', [AClassName]);
    for RttiMethod in RttiType.GetMethods do
      if (RttiMethod.IsDestructor) and SameText(RttiMethod.Name,ADestructorName) then
        begin
          RttiMethod.Invoke(TObject(Instance), []);
          Exit;
        end;
    RaiseException('Destructor not found: %s.%s', [AClassName, ADestructorName]);
  finally
    RttiContext.Free;
  end;
end;

function InvokeClassMethodImpl(Context: NativeInt; Instance: NativeInt; const AClassName: PChar; const AMethodName: PChar; const ParameterValues: array of variant): Variant;
var
  k: integer;
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiMethod: TRttiMethod;
  Args: array of TValue;
begin
  RttiContext := TRttiContext.Create;
  try
    RttiType := RttiContext.FindType(AClassName);
    if RttiType = nil then
      RaiseException('Class not found: %s', [AClassName]);
    for RttiMethod in RttiType.GetMethods do
      if (not RttiMethod.IsConstructor) and (not RttiMethod.IsDestructor) and SameText(RttiMethod.Name,AMethodName) then
        begin
          SetLength(Args, Length(ParameterValues));
          for k:=0 to High(Args) do
            Args[k]:=TValue.FromVariant(ParameterValues[k]);
          Result := RttiMethod.Invoke(TObject(Instance), Args).AsVariant;
          Exit;
        end;
    RaiseException('Method not found: %s.%s', [AClassName, AMethodName]);
  finally
    RttiContext.Free;
  end;
end;

end.
