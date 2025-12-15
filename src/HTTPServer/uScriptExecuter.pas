unit uScriptExecuter;

interface

uses
  System.Classes, dwsUtils, System.SysUtils, System.IOUtils, System.StrUtils, Variants, System.Types, Generics.Collections,
  dwsStrings, dwsComp, dwsExprs, dwsDataContext, dwsCompiler, dwsFunctions, dwsStack, dwsClassesLibModule,
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
        Namespace:string;
        Path:array of string;
      end;

      TUnitSearch=class(TObject)
      private
        FDict:TDictionary<string,TUnitSearchInfo>;
      public
        procedure AfterConstruction;override;
        procedure BeforeDestruction;override;
        procedure ImportFromPath(const ANamespace,APath:string);
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
    procedure ImportFromPath(const ANamespace,APath:string);
    property VariablesDictionary:TDictionary<string,variant> read FVariablesDictionary;
    property MustRestartFlag:boolean read GetMustRestartFlag write SetMustRestartFlag;
  end;

implementation

{$R *.dfm}

uses
  uUtility, uScriptUnitBaseLibrary;

const
  varConsoleOutout='__CONSOLE_OUTPUT__';
  varFlagRestart='__FLAG_RESTART__';

var
  FlagPreserveStack:boolean=false;

type
  TOPNBProgramExecution=class(TdwsProgramExecution)
  public
    function BeginProgram:boolean;override;
    procedure EndProgram;override;
  end;

{ TOPNBProgramExecution }

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

{ TScriptExecuter.TUnitSearch }

procedure TScriptExecuter.TUnitSearch.AfterConstruction;
begin
  inherited;
  FDict:=TDictionary<string,TUnitSearchInfo>.Create;
end;

procedure TScriptExecuter.TUnitSearch.BeforeDestruction;
begin
  inherited;
  FDict.Free;
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
  FileList:=TDirectory.GetFiles(
    APath,
    '*.*',
    TSearchOption(1), // soAllDirectories
    function(const Path:string;const SearchRec:TSearchRec):boolean
    begin
      Result:=((SearchRec.Attr or faArchive)<>0);
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

function TScriptExecuter.TUnitSearch.GetUnitCode(const UnitName:string):string;
var
  UnitSearchInfo:TUnitSearchInfo;
begin
  if (not(FDict.TryGetValue(UnitName,UnitSearchInfo))) then
    Result:=''
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
  FUnitSearch:=TUnitSearch.Create;
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
    InitExpr:TBlockInitExpr;
begin
  FVariablesDictionary.Clear;
  InjectUnit(Script);
  FlagDropProgram:=false;
  if (Assigned(FProgram)) then
    try
      SymbolList:=TObjectList<TSymbol>.Create(false);
      InitExpr:=TBlockInitExpr.Create(cNullPos);

      // Preserve initial expressions.
      (* while (FProgram.ProgramObject.InitExpr.StatementCount>0) do
        InitExpr.AddStatement(FProgram.ProgramObject.InitExpr.ExtractStatement(0)); *)

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
        end
      else
        // Merge the current initial expressions with the previous ones.
        (* while (InitExpr.StatementCount>0) do
          FProgram.ProgramObject.InitExpr.AddStatement(InitExpr.ExtractStatement(0)); *)
    finally
      SymbolList.Free;
      InitExpr.Free;
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

procedure TScriptExecuter.ImportFromPath(const ANamespace,APath:string);
begin
  FUnitSearch.ImportFromPath(ANamespace,APath);
end;

end.
