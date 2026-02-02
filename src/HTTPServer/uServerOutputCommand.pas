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
  NotebookId,ExecutionId,Output:string;
  Offset:integer;
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
      Output:=Context.Output;
      if (WriteJSONValue(Response,'finished',Context.Finished)) then
        Context.Cancel;
    except
      WriteJSONValue(Response,'finished',true);
      Output:='';
    end;
    WriteJSONValue(Response,'cancelled',false);
    WriteJSONValue(Response,'chunk',Output);
    WriteJSONValue(Response,'completeOutput',Output);
    AResponseInfo.ContentType:='application/json';
    AResponseInfo.ContentText:=Response.ToString;
  finally
    Body.Free;
    Response.Free;
  end;
end;

initialization
  TServerOutputCommand.Create;
end.
