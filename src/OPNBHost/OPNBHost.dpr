program OPNBHost;

uses
  //FastMM4,
  System.StartUpCopy,
  FMX.Forms,
  System.SysUtils,
  JSON,
  uDataModuleWebServer in 'uDataModuleWebServer.pas' {DataModuleWebServer: TDataModule},
  uUtility in 'uUtility.pas';

{$R *.res}

var
  Configuration: TJSONobject;
  Value: string;

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
  Application.Run;
end.
