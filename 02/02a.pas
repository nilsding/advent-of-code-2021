program day02a;

uses sysutils, strutils;

var
  horpos : Integer = 0;
  depth  : Integer = 0;
  inval  : Integer = 0;
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
      'f': horpos := horpos + inval;
      'd': depth := depth + inval;
      'u': depth := depth - inval;
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
