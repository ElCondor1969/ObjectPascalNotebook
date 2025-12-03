unit uExecuteServerCommand;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver, httpdefs, fpjson, jsonparser, uServer;

type
  TExecuteServerCommand=class(TServerCommand)
  protected
    procedure GetCommandInfo(out AMethod, APathInfo: string);override;
    procedure Execute(Sender: TObject; Var ARequest: TFPHTTPConnectionRequest; Var AResponse : TFPHTTPConnectionResponse);override;
  end;

implementation

uses
  uUtilities;

{ TExecuteServerCommand }

procedure TExecuteServerCommand.GetCommandInfo(out AMethod: string; out APathInfo: string);
begin
  AMethod := 'POST';
  APathInfo := '/execute';
end;

procedure TExecuteServerCommand.Execute(Sender: TObject; var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
var
  data: TJSONData;
  obj, response: TJSONObject;
  notebookId: string;
begin
  try
    data := GetJSON(ARequest.Content);
    try
      obj := TJSONObject(data);
      response := TJSONObject.Create;
      notebookId := obj.Get('notebookId', '');
      response.Add('executionId', GenerateUUID);
      AResponse.ContentType := 'application/json';
      AResponse.Content := response.AsJSON;
    finally
      data.Free;
      response.Free;
    end;
  except
    on E: Exception do
      Writeln('Errore parsing JSON: ', E.Message);
  end;
end;

initialization
  TExecuteServerCommand.Create;
end.
