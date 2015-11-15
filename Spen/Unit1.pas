unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtDlgs;

type
  TArrayOfString = array of string;

  TOperand = record
    operand: string;
    count: integer;
  end;

  TArrayOperands = array of TOperand;
  TArrInt = array of integer;

  TForm_Spen = class(TForm)
    OpenTextFileDialog_Load_Code: TOpenTextFileDialog;
    Button_Load: TButton;
    Memo_Code_From_File: TMemo;
    Button_Check: TButton;
    Memo_Found_Operands: TMemo;
    Memo_Original_Code: TMemo;
    procedure Button_LoadClick(Sender: TObject);
    procedure Button_CheckClick(Sender: TObject);
    function create_array_to_analyze: TArrayOfString;
    procedure output_operands(operands_found: TArrayOperands);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form_Spen: TForm_Spen;

implementation

{$R *.dfm}

function TForm_Spen.create_array_to_analyze: TArrayOfString;
const
  comment_open = '/*';
  comment_short = '//';
  comment_close = '*/';
var
  code_to_analyze: TArrayOfString;
  lines_in_code, i, j, k, lines_added, comment_line: integer;
  line_to_analyze, string_for_quote: string;
begin
  lines_in_code := Memo_Code_From_File.Lines.count;
  lines_added := 1;
  setlength(code_to_analyze, lines_added);
  i := 0;
  while i < lines_in_code - 1 do
  begin
    if Memo_Code_From_File.Lines[i] <> '' then
    begin
      line_to_analyze := Memo_Code_From_File.Lines[i];
      comment_line := pos(comment_short, line_to_analyze);
      if comment_line <> 0 then
        delete(line_to_analyze, comment_line, length(line_to_analyze));
      comment_line := pos(comment_open, line_to_analyze);
      if comment_line <> 0 then
      begin
        comment_line := pos(comment_close, line_to_analyze);
        while comment_line = 0 do
        begin
          inc(i);
          line_to_analyze := Memo_Code_From_File.Lines[i];
          comment_line := pos(comment_close, line_to_analyze);
        end;
      end
      else
      begin
        setlength(code_to_analyze, lines_added);
        code_to_analyze[lines_added - 1] := line_to_analyze;
        inc(lines_added);

      end;
    end;
    inc(i);
  end;
  result := code_to_analyze;
end;

function find_doubles(found_operands: TArrayOperands;
  operand_to_search_for: string): integer;
var
  i, length_array: integer;
begin
  length_array := length(found_operands);
  for i := 0 to length_array - 1 do
  begin
    if found_operands[i].operand = operand_to_search_for then
      break;
  end;
  if i = length_array then
    i := -1;
  result := i;
end;

function test_line_to_be_operand(line_to_test: string): string;
const
  delimeters: set of char = ['(', ')', '[', ']', '<', ',', '.', '+', '-',
    ':', ';'];
  alfabet: set of char = ['A' .. 'Z', 'a' .. 'z'];
var
  i: integer;
  buffer_for_new_string: string;
begin
  buffer_for_new_string := line_to_test[1];
  for i := 2 to length(line_to_test) do
  begin
    if line_to_test[i] in alfabet then
      buffer_for_new_string := buffer_for_new_string + line_to_test[i]
    else
      break;
  end;
  result := buffer_for_new_string;
end;

function include_new_operand(found_operands: TArrayOperands;
  new_operand: string): TArrayOperands;
var
  j, place_of_double: integer;
  new_operand_after_test: string;
begin
  j := length(found_operands);
  new_operand_after_test := test_line_to_be_operand(new_operand);
  if j = 0 then
  begin
    setlength(found_operands, 1);
    found_operands[j].operand := test_line_to_be_operand
      (new_operand_after_test);
    found_operands[j].count := 1;
  end
  else
  begin
    place_of_double := find_doubles(found_operands, new_operand_after_test);
    if place_of_double = -1 then
    begin
      inc(j);
      setlength(found_operands, j);
      found_operands[j - 1].operand := test_line_to_be_operand
        (new_operand_after_test);
      found_operands[j - 1].count := 1;
    end
    else
    begin
      found_operands[place_of_double].count := found_operands[place_of_double]
        .count + 1;
    end;
  end;
  result := found_operands;
end;

function find_delimiters(line_to_test: string): integer;
const
  delimeters: set of char = ['(', ')', '[', ']', '<'];
  alphabet: set of char = ['A' .. 'Z', 'a' .. 'z'];
