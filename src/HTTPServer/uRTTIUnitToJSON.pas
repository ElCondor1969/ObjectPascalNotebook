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

      ClassObj.AddPair('name', RClass.Name);
      ClassObj.AddPair('qualifiedName', RClass.QualifiedName);

      if Assigned(RClass.BaseType) then
        ClassObj.AddPair('ancestor', RClass.BaseType.Name)
      else
        ClassObj.AddPair('ancestor', '');

      ClassObj.AddPair('visibility', VisibilityToString(mvPublic));

      // ===== Fields =====
      FieldsArr := TJSONArray.Create;
      ClassObj.AddPair('fields', FieldsArr);

      for Field in RClass.GetFields do
        if Field.Parent = RType then
          begin
            FieldObj := TJSONObject.Create;
            FieldsArr.AddElement(FieldObj);
            FieldObj.AddPair('name', Field.Name);
            FieldObj.AddPair('type', Field.FieldType.Name);
            FieldObj.AddPair('visibility', VisibilityToString(Field.Visibility));
            FieldObj.AddPair('isStatic', TJSONBool.Create(Field.Offset < 0));
          end;

      // ===== Properties =====
      PropsArr := TJSONArray.Create;
      ClassObj.AddPair('properties', PropsArr);

      for Prop in RClass.GetProperties do
        if Prop.Parent = RType then
          begin
            PropObj := TJSONObject.Create;
            PropsArr.AddElement(PropObj);
            PropObj.AddPair('name', Prop.Name);
            PropObj.AddPair('type', Prop.PropertyType.Name);
            PropObj.AddPair('visibility', VisibilityToString(Prop.Visibility));
            PropObj.AddPair('readable', TJSONBool.Create(Prop.IsReadable));
            PropObj.AddPair('writable', TJSONBool.Create(Prop.IsWritable));
          end;

      // ===== Methods =====
      MethodsArr := TJSONArray.Create;
      ClassObj.AddPair('methods', MethodsArr);

      for Method in RClass.GetMethods do
        if Method.Parent = RType then
          begin
            MethodObj := TJSONObject.Create;
            MethodsArr.AddElement(MethodObj);
            MethodObj.AddPair('name', Method.Name);
            MethodObj.AddPair('kind', MethodKindToString(Method.MethodKind));
            MethodObj.AddPair('visibility', VisibilityToString(Method.Visibility));
            MethodObj.AddPair('isClassMethod', TJSONBool.Create(Method.IsClassMethod));
            MethodObj.AddPair('callingConvention', GetEnumName(TypeInfo(TCallConv), Ord(Method.CallingConvention)));

            if Assigned(Method.ReturnType) then
              MethodObj.AddPair('returnType', Method.ReturnType.Name)
            else
              MethodObj.AddPair('returnType', '');

            // ===== Parameters =====
            ParamsArr := TJSONArray.Create;
            MethodObj.AddPair('parameters', ParamsArr);

            for Param in Method.GetParameters do
              begin
                ParamObj := TJSONObject.Create;
                ParamsArr.AddElement(ParamObj);
                ParamObj.AddPair('name', Param.Name);
                if Assigned(Param.ParamType) then
                  ParamObj.AddPair('type', Param.ParamType.Name)
                else
                  ParamObj.AddPair('type', '');
                ParamObj.AddPair('kind', ParamFlagsToString(Param.Flags));
                ParamObj.AddPair('flags', ParamFlagsToJSON(Param.Flags));
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
