unit uScriptUnitBaseLibrary;

interface

uses
  System.SysUtils, System.Classes, Variants, Generics.Collections, Types, JSON,
  dwsComp, dwsExprs, dwsExprList, dwsCompiler, dwsFunctions, dwsSymbols, dwsDataContext,
  dwsInfo, dwsDynamicArrays, uScriptExecuter, uUtility;

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
    procedure dwsUnitLibraryFunctionsSetRemoteOPNBHostEval(info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsRegisterMessageCallbackEval(
      info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsProcessMessageEval(info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsProcessPostedMessageEval(
      info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsEnablePostingMessageEval(
      info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsCreateProcessEval(info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsTerminateProcessEval(info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsImport_stringstring_Eval(
      info: TProgramInfo);
    procedure dwsUnitLibraryFunctionsVarToBoolEval(info: TProgramInfo);
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
  uLibInterface;

type
  _TDataContext=class(TDataContext);

{ TScriptUnitBaseLibrary }

procedure TScriptUnitBaseLibrary.AddConsoleOutputRow(Info: TProgramInfo;
  BreakLine: boolean);
var
  k:integer;
  AMessage,Value:string;
begin
  AMessage:=Info.ValueAsString['P1'];
  for k:=2 to 10 do
    begin
      Value:=Info.ValueAsString[Format('P%d',[k])];
      if (Value<>'') then
        AMessage:=AMessage+Value;
    end;
  AMessage:=StringReplace(AMessage,#13#10,'<br>',[rfReplaceAll]);
  AMessage:=StringReplace(AMessage,#13,'<br>',[rfReplaceAll]);
  AMessage:=StringReplace(AMessage,#10,'<br>',[rfReplaceAll]);
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
  Info: TProgramInfo);
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
  LibGUID: string;
  LibInterface: TLibInterface;
  Data: TData;
begin
  LibGUID:=Info.ValueAsString['LibGUID'];
  LibInterface:=FScriptExecuter.GetLibInterface(LibGUID);
  if (LibInterface.LibGUID='') then
    RaiseException('No library found with GUID: %s',[LibGUID]);
  Data:=Info.Vars['Args'].Data;
  try
    Info.ResultAsVariant:=
      LibInterface.InvokeLibProc(
        NativeInt(FScriptExecuter),
        Info.ValueAsInteger['Instance'],
        PChar(Info.ValueAsString['ProcName']),
        Data
      );
    Info.Vars['Args'].Data:=Data;
  except
    on E: Exception do
      RaiseException(E.Message); // Don't use "raise".
  end;
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
  Info: TProgramInfo);
begin
  RaiseException(Info.ValueAsString['AMessage']);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsRegisterMessageCallbackEval(
  Info: TProgramInfo);
var MessageCallback:variant;
begin
  MessageCallback:=Info.Vars['MessageCallback'];
  FScriptExecuter.AddMessageCallback(
    Info.ValueAsVariant['Key'],
    MessageCallback
  );
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsSetRemoteOPNBHostEval(
  Info: TProgramInfo);
begin
  WriteJSONValue(FScriptExecuter.OutputData,'UrlRemoteOPNBHost',Info.ValueAsString['URL']);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsTerminateProcessEval(
  Info: TProgramInfo);
begin
  TerminateProcess(StrToUInt(Info.ValueAsString['Handle']));
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsVarToBoolEval(
  Info: TProgramInfo);
begin
  Info.ResultAsBoolean:=Info.ValueAsBoolean['Value'];
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsVarToFloatEval(
  Info: TProgramInfo);
begin
  Info.ResultAsFloat:=Info.ValueAsFloat['Value'];
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsVarToIntEval(
  Info: TProgramInfo);
begin
  Info.ResultAsInteger:=Info.ValueAsInteger['Value'];
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsVarToStrEval(
  Info: TProgramInfo);
begin
  Info.ResultAsString:=Info.ValueAsString['Value'];
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsCreateProcessEval(
  Info: TProgramInfo);
begin
  Info.ResultAsString:=UIntToStr(CreateProcess(
    Info.ValueAsString['Command'],
    Trim(Info.ValueAsString['Arguments']),
    Info.ValueAsBoolean['ShowWindow']
  ));
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsEnablePostingMessageEval(
  Info: TProgramInfo);
begin
  FScriptExecuter.PostingMessageEnabled:=Info.ValueAsBoolean['Enable'];
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsImport_stringstring_Eval(
  Info: TProgramInfo);
begin
  try
    FScriptExecuter.Import(Info.ValueAsString['Namespace'],Info.ValueAsString['APath']);
  except
    on E: Exception do
      RaiseException(E.Message); // Don't use "raise".
  end;
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsProcessMessageEval(
  Info: TProgramInfo);
var Key,MessageCallback:variant;
    CallbackInfo:IInfo;
begin
  Key:=Info.ValueAsVariant['Key'];
  if (not FScriptExecuter.GetMessageCallback(Key,MessageCallback)) then
    RaiseException('Message callback key "%s" not found.',[VarToStr(Key)]);
  CallbackInfo:=IInfo(IUnknown(MessageCallback));
  CallbackInfo.Call([Info.ValueAsVariant['Parameters']]);
end;

procedure TScriptUnitBaseLibrary.dwsUnitLibraryFunctionsProcessPostedMessageEval(
  Info: TProgramInfo);
var k:integer;
    Risultato:boolean;
    CallbackMessage,Parameters:variant;
    CallbackInfo:IInfo;
    ArrayInfo:IScriptDynArray;
    VariantSymbol:TBaseVariantSymbol;
    PostedMessage:TScriptExecuter.TPostedMessage;
begin
  Risultato:=false;
  with FScriptExecuter do
    while (PopPostMessage(PostedMessage)) do
      begin
        if (GetMessageCallback(PostedMessage.Key,CallbackMessage)) then
          try
            VariantSymbol:=TBaseVariantSymbol.Create('Parameters');
            CreateNewDynamicArray(VariantSymbol,ArrayInfo);
            ArrayInfo.SetArrayLength(Length(PostedMessage.Parameters));
            for k:=0 to High(PostedMessage.Parameters) do
              ArrayInfo.AsVariant[k]:=PostedMessage.Parameters[k];
            Parameters:=ArrayInfo;
            CallbackInfo:=IInfo(IUnknown(CallbackMessage));
            CallbackInfo.Call([Parameters]);
            Risultato:=true;
          finally
            VariantSymbol.Free;
          end;
      end;
  Info.ResultAsBoolean:=Risultato;
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
