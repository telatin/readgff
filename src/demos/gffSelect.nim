import argparse
import os
import strformat
import strutils

import ../readgff

proc intervalLength(startPos, endPos: int): int =
  ## Calculate the length of a GFF interval (inclusive coordinates).
  return max(0, endPos - startPos + 1)

proc parseOptionalInt(value: string; optionName: string): tuple[enabled: bool, number: int] =
  ## Parse an optional integer value passed via the CLI.
  if value.len == 0:
    return (enabled: false, number: 0)
  try:
    return (enabled: true, number: parseInt(value))
  except ValueError:
    raise newException(ValueError, fmt"Invalid value '{value}' supplied for {optionName}.")

proc main() =
  let parser = newParser("gffSelect"):
    help("Filter records from a GFF file.")
    option("-t", "--type", help="Only keep records with the specified feature type.")
    option("-m", "--min-len", help="Minimum allowed length for a record.")
    option("-x", "--max-len", help="Maximum allowed length for a record.")
    option("-c", "--contig", help="Only keep records from this contig (seqid).")
    arg("gff", help="Input GFF file to filter.")

  try:
    let opts = parser.parse(commandLineParams())
    let filename = opts.gff
    let featureType = opts.`type`
    let contig = opts.contig
    let minConf = parseOptionalInt(opts.min_len, "--min-len")
    let maxConf = parseOptionalInt(opts.max_len, "--max-len")

    for record in readGff(filename):
      if featureType.len > 0 and record.featureType != featureType:
        continue
      if contig.len > 0 and record.seqid != contig:
        continue

      let length = intervalLength(record.start, record.stop)
      if minConf.enabled and length < minConf.number:
        continue
      if maxConf.enabled and length > maxConf.number:
        continue

      echo $record
  except ShortCircuit as exc:
    if exc.flag == "argparse_help":
      echo parser.help
      return
    else:
      raise
  except UsageError as exc:
    stderr.writeLine(exc.msg)
    stderr.writeLine(parser.help)
    quit(1)

when isMainModule:
  main()
