program day02b;

uses sysutils, strutils;

var
  horpos : Int64 = 0;
  depth  : Int64 = 0;
  aim    : Int64 = 0;
  inval  : Int64 = 0;
  inp    : String  = '';

function ReadInput : Boolean;
var
  tmp : String = '';
begin
   ReadInput := false;
   readln(inp);

   inp := LowerCase(inp);
   tmp := ExtractWord(2, inp, StdWordDelims);
   inval := StrToInt(tmp);

   case inp[1] of
      'f':
         begin
            depth  := depth  + aim * inval;
            horpos := horpos + inval;
         end;
      'd': aim := aim + inval;
      'u': aim := aim - inval;
      else exit;
   end;

   if not eof(input) then ReadInput := true;
end;

begin
   while ReadInput do;

   write('final horizontal position: ');
   writeln(horpos);
   write('final depth: ');
   writeln(depth);
   write('final result: ');
   writeln(horpos * depth);
end.
