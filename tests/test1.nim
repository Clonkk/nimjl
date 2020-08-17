import unittest
import nimjl
import sequtils
import arraymancer
import strformat

echo "init"
nimjl_init()

test "nim_eval_string":
  var test = nimjl_eval_string("sqrt(4.0)")
  check nimjl_unbox_float64(test) == 2.0

test "nimjl_box_unbox":
  block:
    var orig: float64 = 126545836.31266
    var x: nimjl_value = nimjl_box_float64(orig)
    check nimjl_unbox_float64(x) == orig

  block:
    var orig: float32 = 0.01561238536
    var x: nimjl_value = nimjl_box_float32(orig)
    check nimjl_unbox_float32(x) == orig

  block:
    var orig: int8 = -121
    var x: nimjl_value = nimjl_box_int8(orig)
    check nimjl_unbox_int8(x) == orig

  block:
    var orig: uint8 = 251
    var x: nimjl_value = nimjl_box_uint8(orig)
    check nimjl_unbox_uint8(x) == orig

test "jl_call1":
  var x: nimjl_value = nimjl_box_float64(4.0)
  var f = nimjl_get_function(jl_base_module, "sqrt");
  var res = nimjl_call1(f, x)
  check nimjl_unbox_float64(res) == 2.0
  check nimjl_unbox_float64(x) == 4.0

test "jl_array_1d":
  let ARRAY_LEN = 10
  var orig: seq[float64] = @[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]

  var array_type: nimjl_value = nimjl_apply_array_type_float64(1)
  var x = nimjl_alloc_array_1d(array_type, ARRAY_LEN.csize_t)

  nimjl_gc_push1(x.addr)
  var xData: ptr UncheckedArray[float64] = cast[ptr UncheckedArray[float64]](
      nimjl_array_data(x))
  check ARRAY_LEN == nimjl_array_len(x)

  for i in 0..<nimjl_array_len(x):
    xData[i] = i.float64

  var reverse = nimjl_get_function(jl_base_module, "reverse!")
  var res = nimjl_call(reverse, x.addr, 1)
  check not isNil(res)

  var resData = cast[ptr UncheckedArray[float64]](nimjl_array_data(x))
  check resData == xData

  for i in 0..<ARRAY_LEN:
    check xData[i] == orig[ARRAY_LEN - i - 1]
  nimjl_gc_pop()

