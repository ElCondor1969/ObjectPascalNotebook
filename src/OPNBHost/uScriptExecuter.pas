unit uScriptExecuter;

interface

uses
  System.Classes, dwsUtils, System.SysUtils, System.IOUtils, System.StrUtils, System.Variants, System.Types, Generics.Collections,
  System.RegularExpressions, uDynLibLoader, JSON, uLibInterface, uUtility, dwsStrings, dwsComp, dwsExprs, dwsDataContext, dwsInfo,
  dwsCompiler, dwsFunctions, dwsStack, dwsClassesLibModule, dwsJSONConnector, dwsDataBaseLibModule, dwsLinq, dwsLinqSql, 
  dwsSymbols, dwsUnitSymbols, dwsScriptSource, dwsRTTIConnector, dwsRTTIFunctions, dwsDynamicArrays;

type
  TScriptExecuter = class(TDataModule)
    DelphiWebScript: TDelphiWebScript;
    dwsClassesLib: TdwsClassesLib;
    dwsJSONLibModule: TdwsJSONLibModule;
    dwsRTTIConnector: TdwsRTTIConnector;
    function DelphiWebScriptNeedUnit(const UnitName: string;
      var UnitSource: string): IdwsUnit;
    procedure DelphiWebScriptInclude(const scriptName: string;
      var scriptSource: string);
  private
    { Private declarations }
    const
      ConsoleOutputStartBlockTemplate='<opnbo_%s>';
      ConsoleOutputEndBlockTemplate='</opnbo_%s>';
    type
      TUnitSearchInfo=record
        Namespace: string;
        Source: string;
      end;

      TUnitSearch=class(TObject)
      private
        FScriptExecuter: TScriptExecuter;
        FDict:TDictionary<string,TUnitSearchInfo>;
        FLibraryDict:TDictionary<string,TLibInterface>;
        procedure CheckNamespace(const ANamespace:string);
        procedure FreeLibrary(const LibGUID:string);
      public
        constructor Create(AScriptExecuter: TScriptExecuter);
        procedure AfterConstruction;override;
        procedure BeforeDestruction;override;
        procedure ImportFromPath(const ANamespace,APath:string);
        procedure ImportFromLibrary(const ANamespace,ALibraryName:string);
        procedure AddUnit(const ANamespace,AUnitName,AUnitSource:string);
        function GetUnitCode(const UnitName:string;Shrink:boolean=false):string;
      end;
  public
    type
      TConsoleOutputBlockPosition=(bpAdd,bpReplace,bpDelete,bpPrior,bpNext);
      TPostedMessage=record
        Key: variant;
        Parameters: array of variant;
      end;
  private
    { Private declarations }
    FInternalDestroying: boolean;
    FExecutionPath:string;
    FVariablesDictionary:TDictionary<string,variant>;
    FLibraryUnitAdded:TStringList;
    FUnitSearch:TUnitSearch;
    FProgram:IdwsProgram;
    FExecution:IdwsProgramExecution;
    FPostingMessageEnabled:boolean;
    FOutputData:TJSONObject;
    FPostedMessages:TThreadedQueue<TPostedMessage>;
    FMessageCallbacksDictionary:TDictionary<variant,variant>;
    procedure InjectUnit(var Script:string);
    function GetMustRestartFlag:boolean;
    procedure SetMustRestartFlag(const Value:boolean);
    function GetCancelPending:boolean;
    procedure SetCancelPending(const Value:boolean);
    procedure LoadLibraries(var Args: array of variant);
    procedure UnloadLibraries(const Args: array of variant);
  protected
    { Protected declarations }
    function GetUnitList:string;virtual;
  public
    { Public declarations }
    procedure AfterConstruction;override;
    procedure BeforeDestruction;override;
    function ExecuteScript(Script:string):string;overload;
    function ExecuteScript(Script:string;InitialVariables:TDictionary<string,variant>):string;overload;
    function GetConsoleOutput:string;
    procedure SetConsoleOutput(const Value:string);
    procedure AddConsoleOutputRow(const AMessage:string;BreakLine:boolean=true);
    procedure ClearConsoleOutput;
    function WriteConsoleOutputBlock(const Text:string;IDBlockRef:string='';Position:TConsoleOutputBlockPosition=bpAdd):string;
    function GetConsoleOutputBlockPosition(const Output,IDBlock:string;out StartPos,EndPos:integer):boolean;
    procedure Import(const ANamespace,AValue:string);
    procedure AddUnit(const ANamespace,AUnitName,AUnitText:string);
    function GetLibInterface(const LibGUID:string):TLibInterface;
    procedure AddMessageCallback(const Key,MessageCallback:variant);
    procedure PushPostMessage(const PostedMessage:TPostedMessage);
    function PopPostMessage(out PostedMessage:TPostedMessage):boolean;
    function GetMessageCallback(const Key:variant;out MessageCallback:variant):boolean;
    property ExecutionPath:string read FExecutionPath write FExecutionPath;
    property VariablesDictionary:TDictionary<string,variant> read FVariablesDictionary;
    property MustRestartFlag:boolean read GetMustRestartFlag write SetMustRestartFlag;
    property CancelPending:boolean read GetCancelPending write SetCancelPending;
    property OutputData:TJSONObject read FOutputData;
    property PostingMessageEnabled:boolean read FPostingMessageEnabled write FPostingMessageEnabled;
  end;

