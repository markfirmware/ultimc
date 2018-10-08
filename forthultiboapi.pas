unit ForthUltiboApi;

interface
procedure UltiboApiAddPrimitives;

implementation
uses
 engine,
 globalconfig,console,platform,ultibo,moreultibo;

function IntToBool(X:Integer):Boolean;
begin
 Result:=X <> 0;
end;

procedure P_Ultibo_Core_Platform_ActivityLedEnable;
begin
 ActivityLedEnable;
end;

procedure P_Ultibo_Core_Platform_ActivityLedOff;
begin
 ActivityLedOff;
end;

procedure P_Ultibo_Core_Platform_ActivityLedOn;
begin
 ActivityLedOn;
end;

procedure P_Ultibo_Core_Console_ConsoleWindowGetDefault;
begin
 Push(Integer(ConsoleWindowGetDefault(ConsoleDeviceGetDefault)));
end;

procedure P_Ultibo_Core_Console_ConsoleWindowClearEx;
var
 Handle,X1,X2,Y1,Y2,Cursor:Integer;
begin
 Cursor:=Pop;
 Y2:=Pop;
 Y1:=Pop;
 X2:=Pop;
 X1:=Pop;
 Handle:=Pop;
 Push(ConsoleWindowClearEx(Handle,X1,Y1,X2,Y2,IntToBool(Cursor)));
end;

procedure P_Ultibo_Core_Ultibo_Sleep;
begin
 Sleep(Pop);
end;

procedure P_MoreUltibo_StartSerialLogging;
begin
 MoreUltibo.StartSerialLogging;
end;

procedure UltiboApiAddPrimitives;
begin
 AddPrim(0, 'Ultibo.Core.Console.ConsoleWindowClearEx', @P_Ultibo_Core_Console_ConsoleWindowClearEx);
 AddPrim(0, 'Ultibo.Core.Console.ConsoleWindowGetDefault', @P_Ultibo_Core_Console_ConsoleWindowGetDefault);
 AddPrim(0, 'Ultibo.Core.Platform.ActivityLedEnable', @P_Ultibo_Core_Platform_ActivityLedEnable);
 AddPrim(0, 'Ultibo.Core.Platform.ActivityLedOff', @P_Ultibo_Core_Platform_ActivityLedOff);
 AddPrim(0, 'Ultibo.Core.Platform.ActivityLedOn', @P_Ultibo_Core_Platform_ActivityLedOn);
 AddPrim(0, 'Ultibo.Core.Ultibo.Sleep', @P_Ultibo_Core_Ultibo_Sleep);
 AddPrim(0, 'MoreUltibo.StartSerialLogging', @P_MoreUltibo_StartSerialLogging);
end;

end.
