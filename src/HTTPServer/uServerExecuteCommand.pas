unit uServerExecuteCommand;

interface

uses
  Classes, SysUtils, StrUtils, Generics.Collections, JSON, uServerCommand, IdHTTPServer, IdCustomHTTPServer;

type  
  TServerExecuteCommand=class(TServerCommand)
  protected
    procedure GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);override;
    procedure Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);override;
  end;

implementation

uses
  uUtility, uExecutionContext;

{ TServerExecuteCommand }

procedure TServerExecuteCommand.GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);
begin
  ACommandType:=hcPOST;
  APathInfo:='/execute';
end;

procedure TServerExecuteCommand.Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
var
  Body,Response:TJSONObject;
  NotebookId,Script:string;
  Context:TExecutionContext;
begin
  Body:=ParseJSONObject(GetRequestBody(ARequestInfo));
  try
    Response:=TJSONObject.Create;
    NotebookId:=Trim(ReadJSONValue(Body,'notebookId',''));
    if (NotebookId='') then
      RaiseException('NotebookId missing');
    Script:=Trim(ReadJSONValue(Body,'code',''));
    if (Script='') then
      RaiseException('Nothing to execute');
    Context:=TExecutionContext.Get(NotebookId);
    Context.Execute(Script);
    Response.AddPair('executionId',Context.ExecutionId);
    AResponseInfo.ContentType:='application/json';
    AResponseInfo.ContentText:=Response.ToString;
  finally
    Body.Free;
    Response.Free;
  end;
end;

initialization
  TServerExecuteCommand.Create;
end.
