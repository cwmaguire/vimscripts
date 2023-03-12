" works in the current buffer

" If called with a range, call TableWithRange with that range
function TableFromRange() range
  call TableWithRange(a:firstline, a:lastline)
endf

" TODO
" - add header row
"   - change lines to thinner lines for the rest of the table
"   - I'm thinking / for the separator
" - merge cells
"   - "invalid" rows would just take up the entire table
"   - Not as easy as it sounds: column separators get all messed up

" " Find the first and last lines of the current table,
" " if any, and call TableWithRange(f, l)
function Table()
  " Find table's first and last lines
  let [start_line, end_line] = GetLineNumbers()
  call TableWithRange(start_line, end_line)
endf

function GetLineNumbers()
  let first_blank_line_up = search("^$", 'nbW')
  let start_line = first_blank_line_up + 1
  let first_blank_line_down = search("^$", 'nW')
  if first_blank_line_down > 0
    let end_line = first_blank_line_down - 1
  else
    let end_line = line('$')
  endif
  return [start_line, end_line]
endf

" TODO: either: don't add spacing, or remove spacing on "undo"
function TableWithRange(first_line, last_line)
  echo "f: " .. a:first_line .. ", l: " .. a:last_line
  let lines = getline(a:first_line, a:last_line)
  let num_columns = 0
  let rows = map(copy(lines), {_, v -> LineToRow(v)})
  let num_columns = max(map(copy(rows), {_, v -> len(v)}))
  let rows = map(rows, {_, v -> AddColumns(v, num_columns)})
  let col_sizes = ColSizes(rows)
  let rows = map(rows, {_, v -> ResizeColumns(v, col_sizes)})
  let top = TopRow(col_sizes)
  let bottom = BottomRow(col_sizes)

  let line_rows = Zip(rows, range(a:first_line, a:last_line))
  call map(line_rows, {_, v -> RenderRow(v, col_sizes)})
  let separator = SeparatorRow(col_sizes)

  " work from the bottom up so as not to mess up line numbers
  call append(a:last_line, bottom)
  call map(range(a:last_line - 1, a:first_line, -1),
\          {_, v -> append(v, separator)})
  call append(a:first_line - 1, top)
endf

" delete top, bottom and separator lines
" convert column lines to pipes
" remove padding
function UndoTable()
  let [start_line, end_line] = GetLineNumbers()
  call map(range(end_line, start_line, -1),
\          {_, v -> UndoRow(v)})
  call map(range(end_line, start_line, -1),
\          {_, v -> MaybeDeleteGridLine(v)})
endf

"function LineToRow(index, value)
"  if IsHeader(value)
"    LineToHeader
"  endif
"endf
"
"function LineToHeader(Line)
"  LineToRow(Line)  " just treat headers as lines for now
"endf

function LineToRow(line)
  " create a list of columns
  let columns = []
  let column = ""
  let first_pipe = stridx(a:line, '|')
  let last_pipe = strridx(a:line, '|')

  if first_pipe == -1 || first_pipe == last_pipe
    echo "Invalid row"
    return []
  endif

  return Columns(String2Chars(a:line[first_pipe + 1:]))
endf

function String2Chars(string)
  return map(str2list(a:string), {_, v -> nr2char(v)})
endf

function Columns(chars, columns = [""])
  if empty(a:chars)
    if Last(a:columns) == ""
      return a:columns[:len(a:columns) -2]
    else
      return a:columns
    endif
  endif

  let columns = copy(a:columns)
  let head = Hd(a:chars)
  let rest = Tail(a:chars)
  if head == "|"
    return Columns(rest, a:columns + [""])
  else
    let columns[len(a:columns) - 1] = Last(a:columns) .. head
    return Columns(rest, columns)
  endif
endf

function Last(list)
  return a:list[len(a:list) - 1]
endf

function AddColumns(row, num_columns)
  if len(a:row) >= a:num_columns
    return a:row
  endif
  return AddColumns(a:row + [""], a:num_columns)
endf

function RenderRow(row_line_number, col_sizes)
  let [row, line_number] = a:row_line_number
  let row = "┃ " .. join(row, " ┃ ") .. " ┃"
  call setline(line_number, row)

endf

function SeparatorRow(sizes)
  let columns = map(copy(a:sizes), {_, v -> repeat("━", v)})
  return "┣━" .. join(columns, "━╋━") .. "━┫"
endf

function TopRow(sizes)
  let columns = map(copy(a:sizes), {_, v -> ColumnBorder(v)})
  return "┏━" .. join(columns, "━┳━") .. "━┓"
endf

function BottomRow(sizes)
  let columns = map(copy(a:sizes), {_, v -> ColumnBorder(v)})
  return "┗━" .. join(columns, "━┻━") .. "━┛"
endf

function ColumnBorder(size)
  return repeat("━", a:size)
endf

" Assumes all rows have the same # of columns
function ColSizes(rows, sizes = [])
  if empty(a:rows[0])
    return a:sizes
  endif

  let max = max(map(copy(a:rows), {_, v -> strlen(Hd(v))}))
  let rest = map(copy(a:rows), {_, v -> Tail(v)})

  return ColSizes(rest, a:sizes + [max])
endf

function Hd(list)
  return a:list[0]
endf

function Tail(list)
  return a:list[1:]
endf

function ResizeColumns(row, col_sizes)
  return map(Zip(a:row, a:col_sizes), {_, v -> ResizeColumn(v)})
