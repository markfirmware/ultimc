unit ForthProcessor;

interface
type
 TFunctionReturningString = function:String;
 TProcedureTakingString = procedure(S:String);

 TForthProcessor = class
 procedure Run (ReadLine:TFunctionReturningString;WriteLineProcedure:TProcedureTakingString;WriteStringProcedure:TProcedureTakingString);
 end;

implementation
uses GlobalConst, Platform, Threads, Serial, SysUtils, MoreUltibo;

procedure TForthProcessor.Run (ReadLine:TFunctionReturningString;WriteLineProcedure:TProcedureTakingString;WriteStringProcedure:TProcedureTakingString);
var
 Line:String;
begin
 while True do
  begin
   Line:=ReadLine();
   if Line = 'bye' then
    begin
     break;
    end
   else
    begin
     WriteLineProcedure (Format ('results are sent by calling WriteLineProcedure and WriteStringProcedure', ['... output from the eval ...']));
    end;
  end;
end;

procedure CreateForthSerialProcessor (SerialDevice:PSerialDevice);
var
 Processor:TForthProcessor;
begin
 if SerialDeviceOpen (SerialDevice,9600,SERIAL_DATA_8BIT,SERIAL_STOP_1BIT,SERIAL_PARITY_NONE,SERIAL_FLOW_NONE,0,0) = ERROR_SUCCESS then
  begin
   SerialDeviceWriteLine(SerialDevice, 'forth ready and waiting ...');
   Processor:=TForthProcessor.Create;
  end;
end;

procedure CreateForthProcessors;
var
 SerialDeviceNumber:Integer;
 SerialDevice:PSerialDevice;
 ProcessorName:String;
begin
 if BoardGetType = BOARD_TYPE_QEMUVPB then
  begin
   for SerialDeviceNumber:=0 to 3 do
    begin
     SerialDevice:=SerialDeviceFindByName(Format('Serial%d',[SerialDeviceNumber]));
     if SerialDevice <> Nil then
      begin
       ProcessorName:=SysUtils.GetEnvironmentVariable(Format('SERIAL%d_PROCESSOR',[SerialDeviceNumber]));
       if UpperCase(ProcessorName) = 'FORTH' then
        CreateForthSerialProcessor(SerialDevice);
      end;
    end;
  end;
end;

initialization
 CreateForthProcessors;
end.
