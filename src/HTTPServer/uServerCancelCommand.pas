unit uServerCancelCommand;

interface

uses
  Classes, SysUtils, StrUtils, Generics.Collections, JSON, uServerCommand, IdHTTPServer, IdCustomHTTPServer;

type  
  TServerCancelCommand=class(TServerCommand)
  protected
    procedure GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);override;
    procedure Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);override;
  end;

implementation

uses
  uUtility, uExecutionContext;

{ TServerCancelCommand }

procedure TServerCancelCommand.GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);
begin
  ACommandType:=hcPOST;
  APathInfo:='/cancel';
end;

procedure TServerCancelCommand.Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
var
  Body,Response:TJSONObject;
  NotebookId,ExecutionId:string;
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
    try
      Context:=TExecutionContext.Get(NotebookId,ExecutionId);
      Context.Cancel;
    except
    end;
    WriteJSONValue(Response,'cancelled',true);
    AResponseInfo.ContentType:='application/json';
    AResponseInfo.ContentText:=Response.ToString;
  finally
    Body.Free;
    Response.Free;
  end;
end;

initialization
  TServerCancelCommand.Create;
end.
