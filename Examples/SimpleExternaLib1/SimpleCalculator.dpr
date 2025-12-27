library SimpleCalculator;

{$RTTI EXPLICIT METHODS([vcPublic]) PROPERTIES([]) FIELDS([])}

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.JSON,
  System.Classes,
  System.StrUtils,
  uLibInterface,
  uRTTIUnitToJSON,
  uDWSScripter,
  uCalculator in 'uCalculator.pas';

{$R *.res}

var
  UnitDefinition: string;

procedure LibInit(ALibInterface: PLibInterface); cdecl;
begin
  (*
  ALibInterface^.InstantiateClassObject:=InstantiateClassObjectImpl;
  ALibInterface^.DestructorClassObject:=DestructorClassObjectImpl;
  ALibInterface^.InvokeClassMethod:=InvokeClassMethodImpl;
  ALibInterface^.CreateUnitByDef(ALibInterface.Context,ALibInterface.Namespace,'uCalculator',PChar(UnitDefinition));
  *)
end;

procedure LibFree(ALibInterface: PLibInterface); cdecl;
begin
end;

exports
  LibInit,
  LibFree;

begin
  TCalculator.ClassName;
  UnitDefinition:=ExportUnitClassesToJSON('uCalculator');
end.
