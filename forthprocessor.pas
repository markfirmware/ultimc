unit ForthProcessor;

interface
type
 TFunctionReturningString = function:String;
 TProcedureTakingString = procedure(X:String);

 TForthProcessor = class
 procedure Run (ReadLine:TFunctionReturningString;WriteLineProcedure:TProcedureTakingString;WriteStringProcedure:TProcedureTakingString);
 end;

procedure CreateForthProcessors;

implementation
uses Threads, Serial, SysUtils;

procedure TForthProcessor.Run (ReadLine:TFunctionReturningString;WriteLineProcedure:TProcedureTakingString;WriteStringProcedure:TProcedureTakingString);
var
 Line:String;
begin
 while True do
  begin
   Line:=ReadLine();
   if Line = 'bye' then
    break
   else
    WriteLineProcedure (Format ('results are sent by calling WriteLineProcedure and WriteStringProcedure', ['... output from the eval ...']));
  end;
end;

procedure CreateForthSerialProcessor (SerialDeviceNumber:Integer);
var
 SerialDeviceName:String;
 Processor:TForthProcessor;
begin
 SerialDeviceName=Format('ARM PrimeCell PL011 UART (UART%d)',[SerialDeviceNumber]));
 Processor:=TForthProcessor.Create;
end;

procedure CreateForthProcessors;
var
 SerialDeviceNumber:Integer;
 ProcessorName:String;
begin
  if BoardGetType = BoardTypeQemu then
   begin
    for SerialDeviceNumber:=0 to 3 do
     begin
      ProcessorName:=SysUtils.GetEnvironmentVariable(Format('SERIAL%d_PROCESSOR',[SerialDeviceNumber]));
      if UpperCase(ProcessorName) = 'FORTH' then
       CreateForthSerialProcessor(SerialDeviceNumber);
   end;
end;

intialization
CreateForthProcessors;

end.
