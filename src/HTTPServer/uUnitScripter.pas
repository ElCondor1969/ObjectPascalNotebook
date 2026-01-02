unit uUnitScripter;

interface

uses
  System.Classes, System.SysUtils, System.IOUtils, System.StrUtils, System.Types, System.JSON, Generics.Collections;

procedure CreateUnitByDefImpl(Context: NativeInt; const ANamespace, AUnitName, AUnitDefinition: PChar);cdecl;

implementation

uses
  uUtility, uScriptExecuter;

procedure CreateUnitByDefImpl(Context:NativeInt; const ANamespace, AUnitName, AUnitDefinition: PChar);
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
    'protected'+sLineBreak+
    'FExternalObjectHandle: integer;'+sLineBreak+
    'public'+sLineBreak+
    '%s'+sLineBreak+
    'end;';
var
  InterfaceTypeDefinition, ImplementationDefinition, ClassList, ClassDef, MethodList, MethodDef, ReturnType: string;
  QualifiedName, MethodKind, ClassName, InternalClassName, MethodName, MethodDirectives, Ancestor: string;
  ParameterCount, IndexTypeAddedList: integer;
  FlagConstructor: boolean;
  TypeAddedList:TStringArray;
  ParametersDefinition: TJSONArray;
  Definition: TJSONobject;
  ClassDefinition, MethodDefinition, ParameterDefinition: TJSONvalue;
begin
  InterfaceTypeDefinition:='';
  ImplementationDefinition:='';
  SetLength(TypeAddedList,0);
  IndexTypeAddedList:=0;
  Definition:=ParseJSONObject(AUnitDefinition);
  try
    ClassList:='';
    if (ReadJSONArrayCount(Definition,'Classes')>0) then
      for ClassDefinition in ReadJSONArray(Definition, 'Classes') do
        begin
          MethodList:='';
          FlagConstructor := false;
          ClassName:=ReadJSONValue(ClassDefinition,'Name','');
          SetLength(TypeAddedList,IndexTypeAddedList+1);
          TypeAddedList[IndexTypeAddedList]:=ClassName;
          Inc(IndexTypeAddedList);
          QualifiedName:=ReadJSONValue(ClassDefinition,'QualifiedName','');
          Ancestor:=ReadJSONValue(ClassDefinition,'Ancestor','TObject');
          if (Trim(Ancestor)='') then
            Ancestor:='TObject';
          InternalClassName:=Format('%s_%s',[ClassName,AUnitName]);
          if (ReadJSONArrayCount(ClassDefinition,'Methods')>0) then
            begin
              for MethodDefinition in ReadJSONArray(ClassDefinition,'Methods') do
                begin
                  MethodKind:=ReadJSONValue(MethodDefinition,'Kind','');
                  MethodName:=ReadJSONValue(MethodDefinition,'Name','');
                  MethodDirectives:=Trim(ReadJSONValue(MethodDefinition,'Directives',''));
                  if MethodDirectives<>'' then
                    if MethodDirectives[Length(MethodDirectives)]<>';' then
                      MethodDirectives:=MethodDirectives+';';

                  // Interface part
                  MethodDef:=Format('%s {_1_}%s(', [MethodKind, MethodName]);
                  ParametersDefinition:=ReadJSONArray(MethodDefinition,'Parameters');
                  ParameterCount:=ReadJSONArrayCount(MethodDefinition,'Parameters');
                  if (ParameterCount>0) then
                    for ParameterDefinition in ParametersDefinition do
                      MethodDef:=Format('%s%s %s: %s;', [
                        MethodDef,
                        ReadJSONValue(ParameterDefinition,'Kind',''),
                        ReadJSONValue(ParameterDefinition,'Name',''),
                        ReadJSONValue(ParameterDefinition,'Type','')
                      ]);
                  if MethodDef[Length(MethodDef)]=';' then
                    Delete(MethodDef, Length(MethodDef), 1);
                  ReturnType := ReadJSONValue(MethodDefinition,'ReturnType','');
                  if (ReturnType <> '') then
                    ReturnType := ': ' + ReturnType;
                  MethodDef:=Format('%s)%s;', [
                    MethodDef,
                    ReturnType
                  ]);
                  MethodList:=
                    MethodList+
                    StringReplace(MethodDef, '{_1_}', '', [])+
                    MethodDirectives+
                    sLineBreak;

                  // Implementation part
                  ImplementationDefinition:=
                    ImplementationDefinition+
                    StringReplace(MethodDef, '{_1_}', InternalClassName+'.', [])+sLineBreak+
                    sLineBreak;
                  if SameText(MethodKind,'Constructor') then
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
                            Format('  Args.push(%s);',[ReadJSONValue(ParameterDefinition,'Name','')])+
                            sLineBreak; 
                      ImplementationDefinition:=
                        ImplementationDefinition+
                        Format(
                          '  FExternalObjectHandle := __LibInterface_Create(''%s'', ''%s'', ''%s'', Args);',
                          [ANamespace, QualifiedName, MethodName]
                        )+
                        sLineBreak;
                    end
                  else if SameText(MethodKind,'Destructor') then
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
                            Format('  Args.push(%s);',[ReadJSONValue(ParameterDefinition,'Name','')])+
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
                    Format(MethodDef, [InternalClassName+'.'])+
                    sLineBreak+
                    'begin'+sLineBreak+
                    Format('  FExternalObjectHandle := __LibInterface_Create(''%s'', ''%s'', ''Create'', []);',
                           [ANamespace, QualifiedName])+sLineBreak+
                    'end;'+sLineBreak;
                end;
            end;

          // Default destructor
          MethodDef:='destructor %sDestroy;';
          MethodList:=
            MethodList+
            Format(MethodDef+'override;',[''])+
            sLineBreak;
          ImplementationDefinition:=
            ImplementationDefinition+
            Format(MethodDef, [InternalClassName+'.'])+
            sLineBreak+
            'begin'+sLineBreak+
            '  try '+sLineBreak+
            Format('    __LibInterface_Destroy(''%s'', FExternalObjectHandle, ''%s'', ''Destroy'');', 
                   [ANamespace, QualifiedName])+
            sLineBreak+
            '  finally'+sLineBreak+
            '    FExternalObjectHandle := 0;'+sLineBreak+
            '  end;'+sLineBreak+
            '  inherited;'+sLineBreak+
            'end;'+sLineBreak;

          ClassDef:=Format(ClassTemplate, [InternalClassName, Ancestor, MethodList]);
          ClassList:=ClassList+sLineBreak+ClassDef+sLineBreak;
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
    ]),
    TypeAddedList
  );
end;

end.
