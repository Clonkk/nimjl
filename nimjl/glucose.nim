# This file is named glucose because it gives you sugar ;)
# It contains most syntactic sugar to ease using Julia inside Nim
import ./types
import ./cores
import ./functions
import ./conversions

import ./private/jlcores

type Julia* = object

proc init*(jl: type Julia) =
  jlVmInit()

proc exit*(jl: type Julia, exitcode: int = 0) =
  jlVmExit(exitcode.cint)

# macro loadModule*(jl: type Julia, modname: untyped) =
# TODO generate a proc ``modname`` that returns module

#####################################################
# Interop and utility
#####################################################
proc `$`*(val: JlValue): string =
  jlCall("string", val).to(string)

proc `$`*(val: JlModule): string =
  jlCall("string", val).to(string)

proc `$`*[T](val: JlArray[T]): string =
  jlCall("string", val).to(string)

proc `$`*(val: JlFunc): string =
  jlCall("string", val).to(string)

proc `$`*(val: JlSym): string =
  jlCall("string", val).to(string)

# typeof is taken by Nim already
proc jltypeof*(x: JlValue): JlValue =
  jlCall("typeof", x)

proc len*(val: JlValue): int =
  jlCall("length", val).to(int)

proc firstindex*(val: JlValue): int =
  jlCall("firstindex", val).to(int)

proc lastindex*(val: JlValue): int =
  jlCall("lastindex", val).to(int)

template getindex*(val: JlValue, idx: varargs[untyped]): JlValue =
  jlCall("getindex", val, idx)

template getproperty*(val: JlValue, propertyname: untyped): JlValue =
  jlCall("getproperty", val, jlSym(astToStr(propertyname)))

template setindex*(val: JlValue, newval: untyped, idx: varargs[untyped]) =
  discard jlCall("setindex!", val, newval, idx)

template setproperty*(val: JlValue, propertyname: untyped, newval: untyped) =
  discard jlCall("setproperty!", val, jlSym(astToStr(propertyname)), newval)

#####################################################
# Syntactic sugar
#####################################################
template `.()`*(jl: type Julia, funcname: untyped, args: varargs[JlValue, toJlVal]): untyped =
  jlCall(astToStr(funcname), args)

template `.()`*(jlmod: JlModule, funcname: untyped, args: varargs[JlValue, toJlVal]): untyped =
  jlCall(jlmod, astToStr(funcname), args)

template `.()`*(jlval: JlValue, funcname: untyped, args: varargs[JlValue, toJlVal]): untyped =
  jlCall(astToStr(funcname), jlval, args)

template `.`*(jlval: JlValue, propertyname: untyped): JlValue =
  getproperty(jlval, propertyname)

template `.=`*(jlval: var JlValue, fieldname: untyped, newval: untyped) =
  setproperty(jlval, fieldname, newval)

# Re-export
import ./sugar/iterators
export iterators

import ./sugar/operators
export operators

import ./sugar/valindexing
export valindexing
