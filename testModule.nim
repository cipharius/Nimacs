import nimacs
import macros

proc identTest(ident: EmacsValue): EmacsValue {.emacsProc.} =
  ## This is a emacs symbol fetching test.
  ##
  ## If first argument is a symbol `test`, return something non-nil.
  emacsFunctions concat

  if ident == emSym"test":
    return concat(emLit"This is ",
                  emLit" emacs", emLit" function",
                  emLit" call test")
  else:
    return emSym("nil")

emacsModule:
  identTest.bindProcedure("nim-ident")
  provide("libtestModule")
