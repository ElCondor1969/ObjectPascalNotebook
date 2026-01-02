unit uUnitBuilder;

interface

uses
  System.Classes, System.SysUtils, System.IOUtils, System.StrUtils, Variants, System.Types,
  System.JSON, Generics.Collections;

type
  TUnitBuilder=class(TObject)
  private
    FUnitName:string;
    FJSON,FCurrentClass,FCurrentMethod,FCurrentParameter:TJSONObject;
    FClassList,FMethodList,FParameterList:TJSONArray;
  public
    type
      TParameterKind=(pkNone,pkVar,pkConst);
  public
    constructor Create(AUnitName:string);
    procedure AfterConstruction;override;
    procedure BeforeDestruction;override;
    function ToString:string;
    function AddClass(ClassName:string;Ancestor:string=''):TUnitBuilder;
    function AddMethod(MethodName:string;ReturnType:string='';Directives:string='';AsClass:boolean=false):TUnitBuilder;
    function AddParameter(ParameterName,AType:string;Kind:TParameterKind=pkNone):TUnitBuilder;
  end;

implementation

uses
  uUtility;

{ TUnitBuilder }

constructor TUnitBuilder.Create(AUnitName: string);
begin
  inherited Create;
  FUnitName:=AUnitName;
end;

procedure TUnitBuilder.AfterConstruction;
begin
  inherited;
  FJSON:=TJSONObject.Create;
end;

procedure TUnitBuilder.BeforeDestruction;
begin
  inherited;
  FJSON.Free;
end;

function TUnitBuilder.ToString: string;
begin
  Result:=FJSON.ToString;
end;

function TUnitBuilder.AddClass(ClassName, Ancestor: string): TUnitBuilder;
begin
  if (not(Assigned(FClassList))) then
    FClassList:=WriteJSONValue(FJSON,'Classes',TJSONArray.Create);
  FCurrentClass:=AddJSONElement(FClassList,TJSONObject.Create);
  WriteJSONValue(FCurrentClass,'Name',ClassName);
  WriteJSONValue(FCurrentClass,'QualifiedName',Format('%s.%s',[FUnitName,ClassName]));
  if (Ancestor<>'') then  
    WriteJSONValue(FCurrentClass,'Ancestor',Ancestor);
  FMethodList:=nil;
  Result:=Self;
end;

function TUnitBuilder.AddMethod(MethodName: string; ReturnType, Directives: string; AsClass: boolean): TUnitBuilder;
var
  Kind:string;
begin
  if (not(Assigned(FMethodList))) then
    FMethodList:=WriteJSONValue(FCurrentClass,'Methods',TJSONArray.Create);
  FCurrentMethod:=AddJSONElement(FMethodList,TJSONObject.Create);
  if (ReturnType='') then
    Kind:='procedure'
  else
    Kind:='function';
  if (AsClass) then
    Kind:='class '+Kind;
  WriteJSONValue(FCurrentMethod,'Name',MethodName);
  WriteJSONValue(FCurrentMethod,'Kind',Kind);
  WriteJSONValue(FCurrentMethod,'Directives',Directives);
  WriteJSONValue(FCurrentMethod,'ReturnType',ReturnType);
  FParameterList:=nil;
  Result:=Self;
end;

function TUnitBuilder.AddParameter(ParameterName: string; AType: string; Kind: TParameterKind): TUnitBuilder;

  function KindToString:string;
  begin
    case Kind of
      pkVar: Result:='var';
      pkConst: Result:='const';
    else
      Result:='';
    end;
  end;

begin
  if (not(Assigned(FParameterList))) then
    FParameterList:=WriteJSONValue(FCurrentMethod,'Parameters',TJSONArray.Create);
  FCurrentParameter:=AddJSONElement(FParameterList,TJSONObject.Create);
  WriteJSONValue(FCurrentParameter,'Name',ParameterName);
  WriteJSONValue(FCurrentParameter,'Kind',KindToString);
  WriteJSONValue(FCurrentParameter,'Type',AType);
  Result:=Self;
end;

end.
