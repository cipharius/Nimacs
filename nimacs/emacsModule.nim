type
  EmacsValue* = ptr object
  EmacsValueArray* = UncheckedArray[EmacsValue]
  EmacsFuncallExit* = enum
    EmacsFuncallExitReturn,
    emacsFuncallExitSignal,
    emacsFuncallThrow
  EmacsFunction* = proc(env: EmacsEnv, nargs: cint, args: EmacsValueArray,
                        data: pointer): EmacsValue
  EmacsRuntime* {.importc: "struct emacs_runtime", header: "<emacs-module.h>".} = object
    get_environment*: proc(ert: ptr EmacsRuntime): EmacsEnv {.nimcall.}

  EmacsEnv* = ptr EmacsEnvObj
  EmacsEnvObj* {.importc: "emacs_env", header: "<emacs-module.h>".} = object
    make_global_ref*: proc(env: EmacsEnv, anyReference: EmacsValue): EmacsValue {.nimcall.}
    free_global_ref*: proc(env: EmacsEnv, globalReference: EmacsValue) {.nimcall.}
    non_local_exit_check*: proc(env: EmacsEnv): EmacsFuncallExit {.nimcall.}
    non_local_exit_clear*: proc(env: EmacsEnv) {.nimcall.}
    non_local_exit_get*: proc(env: EmacsEnv, nonLocalExitSymbolOut: ptr EmacsValue,
                               nonLocalExitDataOut: ptr EmacsValue): EmacsFuncallExit {.nimcall.}
    non_local_exit_signal*: proc(env: EmacsEnv, nonLocalExitSymbol: EmacsValue,
                                  nonLocalExitData: EmacsValue) {.nimcall.}
    non_local_exit_throw*: proc(env: EmacsEnv, tag: EmacsValue, value: EmacsValue) {.nimcall.}
    make_function*: proc(env: EmacsEnv, min_arity, max_arity: cint, function: ptr EmacsFunction,
                         documentation: cstring, data: pointer): EmacsValue {.nimcall.}
    funcall*: proc(env: EmacsEnv, function: EmacsValue, nargs: clong,
                   args: EmacsValueArray): EmacsValue {.nimcall.}
    intern*: proc(env: EmacsEnv, symbol_name: cstring): EmacsValue {.nimcall.}
    type_of*: proc(env: EmacsEnv, value: EmacsValue): EmacsValue {.nimcall.}
    is_not_nil*: proc(env: EmacsEnv; value: EmacsValue): bool {.nimcall.}
    eq*: proc(env: EmacsEnv; a: EmacsValue; b: EmacsValue): bool {.nimcall.}
    extract_integer*: proc(env: EmacsEnv, value: EmacsValue): cint {.nimcall.}
    make_integer*: proc(env: EmacsEnv, value: cint): EmacsValue {.nimcall.}
    extract_float*: proc(env: EmacsEnv; value: EmacsValue): cdouble {.nimcall.}
    make_float*: proc(env: EmacsEnv; value: cdouble): EmacsValue
    copy_string_contents*: proc(env: EmacsEnv, value: EmacsValue, buffer: pointer,
                              size: ptr clong): bool {.nimcall.}
    make_string*: proc(env: EmacsEnv, contents: cstring, length: clong): EmacsValue {.nimcall.}
    make_user_ptr*: proc(env: EmacsEnv, fin: proc(arg: pointer), uptr: pointer): EmacsValue {.nimcall.}
    get_user_ptr*: proc(env: EmacsEnv; uptr: EmacsValue): pointer {.nimcall.}
    set_user_ptr*: proc(env: EmacsEnv; uptr: EmacsValue; newptr: pointer) {.nimcall.}
    get_user_finalizer*: proc(env: EmacsEnv, uptr: EmacsValue): pointer {.nimcall.}
    set_user_finalizer*: proc(env: EmacsEnv, uptr: EmacsValue, fin: proc(arg: pointer)) {.nimcall.}
    vec_get*: proc(env: EmacsEnv, vec: EmacsValue, i: clong): EmacsValue {.nimcall.}
    vec_set*: proc(env: EmacsEnv, vec: EmacsValue, i: clong, val: EmacsValue) {.nimcall.}
    vec_size*: proc(env: EmacsEnv, vec: EmacsValue): clong {.nimcall.}
    should_quit*: proc(env: EmacsEnv): bool
