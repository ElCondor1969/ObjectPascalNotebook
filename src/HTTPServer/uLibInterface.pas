unit uLibInterface;

interface

uses
  uDynLibLoader;

type
  TCreateUnitByDef = procedure(Context: NativeInt; const ANamespace, AUnitName, AUnitDefinition: PChar); cdecl;
  TInstantiateClassObject = function(Context: NativeInt; const AClassName, AConstructorName: PChar; const ParameterValues:array of variant): NativeInt; cdecl;
  TDestructorClassObject = procedure(Context, Instance: NativeInt; const AClassName, ADestructorName: PChar); cdecl;
  TInvokeClassMethod = function(Context, Instance: NativeInt; const AClassName, AMethodName: PChar; const ParameterValues:array of variant): Variant; cdecl;

  PLibInterface = ^TLibInterface;
  TLibInterface = record
    Version: Integer;
    Context: NativeInt;
    Namespace: PChar;
    LibHandle: TDynLibHandle;
    CreateUnitByDef: TCreateUnitByDef;
    InstantiateClassObject: TInstantiateClassObject;
    DestructorClassObject: TDestructorClassObject;
    InvokeClassMethod: TInvokeClassMethod;
  end;

  TLibInit = procedure(const LibInterface: PLibInterface); cdecl;
  TLibFree = procedure(const LibInterface: PLibInterface); cdecl;

implementation

end.
