unit ed;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils
  ;


var
        blocks: array [1..64, 1..16] of string;
        blk, bln:Integer;

procedure SayFile(filename:string);

implementation

procedure P_prb();
var i:integer;
begin
     for i := 1 to 16 do
     begin
          write(i); // TODO sort this out
          if i < 10 then write(' ');
          if i = bln then write('>') else writeptr(' ');
          forthwriteln(blocks[blk, i]);
     end;
end;

procedure P_slt();
begin
     blocks[blk, bln] := MakeString();
end;
procedure P_savb();
var b, l:integer; f: TextFile;
begin
     AssignFile(f, 'blocks.dat');
     Rewrite(f);
     for b := 1 to 64 do
     for l := 1 to 16 do
     begin
          forthwriteln('P_savb TODO');
          //forthwriteln(f, blocks[b, l]); // TODO
     end;
     CloseFile(f);
end;

procedure  P_lodb();
var b, l:integer; f: TextFile;
begin
     AssignFile(f, 'blocks.dat');
     Reset(f);
     for b := 1 to 64 do
     for l := 1 to 16 do
     begin
          readln(f, blocks[b, l]);
     end;
     CloseFile(f);
end;

procedure SayFile(filename:string);
var
	tfIn:TextFile;
	line:string;
begin
	AssignFile(tfIn, filename);
	reset(tfIn);

	while not eof(tfIn) do
	begin
		readln(tfIn, line);
		writeln(line);
	end;

	CloseFile(tfIn);
end;


procedure P_cl();
label again;
var str:string;
begin
     again:
     readln(str);
     if str = '.' then exit;
     blocks[blk, bln] := str;
     if (bln >= 16) then exit;
     inc(bln);
     goto again;
end;

function clamp(v,lo, hi: integer):Integer;
begin
     clamp := v;
     if clamp < lo then clamp := lo;
     if clamp > hi then clamp := hi;
end;

procedure P_sl();
begin
     bln := clamp(pop(), 1, 16);
end;

procedure P_sb();
begin
     blk := clamp(pop(), 1, 64);
end;
procedure P_xl();
begin
     EvalString(blocks[blk, bln]);
end;
procedure P_xb();
var l:integer;
begin
     //str := '';
     for l := 1 to 16 do EvalString(blocks[blk, l]);

end;

procedure InitEd();
begin
        { blocks }
        blk := 1;
        bln := 1;
        Addprim(0, 'prb', @P_prb);
        AddPrim(0, 'slt', @P_slt);
        AddPrim(0, 'savb', @P_savb);
        AddPrim(0, 'lodb', @P_lodb);
        AddPrim(0, 'cl', @P_cl);
        AddPrim(0, 'sl', @P_sl);
        AddPrim(0, 'sb', @P_sb);
        AddPrim(0, 'xl', @P_xl);

end;

end;

end.

