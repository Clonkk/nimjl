import arraymancer
import nimjl

proc main() =
  Julia.init() # Initialize Julia VM. This should be done once in the lifetime of your program.

  # Just be aware that Nim Seq/Tensor are Row Major.
  # Julia usually work in Column major.
  var tensor = randomTensor[float](2, 3, 10.0)

  # Uncomment this block if you haven't installed LinearAlgebra on Julia yet
  ##################################################
  # Install LinearAlgebra package
  # let evRes = jlEval("""using Pkg; Pkg.add("LinearAlgebra")""")
  # doAssert not isNil(evRes)
  ##################################################
  # Use the module
  jlUseModule("LinearAlgebra")

  block:
    # Julia Arrays starts at 1 even from Nim
    # Automatic conversions creates a copy of Tensor
    var res = Julia.permutedims(tensor, [2, 1]).toJlArray(float)
    jlGcRoot(res):
      # Check dimensions have changed
      echo typeof(res) # From Nim : JlArray[float64]
      echo jltypeof(res) # From Julia: Matrix{Float64}

      var tmp = res[1, 1]
      echo ">< ", tmp
      echo ">< ", jltypeof(tmp)
      echo ">< ", tmp.length()
      echo "----------------------"
      # You can index Julia Arrays from Nim
      res[1, 1] = 120.0
      echo res
      echo tensor
      echo res.shape()



  Julia.exit() # Exit Julia VM. This can be done only once in the lifetime of your program.

when isMainModule:
  main()
