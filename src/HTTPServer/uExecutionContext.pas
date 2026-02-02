unit uExecutionContext;

interface

uses
  Classes, SysUtils, StrUtils, Generics.Collections, JSON, uScriptExecuter;

type
  TExecutionContext=class(TObject)
  private
    type
      TExecutionThread=class(TThread)
      private
        FContext:TExecutionContext;
      protected
        procedure DoTerminate;override;
        procedure Execute;override;
      public
        constructor Create(AContext:TExecutionContext);
      end;
  private
    FNotebookId:string;
    FExecutionId:string;
    FNotebookPath:string;
    FExecutionThread:TExecutionThread;
    FScriptExecuter:TScriptExecuter;
    FScript:string;
    function GetOutput:string;
  public
    constructor Create(ANotebookId:string);
    procedure AfterConstruction;override;
    procedure BeforeDestruction;override;
    function Execute(const Script:string):string;
    procedure Cancel;
    function Finished:boolean;
    function MustRestart:boolean;
    property NotebookId:string read FNotebookId;
    property ExecutionId:string read FExecutionId;
    property NotebookPath:string read FNotebookPath write FNotebookPath;
    property Output:string read GetOutput;
  public
    class function Get(const NotebookId:string;ExecutionId:string=''):TExecutionContext;
  end;

implementation

uses
  uUtility;

var
  ExecutionContextList:TObjectList<TExecutionContext>;

{ TExecutionContext.TExecutionThread }

constructor TExecutionContext.TExecutionThread.Create(AContext:TExecutionContext);
begin
  inherited Create(true);
  FContext:=AContext;
  with FContext do
    begin
      FExecutionId:=GenerateID;
      FExecutionThread:=Self;
    end;
  FreeOnTerminate:=true;
  Resume;
end;

procedure TExecutionContext.TExecutionThread.DoTerminate;
begin
  inherited;
  FContext.FExecutionThread:=nil;
end;

procedure TExecutionContext.TExecutionThread.Execute;
begin
  with FContext.FScriptExecuter do
    try
      ExecutionPath:=FContext.FNotebookPath;
      ExecuteScript(FContext.FScript);
    except
      on E:EAbort do
        ;
      on E:Exception do
        AddConsoleOutputRow(E.Message);
    end;
end;

{ TExecutionContext }

constructor TExecutionContext.Create(ANotebookId:string);
begin
  inherited Create;
  FNotebookId:=ANotebookId;
end;

procedure TExecutionContext.AfterConstruction;
begin
  inherited;
  FScriptExecuter:=TScriptExecuter.Create(nil);
end;

procedure TExecutionContext.BeforeDestruction;
begin
  inherited;
  if (Assigned(FExecutionThread)) then
    try
      FExecutionThread.WaitFor;
    except
    end;
  DestroyObject(FScriptExecuter);
  ExecutionContextList.Extract(Self);
end;

function TExecutionContext.Execute(const Script:string):string;
begin
  if (Assigned(FExecutionThread)) then
    RaiseException('Execution already in progress');
  FScript:=Script;
  TExecutionThread.Create(Self);
end;

function TExecutionContext.Finished:boolean;
begin
  Result:=not(Assigned(FExecutionThread));
end;

procedure TExecutionContext.Cancel;
begin
  if (Assigned(FExecutionThread)) then
    FScriptExecuter.CancelPending:=true;
end;

function TExecutionContext.GetOutput:string;
begin
  Result:=FScriptExecuter.GetConsoleOutput;
end;

function TExecutionContext.MustRestart:boolean;
begin
  Result:=Finished and FScriptExecuter.MustRestartFlag;
end;

class function TExecutionContext.Get(const NotebookId:string;ExecutionId:string):TExecutionContext;
var Idx:integer;
    Context:TExecutionContext;
begin
  Idx:=0;
  while (Idx<ExecutionContextList.Count) do
    begin
      Context:=ExecutionContextList[Idx];
      if (Context.MustRestart) then
        DestroyObject(Context)
      else
        begin
          if (Context.NotebookId=NotebookId) and ((ExecutionId='') or (Context.ExecutionId=ExecutionId)) then
            begin
              Result:=Context;
              Exit;
            end;
          Inc(Idx);
        end;
    end;
  if (ExecutionId='') then
    begin
      Result:=TExecutionContext.Create(NotebookId);
      ExecutionContextList.Add(Result);
    end
  else
    RaiseException('Notebook not in execution');
end;

initialization
  ExecutionContextList:=TObjectList<TExecutionContext>.Create;

finalization
  while (ExecutionContextList.Count>0) do
    ExecutionContextList.Delete(0);
  ExecutionContextList.Free;

end.
