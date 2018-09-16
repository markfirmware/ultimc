unit forthgpio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, parser, heapfuncs
  //Glute,
  {Devices,}
  ,GPIO
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
//{$push}{$warn 5024 off}
//var pin, mode:TCell;
begin
     //mode := Pop();
     //pin  := Pop();
     Args2(@SysGPIOFunctionSelect);
     {* SysGPIOFunctionSelect(pin, mode); *}
end;
//{$pop}

procedure gos();
//{$push}{$warn 5024 off}
begin
     Args2(@SysGPIOOutputSet);
end;
//{$pop}

procedure gps();
//{$push}{$warn 5024 off}
begin
     Args2(@SysGPIOPullSelect);
end;
//{$pop}

initialization
begin
  AddPrim(0, 'gfs', @gfs);
  AddPrim(0, 'gos', @gos);
  AddPrim(0, 'gps', @gps);
end;
end.