implementation

{$R *.dfm}

uses
  uScriptUnitBaseLibrary;

const
  varConsoleOutout='__CONSOLE_OUTPUT__';
  varFlagRestart='__FLAG_RESTART__';
  varFlagCancel='__FLAG_CANCEL__';

type
  TOPNBProgramExecution=class(TdwsProgramExecution)
  private
    FFlagPreserveStack: boolean;
    FScriptExecuter: TScriptExecuter;
  public
    constructor Create(aProgram : TdwsMainProgram; const stackParams : TStackParameters); override;
    function BeginProgram:boolean;override;
    procedure EndProgram;override;
  end;

threadvar
  TheScriptExecuter: TScriptExecuter;

{ InternalInvokeHostProc }

function InternalInvokeHostProc(Context: NativeInt; const Command: variant; var Args: array of variant): variant; cdecl;

  procedure DoPostMessage;
  var 
    k:integer;
    PostedMessage:TScriptExecuter.TPostedMessage;
  begin
    PostedMessage:=Default(TScriptExecuter.TPostedMessage);
    PostedMessage.Key:=Args[0];
    SetLength(PostedMessage.Parameters,Length(Args)-1);
    for k:=1 to High(Args) do
      PostedMessage.Parameters[k-1]:=Args[k];
    TScriptExecuter(Context).PushPostMessage(PostedMessage);
  end;

begin
  if (not(VarIsInt(Command))) then
    RaiseException('Unknown host command');
  case Command of
    COMHOST_LOADLIBRARY: TScriptExecuter(Context).LoadLibraries(Args);
    COMHOST_UNLOADLIBRARY: TScriptExecuter(Context).UnloadLibraries(Args);
    COMHOST_POSTMESSAGE: DoPostMessage;
  else
    RaiseException('Unknown host command');
  end;
end;

procedure InternalSynchronize(AProcedure: TThreadProcedure); cdecl;
begin
  TThread.Synchronize(nil, AProcedure);
end;

{ TOPNBProgramExecution }

constructor TOPNBProgramExecution.Create(aProgram: TdwsMainProgram;
  const stackParams: TStackParameters);
begin
  inherited;
  FScriptExecuter:=TheScriptExecuter;
end;

function TOPNBProgramExecution.BeginProgram:boolean;
var
  TempStack:TStackMixIn;
begin
  if (FFlagPreserveStack) then
    begin
      TempStack:=Default(TStackMixIn);
      TempStack.Assign(FStack);
    end;
  try
    if (FFlagPreserveStack) then
      DestroyCostantObject(ProgramInfo);
    Result:=inherited;
    if (FFlagPreserveStack) then
      FStack.Assign(TempStack);
  finally
    if (FFlagPreserveStack) then
      TempStack.Finalize;
  end;