var
  j, place_of_operand: integer;
begin
  place_of_operand := pos('$', line_to_test);
  if (line_to_test[place_of_operand - 1] in delimeters) then
  begin
    result := place_of_operand - 1;
  end
  else
  begin
    for j := place_of_operand to length(line_to_test) do
      if line_to_test[j] in delimeters then
        break;
    result := j;
  end;
end;

Function look_for_operands_in_line(line_to_analyze: string;
  operand_place_in_line: integer; found_operands: TArrayOperands)
  : TArrayOperands;
var
  copy_string: string;
  place_of_delimiter, place_of_string_delimeter: integer;
begin
  while operand_place_in_line <> 0 do
  begin
    place_of_delimiter := find_delimiters(line_to_analyze);
    if place_of_delimiter <> 0 then
    begin
      if place_of_delimiter < operand_place_in_line then
      begin
        copy_string := copy(line_to_analyze, operand_place_in_line,
          length(line_to_analyze) - place_of_delimiter);
        copy_string := test_line_to_be_operand(copy_string);
      end
      else
      begin
        copy_string := copy(line_to_analyze, operand_place_in_line,
          place_of_delimiter - operand_place_in_line);
        copy_string := test_line_to_be_operand(copy_string);
      end;
      if copy_string <> '' then
        found_operands := include_new_operand(found_operands, copy_string);
      if operand_place_in_line > 1 then
        delete(line_to_analyze, 1, operand_place_in_line + 1)
      else
        delete(line_to_analyze, operand_place_in_line, place_of_delimiter);
      operand_place_in_line := pos('$', line_to_analyze);
    end
    else
    begin
      found_operands := include_new_operand(found_operands, line_to_analyze);
      operand_place_in_line := 0;
    end;
  end;
  result := found_operands;
end;

function find_operands(code_to_analyze: TArrayOfString): TArrayOperands;
const
  symbol_operand = '$';
var
  i, operand_place, lines_in_code: integer;
  found_operands: TArrayOperands;
begin
  lines_in_code := length(code_to_analyze);
  setlength(found_operands, 0);
  for i := 0 to lines_in_code - 1 do
  begin
    operand_place := pos(symbol_operand, code_to_analyze[i]);
    if operand_place <> 0 then
      found_operands := look_for_operands_in_line(code_to_analyze[i],
        operand_place, found_operands);
  end;
  result := found_operands;
end;

procedure TForm_Spen.output_operands(operands_found: TArrayOperands);
var
  i, amount_of_unique_operands: integer;
begin
  amount_of_unique_operands := length(operands_found);
  for i := 0 to amount_of_unique_operands - 1 do
  begin
    if operands_found[i].count <> 1 then
      Memo_Found_Operands.Lines.Add('Операнд ' + operands_found[i].operand +
        ' имеет спен равный ' + inttostr(operands_found[i].count - 1));
  end;
end;

procedure TForm_Spen.Button_CheckClick(Sender: TObject);
var
  lines_in_code: integer;
  code_to_analyze: TArrayOfString;
  operands_found: TArrayOperands;
begin
  lines_in_code := Memo_Code_From_File.Lines.count;
  code_to_analyze := create_array_to_analyze;
  operands_found := find_operands(code_to_analyze);
  output_operands(operands_found);
end;

procedure TForm_Spen.Button_LoadClick(Sender: TObject);
var
  text_file_name, file_with_needed_code: textfile;
  i: integer;
  temporary_for_symbol: ansichar;
begin
  if OpenTextFileDialog_Load_Code.execute then
    assignfile(text_file_name, OpenTextFileDialog_Load_Code.filename);
  reset(text_file_name);
  assignfile(file_with_needed_code, 'output.txt');
  rewrite(file_with_needed_code);
  i := 1;
  while not eof(text_file_name) do
  begin
    read(text_file_name, temporary_for_symbol);
    if temporary_for_symbol = '''' then
    begin
      read(text_file_name, temporary_for_symbol);
      while temporary_for_symbol <> '''' do
        read(text_file_name, temporary_for_symbol);
    end;
      write(file_with_needed_code, temporary_for_symbol);
  end;
  closefile(text_file_name);
  closefile(file_with_needed_code);
  Memo_Code_From_File.Lines.LoadFromFile('output.txt');
  Memo_Original_Code.Lines.LoadFromFile(OpenTextFileDialog_Load_Code.filename);
end;

end.
