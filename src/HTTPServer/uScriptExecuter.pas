unit uScriptExecuter;

interface

uses
  System.SysUtils, System.Classes, Variants, Generics.Collections, System.IOUtils,
  dwsStrings, dwsComp, dwsExprs, dwsCompiler, dwsFunctions, dwsClassesLibModule, dwsJSONConnector,
  dwsDataBaseLibModule, dwsLinq, dwsLinqSql, dwsSymbols, dwsUnitSymbols, dwsScriptSource,
  dwsRTTIConnector, dwsRTTIFunctions;

type
  TScriptExecuter = class(TDataModule)
    DelphiWebScript: TDelphiWebScript;
    dwsClassesLib: TdwsClassesLib;
    dwsJSONLibModule: TdwsJSONLibModule;
    dwsRTTIConnector: TdwsRTTIConnector;
    function DelphiWebScriptNeedUnit(const UnitName: string;
      var UnitSource: string): IdwsUnit;
  private
    { Private declarations }
    FVariablesDictionary:TDictionary<string,variant>;
    FProgram:IdwsProgram;
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

{ TScriptExecuter }

procedure TScriptExecuter.AfterConstruction;
var Linq:TdwsLinqFactory;
begin
  inherited;
  FVariablesDictionary:=TDictionary<string,variant>.Create;
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
  FProgram:=nil;
end;

function TScriptExecuter.DelphiWebScriptNeedUnit(const UnitName:string;var UnitSource:string):IdwsUnit;
begin
  UnitSource:='';
end;

function TScriptExecuter.ExecuteScript(Script:string):string;
begin
  Result:=ExecuteScript(Script,nil);
end;

function TScriptExecuter.ExecuteScript(Script:string;InitialVariables:TDictionary<string,variant>):string;
var k:integer;
    Errors,Error,OriginalScript:string;
    FlagDropProgram:boolean;
    Execution:IdwsProgramExecution;
    Variable:TPair<string,variant>;
    SymbolList:TObjectList<TSymbol>;
    Symbol:TSymbol;
begin
  FVariablesDictionary.Clear;
  InjectUnit(Script);
  FlagDropProgram:=false;
  try
    if (Assigned(FProgram)) then
      try
        FProgram.Msgs.Clear;
        SymbolList:=TObjectList<TSymbol>.Create(false);
        for k:=0 to FProgram.Table.Count do
          SymbolList.Add(FProgram.Table.Symbols[k]);
        OriginalScript:=FProgram.SourceList.FindScriptSourceItem(MSG_MainModule).SourceFile.Code;
        DelphiWebScript.RecompileInContext(FProgram,Script);
        if (FProgram.Msgs.HasErrors) then
          begin
            k:=0;
            while (k<FProgram.Table.Count) do
              begin
                Symbol:=FProgram.Table.Symbols[k];
                if (SymbolList.IndexOf(Symbol)=-1) then
                  FProgram.Table.Remove(Symbol)
                else
                  Inc(k);
              end;
            FProgram.SourceList.FindScriptSourceItem(MSG_MainModule).SourceFile.Code:=OriginalScript;
          end;
      finally
        SymbolList.Free;
      end
    else
      begin
        FProgram:=DelphiWebScript.Compile(Script);
        if (FProgram.Msgs.HasErrors) then
          FlagDropProgram:=true;
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
          FProgram:=nil;
        RaiseException(Errors);
      end
    else
      begin
        if (Assigned(InitialVariables)) then
          for Variable in InitialVariables.ToArray do
            FVariablesDictionary.AddOrSetValue(Variable.Key,Variable.Value);
        FVariablesDictionary.AddOrSetValue(varConsoleOutout,'');
        Execution:=FProgram.Execute;
        if (not(Execution.Msgs.HasErrors)) then
          Result:=Execution.Result.ToString
        else
          with Execution.Msgs do
            begin
              Error:=Msgs[Count-1].Text;
              AddConsoleOutputRow(Error);
              RaiseException(Error);
            end;
      end;
  finally
    Execution:=nil;
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

end.
