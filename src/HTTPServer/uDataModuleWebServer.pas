unit uDataModuleWebServer;

interface

uses
  SysUtils, Classes, DateUtils, IOUtils, JSON, IdContext, IdSSL, IdServerIOHandler,
  IdSSLOpenSSL, IdBaseComponent, IdComponent, IdCustomTCPServer, IdCustomHTTPServer,
  IdHTTPServer, IdMessageCoder, IdMessageCoderMIME, IdGlobalProtocols, IdOpenSSLIOHandlerServer;

type
  TDataModuleWebServer = class(TDataModule)
    IdHTTPServer: TIdHTTPServer;
    IdMessageEncoderMIME: TIdMessageEncoderMIME;
    IdMessageDecoderMIME: TIdMessageDecoderMIME;
    IdOpenSSLIOHandlerServer: TIdOpenSSLIOHandlerServer;
    procedure IdHTTPServerQuerySSLPort(APort: Word; var VUseSSL: Boolean);
    procedure IdHTTPServerCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure IdHTTPServerCommandError(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
      AException: Exception);
    procedure IdHTTPServerCommandOther(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure IdHTTPServerParseAuthentication(AContext: TIdContext;
      const AAuthType, AAuthData: string; var VUsername, VPassword: string;
      var VHandled: Boolean);
    procedure IdOpenSSLIOHandlerServerGetPassword(Sender: TObject;
      var Password: string; const IsWrite: Boolean);
  private
    { Private declarations }
    FHTTPS:boolean;
    FPassword:string;
    FBasePathServer:string;
    procedure Process(AContext:TIdContext;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
    function IsServerCommand(var Command:string):boolean;
    procedure GetAndSendDocument(Document:string;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
    procedure ProcessServerCommand(Command:string;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
    function GetHTTPPort:cardinal;
    procedure SetHTTPPort(const Value:cardinal);
    function GetActive:boolean;
    procedure SetActive(const Value:boolean);
    function FileModifyDate(const FileName:string):TDateTime;
  protected
    { Protected declarations }
    procedure AfterConstruction;override;
    procedure BeforeDestruction;override;
  public
    { Public declarations }
    procedure SetConfiguration(Configuration:TJSONObject);
    property Active:boolean read GetActive write SetActive;
    property HTTPPort:cardinal read GetHTTPPort write SetHTTPPort;
  end;

var DataModuleWebServer:TDataModuleWebServer;

implementation

uses
  uUtility, uServerCommand, uServerOffCommand, uServerPingCommand, uServerExecuteCommand, uServerCancelCommand,
  uServerOutputCommand;

const
  parRemoteAddr='__RemoteAddr__';

{$R *.dfm}

{ TDataModuleWebServer }

procedure TDataModuleWebServer.AfterConstruction;
begin
  inherited;
  IdOpenSSLIOHandlerServer.Options.OnGetPassword:=IdOpenSSLIOHandlerServerGetPassword;
  FBasePathServer:=GetCurrentDir;
end;

procedure TDataModuleWebServer.BeforeDestruction;
begin
  inherited;
  Active:=false;
end;

function TDataModuleWebServer.GetActive:boolean;
begin
  Result:=IdHTTPServer.Active;
end;

function TDataModuleWebServer.GetHTTPPort:cardinal;
begin
  Result:=IdHTTPServer.DefaultPort;
end;

procedure TDataModuleWebServer.
            IdHTTPServerCommandError(AContext:TIdContext;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo;AException:Exception);
begin
  //
end;

procedure TDataModuleWebServer.
            IdHTTPServerCommandGet(AContext:TIdContext;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
begin
  Process(AContext,ARequestInfo,AResponseInfo);
end;

procedure TDataModuleWebServer.
            IdHTTPServerCommandOther(AContext:TIdContext;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
begin
  Process(AContext,ARequestInfo,AResponseInfo);
end;

procedure TDataModuleWebServer.
            IdHTTPServerParseAuthentication(AContext:TIdContext;const AAuthType,AAuthData:string;var VUsername,VPassword:string;var VHandled:boolean);
begin
  VHandled:=true;
end;

procedure TDataModuleWebServer.IdHTTPServerQuerySSLPort(APort:word;var VUseSSL:boolean);
begin
  VUseSSL:=FHTTPS;
end;

procedure TDataModuleWebServer.
            IdOpenSSLIOHandlerServerGetPassword(Sender:TObject;var Password:string;const IsWrite:Boolean);
begin
  Password:=FPassword;
end;

procedure TDataModuleWebServer.
            Process(AContext:TIdContext;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
var Document:string;
begin
  try
    AResponseInfo.CustomHeaders.Values['Access-Control-Allow-Origin']:='*'; // Permette al client di eseguire interrogazioni cross domain.
    Document:=ARequestInfo.Document;
    if (IsServerCommand(Document)) then
      ProcessServerCommand(Document,ARequestInfo,AResponseInfo)
    else
      GetAndSendDocument(Document,ARequestInfo,AResponseInfo);
  except
    on E:Exception do
      with AResponseInfo do
        begin
          ResponseNo:=500;
          ContentText:=E.Message;
        end;
  end;
end;

procedure TDataModuleWebServer.ProcessServerCommand(Command:string;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
var Risposta,ContentTypeRisposta,Corpo:string;
begin
  ARequestInfo.Params.Values[parRemoteAddr]:=ARequestInfo.RemoteIP;
  TServerCommand.ExecuteCommand(IdHTTPServer,ARequestInfo,AResponseInfo);
end;

function TDataModuleWebServer.FileModifyDate(const FileName:string):TDateTime;
begin
  Result:=TFile.GetLastWriteTime(FileName);
end;

procedure TDataModuleWebServer.
            GetAndSendDocument(Document:string;ARequestInfo:TIdHTTPRequestInfo;AResponseInfo:TIdHTTPResponseInfo);
var HeaderDateDocument:string;
    DocumentDate:TDateTime;
    FlagGet:boolean;
begin
  if (Document='/') then
    Document:=FBasePathServer+'\Index.html'
  else
    Document:=FBasePathServer+StringReplace(Document,'/','\',[rfReplaceAll]);
  try
    DocumentDate:=FileModifyDate(Document);
    HeaderDateDocument:=ARequestInfo.RawHeaders.Values['If-Modified-Since'];
    if (HeaderDateDocument='') then
      HeaderDateDocument:=ARequestInfo.RawHeaders.Values['If-None-Match'];
    if (HeaderDateDocument<>'') then
      FlagGet:=((DocumentDate-GMTToLocalDateTime(HeaderDateDocument))>OneSecond)
    else
      FlagGet:=true;
    if (FlagGet) then
      begin
        AResponseInfo.ContentText:='';
        AResponseInfo.ContentStream:=TFileStream.Create(Document,fmOpenRead);
        AResponseInfo.FreeContentStream:=true;
        AResponseInfo.LastModified:=DocumentDate;
        AResponseInfo.ETag:=DateTimeToStr(DocumentDate);
        AResponseInfo.CacheControl:='no-cache';
        AResponseInfo.ContentType:=MIMEFromFileExtension(GetFileExtension(Document));
        AResponseInfo.CharSet:='utf-8';
      end
    else
      AResponseInfo.ResponseNo:=304;
  except
    AResponseInfo.ResponseNo:=404;
  end;
end;

function TDataModuleWebServer.IsServerCommand(var Command:string):boolean;
begin
  Result:=true;
end;

procedure TDataModuleWebServer.SetActive(const Value:boolean);
begin
  IdHTTPServer.Active:=Value;
end;

procedure TDataModuleWebServer.SetConfiguration(Configuration:TJSONObject);
begin
  with IdHTTPServer do
    begin
      Active:=false;
      Bindings.Clear;
    end;
  FHTTPS:=ReadJSONValue(Configuration,'UseSSL',false);
  FPassword:=ReadJSONValue(Configuration,'CertPassword','');
  with IdOpenSSLIOHandlerServer.Options do
    begin
      CertFile:=ReadJSONValue(Configuration,'CertFile','');
      CertKey:=ReadJSONValue(Configuration,'CertKey','');
    end;
  with IdHTTPServer do
    begin
      DefaultPort:=ReadJSONValue(Configuration,'HTTPPort',9000);
      if (FHTTPS) then
        IOHandler:=IdOpenSSLIOHandlerServer
      else
        IOHandler:=nil;
      Active:=true;
    end;
end;

procedure TDataModuleWebServer.SetHTTPPort(const Value:cardinal);
begin
  with IdHTTPServer do
    begin
      Bindings.Clear;
      DefaultPort:=Value;
    end;
end;

end.

