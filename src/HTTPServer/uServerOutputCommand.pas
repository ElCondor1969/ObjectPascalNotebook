unit uServerOutputCommand;

interface

uses
  Classes, SysUtils, StrUtils, Generics.Collections, JSON, uServerCommand, IdHTTPServer, IdCustomHTTPServer;

type  
  TServerOutputCommand=class(TServerCommand)
  protected
    procedure GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);override;
    procedure Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);override;
  end;

implementation

uses
  uUtility, uExecutionContext;

{ TServerOutputCommand }

procedure TServerOutputCommand.GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);
begin
  ACommandType:=hcPOST;
  APathInfo:='/output';
end;

procedure TServerOutputCommand.Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
var
  Body,Response:TJSONObject;
  NotebookId,ExecutionId:string;
  Offset:integer;
  Finished:boolean;
  Context:TExecutionContext;
begin
  Body:=ParseJSONObject(GetRequestBody(ARequestInfo));
  try
    Response:=TJSONObject.Create;
    NotebookId:=Trim(ReadJSONValue(Body,'notebookId',''));
    if (NotebookId='') then
      RaiseException('NotebookId missing');
    ExecutionId:=Trim(ReadJSONValue(Body,'executionId',''));
    if (ExecutionId='') then
      RaiseException('ExecutionId missing');
    Offset:=ReadJSONValue(Body,'offset',0);
    try
      Context:=TExecutionContext.Get(NotebookId,ExecutionId);
      Response.AddPair('cancelled',TJSONFalse.Create);
      Finished:=Context.Finished;
      Response.AddPair('finished',TJSONBool.Create(Finished));
      if (Finished) then
        Context.Cancel;
    except
      Response.AddPair('cancelled',TJSONTrue.Create);
      Response.AddPair('finished',TJSONTrue.Create);
      Finished:=true;
    end;
    Response.AddPair('chunk',Context.Output);
    Response.AddPair('completeOutput',Context.Output);
    AResponseInfo.ContentType:='application/json';
    AResponseInfo.ContentText:=Response.ToString;
    if (Context.MustRestart) then
      DestroyObject(Context);
  finally
    Body.Free;
    Response.Free;
  end;
end;

initialization
  TServerOutputCommand.Create;
end.
