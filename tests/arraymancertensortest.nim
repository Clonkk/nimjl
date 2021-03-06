import std/unittest
import std/sequtils
import std/options
import std/sugar

import arraymancer
import nimjl

### Tensor Args
proc tensorSquareMeBaby() =
  let dims = [18, 21, 33]
  var
    orig: Tensor[float64] = ones[float64](dims)
    index = 0
  for i in orig.mitems:
    i = index.float64 / 3.0
    inc(index)

  var xTensor = jlArrayFromBuffer[float64](orig)

  block:
    var
      len_ret = len(xTensor)
      rank_ret = ndims(xTensor)
    check len_ret == orig.size
    check rank_ret == orig.rank

    var
      d0 = dim(xTensor, 0)
      d1 = dim(xTensor, 1)
      d2 = dim(xTensor, 2)
    check @[d0, d1, d2] == orig.shape.toSeq

  var
    ret = toJlArray[float64](Julia.squareMeBaby(xTensor))
    len_ret = len(ret)
    rank_ret = ndims(ret)

  check len_ret == orig.size
  check rank_ret == 3

  var tensorData = ret.to(Tensor[float])
  check tensorData == square(orig)

proc tensorMutateMeBaby() =
  let dims = [14, 12, 10]

  var
    orig: Tensor[float64] = ones[float64](dims)
    index = 0
  for i in orig.mitems:
    inc(index)
    i = index.float64 / 3.0

  # Create a deepcopy immutable with the expected result
  let tensorcmp = orig.map(x => x*10)

  var
    # ! is a special character in Nim but not in Julia so backticks are necessary
    ret = toJlArray[float](Julia.`mutateMeByTen!`(orig))
    len_ret = len(ret)
    rank_ret = ndims(ret)

  check not isNil(ret)
  check len_ret == orig.size
  check rank_ret == 3

  # Check result is correct
  check orig == tensorcmp

proc tensorBuiltinRot180() =
  var
    orig_tensor = newTensor[float64](4, 3)
    index = 0

  for i in orig_tensor.mitems:
    i = index.float64
    inc(index)

  var
    xArray = jlArrayFromBuffer[float64](orig_tensor)
    d0 = dim(xArray, 0).int
    d1 = dim(xArray, 1).int

  check d0 == orig_tensor.shape[0]
  check d1 == orig_tensor.shape[1]

  var ret = toJlArray[float64](Julia.rot180(xArray))
  check not isNil(ret)

  var tensorResData = ret.to(Tensor[float64])
  orig_tensor.apply_inline: 11.0 - x
  check tensorResData == orig_tensor

proc runTensorArgsTest*() =
  suite "Tensor":
    teardown: jlGcCollect()

    test "squareMeBaby[Tensor]":
      tensorSquareMeBaby()

    test "mutateMeByTen[Tensor]":
      tensorMutateMeBaby()

    test "rot180[Tensor]":
      tensorBuiltinRot180()

when isMainModule:
  import ./testfull
  Julia.init()
  runExternalsTest()
  runTensorArgsTest()
  Julia.exit()
