{
Ultibo Forth Shell extension unit.

Copyright (C) 2015 - SoftOz Pty Ltd.

Arch
====

 <All>

Boards
======

 <All>

Licence
=======

 LGPLv2.1 with static linking exception (See COPYING.modifiedLGPL.txt)
 
Credits
=======

 Information for this unit was obtained from:

 
References
==========

 

Shell Forth
===========

}

{$mode delphi} {Default to Delphi compatible syntax}
{$H+}          {Default to AnsiString}
{$inline on}   {Allow use of Inline procedures}

unit ShellForth;

interface

uses GlobalConfig,GlobalConst,GlobalTypes,Platform,Threads,Devices,FileSystem,SysUtils,Classes,Ultibo,UltiboClasses,UltiboUtils,Shell,HTTP;

//To Do //Look for:

//--

{==============================================================================}
{Global definitions}
//{$INCLUDE ..\core\GlobalDefines.inc}

{==============================================================================}
type
 {Shell Forth specific clases}
 TShellForth = class(TShellCommand)
 public
  {}
  constructor Create;
 private
  {Internal Variables}
 
  {Internal Methods}
  
 protected
  {Internal Variables}

  {Internal Methods}
  
 public
  {Public Properties}

  {Public Methods}
  function DoHelp(AShell:TShell;ASession:TShellSession):Boolean; override;
  function DoInfo(AShell:TShell;ASession:TShellSession):Boolean; override;
  function DoCommand(AShell:TShell;ASession:TShellSession;AParameters:TStrings):Boolean; override;
 end;
 
 //TShellWGET = class(TShellCommand) //To Do //Simple WGET 

{==============================================================================}
{Initialization Functions}
procedure ShellForthInit;

{==============================================================================}
{Shell Forth Functions}
 
{==============================================================================}
{Shell Forth Helper Functions}
 
{==============================================================================}
{==============================================================================}

implementation

{==============================================================================}
{==============================================================================}
var
 {Shell Forth specific variables}
 ForthInterpreter:Integer; // Probably replace with an object refernce
 ShellForthInitialized:Boolean;
 
{==============================================================================}
{==============================================================================}
{TShellForth}
constructor TShellForth.Create;
begin
 inherited Create;
 Name:='Forth';
 Flags:=SHELL_COMMAND_FLAG_INFO or SHELL_COMMAND_FLAG_HELP;
end;

function TShellForth.DoHelp(AShell:TShell;ASession:TShellSession):Boolean; 
begin
 {}
 Result:=False;
 
 {Check Shell}
 if AShell = nil then Exit;
 
 {Do Help}
 AShell.DoOutput(ASession,'Submit sentence to forth interpreter');
 AShell.DoOutput(ASession,'');
 
 {Return Result}
 Result:=True;
end;
 
function TShellForth.DoInfo(AShell:TShell;ASession:TShellSession):Boolean; 
begin
 {}
 Result:=False;
 
 {Check Shell}
 if AShell = nil then Exit;
 
 {Do Info}
 Result:=AShell.DoOutput(ASession,'Submit sentence to forth interpreter');
end;


function TShellForth.DoCommand(AShell:TShell;ASession:TShellSession;AParameters:TStrings):Boolean; 
var
 Sentence:String;
 i:Integer;
begin
 {}
 Result:=False;
 
 {Check Shell}
 if AShell = nil then Exit;

 {Check Parameters}
 if AParameters = nil then Exit;

 if ForthInterpreter = 0 then
  begin
   ForthInterpreter:=1; 
   AShell.DoOutput(ASession, Format('forth interpreter initialized',[]));
  end;

 Sentence:='';
 for I:=0 to AParameters.Count - 1 do
  begin
   if Length(Sentence) <> 0 then
    Sentence:=Sentence + ' ';
   Sentence:=Sentence + AParameters[I];
  end;
 AShell.DoOutput(ASession, Format('forth sentence <%s>',[Sentence]));
 AShell.DoOutput(ASession, Format('forth output is %s',['...']));
end;
 
{==============================================================================}
{==============================================================================}
{Initialization Functions}
procedure ShellForthInit;
begin
 {}
 {Check Initialized}
 if ShellForthInitialized then Exit;
 
 {Register FileSystem Commands}
 ShellRegisterCommand(TShellForth.Create);

 ShellForthInitialized:=True;
end;
 
{==============================================================================}
{==============================================================================}
{Shell Forth Functions}
 
{==============================================================================}
{==============================================================================}
{Shell Forth Helper Functions}
 
{==============================================================================}
{==============================================================================}

initialization
 ShellForthInit;

{==============================================================================}
 
finalization
 {Nothing}

{==============================================================================}
{==============================================================================}
 
end.