test "jl_array_1d_own_buffer":
  let ARRAY_LEN = 10
  var orig: seq[float64] = @[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
  let unchecked_orig = cast[ptr UncheckedArray[float64]](orig[0].addr)

  var array_type: nimjl_value = nimjl_apply_array_type_float64(1)
  var x = nimjl_ptr_to_array_1d(array_type, unchecked_orig, ARRAY_LEN.csize_t, 0)
  check ARRAY_LEN == nimjl_array_len(x)

  for i in 0..<nimjl_array_len(x):
    unchecked_orig[i] = i.float64

  var reverse = nimjl_get_function(jl_base_module, "reverse!")
  var res = nimjl_call(reverse, x.addr, 1)
  check not isNil(res)

  var resData = cast[ptr UncheckedArray[float64]](nimjl_array_data(x))
  check resData == unchecked_orig

  for i in 0..<ARRAY_LEN:
    check unchecked_orig[i] == (ARRAY_LEN - i - 1).float

test "external_module":
  var res_eval_include = nimjl_eval_string("include(\"tests/test.jl\")")
  check not isNil(res_eval_include)

  var res_eval_using = nimjl_eval_string("using .custom_module")
  check not isNil(res_eval_using)

test "dummy":
  var dummy = nimjl_get_function(jl_main_module, "dummy")
  check not isNil(dummy)

  var ret: nimjl_value = nimjl_call0(dummy)
  check not isNil(ret)

test "external_module : squareMeBaby[Array]":
  var squareMeBaby = nimjl_get_function(jl_main_module, "squareMeBaby")
  check not isNil(squareMeBaby)

  var orig: seq[float64] = @[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
  let orig_ptr = cast[ptr UncheckedArray[float64]](orig[0].addr)
  var array_type: nimjl_value = nimjl_apply_array_type_float64(1)
  var xArray = nimjl_ptr_to_array_1d(array_type, orig_ptr, orig.len.csize_t, 0)
  var ret: nimjl_value = nimjl_call1(squareMeBaby, xArray)

  var len_ret = nimjl_array_len(ret)
  check len_ret == orig.len

  var rank_ret = nimjl_array_rank(ret)
  check rank_ret == 1

  var data_ret = nimjl_array_data(ret)
  let unchecked_array_data_ret = cast[ptr UncheckedArray[float64]](data_ret) 
  for i in 0..<orig.len:
    check unchecked_array_data_ret[i] == orig[i]*orig[i]

  var seqData: seq[float64] = newSeq[float64](len_ret)
  copyMem(seqData[0].unsafeAddr, data_ret, len_ret*sizeof(float64))
  check seqData == @[0.0, 1.0, 4.0, 9.0, 16.0, 25.0, 36.0, 49.0, 64.0, 81.0]
  check orig == @[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]

  # nimjl_gc_pop()

test "external_module : mutateMeByTen[Array]":
  var mutateMeByTen = nimjl_get_function(jl_main_module, "mutateMeByTen!")
  check not isNil(mutateMeByTen)

  var orig: seq[float64] = @[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
  let orig_ptr = cast[ptr UncheckedArray[float64]](orig[0].addr)
  var array_type: nimjl_value = nimjl_apply_array_type_float64(1)
  var xArray = nimjl_ptr_to_array_1d(array_type, orig_ptr, orig.len.csize_t, 0)
  var ret: nimjl_value = nimjl_call1(mutateMeByTen, xArray)
  check not isNil(ret)

  var len_ret = nimjl_array_len(xArray)
  check len_ret == orig.len

  var rank_ret = nimjl_array_rank(xArray)
  check rank_ret == 1

  var data_ret: nimjl_array = nimjl_array_data(xArray)
  var seqData: seq[float64] = newSeq[float64](len_ret)
  copyMem(seqData[0].unsafeAddr, data_ret, len_ret*sizeof(float64))
  check seqData == @[0.0, 10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0]
  check seqData == orig

test "external_module : rot180[2D_Array]":
  var printArray = nimjl_get_function(jl_main_module, "rot180")
  check not isNil(printArray)

  var orig: seq[float64] = @[0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0]
  let orig_ptr = cast[ptr UncheckedArray[float64]](orig[0].addr)

  var array_type: nimjl_value = nimjl_apply_array_type_float64(2)
  var xDims = nimjl_eval_string("(4, 3)")
  var xArray = nimjl_ptr_to_array(array_type, orig_ptr, xDims, 0)

  var d0 = nimjl_array_dim(xArray, 0).int
  var d1 = nimjl_array_dim(xArray, 1).int
  check d0 == 4
  check d1 == 3

  var ret: nimjl_value = nimjl_call1(printArray, xArray)
  check not isNil(ret)

  var origT = orig.toTensor.reshape(4, 3)
  echo origT

  var data_ret = nimjl_array_data(ret)
  var seqData: seq[float64] = newSeq[float64](12)
  copyMem(seqData[0].unsafeAddr, data_ret, 12*sizeof(float64))
  var seqDataT = seqData.toTensor.reshape(4, 3)
  echo seqDataT

# WIP TODO : MAKE IT WORK
# Maybe try 2d array first ?
test "external_module : squareMeBaby[Tensor]":
  var squareMeBaby = nimjl_get_function(jl_main_module, "rot180")
  # var squareMeBaby = nimjl_get_function(jl_main_module, "squareMeBaby")
  check not isNil(squareMeBaby)

  var orig: Tensor[float64] = ones[float64](3, 4, 5)
  var index = 0
  for i in orig.mitems:
    inc(index)
    i = index.float64 / 3.0

  var array_type: nimjl_value = nimjl_apply_array_type_float64(3)
  var xDims = nimjl_eval_string("(3, 4, 5)")
  var xTensor = nimjl_ptr_to_array(array_type, orig.get_data_ptr(), xDims, 0)

  block:
    var len_ret = nimjl_array_len(xTensor)
    check len_ret == orig.size

    var rank_ret = nimjl_array_rank(xTensor)
    check rank_ret == orig.rank

    var d0 = nimjl_array_dim(xTensor, 0).int
    var d1 = nimjl_array_dim(xTensor, 1).int
    var d2 = nimjl_array_dim(xTensor, 2).int
    check @[d0, d1, d2] == orig.shape.toSeq
    echo &"({d0}, {d1}, {d2})"

  # var ret: nimjl_value = nimjl_call(squareMeBaby, addr(xTensor), 1)
  var ret: nimjl_value = nimjl_call1(squareMeBaby, xTensor)
  echo &"ret> {ret.repr}"
  echo &"orig> {orig}"

  var len_ret = nimjl_array_len(ret)
  check len_ret == orig.size

  var rank_ret = nimjl_array_rank(ret)
  check rank_ret == 3

  var data_ret: nimjl_array = nimjl_array_data(ret)
  var tensorData: Tensor[float64] = newTensor[float64](3, 4, 5)
  echo &"dataRet> {data_ret.repr}"
  copyMem(tensorData.get_data_ptr(), data_ret, len_ret*sizeof(float64))
  echo &"tensorData> {tensorData}"
  # check tensorData == square(orig)

# test "external_module : mutateMeByTen[Tensor]":
#   var mutateMeByTen = nimjl_get_function(jl_main_module, "mutateMeByTen!")
#   check not isNil(mutateMeByTen)

#   var orig: Tensor[float64] = ones[float64](4, 6, 8)
#   var index = 0
#   for i in orig.mitems:
#     inc(index)
#     i = index.float64 / 3.0

#   var array_type: nimjl_value = nimjl_apply_array_type_float64(3)
#   var xDims = nimjl_eval_string("(4, 6, 8)")
#   var xTensor = nimjl_ptr_to_array(array_type, orig.get_data_ptr(), xDims, 0)

#   var ret: nimjl_value = nimjl_call1(mutateMeByTen, xTensor)
#   check not isNil(ret)

#   var len_ret = nimjl_array_len(xTensor)
#   check len_ret == orig.size

#   var rank_ret = nimjl_array_rank(xTensor)
#   check rank_ret == 3

#   var data_ret: nimjl_array = nimjl_array_data(xTensor)
#   var tensorData: Tensor[float64] = newTensor[float64](4, 6, 8)
#   copyMem(tensorData.get_data_ptr(), data_ret, len_ret*sizeof(float64))
#   check tensorData == orig*10

echo "exithook"
nimjl_atexit_hook(0)
