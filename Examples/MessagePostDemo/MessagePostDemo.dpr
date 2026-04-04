(*
  The MessagePostDemo library was written as an example to demonstrate how to implement sending 
  messages to the outside world.
  The library simulates a virtual thermometer that periodically detects the temperature of a 
  certain environment. This virtual detection is performed via a dedicated thread that will run 
  asynchronously with the library's main thread.
  The thread will send periodic messages to communicate the detected virtual temperature to the 
  outside world.
*)

library MessagePostDemo;

uses
  System.SysUtils,
  System.JSON,
  System.Classes,
  System.StrUtils,
  System.Variants,
  System.Types,
  System.TypInfo,
  Generics.Collections,
  uLibInterface,
  uUtility;

{$R *.res}

(*
  The TMeterTask class implements the thread that will simulate temperature detection and that 
  will take care of sending the related values ??externally via specific messages.
*)

type
  TMeterTask=class(TThread)
  private
    FTemperature: double;
    procedure TerminatedEvent(Sender: TObject);
  protected
    procedure Execute;override;
  public
    constructor Create;
  end;

var CallerContext: NativeInt;
    InvokeHost: TInvokeHostProc;
    MeterTask: TMeterTask;

function InvokeLibProcImpl(Context, Instance: NativeInt; const ProcName: PChar; var Args:array of variant): Variant; cdecl;
begin
  if (SameText(ProcName,'ST')) then
    begin
      (*
        The "ST" command starts the virtual temperature detection and consequently 
        starts the related thread.
      *)
      if (not Assigned(MeterTask)) then
        MeterTask:=TMeterTask.Create;
    end
  else if (SameText(ProcName,'FT')) then
    begin
      (*
        The "FT" command terminates the virtual temperature detection and consequently 
        stops the related thread.
      *)
      if (Assigned(MeterTask)) then
        MeterTask.Terminate;
    end
  else
    RaiseException('Proc "%s" unknown',[ProcName]);
end;

procedure LibInit(const ALibInterface: PLibInterface); cdecl;
begin
  (*
    Library initialization. Note how both the reference to the InvokeHostProc procedure and
    the calling context are saved separately.
    The InvokeHostProc procedure is the procedure that will allow the library to send messages
    outward.
    The procedure's parameters are:
      1) The calling context. This must be the same as the one received during initialization.
      2) The command identifier for sending messages: it's must be COMHOST_INVOKEPROC.
      3) A list of values ??that will be transported by the message outward.
  *)
  with ALibInterface^ do
    begin
      LibGUID:='{05B0E609-B7EB-4FBF-A8F6-024F6749EF0D}';
      InvokeLibProc:=InvokeLibProcImpl;
      CallerContext:=Context;
      InvokeHost:=InvokeHostProc;
    end;
end;

procedure LibFree(const ALibInterface: PLibInterface); cdecl;
begin
  if (Assigned(MeterTask)) then
    MeterTask.Terminate;
end;

{ TMeterTask }

constructor TMeterTask.Create;
begin
  inherited Create(true);
  FreeOnTerminate:=true;
  OnTerminate:=TerminatedEvent;
  FTemperature:=25;
  Resume;
end;

procedure TMeterTask.Execute;
var
  Counter: integer;
  Args: array of Variant;
begin
  while (not Terminated) do
    begin
      Counter:=20;
      while (not Terminated) and (Counter>0) do
        begin
          Sleep(100);
          Dec(Counter);
        end;
      if (not Terminated) then
        begin
          // Simulates a temperature change.
          FTemperature:=FTemperature+Random-Random;
          
          (*
            Sends a message outside with the detected temperature.
            The first proc's parameter have to be the caller context.
            The second proc's parameter is the command's identifier that allow us to send messages.
            The first value in proc's Args have to be the key for these types of messages;
            in our example, we will always have a single key with the value 0.
            The second value in proc's Args is a fixed value of zero (for possible future expansions of the current example).
            The third value in proc's Args is the detected temperature.
          *)
          Args:=[0,0,FTemperature];
          InvokeHost(CallerContext,COMHOST_POSTMESSAGE,Args);
        end;
    end;
end;

procedure TMeterTask.TerminatedEvent(Sender: TObject);
begin
  MeterTask:=nil;
end;

exports
  LibInit,
  LibFree;

begin
  Randomize;
end.
