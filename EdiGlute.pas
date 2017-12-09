unit EdiGlute;

{$mode objfpc}{$H+}

interface

uses
	Classes, SysUtils
	, Glute
	, Edi
	;


implementation

procedure DoSayFile();
begin
	yylex(yytext);
	sayfile(yytext);
end;

initialization
begin
	AddGluteProc('sayfile', @DoSayFile);
end;


end.

