unit uMessagePostDemo;

(*
  This unit is the interface between the library and external users.
  It defines and implements the TSmartMeter class to hide all implementation details 
  and provide useful features to users.
*)

interface

uses
  uBaseLibrary;

type
  // Defines the event signatures of the TSmartMeter class.
  TTemperatureEvent=procedure(Sender: TObject; const Temperature: float) of object;
  TTemperatureProceEvent=procedure(Sender: TObject; const Temperature: float);
  
  TSmartMeter=class(TObject)
  private
    FInstance: integer;
    FOnTemperature: TTemperatureEvent;
    FOnTemperature2: TTemperatureProceEvent;
  public
    procedure Start;
    procedure Stop;
    procedure ListenFor(const SecondNumber: integer);
    property OnTemperature: TTemperatureEvent read FOnTemperature write FOnTemperature;
    property OnTemperature2: TTemperatureProceEvent read FOnTemperature2 write FOnTemperature2;
    constructor Create;
    destructor Destroy;
  end;

implementation

const
  LibGUID='{05B0E609-B7EB-4FBF-A8F6-024F6749EF0D}';

var 
  // SmartMeterDict serves as a dictionary for all instances of the TSmartMeter class.
  SmartMeterDict: array[integer] of TSmartMeter;

(*
  The Callback procedure will be invoked for each message received from the library.
  The procedure tests whether the first parameter of the message is equal to zero and, if so, 
  invokes the OnTemperature or OnTemperature2 events of all existing instances of the TSmartMeter 
  class.
*)
procedure Callback(const Parameters:TVariantArray);
var k: integer;
    SmartMeter: TSmartMeter;
begin
  for k:=0 to High(SmartMeterDict.Keys) do
    begin
      SmartMeter:=SmartMeterDict[SmartMeterDict.Keys[k]];
      if (Parameters[0]=0) then
        begin
          if (Assigned(SmartMeter.OnTemperature)) then
            SmartMeter.OnTemperature(SmartMeter,Parameters[1]);
          if (Assigned(SmartMeter.OnTemperature2)) then
            SmartMeter.OnTemperature2(SmartMeter,Parameters[1]);
        end;
    end;
end;

{ TSmartMeter }

constructor TSmartMeter.Create;
begin
  FInstance:=Trunc(Random*10000);
  SmartMeterDict[FInstance]:=Self;
end;

destructor TSmartMeter.Destroy;
begin
  SmartMeterDict.Keys.Remove(FInstance);
end;

procedure TSmartMeter.Start;
var
  Args: TVariantArray;
begin
  // Send the command to our library to start the virtual temperature detection task.
  __LibInterface_InvokeLibProc(LibGUID, 0, 'ST', Args);
end;

procedure TSmartMeter.Stop;
var
  Args: TVariantArray;
begin
  // Send the command to our library to stop the virtual temperature detection task.
  __LibInterface_InvokeLibProc(LibGUID, 0, 'FT', Args);
end;

procedure TSmartMeter.ListenFor(const SecondNumber: integer);
var
  Counter: integer;
begin
  Counter:=SecondNumber*10;
  while (Counter>0) do
    begin
      (*
        ProcessPostedMessage is the procedure that checks for any received messages and, if so, 
        routes them to the relevant callback procedures.
        This procedure must be invoked periodically to allow message sorting, otherwise 
        no messages will ever be processed.
      *)
      ProcessPostedMessage;
      
      Sleep(100);
      Counter:=Counter-1;
    end;
end;

initialization
  Randomize;

  (*
    The RegisterMessageCallback procedure allows you to register a callback procedure for 
    a given message class.
    The first parameter is the key indicating the message class that will be listened for, 
    while the second is the callback procedure to invoke.
    In our example, we have only a single message class, characterized by the key value 0.
  *)
  RegisterMessageCallback(0, Callback);
end.
