import ../private/jlcores
import ../types
import ../arrays

import ./unbox

import std/json
import std/tables
import arraymancer

{.push inline.}

# POD types
## Julia -> Nim
proc toNimVal[T: SomeNumber|bool|pointer](x: JlValue, res: var T) =
  res = jlUnbox[T](x)

proc toNimVal(x: JlValue, res: var string) =
  res = jlvalue_to_string(x)

# Julia Tuple / Dict can't really be mapped to Nim's type so returning JsonNode is easier.
# It introduces a "distinction" between to[T] -> T and to[T] -> JsonNode as return types
# Forward declare for cyclic import
proc toNimVal(x: JlValue, t: var object)
proc toNimVal(x: JlValue, t: var tuple)
proc toNimVal[U, V](x: JlValue, tab: var Table[U, V])

# Array, Seq, Tensor
proc toNimVal[T](x: JlArray[T], tensor: var Tensor[T]) =
  # This is possible but relies on keep Julia's memory intact
  # I believe a copyMem is cleaner and safer
  # tensor = fromBuffer(x, x.shape)
  # Version that doesn't rely on keepin Jl array alive
  if x.ndims > 6:
    raise newException(JlError, "Tensor only support up to 6 dimensions")
  tensor = newTensor[T](x.shape)
  if x.len > 0:
    # Can create a view as well
    let tmp = fromBuffer[T](x.getRawData(), x.shape())
    tensor = tmp.clone()
    # let nbytes: int = x.len()*sizeof(T) div sizeof(byte)
    # copyMem(tensor.get_offset_ptr(), x.getRawData(), nbytes)

proc toNimVal[T](x: JlArray[T], locseq: var seq[T]) =
  if x.ndims > 1:
    raise newException(JlError, "Can only convert 1D Julia Array to Nim seq")
  let nbytes: int = x.len()*sizeof(T) div sizeof(byte)
  locseq.setLen(x.len())
  if x.len() > 0:
    copyMem(unsafeAddr(locseq[0]), x.getRawData(), nbytes)

proc toNimVal[I, T](x: JlArray[T], locarr: var array[I, T]) =
  if x.ndims > 1:
    raise newException(JlError, "Can only convert 1D Julia Array to Nim seq")
  let nbytes: int = x.len()*sizeof(T) div sizeof(byte)
  if x.len() > 0:
    copyMem(unsafeAddr(locarr[0]), x.rawData(), nbytes)

proc toNimVal[T](x: JlValue, tensor: var Tensor[T]) =
  let x = toJlArray[T](x)
  toNimVal(x, tensor)

proc toNimVal[T](x: JlValue, locseq: var seq[T]) =
  let x = toJlArray[T](x)
  toNimVal(x, locseq)

proc toNimVal[I, T](x: JlValue, locarr: var array[I, T]) =
  let x = toJlArray[T](x)
  toNimVal(x, locarr)

proc toNimVal(x: JlValue, jltype: var JlDataType) =
  jltype = cast[JlDataType](x)

proc toNimVal(x: JlValue, jlmod: var JlModule) =
  jlmod = cast[JlModule](x)

proc toNimVal(x: JlValue, jlfunc: var JlFunc) =
  jlfunc = cast[JlFunc](x)

{.pop.}

# Public API
proc to*[U](x: JlArray[U], T: typedesc): T =
  when T is void:
    discard
  else:
    toNimVal(x, result)

proc to*(x: JlValue, T: typedesc): T =
  ## Copy a JlValue into a Nim type
  when T is void:
    discard
  else:
    toNimVal(x, result)

# Recursive import strategy
import ./dict_tuples
import ./obj_structs

proc toNimVal(x: JlValue, t: var object) =
  jlStructToNim(x, t)

proc toNimVal(x: JlValue, t: var tuple) =
  jlTupleToNim(x, t)

proc toNimVal[U, V](x: JlValue, tab: var Table[U, V]) =
  jlDictToNim[U, V](x, tab)
