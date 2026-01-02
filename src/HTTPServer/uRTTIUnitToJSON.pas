unit uRTTIUnitToJSON;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.JSON,
  System.Classes,
  System.StrUtils,
  Generics.Collections;

procedure ExportUnitClassesToJSON(const AUnitName: string; out Def:TJSONObject);overload;
function ExportUnitClassesToJSON(const AUnitName: string): string;overload;

implementation

uses
  uUtility;

function VisibilityToString(V: TMemberVisibility): string;
begin
  case V of
    mvPrivate:   Result := 'private';
    mvProtected: Result := 'protected';
    mvPublic:    Result := 'public';
    mvPublished: Result := 'published';
  else
    Result := 'unknown';
  end;
end;

function MethodKindToString(K: TMethodKind): string;
begin
  case K of
    mkProcedure: Result := 'procedure';
    mkFunction:  Result := 'function';
    mkConstructor: Result := 'constructor';
    mkDestructor:  Result := 'destructor';
    mkClassProcedure: Result := 'class procedure';
    mkClassFunction:  Result := 'class function';
  else
    Result := 'unknown';
  end;
end;

function ParamFlagsToJSON(const Flags: TParamFlags): TJSONArray;
begin
  Result := TJSONArray.Create;
  if pfVar in Flags then
    Result.Add('var');
  if pfConst in Flags then
    Result.Add('const');
  if pfOut in Flags then
    Result.Add('out');
  if pfArray in Flags then
    Result.Add('array');
  if pfReference in Flags then
    Result.Add('reference');
end;

function ParamFlagsToString(const Flags: TParamFlags): string;
begin
  Result:='';
  if pfVar in Flags then
    Result := 'var';
  if pfConst in Flags then
    Result := 'const';
  if pfOut in Flags then
    Result := 'out';
  if pfArray in Flags then
    Result := 'array';
  if pfReference in Flags then
    Result := 'reference';
end;

procedure ExportUnitClassesToJSON(const AUnitName: string; out Def:TJSONObject); overload;
var
  Ctx: TRttiContext;
  RType: TRttiType;
  RClass: TRttiInstanceType;
  ClassesArray: TJSONArray;
  ClassObj, FieldObj, PropObj, MethodObj, ParamObj: TJSONObject;
  FieldsArr, PropsArr, MethodsArr, ParamsArr: TJSONArray;
  Field: TRttiField;
  Prop: TRttiProperty;
  Method: TRttiMethod;
  Param: TRttiParameter;
begin
  Def := TJSONObject.Create;
  ClassesArray := TJSONArray.Create;

  Def.AddPair('unit', AUnitName);
  Def.AddPair('classes', ClassesArray);

  Ctx := TRttiContext.Create;
  try
    for RType in Ctx.GetTypes do
    begin
      if not (RType is TRttiInstanceType) then
        Continue;

      RClass := TRttiInstanceType(RType);

      // Filter by unit name
      if not StartsText(AUnitName+'.',RClass.QualifiedName ) then
        Continue;

      ClassObj := TJSONObject.Create;
      ClassesArray.AddElement(ClassObj);

      WriteJSONValue(ClassObj, 'name', RClass.Name);
      WriteJSONValue(ClassObj, 'qualifiedName', RClass.QualifiedName);

      if Assigned(RClass.BaseType) then
        WriteJSONValue(ClassObj, 'ancestor', RClass.BaseType.Name)
      else
        WriteJSONValue(ClassObj, 'ancestor', '');

      WriteJSONValue(ClassObj, 'visibility', VisibilityToString(mvPublic));

      // ===== Fields =====
      FieldsArr := TJSONArray.Create;
      WriteJSONValue(ClassObj, 'fields', FieldsArr);

      for Field in RClass.GetFields do
        if Field.Parent = RType then
          begin
            FieldObj := TJSONObject.Create;
            FieldsArr.AddElement(FieldObj);
            WriteJSONValue(FieldObj,'name', Field.Name);
            WriteJSONValue(FieldObj,'type', Field.FieldType.Name);
            WriteJSONValue(FieldObj,'visibility', VisibilityToString(Field.Visibility));
            WriteJSONValue(FieldObj,'isStatic', (Field.Offset < 0));
          end;

      // ===== Properties =====
      PropsArr := TJSONArray.Create;
      WriteJSONValue(ClassObj,'properties', PropsArr);

      for Prop in RClass.GetProperties do
        if Prop.Parent = RType then
          begin
            PropObj := TJSONObject.Create;
            PropsArr.AddElement(PropObj);
            WriteJSONValue(PropObj, 'name', Prop.Name);
            WriteJSONValue(PropObj, 'type', Prop.PropertyType.Name);
            WriteJSONValue(PropObj, 'visibility', VisibilityToString(Prop.Visibility));
            WriteJSONValue(PropObj, 'readable', Prop.IsReadable);
            WriteJSONValue(PropObj, 'writable', Prop.IsWritable);
          end;

      // ===== Methods =====
      MethodsArr := TJSONArray.Create;
      WriteJSONValue(ClassObj, 'methods', MethodsArr);

      for Method in RClass.GetMethods do
        if Method.Parent = RType then
          begin
            MethodObj := TJSONObject.Create;
            MethodsArr.AddElement(MethodObj);
            WriteJSONValue(MethodObj, 'name', Method.Name);
            WriteJSONValue(MethodObj, 'kind', MethodKindToString(Method.MethodKind));
            WriteJSONValue(MethodObj, 'visibility', VisibilityToString(Method.Visibility));
            WriteJSONValue(MethodObj, 'isClassMethod', Method.IsClassMethod);
            WriteJSONValue(MethodObj, 'callingConvention', GetEnumName(TypeInfo(TCallConv), Ord(Method.CallingConvention)));

            if Assigned(Method.ReturnType) then
              WriteJSONValue(MethodObj, 'returnType', Method.ReturnType.Name)
            else
              WriteJSONValue(MethodObj, 'returnType', '');

            // ===== Parameters =====
            ParamsArr := TJSONArray.Create;
            WriteJSONValue(MethodObj, 'parameters', ParamsArr);

            for Param in Method.GetParameters do
              begin
                ParamObj := TJSONObject.Create;
                ParamsArr.AddElement(ParamObj);
                WriteJSONValue(ParamObj, 'name', Param.Name);
                if Assigned(Param.ParamType) then
                  WriteJSONValue(ParamObj, 'type', Param.ParamType.Name)
                else
                  WriteJSONValue(ParamObj, 'type', '');
                WriteJSONValue(ParamObj, 'kind', ParamFlagsToString(Param.Flags));
                WriteJSONValue(ParamObj, 'flags', ParamFlagsToJSON(Param.Flags));
              end;
          end;
    end;
  finally
    Ctx.Free;
  end;
end;

function ExportUnitClassesToJSON(const AUnitName: string): string; overload;
var Def:TJSONObject;
begin
  ExportUnitClassesToJSON(AUnitName,Def);
  try
    Result:=Def.ToString;
  finally
    Def.Free;
  end;
end;

end.
