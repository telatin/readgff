import argparse
import os
import tables
import sequtils
import algorithm
import strformat

import ../readgff

type
  TypeStats = tuple
    count: int
    bases: int

proc intervalLength(startPos, endPos: int): int =
  ## Calculate the length of a GFF interval (inclusive coordinates).
  return max(0, endPos - startPos + 1)

proc uniqueCoverage(intervals: seq[(int, int)]): int =
  ## Calculate the number of unique bases covered by the given intervals.
  if intervals.len == 0:
    return 0

  var sortedIntervals = intervals
  sortedIntervals.sort(proc (a, b: (int, int)): int = cmp(a[0], b[0]))

  var currentStart = sortedIntervals[0][0]
  var currentEnd = sortedIntervals[0][1]
  var total = 0

  for i in 1 ..< sortedIntervals.len:
    let startPos = sortedIntervals[i][0]
    let endPos = sortedIntervals[i][1]

    if startPos <= currentEnd + 1:
      if endPos > currentEnd:
        currentEnd = endPos
    else:
      total += intervalLength(currentStart, currentEnd)
      currentStart = startPos
      currentEnd = endPos

  total += intervalLength(currentStart, currentEnd)
  return total

proc main() =
  let parser = newParser("gffStats"):
    help("Compute basic statistics from a GFF file.")
    arg("gff", help="Input GFF file to analyse.")

  let opts = parser.parse(commandLineParams())
  let filename = opts.gff

  var totalRecords = 0
  var totalBases = 0
  var uniqueBySeqid = initTable[string, seq[(int, int)]]()
  var statsByType = initTable[string, TypeStats]()

  for record in readGff(filename):
    let length = intervalLength(record.start, record.stop)
    totalRecords.inc
    totalBases += length

    uniqueBySeqid.mgetOrPut(record.seqid, @[]).add((record.start, record.stop))

    let current = statsByType.getOrDefault(record.featureType, (count: 0, bases: 0))
    statsByType[record.featureType] = (count: current.count + 1, bases: current.bases + length)

  var totalUnique = 0
  for seqid, intervals in uniqueBySeqid:
    totalUnique += uniqueCoverage(intervals)

  echo fmt"Total records: {totalRecords}"
  echo fmt"Total bases covered: {totalBases}"
  echo fmt"Total unique bases covered: {totalUnique}"

  if statsByType.len > 0:
    echo ""
    echo "Per feature type:"
    echo "Type\tRecords\tBases"
    var featureTypes = statsByType.keys.toSeq
    featureTypes.sort()
    for featureType in featureTypes:
      let entry = statsByType[featureType]
      echo fmt"{featureType}\t{entry.count}\t{entry.bases}"

when isMainModule:
  main()
