import argparse

proc main() =
  let parser = newParser:
    option("-t", "--type")
  let opts = parser.parse(@["--type", "foo"])
  echo opts.`type`

main()
