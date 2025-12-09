unit uServerCommand;

interface

uses
  Classes, SysUtils, StrUtils, Generics.Collections, IdHTTPServer, IdCustomHTTPServer;

type
  TServerCommand=class
  private
    FCommandType:THTTPCommandType;
    FPathInfo:string;
  protected
    procedure GetCommandInfo(out ACommandType:THTTPCommandType;out APathInfo:string);virtual;abstract;
    procedure Execute(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);virtual;abstract;
    function GetRequestBody(ARequestInfo:TIdHTTPRequestInfo):string;
  public
    constructor Create;
  public
    class procedure ExecuteCommand(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
  end;

implementation

uses
  uUtility;

var ServerCommandList: TObjectList<TServerCommand>;

{ TServerCommand }

constructor TServerCommand.Create;
begin
  inherited Create;
  GetCommandInfo(FCommandType,FPathInfo);
  ServerCommandList.Add(Self);
end;

function TServerCommand.GetRequestBody(ARequestInfo:TIdHTTPRequestInfo):string;
var Buffer:TBytes;
begin
  if ((not(Assigned(ARequestInfo.PostStream))) or (ARequestInfo.PostStream.Size=0)) then
    Result:=''
  else
    begin
      SetLength(Buffer,ARequestInfo.PostStream.Size);
      ARequestInfo.PostStream.Position:=0;
      ARequestInfo.PostStream.ReadBuffer(Buffer,ARequestInfo.PostStream.Size);
      Result:=TEncoding.UTF8.GetString(Buffer);
    end;
end;

class procedure TServerCommand.ExecuteCommand(Server:TIdHTTPServer;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
var ServerCommand:TServerCommand;
begin
  for ServerCommand in ServerCommandList do
    if (ARequestInfo.CommandType=ServerCommand.FCommandType) and EndsStr(ServerCommand.FPathInfo,ARequestInfo.Document) then
      begin
        ServerCommand.Execute(Server,ARequestInfo,AResponseInfo);
        Exit;
      end;
  RaiseException('Unknown command: %s %s',[ARequestInfo.Command,ARequestInfo.Document]);
end;

initialization
  ServerCommandList:=TObjectList<TServerCommand>.Create;

finalization
  DestroyObject(ServerCommandList);
end.
