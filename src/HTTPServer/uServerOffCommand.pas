unit uServerOffCommand;

interface

uses
  FMX.Forms, Classes, SysUtils, StrUtils, Generics.Collections, uServerCommand, IdHTTPServer, IdCustomHTTPServer;

type  
  TServerOffCommand=class(TServerCommand)
  protected
    procedure GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);override;
    procedure Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);override;
  end;

implementation

uses
  uUtility;

{ TServerOffCommand }

procedure TServerOffCommand.GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);
begin
  ACommandType:=hcPOST;
  APathInfo:='/off';
end;

procedure TServerOffCommand.Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
begin
  with AResponseInfo do
    begin
      ContentType:='text/plain';
      CharSet:='utf-8';
      ContentText:='Goodby';
    end;
  Application.Terminate;
end;

initialization
  TServerOffCommand.Create;
end.
