program OPNBHost;

uses
  //FastMM4,
  System.StartUpCopy,
  FMX.Forms,
  System.Classes,
  System.SysUtils,
  System.JSON,
  System.RTTI,
  System.TypInfo,
  uDataModuleWebServer in 'uDataModuleWebServer.pas' {DataModuleWebServer: TDataModule},
  uUtility in 'uUtility.pas';

{$R *.res}

type
  TEventCatcher=class(TObject)
  private
    procedure WakeMainThread(Sender: TObject);
    procedure IdleEvent(Sender: TObject; var Done: Boolean);
  end;

var
  Configuration: TJSONobject;
  Value: string;
  EventCatcher: TEventCatcher;

{ TEventCatcher }

procedure TEventCatcher.IdleEvent(Sender: TObject; var Done: Boolean);
var
  Processed: boolean;
begin
  repeat
    Sleep(10);
    Processed:=CheckSynchronize;
  until (not Processed);
  Done:=true;
end;

procedure TEventCatcher.WakeMainThread(Sender: TObject);
var
  Processed: boolean;
begin
  repeat
    Sleep(10);
    Processed:=CheckSynchronize;
  until (not Processed);
end;

begin
  //ReportMemoryLeaksOnShutdown:=true;
  Application.Initialize;
  DataModuleWebServer:=TDataModuleWebServer.Create(Application);
  Configuration:=TJSONObject.Create;
  try
    if FindCmdLineSwitch('port',Value) then
      WriteJSONValue(Configuration,'HTTPPort',StrToInt(Value));
    if FindCmdLineSwitch('UseSSL',Value) then
      WriteJSONValue(Configuration,'UseSSL',StrToBool(Value));
    if FindCmdLineSwitch('CertPassword',Value) then
      WriteJSONValue(Configuration,'CertPassword',Value);
    if FindCmdLineSwitch('CertFile',Value) then
      WriteJSONValue(Configuration,'CertFile',Value);
    if FindCmdLineSwitch('CertKey',Value) then
      WriteJSONValue(Configuration,'CertKey',Value);
    DataModuleWebServer.SetConfiguration(Configuration);
  finally
    Configuration.Free;
  end;
  EventCatcher:=TEventCatcher.Create;
  //WakeMainThread := EventCatcher.WakeMainThread;
  Application.OnIdle:=EventCatcher.IdleEvent;
  try
    Application.Run;
  finally
    WakeMainThread := nil;
    EventCatcher.Free;
  end;
end.
