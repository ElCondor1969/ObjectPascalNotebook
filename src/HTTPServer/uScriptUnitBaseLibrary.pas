unit uScriptUnitBaseLibrary;

interface

uses
  System.SysUtils, System.Classes, Variants, Generics.Collections, Types, JSON,
  dwsComp, dwsExprs, dwsExprList, dwsCompiler, dwsFunctions, dwsSymbols, dwsDataContext,
  dwsInfo, uScriptExecuter, uUtility;

type
  TScriptUnitBaseLibrary = class(TDataModule)
    dwsUnitLibrary: TdwsUnit;
    procedure dwsUnitLibraryFunctions__DestroyObjectEval(
      info: TProgramInfo);
    procedure dwsUnitLibraryFunctions__ArrayToVariantEval(info: TProgramInfo);
    procedure dwsUnitLibraryFunctions__VariantToArrayEval(info: TProgramInfo);
    procedure dwsUnitLibraryClassesTConsoleMethodsWriteLnEval(
      Info: TProgramInfo; ExtObject: TObject);
    procedure dwsUnitLibraryFunctionsWriteLnEval(info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsRaiseException_String_Eval(
      info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsRaiseException_Args_Eval(
      info: TProgramInfo);
    procedure dwsLibreryUnitFunctionsRestartEval(info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsImport_stringstring_Eval(
      info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsWriteEval(info: TProgramInfo);
    procedure dwsUnitLibraryClassesTConsoleMethodsWriteEval(Info: TProgramInfo;
      ExtObject: TObject);
    procedure dwsUnitLibraryClassesTConsoleMethodsClearEval(Info: TProgramInfo;
      ExtObject: TObject);
    procedure dwsUnitLibraryClassesTConsoleMethodsWriteBlockEval(
      Info: TProgramInfo; ExtObject: TObject);
    procedure dwsUnitLibraryClassesTConsoleMethodsDeleteBlockEval(
      Info: TProgramInfo; ExtObject: TObject);
    procedure dwsUnitLibraryFunctions__LibInterface_InvokeLibProcEval(
      info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsVarToIntEval(info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsVarToFloatEval(info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsVarToStrEval(info: TProgramInfo);
    procedure dwsUnitLibraryFunctions__ArrayVariantArrayToVariantArrayEval(
      info: TProgramInfo);
  private
    { Private declarations }
    FScriptExecuter:TScriptExecuter;
    FMemoryHandleList:TList<integer>;
    function DecodificaArrayOfConst(Info:TProgramInfo;const NomeParametro:string):TVarRecArray;
    function GetVariablesDictionary:TDictionary<string,variant>;
    function AggiustaLetturaVariabileData(Valore:variant):variant;
    procedure ReplaceScriptDynArrayData(ScriptDynArray:IScriptDynArray;Dati:TData);
    procedure AddConsoleOutputRow(Info: TProgramInfo;BreakLine:boolean);
  protected
    { Protected declarations }
    property VariablesDictionary:TDictionary<string,variant> read GetVariablesDictionary;
  public
    { Public declarations }
    constructor Create(ScriptExecuter:TScriptExecuter);
    procedure AfterConstruction;override;
    procedure BeforeDestruction;override;
  end;

implementation

{$R *.dfm}

uses
  uDWSScripter, uLibInterface;

type
  _TDataContext=class(TDataContext);

{ TScriptUnitBaseLibrary }

procedure TScriptUnitBaseLibrary.AddConsoleOutputRow(Info: TProgramInfo;
  BreakLine: boolean);
var k:integer;
    AMessage,Value:string;
begin
  AMessage:=Info.ValueAsString['P1'];
  for k:=2 to 10 do
    begin
      Value:=Info.ValueAsString[Format('P%d',[k])];
      if (Value<>'') then
        AMessage:=AMessage+Value;
    end;
  FScriptExecuter.AddConsoleOutputRow(AMessage, BreakLine);
end;

procedure TScriptUnitBaseLibrary.AfterConstruction;
begin
  inherited;
  FMemoryHandleList:=TList<integer>.Create;
end;

function TScriptUnitBaseLibrary.AggiustaLetturaVariabileData(Valore:variant):variant;
var ValoreFloat:double;
begin
  if (VarIsDateTime(Valore)) then
    begin
      ValoreFloat:=Valore;
      Result:=ValoreFloat;
    end
  else
    Result:=Valore;
end;

procedure TScriptUnitBaseLibrary.BeforeDestruction;
var k:integer;
    PP:Pointer;
begin
  inherited;
  for k:=0 to FMemoryHandleList.Count-1 do
    begin
      PP:=Pointer(FMemoryHandleList[k]);
      FreeMem(PP);
    end;
  FMemoryHandleList.Free;
end;

constructor TScriptUnitBaseLibrary.Create(ScriptExecuter:TScriptExecuter);
begin
  inherited Create(ScriptExecuter);
  FScriptExecuter:=ScriptExecuter;
  dwsUnitLibrary.Script:=ScriptExecuter.DelphiWebScript;
end;

function TScriptUnitBaseLibrary.DecodificaArrayOfConst(Info: TProgramInfo;
  const NomeParametro: string): TVarRecArray;
var k:integer;
    InfoArgs:IInfo;
begin
  try
    try
      InfoArgs:=Info.Vars[NomeParametro];
      SetLength(Result,InfoArgs.Member['length'].ValueAsInteger);
      for k:=0 to High(Result) do
        Result[k]:=VariantToVarRec(InfoArgs.Element(k).Value);
    finally
      InfoArgs:=nil;
    end;
  except
    Finalize(Result);
  end;
end;

procedure TScriptUnitBaseLibrary.dwsLibreryUnitFunctionsRestartEval(
  info: TProgramInfo);
begin
  FScriptExecuter.MustRestartFlag:=true;
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryClassesTConsoleMethodsClearEval(
  Info: TProgramInfo; ExtObject: TObject);
begin
  FScriptExecuter.ClearConsoleOutput;
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryClassesTConsoleMethodsDeleteBlockEval(
  Info: TProgramInfo; ExtObject: TObject);
begin
  FScriptExecuter.WriteConsoleOutputBLock(
    '',
    Info.ValueAsString['IDBlock'],
    bpDelete
  );
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryClassesTConsoleMethodsWriteBlockEval(
  Info: TProgramInfo; ExtObject: TObject);
begin
  Info.ResultAsString:=FScriptExecuter.WriteConsoleOutputBLock(
    Info.ValueAsString['Text'],
    Info.ValueAsString['IDBlockRef'],
    TScriptExecuter.TConsoleOutputBlockPosition(Info.ValueAsInteger['Position'])
  );
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryClassesTConsoleMethodsWriteEval(
  Info: TProgramInfo; ExtObject: TObject);
begin
  AddConsoleOutputRow(Info,false);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryClassesTConsoleMethodsWriteLnEval(
  Info: TProgramInfo; ExtObject: TObject);
begin
  AddConsoleOutputRow(Info,true);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsWriteEval(
  Info: TProgramInfo);
begin
  AddConsoleOutputRow(Info,false);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsWriteLnEval(
  Info: TProgramInfo);
begin
  AddConsoleOutputRow(Info,true);
end;

procedure TScriptUnitBaseLibrary.
            dwsUnitLibraryFunctions__ArrayToVariantEval(Info:TProgramInfo);
var Risultato:variant;
    InfoArgs:IInfo;
begin
  try
    InfoArgs:=Info.Vars['Value'];
    DynArrayToVariant(Risultato,Pointer(InfoArgs.Data),TypeInfo(TData));
    try
      Info.ResultAsVariant:=Risultato;
    finally
      VarClear(Risultato);
    end;
  finally
    InfoArgs:=nil;
  end;
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctions__ArrayVariantArrayToVariantArrayEval(
  Info: TProgramInfo);
var
  k: integer;
  Result, Element: IScriptDynArray;
  InfoArgs: IInfo;
begin
  Result:=Info.ResultVars.ScriptDynArray;
  InfoArgs:=Info.Vars['Value'];
  for k:=0 to High(InfoArgs.Data) do
    begin
      Element:=IScriptDynArray(TVarData(InfoArgs.Data[k]).VUnknown);
      Result.Concat(Element,0,Element.ArrayLength);
    end;
end;

procedure TScriptUnitBaseLibrary.
            dwsUnitLibraryFunctions__DestroyObjectEval(Info:TProgramInfo);
begin
  DestroyInternalObject(Info.ValueAsInteger['ObjectHandle']);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctions__LibInterface_InvokeLibProcEval(
  Info: TProgramInfo);
var
  LibInterface: TLibInterface;
  Data: TData;
begin
  LibInterface := FScriptExecuter.GetLibInterface(Info.ValueAsString['LibGUID']);
  Data:=Info.Vars['Args'].Data;
  Info.ResultAsVariant:=
    LibInterface.InvokeLibProc(
      NativeInt(FScriptExecuter),
      Info.ValueAsInteger['Instance'],
      PChar(Info.ValueAsString['ProcName']),
      Data
    );
  Info.Vars['Args'].Data:=Data;
end;

procedure TScriptUnitBaseLibrary.
            ReplaceScriptDynArrayData(ScriptDynArray:IScriptDynArray; Dati:TData);
var DataContext:TDataContext;
begin
  DataContext:=ScriptDynArray.GetSelf as TDataContext;
  ScriptDynArray.ArrayLength:=Length(Dati);
  _TDataContext(DataContext).DirectData:=Dati;
end;

procedure TScriptUnitBaseLibrary.
            dwsUnitLibraryFunctions__VariantToArrayEval(Info:TProgramInfo);
var Risultato:TData;
begin
  DynArrayFromVariant(Pointer(Risultato),Info.ValueAsVariant['Value'],TypeInfo(TData));
  ReplaceScriptDynArrayData(Info.ResultVars.ScriptDynArray,Risultato);
end;

function TScriptUnitBaseLibrary.GetVariablesDictionary:TDictionary<string,variant>;
begin
  Result:=FScriptExecuter.VariablesDictionary;
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsRaiseException_String_Eval(
  info: TProgramInfo);
begin
  RaiseException(Info.ValueAsString['AMessage']);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsVarToFloatEval(
  Info: TProgramInfo);
var
  Value: variant;
begin
  Value:=Info.ValueAsVariant['Value'];
  if (VarIsNull(Value)) then
    Info.ResultAsFloat:=0
  else
    Info.ResultAsFloat:=Value;
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsVarToIntEval(
  Info: TProgramInfo);
var
  Value: variant;
begin
  Value:=Info.ValueAsVariant['Value'];
  if (VarIsNull(Value)) then
    Info.ResultAsInteger:=0
  else
    Info.ResultAsInteger:=Value;
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsVarToStrEval(
  Info: TProgramInfo);
var
  Value: variant;
begin
  Value:=Info.ValueAsVariant['Value'];
  if (VarIsNull(Value)) then
    Info.ResultAsString:=''
  else
    Info.ResultAsString:=Value;
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsImport_stringstring_Eval(
  Info: TProgramInfo);
begin
  FScriptExecuter.Import(Info.ValueAsString['Namespace'],Info.ValueAsString['APath']);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsRaiseException_Args_Eval(
  Info: TProgramInfo);
var Args:TVarRecArray;
    k:integer;
begin
  try
    Args:=DecodificaArrayOfConst(Info,'Args');
    raise Exception.CreateFmt(Info.ValueAsString['AMessage'],Args);
  finally
    for k:=0 to High(Args) do
      DistruggiVarRec(Args[k]);
    Finalize(Args);
  end;
end;

end.
