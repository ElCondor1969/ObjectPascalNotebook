unit uScriptExecuter;

interface

uses
  System.Classes, dwsUtils, System.SysUtils, System.IOUtils, System.StrUtils, Variants, System.Types, Generics.Collections,
  System.RegularExpressions, uDynLibLoader, JSON, uLibInterface, uUtility, dwsStrings, dwsComp, dwsExprs, dwsDataContext, 
  dwsCompiler, dwsFunctions, dwsStack, dwsClassesLibModule, dwsJSONConnector, dwsDataBaseLibModule, dwsLinq, dwsLinqSql, 
  dwsSymbols, dwsUnitSymbols, dwsScriptSource, dwsRTTIConnector, dwsRTTIFunctions;

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
      ConsoleOutputStartBlockTemplate='<!-- _console_output_start_%s_ -->';
      ConsoleOutputEndBlockTemplate='<!-- _console_output_end_%s_ -->';
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
        procedure FreeLibrary(const ANamespace:string);
      public
        constructor Create(AScriptExecuter: TScriptExecuter);
        procedure AfterConstruction;override;
        procedure BeforeDestruction;override;
        procedure ImportFromPath(const ANamespace,APath:string);
        procedure ImportFromLibrary(const ANamespace,ALibraryName:string);
        procedure AddUnit(const ANamespace,AUnitName,AUnitSource:string);
        function GetUnitCode(const UnitName:string;Shrink:boolean=false):string;
      end;
  private
    { Private declarations }
    FExecutionPath:string;
    FVariablesDictionary:TDictionary<string,variant>;
    FUnitTypeAddedDictionary:TDictionary<string,TStringArray>;
    FUnitSearch:TUnitSearch;
    FProgram:IdwsProgram;
    FExecution:IdwsProgramExecution;
    FDestroying:boolean;
    procedure InjectUnit(var Script:string);
    function GetMustRestartFlag:boolean;
    procedure SetMustRestartFlag(const Value:boolean);
  protected
    { Protected declarations }
    procedure AfterConstruction;override;
    procedure BeforeDestruction;override;
    function GetUnitList:string;virtual;
  public
    { Public declarations }
    type
      TConsoleOutputBlockPosition=(bpAdd,bpReplace,bpDelete,bpPrior,bpNext);
  public
    { Public declarations }
    function ExecuteScript(Script:string;InternalExecution:boolean=false):string;overload;
    function ExecuteScript(Script:string;InitialVariables:TDictionary<string,variant>;InternalExecution:boolean=false):string;overload;
    function GetConsoleOutput:string;
    procedure SetConsoleOutput(const Value:string);
    procedure AddConsoleOutputRow(const AMessage:string;BreakLine:boolean=true);
    procedure ClearConsoleOutput;
    function WriteConsoleOutputBlock(const Text:string;IDBlockRef:string='';Position:TConsoleOutputBlockPosition=bpAdd):string;
    function GetConsoleOutputBlockPosition(const Output,IDBlock:string;out StartPos,EndPos:integer):boolean;
    procedure Import(const ANamespace,AValue:string);
    procedure AddUnit(const ANamespace,AUnitName,AUnitText:string;TypeAddedList:TStringArray);
    function GetLibInterface(const ANamespace:string):TLibInterface;
    property ExecutionPath:string read FExecutionPath write FExecutionPath;
    property VariablesDictionary:TDictionary<string,variant> read FVariablesDictionary;
    property MustRestartFlag:boolean read GetMustRestartFlag write SetMustRestartFlag;
  end;

implementation

{$R *.dfm}

uses
  uScriptUnitBaseLibrary, uUnitScripter;

const
  varConsoleOutout='__CONSOLE_OUTPUT__';
  varFlagRestart='__FLAG_RESTART__';

type
  TOPNBProgramExecution=class(TdwsProgramExecution)
  private
    FFlagPreserveStack:boolean;
  public
    function BeginProgram:boolean;override;
    procedure EndProgram;override;
  end;

{ TOPNBProgramExecution }

function TOPNBProgramExecution.BeginProgram:boolean;
var
  TempStack:TStackMixIn;
begin
  if (FFlagPreserveStack) then
    TempStack.Assign(FStack);
  try
    if (FFlagPreserveStack) then
      ProgramInfo.Free;
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
  FProgramState:=psReadyToRun;
  FFlagPreserveStack:=true;
