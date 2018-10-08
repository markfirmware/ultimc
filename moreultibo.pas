unit MoreUltibo;

interface
uses Serial;

procedure StartSerialLogging;
procedure SerialDeviceWriteLine(SerialDevice:PSerialDevice;Line:String);

implementation
uses
 GlobalConfig,Logging;

procedure StartSerialLogging;
begin
 LOGGING_INCLUDE_COUNTER:=False;
 LOGGING_INCLUDE_TICKCOUNT:=True;
 SERIAL_REGISTER_LOGGING:=True;
 SerialLoggingDeviceAdd(SerialDeviceGetDefault);
 SERIAL_REGISTER_LOGGING:=False;
 LoggingDeviceSetDefault(LoggingDeviceFindByType(LOGGING_TYPE_SERIAL));
end;

procedure SerialDeviceWriteChar(SerialDevice:PSerialDevice;C:Char);
var
 Count:LongWord;
begin
 SerialDeviceWrite(SerialDevice,@C,1,SERIAL_WRITE_NONE,Count);
end;

procedure SerialDeviceWriteLine(SerialDevice:PSerialDevice;Line:String);
var
 Count:LongWord;
begin
 SerialDeviceWrite(SerialDevice,PChar(Line),Length(Line),SERIAL_WRITE_NONE,Count);
 SerialDeviceWriteChar(SerialDevice,Char(13));
 SerialDeviceWriteChar(SerialDevice,Char(10));
end;

end.
