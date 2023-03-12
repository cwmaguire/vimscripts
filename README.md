# vimscripts
Toys I've created with Vimscript

- tables.vim
  - Table()
  - TableFromRange() range
  - TableWithRange(first_line, last_line)
  - UndoTable()

Create and undo tables with glyphs:

This: (assume cursor is on one of the following three lines)

```
|a|b
| |c
|d||
```

after

```
:call Table()
```

becomes this:

```
┏━━━┳━━━┓
┃ a ┃ b ┃
┣━━━╋━━━┫
┃   ┃ c ┃
┣━━━╋━━━┫
┃ d ┃   ┃
┗━━━┻━━━┛
```


- wrapline.vim
  - WrapLine(length = 70)

Wraps lines on spaces at or less than the length

This line:

```
 ░ This line has 27 characters
```

after

```
:call WrapLine(15)
```

becomes these lines:

```
 ░ This line has
 ░ 27 characters
```
