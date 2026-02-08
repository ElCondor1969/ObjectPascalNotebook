unit uServerPingCommand;

interface

uses
  Classes, SysUtils, StrUtils, Generics.Collections, uServerCommand, IdHTTPServer, IdCustomHTTPServer;

type  
  TServerPingCommand=class(TServerCommand)
  protected
    procedure GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);override;
    procedure Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);override;
  end;

implementation

uses
  uUtility;

{ TServerPingCommand }

procedure TServerPingCommand.GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);
begin
  ACommandType:=hcGET;
  APathInfo:='/ping';
end;

procedure TServerPingCommand.Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
begin
  with AResponseInfo do
    begin
      ContentType:='text/plain';
      CharSet:='utf-8';
      ContentText:='Pong';
    end;
end;

initialization
  TServerPingCommand.Create;
end.
