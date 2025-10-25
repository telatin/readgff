import argparse

proc main() =
  let parser = newParser("demo"):
    arg("file")
  type OptType = type(parser.parse(@["foo"]))
  var opts: OptType
  discard opts

main()
