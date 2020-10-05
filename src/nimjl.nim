import os
import arraymancer
import strutils
import strformat

# Const julia path
const C_nimjl = "c/nimjl.c"
const JULIA_PATH = getEnv("JULIA_PATH") & "/"
const JULIA_INCLUDES_PATH = JULIA_PATH & "include/julia"
const JULIA_LIB_PATH = JULIA_PATH & "lib/"
const JULIA_DEPLIB_PATH = JULIA_PATH & "lib/julia"

const JULIA_INCLUDE_FLAG = "-I"&JULIA_INCLUDES_PATH
const JULIA_LINK_FLAG = ["-Wl,-rpath," & JULIA_LIB_PATH, "-Wl,-rpath," &
    JULIA_DEPLIB_PATH, "-lm", "-ljulia"]

{.
    compile: C_nimjl,
    passc: JULIA_INCLUDE_FLAG,
    passL: JULIA_LINK_FLAG[0],
    passL: JULIA_LINK_FLAG[1],
    passL: JULIA_LINK_FLAG[2],
    passL: JULIA_LINK_FLAG[3]
.}
const jl_header = "julia.h"

##Types
type nimjl_value *{.importc: "jl_value_t", header: jl_header.} = object
type nimjl_array *{.importc: "jl_array_t", header: jl_header.} = object
type nimjl_func *{.importc: "jl_function_t", header: jl_header.} = object
type nimjl_module *{.importc: "jl_module_t", header: jl_header.} = object

var jl_main_module *{.importc: "jl_main_module",
        header: jl_header.}: ptr nimjl_module
var jl_core_module *{.importc: "jl_core_module",
        header: jl_header.}: ptr nimjl_module
var jl_base_module *{.importc: "jl_base_module",
        header: jl_header.}: ptr nimjl_module
var jl_top_module *{.importc: "jl_top_module",
        header: jl_header.}: ptr nimjl_module

## Basic function
proc nimjl_init*() {.cdecl, importc.}
proc nimjl_atexit_hook*(exit_code: cint) {.cdecl, importc.}
proc nimjl_eval_string*(code: cstring): ptr nimjl_value {.cdecl, importc.}

## Box & Unbox
proc nimjl_unbox_float64(value: ptr nimjl_value): float64 {.cdecl, importc.}
proc nimjl_unbox_float32(value: ptr nimjl_value): float32 {.cdecl, importc.}

proc nimjl_unbox_int64(value: ptr nimjl_value): int64 {.cdecl, importc.}
proc nimjl_unbox_int32(value: ptr nimjl_value): int32 {.cdecl, importc.}
proc nimjl_unbox_int16(value: ptr nimjl_value): int16 {.cdecl, importc.}
proc nimjl_unbox_int8(value: ptr nimjl_value): int8 {.cdecl, importc.}

proc nimjl_unbox_uint64(value: ptr nimjl_value): uint64 {.cdecl, importc.}
proc nimjl_unbox_uint32(value: ptr nimjl_value): uint32 {.cdecl, importc.}
proc nimjl_unbox_uint16(value: ptr nimjl_value): uint16 {.cdecl, importc.}
proc nimjl_unbox_uint8(value: ptr nimjl_value): uint8 {.cdecl, importc.}

proc nimjl_box_float64(value: float64): ptr nimjl_value {.cdecl, importc.}
proc nimjl_box_float32(value: float32): ptr nimjl_value {.cdecl, importc.}

proc nimjl_box_int64(value: int64): ptr nimjl_value {.cdecl, importc.}
proc nimjl_box_int32(value: int32): ptr nimjl_value {.cdecl, importc.}
proc nimjl_box_int16(value: int16): ptr nimjl_value {.cdecl, importc.}
proc nimjl_box_int8(value: int8): ptr nimjl_value {.cdecl, importc.}

proc nimjl_box_uint64(value: uint64): ptr nimjl_value {.cdecl, importc.}
proc nimjl_box_uint32(value: uint32): ptr nimjl_value {.cdecl, importc.}
proc nimjl_box_uint16(value: uint16): ptr nimjl_value {.cdecl, importc.}
proc nimjl_box_uint8(value: uint8): ptr nimjl_value {.cdecl, importc.}

proc nimjl_unbox*[T](value: ptr nimjl_value): T =
    when T is int8:
        result = nimjl_unbox_int8(value)
    elif T is int16:
        result = nimjl_unbox_int16(value)
    elif T is int32:
        result = nimjl_unbox_int32(value)
    elif T is int64:
        result = nimjl_unbox_int64(value)
    elif T is uint8:
        result = nimjl_unbox_uint8(value)
    elif T is uint16:
        result = nimjl_unbox_uint16(value)
    elif T is uint32:
        result = nimjl_unbox_uint32(value)
    elif T is uint64:
        result = nimjl_unbox_uint64(value)
    elif T is float32:
        result = nimjl_unbox_float32(value)
    elif T is float64:
        result = nimjl_unbox_float64(value)
    else:
        assert(false, "Type not supported")

