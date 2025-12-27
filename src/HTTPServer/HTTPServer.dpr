program HTTPServer;

uses
  System.StartUpCopy,
  FMX.Forms,
  JSON,
  uDataModuleWebServer in 'uDataModuleWebServer.pas' {DataModuleWebServer: TDataModule},
  uUtility in 'uUtility.pas';

{$R *.res}

var Configuration:TJSONobject;

begin
  Application.Initialize;
  DataModuleWebServer:=TDataModuleWebServer.Create(Application);
  Configuration:=TJSONObject.Create;
  try
    DataModuleWebServer.SetConfiguration(Configuration);
  finally
    Configuration.Free;
  end;
  Application.Run;
end.
