unit uDWSScripter;

interface

uses
  System.Classes, System.SysUtils, System.IOUtils, System.StrUtils, Variants, System.Types, System.RTTI, System.TypInfo,
  System.JSON, Generics.Collections, dwsComp, dwsExprs, dwsCompiler, dwsFunctions, dwsSymbols, dwsDataContext, dwsInfo, uLibInterface;

procedure CreateUnitByDefImpl(Context: NativeInt; const ANamespace, AUnitName, AUnitDefinition: PChar);cdecl;
function InstantiateClassObjectImpl(Context: NativeInt; const AClassName, AConstructorName: PChar; const ParameterValues:array of variant): NativeInt; cdecl;
procedure DestructorClassObjectImpl(Context, Instance: NativeInt; const AClassName, ADestructorName: PChar); cdecl;
function InvokeClassMethodImpl(Context, Instance: NativeInt; const AClassName, AMethodName: PChar; const ParameterValues:array of variant): Variant; cdecl;

implementation

uses
  uUtility, uScriptExecuter;

procedure CreateUnitByDefImpl0(Context:NativeInt; const ANamespace, AUnitName, AUnitDefinition: string);
const
  UnitTemplate=
    'unit %s;'+sLineBreak+
    'interface'+sLineBreak+
    'uses uBaseLibrary;'+sLineBreak+
    '%s'+sLineBreak+
    'implementation'+sLineBreak+
    '%s'+sLineBreak+
    'end.';
  ClassTemplate=
    '%s = class(%s)'+sLineBreak+
    'private'+sLineBreak+
    'FExternalObjectHandle: integer;'+sLineBreak+
    'public'+sLineBreak+
    '  procedure Free;'+sLineBreak+
    '%s'+sLineBreak+
    'end;';
var
  InterfaceTypeDefinition, ImplementationDefinition, ClassList, ClassDef, MethodList, MethodDef, ReturnType: string;
  QualifiedName, MethodKind, ClassName, MethodName: string;
  ParameterCount: integer;
  FlagConstructor: boolean;
  ParametersDefinition: TJSONArray;
  Definition: TJSONobject;
  ClassDefinition, MethodDefinition, ParameterDefinition: TJSONValue;
