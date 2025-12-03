unit uOutputServerCommand;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver, httpdefs, fpjson, jsonparser, uServer;

type
  TOutputServerCommand=class(TServerCommand)
  protected
    procedure GetCommandInfo(out AMethod, APathInfo: string);override;
    procedure Execute(Sender: TObject; Var ARequest: TFPHTTPConnectionRequest; Var AResponse : TFPHTTPConnectionResponse);override;
  end;

implementation

uses
  uUtilities;

{ TOutputServerCommand }

procedure TOutputServerCommand.GetCommandInfo(out AMethod: string; out APathInfo: string);
begin
  AMethod := 'POST';
  APathInfo := '/output';
end;

procedure TOutputServerCommand.Execute(Sender: TObject; var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
var
  data: TJSONData;
  obj, response: TJSONObject;
  notebookId: String;
  offset: integer;
begin
  try
    data := GetJSON(ARequest.Content);
    try
      obj := TJSONObject(data);
      response := TJSONObject.Create;
      notebookId := obj.Get('notebookId', '');
      offset := obj.Get('offset', 0);
      response.Add('cancelled', false);
      response.Add('finished', true);
      response.Add('chunk','Comando eseguito correttamente');
      response.Add('completeOutput','Comando eseguito correttamente');
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
  TOutputServerCommand.Create;
end.
