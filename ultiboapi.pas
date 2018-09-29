unit UltiboApi;

interface
procedure UltiboApiAddPrimitives;

implementation
uses
 parser,
 //globaltypes,globalconst,
 globalconfig,console,logging,serial,platform,ultibo;

function IntToBool(X:Integer):Boolean;
begin
 Result:=X <> 0;
end;

procedure P_Ultibo_Uses_Platform_ActivityLedEnable;
begin
 ActivityLedEnable;
end;

procedure P_Ultibo_Uses_Platform_ActivityLedOff;
begin
 ActivityLedOff;
end;

procedure P_Ultibo_Uses_Platform_ActivityLedOn;
begin
 ActivityLedOn;
end;

procedure P_Ultibo_Uses_Console_ConsoleWindowGetDefault;
begin
 Push(Integer(ConsoleWindowGetDefault(ConsoleDeviceGetDefault)));
end;

procedure P_Ultibo_Uses_Console_ConsoleWindowClearEx;
var
 Handle,X1,X2,Y1,Y2,Cursor:Integer;
begin
 Handle:=Pop;
 X1:=Pop;
 X2:=Pop;
 X1:=Pop;
 X2:=Pop;
 Cursor:=Pop;
 Push(ConsoleWindowClearEx(Handle,X1,Y1,X2,Y2,IntToBool(Cursor)));
end;

procedure P_Ultibo_Uses_Ultibo_Sleep;
begin
 Sleep(Pop);
end;

procedure P_Ultibo_Uses_UltiboApi_StartSerialLogging;
begin
 LOGGING_INCLUDE_COUNTER:=False;
 LOGGING_INCLUDE_TICKCOUNT:=True;
 SERIAL_REGISTER_LOGGING:=True;
 SerialLoggingDeviceAdd(SerialDeviceGetDefault);
 SERIAL_REGISTER_LOGGING:=False;
 LoggingDeviceSetDefault(LoggingDeviceFindByType(LOGGING_TYPE_SERIAL));
end;

procedure UltiboApiAddPrimitives;
begin
 AddPrim(0, 'Ultibo.Uses.Console.ConsoleWindowClearEx', @P_Ultibo_Uses_Console_ConsoleWindowClearEx);
 AddPrim(0, 'Ultibo.Uses.Console.ConsoleWindowGetDefault', @P_Ultibo_Uses_Console_ConsoleWindowGetDefault);
 AddPrim(0, 'Ultibo.Uses.Platform.ActivityLedEnable', @P_Ultibo_Uses_Platform_ActivityLedEnable);
 AddPrim(0, 'Ultibo.Uses.Platform.ActivityLedOff', @P_Ultibo_Uses_Platform_ActivityLedOff);
 AddPrim(0, 'Ultibo.Uses.Platform.ActivityLedOn', @P_Ultibo_Uses_Platform_ActivityLedOn);
 AddPrim(0, 'Ultibo.Uses.Ultibo.Sleep', @P_Ultibo_Uses_Ultibo_Sleep);
 AddPrim(0, 'Ultibo.Uses.UltiboApi.StartSerialLogging', @P_Ultibo_Uses_UltiboApi_StartSerialLogging);
end;

end.
