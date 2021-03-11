import config
import basetypes
import private/arrays_helpers
import private/basetypes_helpers

import typetraits
import arraymancer
import sequtils


proc toJlArray*[T](x: JlValue): JlArray[T] {.inline.} =
  result = cast[ptr jl_array](x)

proc toJlArray*(x: JlValue, T: typedesc): JlArray[T] {.inline.} =
  result = cast[ptr jl_array](x)

proc getRawData*[T](x: JlArray[T]): ptr UncheckedArray[T] {.inline.} =
  result = cast[ptr UncheckedArray[T]](jl_array_data(x))

proc len*[T](x: JlArray[T]): int =
  result = jl_array_len(x)

# Rank func takes value for some reason
proc ndims*[T](x: JlArray[T]): int =
  result = jl_array_rank(cast[JlValue](x))

proc dim*[T](x: JlArray[T], dim: int): int =
  result = jl_array_dim(x, dim.cint)

proc shape*[T](x: JlArray[T]): seq[int] =
  for i in 0..<x.ndims():
    result.add x.dim(i)

# Buffer with dims
proc jlArrayFromBuffer*[T](data: ptr UncheckedArray[T], dims: openArray[int]): JlArray[T] =
  ## Create an Array from existing buffer
  result = julia_make_array[T](data, dims)

# Seq/array mapped to 1D
proc jlArrayFromBuffer*[T](data: openArray[T]): JlArray[T] =
  ## Create an Array from existing buffer
  let uncheckedDataPtr = cast[ptr UncheckedArray[T]](data[0].unsafeAddr)
  result = jlArrayFromBuffer(uncheckedDataPtr, [data.len()])

proc jlArrayFromBuffer*[T](data: Tensor[T]): JlArray[T] =
  ## Create an Array from existing buffer
  let uncheckedDataPtr = data.unsafe_raw_offset().distinctBase()
  result = jlArrayFromBuffer(uncheckedDataPtr, data.shape.toSeq)

# Julia allocated array
proc allocJlArray*[T](dims: openArray[int]): JlArray[T] =
  ## Create a Julia Array managed by Julia GC
  result = julia_alloc_array[T](dims)

