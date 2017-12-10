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
function gfs(vs:TVariantList):Variant;
{$push}{$warn 5024 off}
begin
     Args2(@SysGPIOFunctionSelect);
     {SysGPIOFunctionSelect(pin, mode);}
     gfs := Null;
end;
{$pop}

function gos(vs:TVariantList):Variant;
{$push}{$warn 5024 off}
begin
     Args2(@SysGPIOOutputSet);
     gos := Null;
end;
{$pop}

function gps(vs:TVariantList):Variant;
{$push}{$warn 5024 off}
begin
     Args2(@SysGPIOPullSelect);
     gps := Null
end;
{$pop}

initialization
begin
  AddGluteProc('gfs', @gfs);
  AddGluteProc('gos', @gos);
  AddGluteProc('gps', @gps);
end;
end.

