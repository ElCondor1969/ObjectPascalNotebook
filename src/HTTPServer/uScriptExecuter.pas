unit uScriptExecuter;

interface

uses
  System.Classes, dwsUtils, System.SysUtils, System.IOUtils, System.StrUtils, Variants, System.Types, Generics.Collections,
  uDynLibLoader, JSON, uLibInterface, dwsStrings, dwsComp, dwsExprs, dwsDataContext, dwsCompiler, dwsFunctions, dwsStack, dwsClassesLibModule,
  dwsJSONConnector, dwsDataBaseLibModule, dwsLinq, dwsLinqSql, dwsSymbols, dwsUnitSymbols, dwsScriptSource,
  dwsRTTIConnector, dwsRTTIFunctions;

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
    type
      TUnitSearchInfo=record
        Namespace: string;
        Path: array of string;
        Source: string;
      end;

      TUnitSearch=class(TObject)
      private
        FScriptExecuter: TScriptExecuter;
        FDict:TDictionary<string,TUnitSearchInfo>;
        FLibraryDict:TDictionary<string,TLibInterface>;
        procedure RemoveNamespace(const ANamespace:string);
        procedure FreeLibrary(const ANamespace:string);
      public
        constructor Create(AScriptExecuter: TScriptExecuter);
        procedure AfterConstruction;override;
        procedure BeforeDestruction;override;
        procedure ImportFromPath(const ANamespace,APath:string);
        procedure ImportFromLibrary(const ANamespace,ALibraryName:string);
        procedure AddUnit(const ANamespace, AUnitName,AUnitSource:string);
        function GetUnitCode(const UnitName:string):string;
      end;
  private
    { Private declarations }
    FVariablesDictionary:TDictionary<string,variant>;
    FUnitSearch:TUnitSearch;
    FProgram:IdwsProgram;
    FExecution:IdwsProgramExecution;
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
    function ExecuteScript(Script:string):string;overload;
    function ExecuteScript(Script:string;InitialVariables:TDictionary<string,variant>):string;overload;
    function GetConsoleOutput:string;
    procedure AddConsoleOutputRow(const AMessage:string);
    procedure Import(const ANamespace,AValue:string);
    procedure AddUnit(const ANamespace, AUnitName, AUnitText: string);
    function GetLibInterface(const ANamespace:string):TLibInterface;
    property VariablesDictionary:TDictionary<string,variant> read FVariablesDictionary;
    property MustRestartFlag:boolean read GetMustRestartFlag write SetMustRestartFlag;
  end;

implementation

{$R *.dfm}

uses
  uUtility, uScriptUnitBaseLibrary, uDWSScripter;

const
  varConsoleOutout='__CONSOLE_OUTPUT__';
  varFlagRestart='__FLAG_RESTART__';

var
  FlagPreserveStack:boolean=false;

type
  TOPNBProgramExecution=class(TdwsProgramExecution)
  public
    constructor Create(aProgram : TdwsMainProgram; const stackParams : TStackParameters); override;
    function BeginProgram:boolean;override;
    procedure EndProgram;override;
  end;

{ TOPNBProgramExecution }

constructor TOPNBProgramExecution.Create(aProgram: TdwsMainProgram; const stackParams: TStackParameters);
begin
  inherited;
end;

function TOPNBProgramExecution.BeginProgram:boolean;
var
  TempStack:TStackMixIn;
begin
  if (FlagPreserveStack) then
    TempStack.Assign(FStack);
  try
    Result:=inherited;
    if (FlagPreserveStack) then
      FStack.Assign(TempStack);
  finally
    if (FlagPreserveStack) then
      TempStack.Finalize;
  end;
end;

procedure TOPNBProgramExecution.EndProgram;
begin
  ProgramInfo.Free;
  FProgramState:=psReadyToRun;
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
  //LibFree: TLibFree;
  LibHandle: TDynLibHandle;
begin
  if (FLibraryDict.TryGetValue(ANamespace,Value)) then
    begin
      LibHandle := Value.LibHandle;
      Async(
        procedure
        var
          LibFree: TLibFree;
        begin
          try
            LibFree := TLibFree(GetDynProc(LibHandle, 'LibFree'));
            LibFree(@Value);
            FreeDynLib(LibHandle);
          except
          end;
        end
      );
      FLibraryDict.Remove(ANamespace);
    end;
end;

procedure TScriptExecuter.TUnitSearch.RemoveNamespace(const ANamespace: string);
var
  Pair: TPair<string,TUnitSearchInfo>;
begin
  for Pair in FDict.toArray do
    if (Pair.Value.Namespace=ANamespace) then
      FDict.Remove(Pair.Key);
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
  SetLength(UnitSearchInfo.Path,0);
  UnitSearchInfo.Source:=AUnitSource;
  FDict.AddOrSetValue(AUnitName,UnitSearchInfo);
end;

procedure TScriptExecuter.TUnitSearch.ImportFromPath(const ANamespace,APath:string);
const
  FileExtensions:array[0..2] of string=('.pas', '.pp', '.inc');
var 
  Element,UnitName:string;
  LengthValue:integer;
  FileList:TArray<string>;
  UnitSearchInfo:TUnitSearchInfo;

  function GetName:string;
  begin
    if (IndexText(ExtractFileExt(Element),FileExtensions)<2) then
      Result:=GetFileName(Element)
    else
      Result:=ExtractFileName(Element);
  end;