proc nimjl_box*[T](value: T): ptr nimjl_value =
    when T is int8:
        result = nimjl_box_int8(value)
    elif T is int16:
        result = nimjl_box_int16(value)
    elif T is int32:
        result = nimjl_box_int32(value)
    elif T is int64:
        result = nimjl_box_int64(value)
    elif T is uint8:
        result = nimjl_box_uint8(value)
    elif T is uint16:
        result = nimjl_box_uint16(value)
    elif T is uint32:
        result = nimjl_box_uint32(value)
    elif T is uint64:
        result = nimjl_box_uint64(value)
    elif T is float32:
        result = nimjl_box_float32(value)
    elif T is float64:
        result = nimjl_box_float64(value)
    else:
        assert(false, "Type not supported")

##GC Functions

proc nimjl_gc_push1*(a: pointer) {.cdecl, importc.}

proc nimjl_gc_push2*(a: pointer, b: pointer) {.cdecl, importc.}

proc nimjl_gc_push3*(a: pointer, b: pointer, c: pointer) {.cdecl, importc.}

proc nimjl_gc_push4*(a: pointer, b: pointer, c: pointer, d: pointer) {.cdecl, importc.}

proc nimjl_gc_push5*(a: pointer, b: pointer, c: pointer, d: pointer,
        e: pointer) {.cdecl, importc.}

proc nimjl_gc_push6*(a: pointer, b: pointer, c: pointer, d: pointer, e: pointer,
        f: pointer) {.cdecl, importc.}

proc nimjl_gc_pushargs*(a: pointer, n: csize_t) {.cdecl, importc.}

proc nimjl_gc_pop*() {.cdecl, importc.}

proc nimjl_exception_occurred*(): ptr nimjl_value {.cdecl, importc.}

proc nimjl_typeof_str*(v: ptr nimjl_value): cstring {.cdecl, importc.}

proc nimjl_string_ptr*(v: ptr nimjl_value): cstring {.cdecl, importc.}

## Call functions
proc nimjl_get_function*(module: ptr nimjl_module,
        name: cstring): ptr nimjl_func {.cdecl, importc.}

proc nimjl_call *(function: ptr nimjl_func, values: ptr ptr nimjl_value,
        nargs: cint): ptr nimjl_value {.cdecl, importc.}

proc nimjl_call0*(function: ptr nimjl_func): ptr nimjl_value {.cdecl, importc.}

proc nimjl_call1*(function: ptr nimjl_func,
        arg: ptr nimjl_value): ptr nimjl_value {.cdecl, importc.}

proc nimjl_call2*(function: ptr nimjl_func, arg1: ptr nimjl_value,
        arg2: ptr nimjl_value): ptr nimjl_value {.cdecl, importc.}

proc nimjl_call3*(function: ptr nimjl_func, arg1: ptr nimjl_value,
        arg2: ptr nimjl_value, arg3: ptr nimjl_value): ptr nimjl_value {.cdecl, importc.}

## Check for nil result
proc nimjl_include_file*(file_name: string): ptr nimjl_value =
    result = nimjl_eval_string(&"include(\"{file_name}\")")

proc nimjl_using_module*(module_name: string): ptr nimjl_value =
    result = nimjl_eval_string(&"using {module_name}")

proc nimjl_get_module*(module_name: string): ptr nimjl_module =
    result = cast[ptr nimjl_module](nimjl_eval_string(module_name))

proc nimjl_exec_func*(module: ptr nimjl_module, func_name: string, va: varargs[
        ptr nimjl_value]): ptr nimjl_value =
    let f = nimjl_get_function(module, func_name)
    if va.len == 0:
        result = nimjl_call0(f)
    else:
        result = nimjl_call(f, unsafeAddr(va[0]), va.len.cint)

proc nimjl_exec_func*(func_name: string, va: varargs[
        ptr nimjl_value]): ptr nimjl_value =
    let f = nimjl_get_function(jl_main_module, func_name)
    result = nil
    if va.len == 0:
        result = nimjl_call0(f)
    elif va.len == 1:
        result = nimjl_call1(f, va[0])
    elif va.len == 2:
        result = nimjl_call2(f, va[0], va[1])
    elif va.len == 3:
        result = nimjl_call3(f, va[0], va[1], va[2])
    else:
        result = nimjl_call(f, unsafeAddr(va[0]), va.len.cint)

## Array
# Values will need to be cast from nimjl_value to nimjl_array back and forth
proc nimjl_array_data*(values: ptr nimjl_array): pointer {.cdecl, importc.}

proc nimjl_array_dim*(a: ptr nimjl_array, dim: cint): cint {.cdecl, importc.}