end;

(*
procedure TOPNBProgramExecution.EndProgram;
var
  TempStack:TStackMixIn;
begin
  TempStack.Assign(FStack);
  try
    inherited;
    FStack.Assign(TempStack);
  finally
    TempStack.Finalize;
  end;
end;
*)

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
  Namespace: string;
begin
  inherited;
  try
    for Namespace in FLibraryDict.Keys.ToArray do
      FreeLibrary(Namespace);
  finally
    FLibraryDict.Free;
  end;
  FDict.Free;
end;

procedure TScriptExecuter.TUnitSearch.FreeLibrary(const ANamespace:string);
var
  Value: TLibInterface;
  LibFree: TLibFree;
  LibHandle: TDynLibHandle;
begin
  if (FLibraryDict.TryGetValue(ANamespace,Value)) then
    begin
      LibHandle := Value.LibHandle;
      LibFree := TLibFree(GetDynProc(LibHandle, 'LibFree'));
      LibFree(@Value);
      try
        FreeDynLib(LibHandle);
      except
      end;
      FLibraryDict.Remove(ANamespace);
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
  FileExtensions:array[0..1] of string=('.pas', '.pp');
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
    TSearchOption(1), // soAllDirectories
    function(const Path:string;const SearchRec:TSearchRec):boolean
    begin
      Result:=((SearchRec.Attr and faDirectory)=0);
      Result:=Result and (IndexText(ExtractFileExt(SearchRec.Name),FileExtensions)<>-1);
    end
  );
  for Element in FileList do
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
      FScriptExecuter.AddUnit(ANameSpace,UnitName,UnitText,[]);
    end;
end;

procedure TScriptExecuter.TUnitSearch.ImportFromLibrary(const ANamespace: string; const ALibraryName: string);
var
  Value: TDynLibHandle;
  LibInit: TLibInit;
  LibInterface: TLibInterface;
begin
  FreeLibrary(ANamespace);
  Value:=LoadDynLib(ALibraryName);
  if (Value = 0) then
    RaiseException('Error loading library: %s',[ALibraryName]);
  try
    CheckNamespace(ANamespace);
    LibInit := TLibInit(GetDynProc(Value, 'LibInit'));
    LibInterface := Default(TLibInterface);
    with LibInterface do
      begin
        Context:=NativeInt(FScriptExecuter);
        Namespace:=PChar(ANamespace);
        LibHandle:=Value;
        CreateUnitByDef:=CreateUnitByDefImpl;
      end;
    LibInit(@LibInterface);
    FLibraryDict.AddOrSetValue(ANamespace,LibInterface);
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
  FUnitTypeAddedDictionary:=TDictionary<string,TStringArray>.Create;
  FUnitSearch:=TUnitSearch.Create(Self);
  TdwsDatabaseLib.Create(Self).Script:=DelphiWebScript;
  Linq:=TdwsLinqFactory.Create(Self);
  Linq.Script:=DelphiWebScript;
  dwsLinqSql.TLinqSqlExtension.Create(DelphiWebScript).LinqFactory:=Linq;
  TScriptUnitBaseLibrary.Create(Self);
end;

procedure TScriptExecuter.BeforeDestruction;
begin
  FDestroying:=true;
  ExecuteScript(''); // Release all resources;
  inherited;
  FVariablesDictionary.Free;
  FUnitTypeAddedDictionary.Free;
  FUnitSearch.Free;
  FExecution:=nil;
  FProgram:=nil;
end;

procedure TScriptExecuter.ClearConsoleOutput;
begin
  SetConsoleOutput('');
end;

procedure TScriptExecuter.DelphiWebScriptInclude(const scriptName: string;
  var scriptSource: string);
begin
  scriptSource:=FUnitSearch.GetUnitCode(scriptName);
end;

function TScriptExecuter.DelphiWebScriptNeedUnit(const UnitName:string;var UnitSource:string):IdwsUnit;
begin
  UnitSource:=FUnitSearch.GetUnitCode(UnitName,true);
end;

function TScriptExecuter.ExecuteScript(Script:string;InternalExecution:boolean):string;
begin
  Result:=ExecuteScript(Script,nil,InternalExecution);