endf

function ResizeColumn(text_size)
  ":let-unpack
  let [text, size] = a:text_size
  return Pad(text, size)
endf

function Pad(text, size)
  if strlen(a:text) >= a:size
    return a:text
  endif
  return Pad(a:text .. " ", a:size)
endf

function Zip(list1, list2, list = [])
  if empty(a:list1) || empty(a:list2)
    return a:list
  endif

  return Zip(Tail(a:list1),
\            Tail(a:list2),
\            a:list + [[Hd(a:list1), Hd(a:list2)]])
endf

function MapFun(_, value, fun)
  return fun(value)
endf

function UndoRow(line_number)
   let line = getline(a:line_number)
   let new_line = substitute(line, " *┃ *", "|", "g")
"   echo "" .. a:line_number .. ": Old line = " .. line ..
"\       ", New line = " .. new_line
   call setline(a:line_number, new_line)
endf

function MaybeDeleteGridLine(line_number)
  let line = trim(getline(a:line_number))
  " if strcharpart(line, 0, 1) != "┃"
  if strcharpart(line, 0, 1) != "|"
    call deletebufline(bufname(), a:line_number)
  endif
endf

""""""""""""""""""""""""" TESTS """""""""""""""""""""""""
function Test()
  call Test_Columns()
  call Test_AddColumns()
  call Test_TopRow()
  call Test_BottomRow()
  call Test_ColumnBorder()
  call Test_ColSizes()
  call Test_ResizeColumns()
  call Test_ResizeColumn()
  call Test_Pad()
  call Test_Hd()
  call Test_Tail()
  call Test_Zip()
endf

function Test_LineToRow()
  let line = "abc"
  if LineToRow(line) != []
    throw "LineToRow/1 test failed: no pipe separators"
  endif

  let line = "abc|"
  if LineToRow(line) != []
    throw "LineToRow/1 test failed: only 1 pipe separator"
  endif

  let line = "abc|def|"
  if LineToRow(line) != ["def"]
    throw "LineToRow/1 test failed"
  endif

  let line = "abc|def|g"
  if LineToRow(line) != ["def", "g"]
    throw "LineToRow/1 test failed"
  endif
endf

function Test_String2Chars()
  let string = "abcdef"
  if String2Chars(string) != ["a", "b", "c", "d", "e", "f"]
    throw "String2Chars/1 test failed"
  endif
endf

function Test_Columns()
  let chars = ["a", "|", "b", "|", "c", "d", "e", "f"]
  if Columns(chars) != ["a", "b", "cdef"]
    throw "Columns/1 test failed"
  endif

  let chars = ["a", "|", "b", "|", "c", "d", "e", "|"]
  if Columns(chars) != ["a", "b", "cde"]
    throw "Columns/1 test failed"
  endif
endf

function Test_AddColumns()
  let row = ["a", "bc", "d"]
  let num_columns = 5
  let result = ["a", "bc", "d", "", ""]
  if AddColumns(row, num_columns) != result
    throw "AddColumns/2 test failed"
  endif
endf

function Test_TopRow()
  if TopRow([0, 1, 2, 3]) != "┏━━┳━━━┳━━━━┳━━━━━┓"
    throw "TopRow/1 test failed"
  endif
endf

function Test_BottomRow()
  if BottomRow([0, 1, 2, 3]) != "┗━━┻━━━┻━━━━┻━━━━━┛"
    throw "BottomRow/1 test failed"
  endif
endf

function Test_ColumnBorder()
  if ColumnBorder(5) != "━━━━━"
    throw "ColumnBorder/1 test failed"
  endif
endf

function Test_ColSizes()
  let rows = [["abc", "defg", "h"],
            \ ["a", "bcdefghij", "kl"]]
  let col_sizes = [3, 9, 2]
  let result = ColSizes(rows)
  if ColSizes(rows) != col_sizes
    throw "ColSizes/2 test failed"
  endif
endf

function Test_ResizeColumns()
  let row = ["abc", "def", "g"]
  let col_sizes = [5, 6, 7]
  let resized_row = ["abc  ", "def   ", "g      "]
  if ResizeColumns(row, col_sizes) != resized_row
    throw "ResizeColumns/2 test failed"
  endif
endf

function Test_ResizeColumn()
  let text_size = ["abc", 7]
  let resized = "abc    "
  if ResizeColumn(text_size) != resized
    throw "ResizeColumn/1 test failed"
  endif
endf

function Test_Pad()
  let str = "abc"
  let padded_str = "abc    "
  if Pad(str, 7) != padded_str
    throw "Pad/2 test failed"
  endif
endf

function Test_Hd()
  let list = [1, 2, 3]
  let head = 1
  if Hd(list) != head
    throw "Hd/1 test failed"
  endif
endf

function Test_Tail()
  let list = [1,2,3]
  let tail = [2,3]
  if Tail(list) != tail
    throw "Tail/1 test failed"
  endif
endf

function Test_Last()
  let list = [1, 2, 3]
  if Last(list) != 3
    throw "Last/1 test failed"
  endif
endf

function Test_Zip()
  let list1 = [1, 2, 3]
  let list2 = ['a','b','c']
  let list3 = [[1, 'a'], [2, 'b'], [3, 'c']]
  if Zip(list1, list2) != list3
    echo "list1: " list1  ", list2: "  list2  ", result: "  list3
    throw "Zip/3 test failed"
  endif
endf
