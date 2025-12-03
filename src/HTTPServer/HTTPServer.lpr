program HTTPServer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  { you can add units after this }
  uServer;

type

  { THTTPServerApplication }

  THTTPServerApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ THTTPServerApplication }

procedure THTTPServerApplication.DoRun;
var
  ErrorMsg, OptiobValue: String;
  PortNumber: integer;
begin
  // quick check parameters
  ErrorMsg:=CheckOptions('hp:', 'help port:');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  if HasOption('p', 'port') then
    begin
      OptiobValue:=GetOptionValue('p','port');
      PortNumber:=StrToInt(OptiobValue);
    end
  else
    PortNumber:=9000;

  // Starts the HTTP server
  StartServer(PortNumber);
end;

constructor THTTPServerApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor THTTPServerApplication.Destroy;
begin
  inherited Destroy;
end;

procedure THTTPServerApplication.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
end;

var
  Application: THTTPServerApplication;
begin
  Application:=THTTPServerApplication.Create(nil);
  Application.Title:='HTTPServerApplication';
  Application.Run;
  Application.Free;
end.

