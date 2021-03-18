import config
import private/basetypes_helpers

type
  JlValue* = ptr jl_value
  JlModule* = ptr jl_module
  JlFunc* = ptr jl_func
  JlArray*[T] = ptr jl_array
  JlSym* = ptr jl_sym

type
  JlError* = object of IOError

{.push header: juliaHeader.}
var jlMainModule *{.importc: "jl_main_module".}: JlModule
var jlCoreModule *{.importc: "jl_core_module".}: JlModule
var jlBaseModule *{.importc: "jl_base_module".}: JlModule
var jlTopModule *{.importc: "jl_top_module".}: JlModule

# TODO : Handle interrupt exception for SIGINT Throw ?
# Currently, you need to define setControlCHook AFTER jlVmInit() or it won't take effect
var jl_interrupt_exception{.importc: "jl_interrupt_exception".}: JlValue

## Init & Exit function
proc jlVmInit*() {.nodecl, importc: "jl_init".}
proc jlVmExit*(exit_code: cint = 0.cint) {.nodecl, importc: "jl_atexit_hook".}
{.pop.}

proc jlExceptionHandler*() =
  let excpt : JlValue = jl_exception_occurred()
  if not isNil(excpt):
    let msg = $(jl_exception_message())
    raise newException(JlError, msg)
  else:
    discard

## Basic eval function
proc jlEval*(code: string): JlValue =
  result = jl_eval_string(code)
  jlExceptionHandler()

proc nimStringToJlVal*(v: string): JlValue =
  result = jlvalue_from_string(v)

proc jlValToString*(v: JlValue): string =
  result = jlvalue_to_string(v)

proc jlSym*(symname: string): JlSym =
  result = jl_symbol(symname.cstring)
