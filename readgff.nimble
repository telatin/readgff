# Package

version       = "0.1.0"
author        = "telatin"
description   = "A Nim library to parse GFF files"
license       = "MIT"
srcDir        = "src"

bin           = @["demos/gffStats", "demos/gffSelect"]

# Dependencies

requires "nim >= 1.6.0", "argparse"