end;

procedure TOPNBProgramExecution.EndProgram;
begin
  if (FScriptExecuter.FInternalDestroying) then
    inherited
  else
    begin
      FProgramState:=psReadyToRun;
      FFlagPreserveStack:=true;
    end;
end;

{ TScriptExecuter.TUnitSearch }

constructor TScriptExecuter.TUnitSearch.Create(AScriptExecuter: TScriptExecuter);
begin
  inherited Create;
  FScriptExecuter:=AScriptExecuter;
end;

procedure TScriptExecuter.TUnitSearch.AfterConstruction;
begin
  inherited;
  FDict:=TDictionary<string,TUnitSearchInfo>.Create;
  FLibraryDict:=TDictionary<string,TLibInterface>.Create;
end;

procedure TScriptExecuter.TUnitSearch.BeforeDestruction;
var
  LibGUID: string;
begin
  inherited;
  try
    for LibGUID in FLibraryDict.Keys.ToArray do
      FreeLibrary(LibGUID);
  finally
    FLibraryDict.Free;
  end;
  FDict.Free;
end;

procedure TScriptExecuter.TUnitSearch.FreeLibrary(const LibGUID:string);
var
  Value: TLibInterface;
  LibFree: TLibFree;
  LibHandle: TDynLibHandle;
begin
  if (FLibraryDict.TryGetValue(LibGUID,Value)) then
    begin
      LibHandle := Value.LibHandle;
      LibFree := TLibFree(GetDynProc(LibHandle, 'LibFree'));
      if (Assigned(LibFree)) then
        try
          LibFree(@Value);
        except
        end;
      try
        FreeDynLib(LibHandle);
      except
      end;
      FLibraryDict.Remove(LibGUID);
    end;
end;

procedure TScriptExecuter.TUnitSearch.CheckNamespace(const ANamespace: string);
var
  Pair: TPair<string,TUnitSearchInfo>;
begin
  for Pair in FDict.toArray do
    if (Pair.Value.Namespace=ANamespace) then
      RaiseException('Namespace already exists');
end;

procedure TScriptExecuter.TUnitSearch.AddUnit(const ANamespace, AUnitName, AUnitSource: string);
var
  UnitSearchInfo:TUnitSearchInfo;
begin
  if (not(FDict.TryGetValue(UnitName,UnitSearchInfo))) then
    begin
      UnitSearchInfo:=Default(TUnitSearchInfo);
      UnitSearchInfo.Namespace:=ANamespace;
    end;
  UnitSearchInfo.Source:=AUnitSource;
  FDict.AddOrSetValue(AUnitName,UnitSearchInfo);
end;

procedure TScriptExecuter.TUnitSearch.ImportFromPath(const ANamespace,APath:string);
const
  FileExtensions:array[0..3] of string=('.pas', '.dll', '.dylib', '.so');
var
  Element, UnitName, UnitText, UnitTextCopy: string;
  FileList: TArray<string>;
  Match: TMatch;
  
  LengthValue:integer;
  UnitSearchInfo:TUnitSearchInfo;