end;

function TScriptExecuter.ExecuteScript(Script:string;InitialVariables:TDictionary<string,variant>;InternalExecution:boolean):string;
var k,h:integer;
    Errors,Error,OriginalScript,UsesList,TypeAdded:string;
    FlagDropProgram, FlagTrickRecompile:boolean;
    Variable:TPair<string,variant>;
    UnitTypeAddedVariable:TPair<string,TStringArray>;
    SymbolList:TObjectList<TSymbol>;
    Symbol,Symbol2:TSymbol;
    Match: TMatch;
begin
  //SymbolList:=nil;
  SymbolList:=TObjectList<TSymbol>.Create(false);
  FVariablesDictionary.Clear;
  if (not(InternalExecution)) then
    FUnitTypeAddedDictionary.Clear;
  InjectUnit(Script);
  FlagDropProgram:=false;
  FlagTrickRecompile:=false;
  try
    if (Assigned(FProgram)) then
      try
        //SymbolList:=TObjectList<TSymbol>.Create(false);

        // Preserve all symbols from the current program.
        for k:=0 to FProgram.Table.Count do
          SymbolList.Add(FProgram.Table.Symbols[k]);
        
        // Store the previously compiled script.
        OriginalScript:=FProgram.SourceList.FindScriptSourceItem(MSG_MainModule).SourceFile.Code;

        // Recompiles the new script within the previous context.
        FProgram.Msgs.Clear;
        DelphiWebScript.RecompileInContext(FProgram,Script);

        if FProgram.Msgs.HasErrors and (FUnitTypeAddedDictionary.Count>0) then
          for k:=0 to FProgram.Msgs.Count-1 do
            if (FProgram.Msgs[k].IsError) then
              begin
                Error:=FProgram.Msgs[k].AsInfo;
                for UnitTypeAddedVariable in FUnitTypeAddedDictionary do
                  begin
                    Match:=TRegEx.Match(Error,Format('Error: %s [line: [\d]+, column: [\d]+, file: %s]',[RTE_InstanceOfAbstractClass,UnitTypeAddedVariable.Key]),[roIgnoreCase,roMultiLine]);
                    if Match.Success then
                      begin
                        for h:=0 to FProgram.Table.Count-1 do
                          begin
                            Symbol:=FProgram.Table[h];
                            if (SymbolList.IndexOf(Symbol)=-1) then
                              if (Symbol is TUnitSymbol) and not SameText(Symbol.Name,'uBaseLibrary') then
                                TUnitSymbol(Symbol).Table.Initialize(FProgram.ProgramObject.CompileMsgs);
                          end;
                        FlagTrickRecompile:=true;
                        Break;
                      end;
                  end;
                if (FlagTrickRecompile) then
                  Break;
              end;
        if (FlagTrickRecompile) then
          try
            FProgram.Msgs.Clear;
            DelphiWebScript.RecompileInContext(FProgram,Script);
          finally
            FUnitTypeAddedDictionary.Clear;
          end;

        if FProgram.Msgs.HasErrors then
          begin
            // Restore the init expressions to the previous state.
            k:=0;
            while (k<FProgram.Table.Count) do
              begin
                Symbol:=FProgram.Table.Symbols[k];
                if (SymbolList.IndexOf(Symbol)=-1) then
                  FProgram.Table.Remove(Symbol)
                else
                  Inc(k);
              end;

            // Restore the previously compiled script.
            FProgram.SourceList.FindScriptSourceItem(MSG_MainModule).SourceFile.Code:=OriginalScript;
          end;
      finally
        //SymbolList.Free;
      end
    else
      begin
        FProgram:=DelphiWebScript.Compile(Script);
        if (FProgram.Msgs.HasErrors) then
          FlagDropProgram:=true
        else if FDestroying then
          FProgram.ExecutionsClass:=nil
        else
          FProgram.ExecutionsClass:=TOPNBProgramExecution;
      end;
    if (FProgram.Msgs.HasErrors) then
      begin
        Errors:='';
        for k:=0 to FProgram.Msgs.Count-1 do
          if (FProgram.Msgs[k].IsError) then
            begin
              Error:=FProgram.Msgs[k].AsInfo;
              AddConsoleOutputRow(Error);
              Errors:=Errors+Error+#13#10;
            end;
        if (FlagDropProgram) then
          begin
            FExecution:=nil;
            FProgram:=nil;
          end;
        RaiseException(Errors);
      end
    else
      begin
        if (Assigned(InitialVariables)) then
          for Variable in InitialVariables.ToArray do
            FVariablesDictionary.AddOrSetValue(Variable.Key,Variable.Value);
        FVariablesDictionary.AddOrSetValue(varConsoleOutout,'');
        if FDestroying then
          begin
            FProgram.ExecutionsClass:=nil;
            FExecution:=nil;
          end;
        if (Assigned(FExecution)) then
          FExecution.Execute(0)
        else
          FExecution:=FProgram.Execute;
        if (not(FExecution.Msgs.HasErrors)) then
          Result:=FExecution.Result.ToString
        else
          with FExecution.Msgs do
            begin
              Error:=Msgs[Count-1].Text;
              AddConsoleOutputRow(Error);
              RaiseException(Error);
            end;

        // !!!!!!
        if (FUnitTypeAddedDictionary.Count>0) then
          for k:=0 to FProgram.Table.Count-1 do
            begin
              Symbol:=FProgram.Table[k];
              if (SymbolList.IndexOf(Symbol)=-1) then
                if (Symbol is TUnitSymbol) and not SameText(Symbol.Name,'uBaseLibrary') then
                  TUnitSymbol(Symbol).Table.Initialize(FProgram.ProgramObject.CompileMsgs);
            end;
        // !!!!!!

        // If libraries have been imported, then references the units.
        if (FUnitTypeAddedDictionary.Count>0) then
          try
            (* SymbolList:=TObjectList<TSymbol>.Create(false);
            for k:=0 to FProgram.Table.Count do
              SymbolList.Add(FProgram.Table.Symbols[k]); *)

            UsesList:='';
            Script:='';
            for UnitTypeAddedVariable in FUnitTypeAddedDictionary do
              begin
                UsesList:=UsesList+UnitTypeAddedVariable.Key+',';
                for TypeAdded in UnitTypeAddedVariable.Value do
                  Script:=
                    Script+
                    Format('%s=class(%s_%s) public end;',[TypeAdded,TypeAdded,UnitTypeAddedVariable.Key])+sLineBreak;
              end;
            Delete(UsesList,Length(UsesList),1);
            if (Script<>'') then
              Script:='type'+sLineBreak+Script;
            Script:='uses'+sLineBreak+UsesList+';'+sLineBreak+Script;
            ExecuteScript(Script,true);

            // Tricks the added class types.
            (* Script:='';
            for k:=0 to FProgram.Table.Count-1 do
              begin
                Symbol:=FProgram.Table[k];
                if (SymbolList.IndexOf(Symbol)=-1) then
                  if (Symbol is TClassSymbol) then
                    Script:=
                      Script+
                      Format('type %s_%s=class(%s) public end;',[Symbol.Name,GenerateID(16,true),Symbol.Name])+sLineBreak
                  else if (Symbol is TUnitSymbol) and not SameText(Symbol.Name,'uBaseLibrary') then
                    for h:=0 to TUnitSymbol(Symbol).Table.Count-1 do
                      begin
                        Symbol2:=TUnitSymbol(Symbol).Table[h];
                        if (Symbol2 is TClassSymbol) then
                          Script:=
                            Script+
                            Format('type %s_%s=class(%s) public end;',[Symbol2.Name,GenerateID(16,true),Symbol2.Name])+sLineBreak;
                      end;
              end;
            if (Script<>'') then
              ExecuteScript(Script,nil); *)
          finally
            //SymbolList.Free;
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

procedure TScriptExecuter.AddUnit(const ANamespace,AUnitName,AUnitText:string;TypeAddedList:TStringArray);
begin
  FUnitSearch.AddUnit(ANamespace,AUnitName,AUnitText);
  FUnitTypeAddedDictionary.AddOrSetValue(AUnitName,TypeAddedList);
end;

function TScriptExecuter.GetLibInterface(const ANamespace: string): TLibInterface;
begin
  if (FUnitSearch.FLibraryDict.TryGetValue(ANamespace, Result)) then
    Exit;
  Result := Default(TLibInterface);
end;

end.
