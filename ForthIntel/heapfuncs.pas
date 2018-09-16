unit heapfuncs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;
const MAX_HEAP = 10000;


type
  {$ifdef CPU32}
  TCell = Int32;
  {$else}
  TCell = Int64;
  {$endif}
  TCellPtr = TCell; // hopefully will eliminate confusion


  TProc = procedure();

  THeaderPtr = ^THeader;
  THeader = record // a header for a word
          link:THeaderPtr;
          flags:byte;
          name:PString;
          codeptr:TProc;
          hptr:Integer; // pointer to the heap
  end; // data will extend beyond this

var
        hptr:Integer; // pointer into the heap
        heap:array[1..MAX_HEAP] of byte;
        latest:THeaderPtr; // the latest word being defined

procedure HeapifyCell(val:TCell);
procedure HeapPointer(ptr:Pointer);
function ToHeaderPtr(ip:Integer):THeaderPtr;
function GetHeapCell(pos:TCellPtr): TCell;
function GetHeapPointer(pos:Integer) : Pointer;
procedure SetHeapCell(ptr:TCellPtr; val:TCell);

implementation

{$push}
//{$warn 5057 off}  // hide warning var not initialized
{$hints off}   // hide warning var not initialized
function ToHeaderPtr(ip:Integer):THeaderPtr;
begin
     Move(heap[ip], ToHeaderPtr, sizeof(Pointer));
end;
function GetHeapCell(pos:TCellPtr): TCell;
begin
     Move(heap[pos], GetHeapCell, sizeof(TCell));
end;
function GetHeapPointer(pos:Integer) : Pointer;
begin
        Move(heap[pos], GetHeapPointer, sizeof(Pointer));
end;
function GetHeapByte(pos:TCellPtr):byte;
begin
     Move(heap[pos], GetHeapByte, sizeof(byte));
end;
{$pop}

procedure SetHeapCell(ptr:TCellPtr; val:TCell);
begin
        Move(val, heap[ptr], sizeof(TCell));
end;
procedure HeapifyHeader(hdr:THeaderPtr);
begin
        Move(hdr, heap[hptr], sizeof(Pointer));
        inc(hptr, sizeof(Pointer));
end;

procedure HeapifyByte(b:byte);
begin
        heap[hptr] := b;
        inc(hptr);
end;


procedure HeapifyCell(val:TCell);
begin
     Move(val, heap[hptr], sizeof(TCell));
     inc(hptr, sizeof(TCell));
end;
procedure HeapPointer(ptr:Pointer);
begin
        Move(ptr, heap[hptr], sizeof(Pointer));
        inc(hptr, sizeof(Pointer));
end;

initialization
begin
  hptr := 1;
end;
end.