begin
  CheckNamespace(ANamespace);
  FileList:=TDirectory.GetFiles(
    APath,
    '*.*',
    TSearchOption.soTopDirectoryOnly,
    function(const Path:string;const SearchRec:TSearchRec):boolean
    begin
      Result:=((SearchRec.Attr and faDirectory)=0);
      Result:=Result and (IndexText(ExtractFileExt(SearchRec.Name),FileExtensions)<>-1);
    end
  );
  for Element in FileList do
    if (IsLibraryFile(Element)) then
      ImportFromLibrary(ANamespace,Element)
    else
      begin
        UnitText:=TFile.ReadAllText(Element);
        UnitTextCopy:=UnitText;
        repeat
          Match:=TRegEx.Match(UnitTextCopy,'/{[^}]*}',[roIgnoreCase,roMultiLine]);
          if Match.Success then
            Delete(UnitTextCopy,Match.Index,Match.Length);
        until (not Match.Success);
        repeat
          Match:=TRegEx.Match(UnitTextCopy,'/\(\*[^}]*\*\)',[roIgnoreCase,roMultiLine]);
          if Match.Success then
            Delete(UnitTextCopy,Match.Index,Match.Length);
        until (not Match.Success);
        repeat
          Match:=TRegEx.Match(UnitTextCopy,'\/\/(?:[ ]|\S)*',[roIgnoreCase,roMultiLine]);
          if Match.Success then
            Delete(UnitTextCopy,Match.Index,Match.Length);
        until (not Match.Success);
        Match:=TRegEx.Match(UnitTextCopy,'unit\s+(\S+)\s*;',[roIgnoreCase,roMultiLine]);
        if (Match.Success) then
          UnitName:=Match.Groups[1].Value
        else
          UnitName:=GetFileName(Element);
        FScriptExecuter.InjectUnit(UnitText);
        FScriptExecuter.AddUnit(ANameSpace,UnitName,UnitText);
      end;
end;

procedure TScriptExecuter.TUnitSearch.ImportFromLibrary(const ANamespace: string; const ALibraryName: string);
var
  CurrentDir: string;
  Value: TDynLibHandle;
  LibInit: TLibInit;
  LibInterface: TLibInterface;
begin
  CurrentDir:=TDirectory.GetCurrentDirectory;
  try
    TDirectory.SetCurrentDirectory(ExtractFilePath(ALibraryName));
    Value:=LoadDynLib(ALibraryName, true);
  finally
    TDirectory.SetCurrentDirectory(CurrentDir);
  end;
  try
    LibInit := TLibInit(GetDynProc(Value, 'LibInit'));
    if (not(Assigned(LibInit))) then
      begin
        FreeDynLib(Value);
        Exit;
      end;
    LibInterface := Default(TLibInterface);
    with LibInterface do
      begin
        Context:=NativeInt(FScriptExecuter);
        Namespace:=PChar(ANamespace);
        ExecutionPath:=PChar(ExtractFilePath(ALibraryName));
        LibHandle:=Value;
        Synchronize:=InternalSynchronize;
        InvokeHostProc:=InternalInvokeHostProc;
      end;
    LibInit(@LibInterface);
    if (LibInterface.LibGUID='') then
      RaiseException('Library didn''t set GUID');
    if FLibraryDict.ContainsKey(LibInterface.LibGUID) then
      RaiseException('Library already imported');
    FLibraryDict.AddOrSetValue(LibInterface.LibGUID,LibInterface);
  except
    FreeDynLib(Value);
    raise;
  end;
end;

function TScriptExecuter.TUnitSearch.GetUnitCode(const UnitName:string;Shrink:boolean):string;
var
  UnitSearchInfo:TUnitSearchInfo;
begin
  if (not(FDict.TryGetValue(UnitName,UnitSearchInfo))) then
    Result:=''
  else
    begin
      Result:=UnitSearchInfo.Source;
      if (Shrink) then
        begin
          UnitSearchInfo.Source:='';
          FDict.AddOrSetValue(UnitName,UnitSearchInfo);
        end;
    end;
end;

{ TScriptExecuter }

procedure TScriptExecuter.AfterConstruction;
var Linq:TdwsLinqFactory;
begin
  inherited;
  FVariablesDictionary:=TDictionary<string,variant>.Create;
  FMessageCallbacksDictionary:=TDictionary<variant,variant>.Create;
  FPostedMessages:=TThreadedQueue<TPostedMessage>.Create(16384,60*1000,60*1000);
  FLibraryUnitAdded:=TStringList.Create;
  FUnitSearch:=TUnitSearch.Create(Self);
  TdwsDatabaseLib.Create(Self).Script:=DelphiWebScript;
  Linq:=TdwsLinqFactory.Create(Self);
  Linq.Script:=DelphiWebScript;
  dwsLinqSql.TLinqSqlExtension.Create(DelphiWebScript).LinqFactory:=Linq;
  TScriptUnitBaseLibrary.Create(Self);
  FOutputData:=TJSONObject.Create;
  FPostingMessageEnabled:=true;
