unit GpioGlute;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  Glute,
  {Devices,}
  GPIO
  ;

type
  TFunc2 = function(arg1, args:LongWord):DWord;

implementation

procedure Args2(f:TFunc2);
var pin, mode:LongWord;
begin
     yylex(yytext);
     pin :=  StrToInt(yytext);
     yylex(yytext);
     mode := StrToInt(yytext);
     f(pin, mode);
end;
procedure gfs();
begin
     Args2(@SysGPIOFunctionSelect);
     {SysGPIOFunctionSelect(pin, mode);}
end;
procedure gos();
begin
     Args2(@SysGPIOOutputSet);
end;

procedure gps();
var pin, mode:LongWord;
begin
     {yylex(yytext);
     pin :=  StrToInt(yytext);
     yylex(yytext);
     mode := StrToInt(yytext);
     SysGPIOPullSelect(pin, mode);
     }
     Args2(@SysGPIOPullSelect);
end;

initialization
begin
  AddGluteProc('gfs', @gfs);
  AddGluteProc('gos', @gos);
  AddGluteProc('gps', @gps);
end;
end.

