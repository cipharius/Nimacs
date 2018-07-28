import macros
import nimacs.emacsModule
export nimacs.emacsModule

# Make sure module complies with GNU Emacs license
when defined(acceptGPL):
  var plugin_is_GPL_compatible {.exportc.} = true
else:
  {.warning: "GNU Emacs dynamic modules requires GPL or other compatible license. To accept, compile with -d:acceptGPL flag".}

## Used to mark emacs procedure argument count
template argCount*(count: int) {.pragma.}

template toCArray*(arr: openArray[EmacsValue]): untyped =
  cast[ptr EmacsValueArray](unsafeaddr(arr))[]

macro `->`*(obj: untyped, funcall: untyped): untyped =
  ## Emacs-module method call
  let funIdent = funcall[0]
  funcall[0] = newNimNode(nnkDotExpr).add(obj, funIdent)
  funcall.insert(1, obj)
  return funcall

proc call*(emacs: EmacsEnv, fun: EmacsValue, args: varargs[EmacsValue]): EmacsValue =
  emacs->funcall(fun, args.len, args.toCArray)

template call*(fun: EmacsValue, args: varargs[EmacsValue]): EmacsValue =
  mixin emacs
  emacs.call(fun, args)

macro bindProcedure*(procSym: EmacsFunction, name: string): typed =
  ## Bind procedure as emacs function
  let procedure = procSym.symbol.getImpl()
  var doc: string
  var argCount = newLit(0)
  var procBody: NimNode

  for pragma in procedure.pragma:
    if pragma[0].eqIdent "argCount":
      argCount = pragma[1]
      break

  if procedure.body[0].kind == nnkStmtList:
    procBody = procedure.body[1]
  else:
    procBody = procedure.body

  if procBody[0].kind == nnkCommentStmt:
    doc = procBody[0].strVal
  else:
    doc = "This procedure has no documentation"

  let docLit = doc.newLit

  result = quote:
    var args = [
      emSym(`name`),
      emacs->makeFunction(`argCount`, `argCount`, cast[ptr EmacsFunction](`procSym`), `docLit`, nil)
    ]
    discard emacs->funcall(emSym("fset"), 2, args.toCArray)

template provide*(feature: string): typed =
  mixin emacs
  let provideFunc = emSym("provide")
  var funcallArgs = [emSym(feature)]
  discard emacs->funcall(provideFunc, 1, funcallArgs.toCArray)

macro emacsModule*(body: untyped): untyped =
  ## Emacs module entry point
  ##
  ## This macro automatically defines variable
  ## `emacs`, which is used to interact with emacs.
  let procName = newIdentNode "emacs_module_init"
  let procArgs = [
    newIdentNode "cint",
    nnkIdentDefs.newTree(
      newIdentNode "runtime",
      nnkPtrTy.newTree(
        newIdentNode "EmacsRuntime"
      ),
      newEmptyNode()
    )
  ]
  let procBody = nnkStmtList.newTree(
    nnkLetSection.newTree(
      nnkIdentDefs.newTree(
        newIdentNode "emacs",
        newEmptyNode(),
        nnkInfix.newTree(
          newIdentNode "->",
          newIdentNode "runtime",
          nnkCall.newTree(
            newIdentNode "getEnvironment"
          )
        )
      )
    ),
    body
  )
  result = newProc(procName, procArgs, procBody)
  result.pragma = nnkPragma.newTree(newIdentNode "exportc")

macro emacsProc*(procedure: untyped): typed =
  ## Convert proecedure into emacs compatible function
  let params = procedure.params
  var letStmt = nnkLetSection.newTree()

  # procedure.params[0] = newIdentNode("EmacsValue")

  if procedure.body[0].kind == nnkCommentStmt:
    procedure.body.insert(1, letStmt)
  else:
    procedure.body.insert(0, letStmt)

  for i in 1..<params.len:
    let
      node = params[i]
      ident = node[0]
      typeSym = node[1]
      curArg = nnkBracketExpr.newTree(newIdentNode "args", newLit(i-1))

    case $typeSym
    of "EmacsValue":
      letStmt.add(newIdentDefs(ident, typeSym, curArg))
    of "int":
      letStmt.add(newIdentDefs(
        ident, typeSym,
        nnkCall.newTree(
          newIdentNode "getInt", newIdentNode "emacs", curArg)))
    of "string":
      letStmt.add(
        newIdentDefs(
          ident, typeSym,
          nnkCall.newTree(newIdentNode "getString", newIdentNode "emacs", curArg)))
    else:
      error("Unhandled type")

  # Save old argument count
  procedure.addPragma(
    nnkExprColonExpr.newTree(newIdentNode "argCount", newLit(params.len - 1))
  )

  # Add new params
  params.del(1, params.len-1)
  params.add(
    newIdentDefs(newIdentNode "emacs", newIdentNode "EmacsEnv"),
    newIdentDefs(newIdentNode "nargs", newIdentNode "cint"),
    newIdentDefs(newIdentNode "args", newIdentNode "EmacsValueArray"),
    newIdentDefs(newIdentNode "data", newIdentNode "pointer")
  )

  return procedure

# macro emacsFunctions*(funcs: varargs[string]): untyped =
#   result = nnkLetSection.newNimNode()

#   for f in funcs:
#     echo f.repr
#     result.add(newIdentDefs(
#       f,
#       nil,
#       newPar(
#         newProc(
#           params: newIdentDefs(
#             newIdentNode "args",
#             [
#               newIdentNode "EmacsValue",
#               nnkBracketExpr.newTree(newIdentNode "varargs", newIdentNode "string")
#             ]
#           ),
#           body: newStmtList(
#             newCall(newIdentNode "call", newIdentNode "args")
#           ),
#           procType: nnkLambda
#         )
#       )
#     ))


template emSym*(symbolName: cstring): EmacsValue =
  mixin emacs
  emacs->intern(symbolName)

template emLit*(value: int): EmacsValue =
  mixin emacs
  emacs->makeInteger(cint(value))

template emLit*(value: string): EmacsValue =
  mixin emacs
  emacs->makeString(cstring(value), value.len)

template toInt*(eValue: EmacsValue): int =
  mixin emacs
  emacs->extractInteger(eValue)

proc toString*(emacs: EmacsEnv, eValue: EmacsValue): string =
  ## Retreive string from emacs value
  var strLen = 0
  if emacs->copyStringContents(eValue, nil, addr(strLen)):
    var memPtr: pointer = alloc(strLen)
    defer: memPtr.dealloc()
    discard emacs->copyStringContents(eValue, memPtr, strLen.addr)
    return $cast[cstring](memPtr)

template toString*(eValue: EmacsValue): string =
  mixin emacs
  emacs.toString(eValue)