end;

procedure TScriptExecuter.BeforeDestruction;
begin
  FInternalDestroying:=true;
  ExecuteScript(''); // Release all resources;
  inherited;
  FPostedMessages.Free;
  FMessageCallbacksDictionary.Free;
  FVariablesDictionary.Free;
  FLibraryUnitAdded.Free;
  FUnitSearch.Free;
  FOutputData.Free;
  FExecution:=nil;
  FProgram:=nil;
end;

procedure TScriptExecuter.ClearConsoleOutput;
begin
  SetConsoleOutput('');
end;

procedure TScriptExecuter.DelphiWebScriptInclude(const scriptName: string;
  var ScriptSource: string);
begin
  ScriptSource:=FUnitSearch.GetUnitCode(scriptName);
end;

function TScriptExecuter.DelphiWebScriptNeedUnit(const UnitName:string;var UnitSource:string):IdwsUnit;
begin
  UnitSource:=FUnitSearch.GetUnitCode(UnitName,true);
end;

function TScriptExecuter.ExecuteScript(Script:string):string;
begin
  Result:=ExecuteScript(Script,nil);
end;

function TScriptExecuter.ExecuteScript(Script:string;InitialVariables:TDictionary<string,variant>):string;
var k:integer;
    OriginalScript, UnitAdded, Error: string;
    FlagDropProgram, Flag: boolean;
    Variable: TPair<string,variant>;
    SymbolList: TObjectList<TSymbol>;
    Symbol: TSymbol;
    Match: TMatch;
    StackParams: TStackParameters;

  procedure RestoreProgram;
  var
    Idx: integer; 
  begin
    // Restore the init expressions to the previous state.
    Idx:=0;
    while (Idx<FProgram.Table.Count) do
      begin
        Symbol:=FProgram.Table.Symbols[Idx];
        if Assigned(Symbol) and (SymbolList.IndexOf(Symbol)=-1) then
          FProgram.Table.Remove(Symbol)
        else
          Inc(Idx);
      end;

    // Restore the previously compiled script.
    FProgram.SourceList.FindScriptSourceItem(MSG_MainModule).SourceFile.Code:=OriginalScript;
  end;

  procedure ReportAndRaiseCompilationErrors;
  var
    k: integer;
    Error: string;
  begin
    for k:=0 to FProgram.Msgs.Count-1 do
      if (FProgram.Msgs[k].IsError) then
        begin
          Error:=FProgram.Msgs[k].AsInfo;
          AddConsoleOutputRow(Error);
        end;
    if (FlagDropProgram) then
      begin
        FExecution:=nil;
        FProgram:=nil;
      end;
    Abort;
  end;

