function WrapLine(length = 70)
   let line = getline(".")
   if strlen(line) <= a:length
     return
   endif

   let first_space = strridx(line, " ", a:length - 1)
   if first_space < 0
     let first_space = stridx(line, " ", a:length - 1)
   endif
   if first_space > -1
     let [head, tail] = SplitStr(line, first_space)
     let ruler = repeat(' ', a:length) .. '| length = ' .. a:length
     let space_ruler = repeat(' ', first_space) .. '▽ first_space = ' .. first_space
     call setline(CurrLineNum(), head)
     call AppendLine(tail)
     call MoveCursorDown(1)
     call WrapLine(a:length)
   endif
endf

function SplitStr(string, pos)
  " stridx and strridx count by char component, not by char
  " e.g.″ is three char components, but one char
  " strpart (as opposed to strcharpart) also counts by component
  " The clue is right in the docs: "byte index"
  let head = strpart(a:string, 0, a:pos)
  let tail = strpart(a:string, a:pos + 1)
  return [head, tail]
endf

function AppendLine(text)
  call append(CurrLineNum(), a:text)
endf

function MoveCursorDown(num_lines)
  let new_pos = [0, CurrLineNum() + a:num_lines, 0, 0]
  call setpos(".", new_pos)
endf

function CurrLineNum()
  let [_, curr_line_num, _, _, _] = getcurpos()
  return curr_line_num
endf