proc nimjl_array_len*(a: ptr nimjl_array): cint {.cdecl, importc.}

proc nimjl_array_rank*(a: ptr nimjl_array): cint {.cdecl, importc.}

proc nimjl_new_array*(atype: ptr nimjl_value,
        dims: ptr nimjl_value): ptr nimjl_array {.cdecl, importc.}

proc nimjl_reshape_array*(atype: ptr nimjl_value, data: ptr nimjl_array,
    dims: ptr nimjl_value): ptr nimjl_array {.cdecl, importc.}

proc nimjl_ptr_to_array_1d*(atype: ptr nimjl_value, data: pointer, nel: csize_t,
    own_buffer: cint): ptr nimjl_array {.cdecl, importc.}

proc nimjl_ptr_to_array*(atype: ptr nimjl_value, data: pointer,
        dims: ptr nimjl_value,
    own_buffer: cint): ptr nimjl_array {.cdecl, importc.}

proc nimjl_alloc_array_1d*(atype: ptr nimjl_value,
        nr: csize_t): ptr nimjl_array {.cdecl, importc.}

proc nimjl_alloc_array_2d*(atype: ptr nimjl_value, nr: csize_t,
    nc: csize_t): ptr nimjl_array {.cdecl, importc.}

proc nimjl_alloc_array_3d*(atype: ptr nimjl_value, nr: csize_t, nc: csize_t,
    z: csize_t): ptr nimjl_array {.cdecl, importc.}

##  Array type

proc nimjl_apply_array_type_int8(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_int16(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_int32(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_int64(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_uint8(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_uint16(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_uint32(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_uint64(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_float32(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_float64(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_bool(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type_char(dim: csize_t): ptr nimjl_value {.cdecl, importc.}

proc nimjl_apply_array_type*[T](dim: int): ptr nimjl_value =
    when T is int8:
        result = nimjl_apply_array_type_int8(dim.csize_t)
    elif T is int16:
        result = nimjl_apply_array_type_int16(dim.csize_t)
    elif T is int32:
        result = nimjl_apply_array_type_int32(dim.csize_t)
    elif T is int64:
        result = nimjl_apply_array_type_int64(dim.csize_t)
    elif T is uint8:
        result = nimjl_apply_array_type_uint8(dim.csize_t)
    elif T is uint16:
        result = nimjl_apply_array_type_uint16(dim.csize_t)
    elif T is uint32:
        result = nimjl_apply_array_type_uint32(dim.csize_t)
    elif T is uint64:
        result = nimjl_apply_array_type_uint64(dim.csize_t)
    elif T is float32:
        result = nimjl_apply_array_type_float32(dim.csize_t)
    elif T is float64:
        result = nimjl_apply_array_type_float64(dim.csize_t)
    elif T is bool:
        result = nimjl_apply_array_type_bool(dim.csize_t)
    elif T is char:
        result = nimjl_apply_array_type_char(dim.csize_t)
    else:
        assert(false, "Type not supported")

proc nimjl_make_array*[T](data: ptr UncheckedArray[T], dims: seq[
        int]): ptr nimjl_array =
    var array_type: ptr nimjl_value = nimjl_apply_array_type[T](dims.len)
    var dimStr = "("
    for d in dims:
        dimStr = dimStr & $d
        if d != dims[^1]:
            dimStr = dimStr & ","
    dimStr = dimStr & ")"
    var xDims = nimjl_eval_string(dimStr)
    nimjl_gc_push1(xDims.addr)
    result = nimjl_ptr_to_array(array_type, data, xDims, 0)
    nimjl_gc_pop()

proc nimjl_make_array*[T](data: ref Tensor[T]): ptr nimjl_array =
    var array_type: ptr nimjl_value = nimjl_apply_array_type[T](data[].rank)
    var dimStr = $(data[].shape)
    dimStr = dimStr.replace("[", "(")
    dimStr = dimStr.replace("]", ")")
    var xDims = nimjl_eval_string(dimStr)
    nimjl_gc_push1(xDims.addr)
    result = nimjl_ptr_to_array(array_type, data[].dataArray(), xDims, 0)
    nimjl_gc_pop()

proc nimjl_make_tuple*(v: tuple): ptr nimjl_value =
    var tupleStr = $v
    tupleStr = tupleStr.replace(":", "=")
    # This make tuple of a single element valid
    # (1) won't create a valid tuple -> (1,) is a valid tuple
    tupleStr = tupleStr.replace(")", ",)")
    result = nimjl_eval_string(tupleStr)

proc nimjl_make_tuple*(v: object): ptr nimjl_value =
    var tupleStr = $v
    tupleStr = tupleStr.replace(":", "=")
    # This make tuple of a single element valid
    # (1) won't create a valid tuple -> (1,) is a valid tuple
    tupleStr = tupleStr.replace(")", ",)")
    result = nimjl_eval_string(tupleStr)