begin
  SymbolList:=TObjectList<TSymbol>.Create(false);
  try
    FOutputData.Free;
    FOutputData:=TJSONObject.Create;
    FVariablesDictionary.Clear;
    FLibraryUnitAdded.Clear;
    InjectUnit(Script);
    FlagDropProgram:=false;
    if (Assigned(FProgram)) then
      begin
        // Preserve all symbols from the current program.
        for k:=0 to FProgram.Table.Count-1 do
          begin
            Symbol:=FProgram.Table.Symbols[k];
            if (Assigned(Symbol)) then
              SymbolList.Add(Symbol);
          end;
        
        // Store the previously compiled script.
        OriginalScript:=FProgram.SourceList.FindScriptSourceItem(MSG_MainModule).SourceFile.Code;

        // Recompiles the new script within the previous context.
        FProgram.Msgs.Clear;
        DelphiWebScript.RecompileInContext(FProgram,Script);

        if FProgram.Msgs.HasErrors then
          // Restore the init expressions to the previous state.
          RestoreProgram;
      end
    else
      begin
        FProgram:=DelphiWebScript.Compile(Script);
        if (FProgram.Msgs.HasErrors) then
          FlagDropProgram:=true
        else
          FProgram.ExecutionsClass:=TOPNBProgramExecution;
      end;
    if (FProgram.Msgs.HasErrors) then
      ReportAndRaiseCompilationErrors
    else
      begin
        TheScriptExecuter:=Self;
        if (Assigned(InitialVariables)) then
          for Variable in InitialVariables.ToArray do
            FVariablesDictionary.AddOrSetValue(Variable.Key,Variable.Value);
        FVariablesDictionary.AddOrSetValue(varConsoleOutout,'');
        try
          if (Assigned(FExecution)) then
            FExecution.Execute(0)
          else
            FExecution:=FProgram.Execute;
        except
          on E: Exception do
            FExecution.Msgs.AddRuntimeError(E);
        end;
        if FInternalDestroying then
          FExecution:=nil
        else
          if (not(FExecution.Msgs.HasErrors)) then
            Result:=FExecution.Result.ToString
          else
            with FExecution.Msgs do
              begin
                Error:=Msgs[Count-1].Text;
                AddConsoleOutputRow(Error);
                Abort;
              end;

        // If libraries have been imported then...
        if (FLibraryUnitAdded.Count>0) then
          begin
            // References the units.
            Script:='uses ';
            for UnitAdded in FLibraryUnitAdded do
              Script:=Script+UnitAdded+',';
            Delete(Script,Length(Script),1);
            Script:=Script+';'+sLineBreak;

            // Compile again for import the new unit.
            FProgram.Msgs.Clear;
            DelphiWebScript.RecompileInContext(FProgram,Script);

            // Check for abstract errors due to imported unit symbols not yet initialized.
            if FProgram.Msgs.HasErrors then
              for k:=0 to FProgram.Msgs.Count-1 do
                if (FProgram.Msgs[k].IsError) then
                  begin
                    Flag:=true;
                    Error:=FProgram.Msgs[k].AsInfo;
                    for UnitAdded in FLibraryUnitAdded do
                      begin
                        Match:=TRegEx.Match(Error,Format('Error: %s [line: [\d]+, column: [\d]+, file: %s]',[RTE_InstanceOfAbstractClass,UnitAdded]),[roIgnoreCase]);
                        if Match.Success then
                          begin
                            Flag:=false;
                            Break;
                          end;
                      end;
                    if (Flag) then
                      begin
                        // Restore the init expressions to the previous state.
                        RestoreProgram;

                        ReportAndRaiseCompilationErrors;
                      end;
                  end;

            // Execute the compilated stataments.
            FExecution.Execute(0);

            // Initialize all symbols that have not been initialized.
            FProgram.UnitMains.Initialize(FProgram.ProgramObject.CompileMsgs);
            for k:=0 to FProgram.Table.Count-1 do
              begin
                Symbol:=FProgram.Table[k];
                if (SymbolList.IndexOf(Symbol)=-1) then
                  if (Symbol is TUnitSymbol) and (FLibraryUnitAdded.IndexOf(Symbol.Name)<>-1) then
                    begin
                      TUnitSymbol(Symbol).Table.Initialize(FProgram.ProgramObject.CompileMsgs);
                      if (Assigned(TUnitSymbol(Symbol).Main.InitializationExpr)) then
                        TUnitSymbol(Symbol).Main.InitializationExpr.EvalNoResult(FExecution.GetExecutionObject);
                      if (Assigned(TUnitSymbol(Symbol).Main.FinalizationExpr)) then
                        begin
                          FProgram.ProgramObject.AddFinalExpr(TUnitSymbol(Symbol).Main.FinalizationExpr as TBlockExprBase);
                          TUnitSymbol(Symbol).Main.FinalizationExpr.IncRefCount;
                        end;
                    end;
              end;
        end;
      end;
  finally
    if (Assigned(SymbolList)) then
      SymbolList.Free;
  end;
end;

procedure TScriptExecuter.InjectUnit(var Script:string);
var Position,InterfacePosition:integer;
    ScriptCopy:string;
