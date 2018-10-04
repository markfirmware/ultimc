unit forthgpio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils
  , engine
  , GPIO
  ;

type
  TFunc2 = function(arg1, args:LongWord):DWord;

implementation


procedure Args2(f:TFunc2);
var pin, mode:TCell;
begin
     mode := Pop();
     pin := Pop();
     f(pin, mode);
end;

procedure gfs();
begin
     Args2(@SysGPIOFunctionSelect);
end;

procedure gos();
begin
     Args2(@SysGPIOOutputSet);
end;

procedure gps();
begin
     Args2(@SysGPIOPullSelect);
end;

initialization
begin
  AddPrim(0, 'gfs', @gfs);
  AddPrim(0, 'gos', @gos);
  AddPrim(0, 'gps', @gps);
end;
end.

