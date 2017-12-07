program glutetest;

{$mode objfpc}{$H+}
uses
	Glute;



procedure LexInput(input:string);
begin


	InitLexer(input);
	while yylex(yytext) <> Eof do
		writeln('yytext is:' + yytext);
end;

procedure GluteTest1();
begin
	LexInput('    hello123 ''this is a string'' world  ');

end;

procedure hi();
begin
	writeln('hello world');
end;

procedure GluteRepl1();
begin
	AddGluteProc('hi', @hi);
	GluteRepl();
end;

begin
	{GluteTest1();}
	GluteRepl1();
end.