begin
  ScriptCopy:=Trim(Script); // The script must be kept as it is.
  if (AnsiPosEx('unit',ScriptCopy)=1) then
    begin
      InterfacePosition:=AnsiPosEx('interface',Script);
      if (InterfacePosition=0) then
        Position:=Pos(';',Script)+1
      else
        Position:=InterfacePosition+9;
    end
  else
    Position:=1;
  Insert(' uses '+GetUnitList+'; ',Script,Position);
end;

function TScriptExecuter.PopPostMessage(out PostedMessage:TPostedMessage):boolean;
begin
  with FPostedMessages do
    begin
      Result:=(QueueSize>0);
      if (Result) then
        PostedMessage:=PopItem;
    end;
end;

procedure TScriptExecuter.PushPostMessage(const PostedMessage:TPostedMessage);
begin
  if (FPostingMessageEnabled) then
    FPostedMessages.PushItem(PostedMessage);
end;

function TScriptExecuter.GetMustRestartFlag:boolean;
var Value:variant;
begin
  if (not(FVariablesDictionary.TryGetValue(varFlagRestart,Value))) then
    Value:=false;
  Result:=VarToBoolean(Value);
end;

procedure TScriptExecuter.SetMustRestartFlag(const Value:boolean);
begin
  FVariablesDictionary.AddOrSetValue(varFlagRestart,Value);
end;

function TScriptExecuter.GetMessageCallback(const Key:variant;out MessageCallback:variant):boolean;
begin
  Result:=FMessageCallbacksDictionary.TryGetValue(Key,MessageCallback);
end;

function TScriptExecuter.GetCancelPending:boolean;
var Value:variant;
begin
  if (not(FVariablesDictionary.TryGetValue(varFlagCancel,Value))) then
    Value:=false;
  Result:=VarToBoolean(Value);
end;

procedure TScriptExecuter.SetCancelPending(const Value:boolean);
begin
  FVariablesDictionary.AddOrSetValue(varFlagCancel,Value);
end;

function TScriptExecuter.GetConsoleOutputBlockPosition(const Output,IDBlock: string;
  out StartPos, EndPos: integer): boolean;
begin
  StartPos:=AnsiPosEx(Format(ConsoleOutputStartBlockTemplate,[IDBlock]),Output);
  if (StartPos=0) then
    begin
      StartPos:=Length(ConsoleOutputEndBlockTemplate);
      EndPos:=MaxInt;
      Result:=false;
    end
  else
    begin
      EndPos:=AnsiPosEx(Format(ConsoleOutputEndBlockTemplate,[IDBlock]),Output,StartPos+1);
      if (EndPos=0) then
        EndPos:=MaxInt
      else
        Inc(EndPos,Length(Format(ConsoleOutputEndBlockTemplate,[IDBlock])));
      Result:=true;
    end;
end;

function TScriptExecuter.WriteConsoleOutputBlock(const Text: string; IDBlockRef: string;
  Position: TConsoleOutputBlockPosition): string;
var
  Output: string;
  StartPos, EndPos: integer;
begin
  Output:=GetConsoleOutput;
  if (IDBlockRef='') and (Position=bpDelete) then
    Exit
  else if IDBlockRef='' then
    begin
      IDBlockRef:='consblok'+GenerateID(8,true);
      Position:=bpAdd;
    end
  else if GetConsoleOutputBlockPosition(Output,IDBlockRef,StartPos,EndPos) then
    case Position of
      bpAdd: Position:=bpReplace;
      bpPrior, bpNext: IDBlockRef:='consblok'+GenerateID(8,true);
    end
  else if Position=bpDelete then
    Exit
  else
    Position:=bpAdd;
  case Position of
    bpAdd:
      Output:=
        Output+
        Format(ConsoleOutputStartBlockTemplate,[IDBlockRef])+
        Text+
        Format(ConsoleOutputEndBlockTemplate,[IDBlockRef]);
    bpReplace:
      Output:=
        Copy(Output,1,StartPos-1)+
        Format(ConsoleOutputStartBlockTemplate,[IDBlockRef])+
        Text+
        Format(ConsoleOutputEndBlockTemplate,[IDBlockRef])+
        Copy(Output,EndPos,MaxInt);
    bpDelete:
      Output:=
        Copy(Output,1,StartPos-1)+
        Copy(Output,EndPos,MaxInt);
    bpPrior:
      Insert(Text,Output,StartPos);
    bpNext:
      Insert(Text,Output,EndPos);
  end;
  SetConsoleOutput(Output);
  Result:=IDBlockRef;
