unit uCancelServerCommand;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver, httpdefs, fpjson, jsonparser, uServer;

type
  TCancelServerCommand=class(TServerCommand)
  protected
    procedure GetCommandInfo(out AMethod, APathInfo: string);override;
    procedure Execute(Sender: TObject; Var ARequest: TFPHTTPConnectionRequest; Var AResponse : TFPHTTPConnectionResponse);override;
  end;

implementation

uses
  uUtilities;

{ TCancelServerCommand }

procedure TCancelServerCommand.GetCommandInfo(out AMethod: string; out APathInfo: string);
begin
  AMethod := 'POST';
  APathInfo := '/cancel';
end;

procedure TCancelServerCommand.Execute(Sender: TObject; var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
var
  data: TJSONData;
  obj, response: TJSONObject;
  notebookId: String;
begin
  try
    data := GetJSON(ARequest.Content);
    try
      obj := TJSONObject(data);
      response := TJSONObject.Create;
      notebookId := obj.Get('notebookId', '');
      response.Add('cancelled', true);
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
  TCancelServerCommand.Create;
end.
