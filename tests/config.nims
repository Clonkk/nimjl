switch("path", "$projectDir/..")
when defined(valgrind):
  switch("stacktrace", "on")
  switch("debugger", "native")
  switch("gc", "arc")
  switch("define", "useMalloc")

when defined(msan):
  switch("gc", "arc")
  switch("cc", "clang")
  switch("stacktrace", "on")
  switch("debugger", "native")
  switch("define", "useMalloc")
  switch("passC", "-fsanitize=memory")
  switch("passL", "-fsanitize=memory")
  switch("passC", "-fsanitize-memory-track-origins=2")
  switch("passL", "-fsanitize-memory-track-origins=2")
  switch("passC", "-fsanitize-recover=memory")
  switch("passL", "-fsanitize-recover=memory")