end;

function TScriptExecuter.GetUnitList:string;
begin
  Result:='uBaseLibrary';
end;

function TScriptExecuter.GetConsoleOutput:string;
var Value:variant;
begin
  if (not(FVariablesDictionary.TryGetValue(varConsoleOutout,Value))) then
    Value:='';
  Result:=VarToStr(Value);
end;

procedure TScriptExecuter.SetConsoleOutput(const Value: string);
begin
  FVariablesDictionary.AddOrSetValue(varConsoleOutout,Value);
  if (CancelPending) then
    begin
      FVariablesDictionary.AddOrSetValue(varConsoleOutout,'Aborted');
      Abort;
    end;
end;

procedure TScriptExecuter.AddMessageCallback(const Key,MessageCallback:variant);
begin
  FMessageCallbacksDictionary.AddOrSetValue(Key,MessageCallback);
end;

procedure TScriptExecuter.AddConsoleOutputRow(const AMessage:string; BreakLine:boolean);
var Output:string;
begin
  Output:=GetConsoleOutput+AMessage;
  if BreakLine then
    Output:=Output+'<br>';
  SetConsoleOutput(Output);
end;

procedure TScriptExecuter.Import(const ANamespace, AValue: string);
var
  Value: string;
begin
  Value:=Trim(AValue);
  if StartsText('.\',Value) or StartsText('./',Value) then
    Value:=IncludeTrailingPathDelimiter(FExecutionPath)+Copy(Value,3,MaxInt)
  else if StartsText('..\',Value) or StartsText('../',Value) then
    Value:=IncludeTrailingPathDelimiter(FExecutionPath)+Value;
  if (IsLibraryFile(Value)) then
    FUnitSearch.ImportFromLibrary(ANamespace,Value)
  else
    FUnitSearch.ImportFromPath(ANamespace,Value);
end;

procedure TScriptExecuter.AddUnit(const ANamespace,AUnitName,AUnitText:string);
begin
  FUnitSearch.AddUnit(ANamespace,AUnitName,AUnitText);
  FLibraryUnitAdded.Add(AUnitName);
end;

function TScriptExecuter.GetLibInterface(const LibGUID: string): TLibInterface;
begin
  if (FUnitSearch.FLibraryDict.TryGetValue(LibGUID, Result)) then
    Exit;
  Result := Default(TLibInterface);
end;

procedure TScriptExecuter.LoadLibraries(var Args: array of variant);
var k: integer;
    LocalArgs: array of variant;
begin
  SetLength(LocalArgs,Length(Args));
  for k:=0 to High(Args) do
    LocalArgs[k]:=VarToStr(Args[k]);
  InternalSynchronize(
    procedure
      var k: integer;
    begin
      for k:=0 to High(LocalArgs) do
        LocalArgs[k]:=LoadDynLib(LocalArgs[k], true);
    end
  );
  for k:=0 to High(Args) do
    Args[k]:=LocalArgs[k];
end;

procedure TScriptExecuter.UnloadLibraries(const Args: array of variant);
var k: integer;
    LocalArgs: array of variant;
begin
  SetLength(LocalArgs,Length(Args));
  for k:=0 to High(Args) do
    LocalArgs[k]:=VarToStr(Args[k]);
  InternalSynchronize(
    procedure
    var k: integer;
    begin
      for k:=0 to High(LocalArgs) do
        FreeDynLib(LocalArgs[k]);
    end
  );
end;

end.