begin
  RemoveNamespace(ANamespace);
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
      UnitName:=GetName;
      if (not(FDict.TryGetValue(UnitName,UnitSearchInfo))) then
        begin
          UnitSearchInfo:=Default(TUnitSearchInfo);
          UnitSearchInfo.Namespace:=ANamespace;
        end;
      LengthValue:=Length(UnitSearchInfo.Path);
      SetLength(UnitSearchInfo.Path,LengthValue+1);
      UnitSearchInfo.Path[LengthValue]:=Element;
      FDict.AddOrSetValue(UnitName,UnitSearchInfo);
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
    RemoveNamespace(ANamespace);
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

function TScriptExecuter.TUnitSearch.GetUnitCode(const UnitName:string):string;
var
  UnitSearchInfo:TUnitSearchInfo;
begin
  if (not(FDict.TryGetValue(UnitName,UnitSearchInfo))) then
    Result:=''
  else if (UnitSearchInfo.Source<>'') then
    Result:=UnitSearchInfo.Source
  else if (Length(UnitSearchInfo.Path)=0) then
    Result:=''
  else
    Result:=TFile.ReadAllText(UnitSearchInfo.Path[0]);
end;

{ TScriptExecuter }

procedure TScriptExecuter.AfterConstruction;
var Linq:TdwsLinqFactory;
begin
  inherited;
  FVariablesDictionary:=TDictionary<string,variant>.Create;
  FUnitSearch:=TUnitSearch.Create(Self);
  TdwsDatabaseLib.Create(Self).Script:=DelphiWebScript;
  Linq:=TdwsLinqFactory.Create(Self);
  Linq.Script:=DelphiWebScript;
  dwsLinqSql.TLinqSqlExtension.Create(DelphiWebScript).LinqFactory:=Linq;
  TScriptUnitBaseLibrary.Create(Self);
end;

procedure TScriptExecuter.BeforeDestruction;
begin
  inherited;
  FVariablesDictionary.Free;
  FUnitSearch.Free;
  FExecution:=nil;
  FProgram:=nil;
end;

procedure TScriptExecuter.DelphiWebScriptInclude(const scriptName: string;
  var scriptSource: string);
begin
  scriptSource:=FUnitSearch.GetUnitCode(scriptName);
end;

function TScriptExecuter.DelphiWebScriptNeedUnit(const UnitName:string;var UnitSource:string):IdwsUnit;
begin
  UnitSource:=FUnitSearch.GetUnitCode(UnitName);
end;

function TScriptExecuter.ExecuteScript(Script:string):string;
begin
  Result:=ExecuteScript(Script,nil);
end;

function TScriptExecuter.ExecuteScript(Script:string;InitialVariables:TDictionary<string,variant>):string;
var k:integer;
    Errors,Error,OriginalScript:string;
    FlagDropProgram:boolean;
    Variable:TPair<string,variant>;
    SymbolList:TObjectList<TSymbol>;
    Symbol:TSymbol;
begin
  SymbolList:=nil;
  FVariablesDictionary.Clear;
  InjectUnit(Script);
  FlagDropProgram:=false;
  if (Assigned(FProgram)) then
    try
      SymbolList:=TObjectList<TSymbol>.Create(false);

      // Preserve all symbols from the current program.
      for k:=0 to FProgram.Table.Count do
        SymbolList.Add(FProgram.Table.Symbols[k]);
      
      // Store the previously compiled script.
      OriginalScript:=FProgram.SourceList.FindScriptSourceItem(MSG_MainModule).SourceFile.Code;

      // Recompiles the new script within the previous context.
      FProgram.Msgs.Clear;
      DelphiWebScript.RecompileInContext(FProgram,Script);
      if (FProgram.Msgs.HasErrors) then
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
      SymbolList.Free;
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
      if (Assigned(FExecution)) then
        FExecution.Execute(0)
      else
        begin
          FExecution:=FProgram.Execute;
          FlagPreserveStack:=true;
        end;
      if (not(FExecution.Msgs.HasErrors)) then
        Result:=FExecution.Result.ToString
      else
        with FExecution.Msgs do
          begin
            Error:=Msgs[Count-1].Text;
            AddConsoleOutputRow(Error);
            RaiseException(Error);
          end;
    end;
end;

procedure TScriptExecuter.InjectUnit(var Script:string);
var Position,InterfacePosition:integer;
    CopiaScript:string;
begin
  CopiaScript:=Trim(Script); // The script must be kept as it is.
  if (AnsiPosEx('unit',CopiaScript)=1) then
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

procedure TScriptExecuter.AddConsoleOutputRow(const AMessage:string);
var Output:string;
begin
  Output:=GetConsoleOutput+Format('<p>%s</p>',[AMessage]);
  FVariablesDictionary.AddOrSetValue(varConsoleOutout,Output);
end;

procedure TScriptExecuter.Import(const ANamespace, AValue: string);
begin
  if (IsLibraryFile(AValue)) then
    FUnitSearch.ImportFromLibrary(ANamespace,AValue)
  else
    FUnitSearch.ImportFromPath(ANamespace,AValue);
end;

procedure TScriptExecuter.AddUnit(const ANamespace, AUnitName, AUnitText: string);
begin
  FUnitSearch.AddUnit(ANamespace, AUnitName, AUnitText);
end;

function TScriptExecuter.GetLibInterface(const ANamespace: string): TLibInterface;
begin
  if (FUnitSearch.FLibraryDict.TryGetValue(ANamespace, Result)) then
    Exit;
  Result := Default(TLibInterface);
end;

end.
