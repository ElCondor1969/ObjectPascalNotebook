unit uServer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver, httpdefs, fgl;

type
  TServerCommand=class
  private
    FMethod: string;
    FPathInfo: string;
  protected
    procedure GetCommandInfo(out AMethod, APathInfo: string);virtual;abstract;
    procedure Execute(Sender: TObject; Var ARequest: TFPHTTPConnectionRequest; Var AResponse : TFPHTTPConnectionResponse);virtual;abstract;
  public
    constructor Create;
  end;

procedure StartServer(APort: Word = 9000);
procedure StopServer;

implementation

uses
  uExecuteServerCommand, uOutputServerCommand, uCancelServerCommand;

type
  TSpecializedServerCommandList = specialize TFPGObjectList<TServerCommand>;

  TPingCommand=class(TServerCommand)
  protected
    procedure GetCommandInfo(out AMethod, APathInfo: string);override;
    procedure Execute(Sender: TObject; Var ARequest: TFPHTTPConnectionRequest; Var AResponse : TFPHTTPConnectionResponse);override;
  end;

  THTTPServer = class
  private
    class var FServerCommandList: TSpecializedServerCommandList;
  private
    FServer: TFPHTTPServer;
    procedure OnRequest(Sender: TObject; Var ARequest: TFPHTTPConnectionRequest; Var AResponse : TFPHTTPConnectionResponse);
  public
    constructor Create(APort: Word);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
  end;

var
  HTTPServer: THTTPServer = nil;

procedure StartServer(APort: Word);
begin
  if HTTPServer = nil then
    HTTPServer := THTTPServer.Create(APort);
  HTTPServer.Start;
end;

procedure StopServer;
begin
  if HTTPServer <> nil then
  begin
    HTTPServer.Stop;
    FreeAndNil(HTTPServer);
  end;
end;

{ THTTPServer }

procedure THTTPServer.OnRequest(Sender: TObject; var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
var ServerCommand: TServerCommand;
begin
  for ServerCommand in FServerCommandList do
    if (ARequest.Method = ServerCommand.FMethod) and (ARequest.PathInfo = ServerCommand.FPathInfo) then
      begin
        ServerCommand.Execute(Sender, ARequest, AResponse);
        Exit;
      end;
  raise Exception.CreateFmt('Unknown command: %s %s',[ARequest.Method,ARequest.PathInfo]);
end;

constructor THTTPServer.Create(APort: Word);
begin
  inherited Create;
  FServer := TFPHTTPServer.Create(nil);
  FServer.Port := APort;
  FServer.Threaded := True;
  FServer.OnRequest := @OnRequest;
end;

destructor THTTPServer.Destroy;
begin
  if Assigned(FServer) then
  begin
    FServer.Free;
    FServer := nil;
  end;
  inherited Destroy;
end;

procedure THTTPServer.Start;
begin
  if Assigned(FServer) then
    FServer.Active := True;
end;

procedure THTTPServer.Stop;
begin
  if Assigned(FServer) then
    FServer.Active := False;
end;

{ TServerCommand }

constructor TServerCommand.Create;
begin
  inherited Create;
  GetCommandInfo(FMethod,FPathInfo);
  if (THTTPServer.FServerCommandList = nil) then
    THTTPServer.FServerCommandList := TSpecializedServerCommandList.Create;
  THTTPServer.FServerCommandList.Add(Self);
end;

{ TPingCommand}

procedure TPingCommand.GetCommandInfo(out AMethod: string; out APathInfo: string);
begin
  AMethod:='GET';
  APathInfo:='/ping';
end;

procedure TPingCommand.Execute(Sender: TObject; var ARequest: TFPHTTPConnectionRequest; var AResponse: TFPHTTPConnectionResponse);
begin
  AResponse.ContentType := 'text/plain';
  AResponse.Content := 'Pong';
end;

initialization
  TPingCommand.Create;
end.
