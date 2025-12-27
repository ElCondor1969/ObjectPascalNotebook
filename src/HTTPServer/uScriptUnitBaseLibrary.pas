unit uScriptUnitBaseLibrary;

interface

uses
  System.SysUtils, System.Classes, Variants, Generics.Collections, Types, JSON,
  dwsComp, dwsExprs, dwsExprList, dwsCompiler, dwsFunctions, dwsSymbols, dwsDataContext,
  dwsInfo, uScriptExecuter;

type
  TScriptUnitBaseLibrary = class(TDataModule)
    dwsUnitLibrary: TdwsUnit;
    procedure dwsUnitLibraryClassesTDestroyerCleanUp(ExternalObject: TObject);
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
    procedure dwsUnitLibraryFunctions__LibInterface_CreateEval(
      info: TProgramInfo);
    procedure dwsUnitLibraryFunctions__LibInterface_DestroyEval(
      info: TProgramInfo);
    procedure dwsUnitLibraryFunctions__LibInterface_InvokeMethodEval(
      info: TProgramInfo);
  private
    { Private declarations }
    FScriptExecuter:TScriptExecuter;
    function GetVariablesDictionary:TDictionary<string,variant>;
    function AggiustaLetturaVariabileData(Valore:variant):variant;
    procedure ReplaceScriptDynArrayData(ScriptDynArray:IScriptDynArray;Dati:TData);
  protected
    { Protected declarations }
    property VariablesDictionary:TDictionary<string,variant> read GetVariablesDictionary;
  public
    { Public declarations }
    constructor Create(ScriptExecuter:TScriptExecuter);
  end;

implementation

{$R *.dfm}

uses
  uUtility, uDWSScripter, uLibInterface;

type
  _TDataContext=class(TDataContext);

{ TScriptUnitBaseLibrary }

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

constructor TScriptUnitBaseLibrary.Create(ScriptExecuter:TScriptExecuter);
begin
  inherited Create(ScriptExecuter);
  FScriptExecuter:=ScriptExecuter;
  dwsUnitLibrary.Script:=ScriptExecuter.DelphiWebScript;
end;

procedure TScriptUnitBaseLibrary.dwsLibreryUnitFunctionsRestartEval(
  info: TProgramInfo);
begin
  FScriptExecuter.MustRestartFlag:=true;
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryClassesTConsoleMethodsWriteLnEval(
  Info: TProgramInfo; ExtObject: TObject);
begin
  FScriptExecuter.AddConsoleOutputRow(Info.ValueAsString['AMessage']);
end;

procedure TScriptUnitBaseLibrary.
            dwsUnitLibraryClassesTDestroyerCleanUp(ExternalObject:TObject);
begin
  DestroyObject(ExternalObject);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsWriteLnEval(
  info: TProgramInfo);
var k:integer;
    AMessage,Value:string;
begin
  AMessage:=Info.ValueAsString['P1'];
  for k:=2 to 10 do
    begin
      Value:=Info.ValueAsString[Format('P%d',[k])];
      if (Value<>'') then
        AMessage:=AMessage+' '+Value;
    end;
  FScriptExecuter.AddConsoleOutputRow(AMessage);
end;

procedure TScriptUnitBaseLibrary.
            dwsUnitLibraryFunctions__ArrayToVariantEval(Info:TProgramInfo);
var Risultato:variant;
    InfoArgs:IInfo;
begin
  try
    InfoArgs:=Info.Vars['Parametro'];
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

procedure TScriptUnitBaseLibrary.
            dwsUnitLibraryFunctions__DestroyObjectEval(Info:TProgramInfo);
begin
  DestroyInternalObject(Info.ValueAsInteger['HandleOggetto']);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctions__LibInterface_CreateEval(
  Info: TProgramInfo);
var
  LibInterface: TLibInterface;
begin
  LibInterface := FScriptExecuter.GetLibInterface(Info.ValueAsString['Namespace']);
  Info.ResultAsInteger:=
    LibInterface.InstantiateClassObject(
      NativeInt(FScriptExecuter),
      PChar(Info.ValueAsString['QualifiedClassName']),
      PChar(Info.ValueAsString['ConstructorName']),
      Info.Vars['Args'].Data
    );
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctions__LibInterface_DestroyEval(
  Info: TProgramInfo);
var
  LibInterface: TLibInterface;
begin
  LibInterface := FScriptExecuter.GetLibInterface(Info.ValueAsString['Namespace']);
  LibInterface.DestructorClassObject(
    NativeInt(FScriptExecuter),
    Info.ValueAsInteger['Instance'],
    PChar(Info.ValueAsString['QualifiedClassName']),
    PChar(Info.ValueAsString['DestructorName'])
  );
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctions__LibInterface_InvokeMethodEval(
  Info: TProgramInfo);
var
  LibInterface: TLibInterface;
begin
  LibInterface := FScriptExecuter.GetLibInterface(Info.ValueAsString['Namespace']);
  Info.ResultAsVariant:=
    LibInterface.InvokeClassMethod(
      NativeInt(FScriptExecuter),
      Info.ValueAsInteger['Instance'],
      PChar(Info.ValueAsString['QualifiedClassName']),
      PChar(Info.ValueAsString['MethodName']),
      Info.Vars['Args'].Data
    );
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
  DynArrayFromVariant(Pointer(Risultato),Info.ValueAsVariant['Parametro'],TypeInfo(TData));
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

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsImport_stringstring_Eval(
  info: TProgramInfo);
begin
  FScriptExecuter.Import(Info.ValueAsString['Namespace'],Info.ValueAsString['APath']);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsRaiseException_Args_Eval(
  info: TProgramInfo);
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
