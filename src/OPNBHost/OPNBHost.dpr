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
    DataModuleWebServer.SetConfiguration(Configuration);
  finally
    Configuration.Free;
  end;
  Application.Run;
end.