begin
  InterfaceTypeDefinition:='';
  ImplementationDefinition:='';
  Definition:=TJSONObject.ParseJSONValue(AUnitDefinition,false,true) as TJSONobject;
  try
    ClassList:='';
    for ClassDefinition in Definition.GetValue('classes') as TJSONArray do
      begin
        MethodList:='';
        FlagConstructor := false;
        ClassName:=ClassDefinition.GetValue<string>('name');
        QualifiedName:=ClassDefinition.GetValue<string>('qualifiedName');
        for MethodDefinition in TJSONobject(ClassDefinition).GetValue('methods') as TJSONArray do
          begin
            MethodKind:=MethodDefinition.GetValue<string>('kind');
            MethodName:=MethodDefinition.GetValue<string>('name');

            // Interface part
            MethodDef:=Format('%s {_1_}%s(', [MethodKind, MethodName]);
            ParametersDefinition:=TJSONObject(MethodDefinition).GetValue('parameters') as TJSONArray;
            if Assigned(ParametersDefinition) then
              ParameterCount:=ParametersDefinition.Count
            else
              ParameterCount:=0;
            if (ParameterCount>0) then
              for ParameterDefinition in ParametersDefinition do
                MethodDef:=Format('%s%s %s: %s;', [
                  MethodDef,
                  ParameterDefinition.GetValue<string>('kind'),
                  ParameterDefinition.GetValue<string>('name'),
                  ParameterDefinition.GetValue<string>('type')
                ]);
            if MethodDef[Length(MethodDef)]=';' then
              Delete(MethodDef, Length(MethodDef), 1);
            ReturnType := MethodDefinition.GetValue<string>('returnType');
            if (ReturnType <> '') then
              ReturnType := ': ' + ReturnType;
            MethodDef:=Format('%s)%s;', [
              MethodDef,
              ReturnType
            ]);
            MethodList:=MethodList+StringReplace(MethodDef, '{_1_}', '', [])+sLineBreak;

            // Implementation part
            ImplementationDefinition:=
              ImplementationDefinition+
              StringReplace(MethodDef, '{_1_}', ClassName+'.', [])+sLineBreak+
              sLineBreak;
            if SameText(MethodKind,'constructor') then
              begin
                FlagConstructor := true;
                ImplementationDefinition:=
                  ImplementationDefinition+
                  'var Args:array of variant;'+sLineBreak+
                  'begin'+
                  sLineBreak;
                if (ParameterCount>0) then
                  for ParameterDefinition in ParametersDefinition do
                    ImplementationDefinition:=
                      ImplementationDefinition+
                      Format('  Args.push(%s);',[ParameterDefinition.GetValue<string>('name')])+
                      sLineBreak; 
                ImplementationDefinition:=
                  ImplementationDefinition+
                  Format(
                    '  FExternalObjectHandle := __LibInterface_Create(''%s'', ''%s'', ''%s'', Args);',
                    [ANamespace, QualifiedName, MethodName]
                  )+
                  sLineBreak;
              end
            else if SameText(MethodKind,'destructor') then
              // Nothing
            else if SameText(MethodName,'Free') then
              // Nothing
            else
              begin
                ImplementationDefinition:=
                  ImplementationDefinition+
                  'var Args:array of variant;'+sLineBreak+
                  'begin'+sLineBreak;
                if (ParameterCount>0) then
                  for ParameterDefinition in ParametersDefinition do
                    ImplementationDefinition:=
                      ImplementationDefinition+
                      Format('  Args.push(%s);',[ParameterDefinition.GetValue<string>('name')])+
                      sLineBreak;
                if SameText(MethodKind,'function') then 
                  ImplementationDefinition:=
                    ImplementationDefinition+
                    Format(
                      '  Result := __LibInterface_InvokeMethod(''%s'', FExternalObjectHandle, ''%s'', ''%s'', Args);',
                      [ANamespace, QualifiedName, MethodName]
                    )+
                    sLineBreak
                else
                  ImplementationDefinition:=
                    ImplementationDefinition+
                    Format(
                      '  __LibInterface_InvokeMethod(''%s'', FExternalObjectHandle, ''%s'', ''%s'', Args);',
                      [ANamespace, QualifiedName, MethodName]
                    )+
                    sLineBreak;
              end;
            ImplementationDefinition:=
              ImplementationDefinition+
              'end;'+sLineBreak;
          end;
        if not FlagConstructor then
          begin
            // Default constructor
            MethodDef:='constructor %sCreate;';
            MethodList:=
              MethodList+
              Format(MethodDef,[''])+
              sLineBreak;
            ImplementationDefinition:=
              ImplementationDefinition+
              Format(MethodDef, [ClassName+'.'])+
              sLineBreak+
              'begin'+
              sLineBreak+
              Format('  FExternalObjectHandle := __LibInterface_Create(''%s'', ''%s'', ''Create'', []);', 
                     [ANamespace, QualifiedName])+
              sLineBreak+
              'end;'+
              sLineBreak;
          end;

        // Free method
        MethodDef:='procedure %sFree;';
        ImplementationDefinition:=
          ImplementationDefinition+
          Format(MethodDef, [ClassName+'.'])+
          sLineBreak+
          'begin'+sLineBreak+
          '  Destroy;'+sLineBreak+
          'end;'+sLineBreak;

        // Default destructor
        MethodDef:='destructor %sDestroy;';
        MethodList:=
          MethodList+
          Format(MethodDef,[''])+
          sLineBreak;
        ImplementationDefinition:=
          ImplementationDefinition+
          Format(MethodDef, [ClassName+'.'])+
          sLineBreak+
          'begin'+sLineBreak+
          '  try '+sLineBreak+
          Format('    __LibInterface_Destroy(''%s'', FExternalObjectHandle, ''%s'', ''Destroy'');', 
                 [ANamespace, QualifiedName])+
          sLineBreak+
          '  finally'+sLineBreak+
          '    FExternalObjectHandle := 0;'+sLineBreak+
          '  end;'+sLineBreak+
          'end;'+
          sLineBreak;
        ClassDef:=Format(ClassTemplate, [
          ClassDefinition.GetValue<string>('name'),
          ClassDefinition.GetValue<string>('ancestor'),
          MethodList
        ]);
        ClassList:=ClassList+ClassDef+sLineBreak;
      end;
  finally
    Definition.Free;
  end;
  if (ClassList<>'') then
    InterfaceTypeDefinition:='type'+sLineBreak;
  InterfaceTypeDefinition:=InterfaceTypeDefinition+ClassList;
  TScriptExecuter(Context).AddUnit(
    ANamespace, 
    AUnitName,
    Format(UnitTemplate, [
      AUnitName,
      InterfaceTypeDefinition,
      ImplementationDefinition
    ])
  );
end;

function InstantiateClassObjectImpl0(Context:NativeInt; const AClassName, AConstructorName: string; const ParameterValues:array of variant): NativeInt;
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

procedure DestructorClassObjectImpl0(Context, Instance: NativeInt; const AClassName, ADestructorName: string);
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

function InvokeClassMethodImpl0(Context: NativeInt; Instance: NativeInt; const AClassName, AMethodName: string; const ParameterValues: array of variant): Variant;
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

procedure CreateUnitByDefImpl(Context:NativeInt; const ANamespace, AUnitName, AUnitDefinition: PChar);
begin
  CreateUnitByDefImpl0(Context, string(ANamespace), string(AUnitName), string(AUnitDefinition));
end;

function InstantiateClassObjectImpl(Context:NativeInt; const AClassName, AConstructorName: PChar; const ParameterValues:array of variant): NativeInt;
begin
  Result := InstantiateClassObjectImpl0(Context, string(AClassName), string(AConstructorName), ParameterValues);
end;

procedure DestructorClassObjectImpl(Context, Instance: NativeInt; const AClassName, ADestructorName: PChar);
begin
  DestructorClassObjectImpl0(Context, Instance, string(AClassName), string(ADestructorName));
end;

function InvokeClassMethodImpl(Context: NativeInt; Instance: NativeInt; const AClassName: PChar; const AMethodName: PChar; const ParameterValues: array of variant): Variant;
begin
  Result := InvokeClassMethodImpl0(Context, Instance, string(AClassName), string(AMethodName), ParameterValues);
end;

end.
