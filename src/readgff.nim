## ReadGFF: A Nim library to parse GFF files
## 
## This module provides functionality to parse GFF (General Feature Format) files.
## It is modeled with APIs similar to readfx for consistency.
##
## Basic usage:
## 
## .. code-block:: nim
##   import readgff
##   
##   for record in readGff("input.gff"):
##     echo record.seqid, " ", record.start, "-", record.end

import strutils
import tables

type
  GffRecord* = object
    ## Represents a single GFF record with all its fields
    seqid*: string      ## Sequence ID (column 1)
    source*: string     ## Source of the feature (column 2)
    featureType*: string ## Type of feature (column 3)
    start*: int         ## Start position (1-based, column 4)
    stop*: int          ## End position (inclusive, column 5)
    score*: string      ## Score (column 6, "." if not available)
    strand*: char       ## Strand ('+', '-', or '.', column 7)
    phase*: char        ## Phase (0, 1, 2, or '.', column 8)
    attributes*: string ## Raw attributes string (column 9)
    
  GffError* = object of CatchableError
    ## Error type for GFF parsing errors

proc parseAttributes*(attrStr: string): Table[string, string] =
  ## Parse the attributes field (column 9) into a table
  ## 
  ## GFF3 format uses key=value pairs separated by semicolons
  ## Returns a table mapping attribute keys to values
  result = initTable[string, string]()
  if attrStr == "." or attrStr.len == 0:
    return
  
  for pair in attrStr.split(';'):
    let trimmed = pair.strip()
    if trimmed.len == 0:
      continue
    let parts = trimmed.split('=', 1)
    if parts.len == 2:
      result[parts[0].strip()] = parts[1].strip()
    elif parts.len == 1:
      # Some GFF files have attributes without values
      result[parts[0].strip()] = ""

proc getAttribute*(record: GffRecord, key: string, default: string = ""): string =
  ## Get a specific attribute value from a GFF record
  ## 
  ## Returns the value of the attribute with the given key, or the default value if not found
  let attrs = parseAttributes(record.attributes)
  return attrs.getOrDefault(key, default)

proc parseLine(line: string): GffRecord =
  ## Parse a single GFF line into a GffRecord
  let fields = line.split('\t')
  
  if fields.len != 9:
    raise newException(GffError, "Invalid GFF line: expected 9 fields, got " & $fields.len)
  
  result.seqid = fields[0]
  result.source = fields[1]
  result.featureType = fields[2]
  
  # Parse start position
  try:
    result.start = parseInt(fields[3])
  except ValueError:
    raise newException(GffError, "Invalid start position: " & fields[3])
  
  # Parse end position
  try:
    result.stop = parseInt(fields[4])
  except ValueError:
    raise newException(GffError, "Invalid end position: " & fields[4])
  
  result.score = fields[5]
  
  # Parse strand
  if fields[6].len > 0:
    result.strand = fields[6][0]
  else:
    result.strand = '.'
  
  # Parse phase
  if fields[7].len > 0:
    result.phase = fields[7][0]
  else:
    result.phase = '.'
  
  result.attributes = fields[8]

iterator readGff*(filename: string): GffRecord =
  ## Iterator that yields GffRecord objects from a GFF file
  ## 
  ## Automatically skips comment lines (starting with #) and empty lines
  ## 
  ## Example:
  ## 
  ## .. code-block:: nim
  ##   for record in readGff("input.gff"):
  ##     echo record.seqid, " ", record.start, "-", record.stop
  var f: File
  if not open(f, filename):
    raise newException(IOError, "Cannot open file: " & filename)
  
  defer: f.close()
  
  var lineNum = 0
  for line in f.lines:
    lineNum.inc
    let trimmed = line.strip()
    
    # Skip empty lines and comments
    if trimmed.len == 0 or trimmed.startsWith("#"):
      continue
    
    try:
      yield parseLine(trimmed)
    except GffError as e:
      raise newException(GffError, "Error at line " & $lineNum & ": " & e.msg)

iterator readGff*(f: File): GffRecord =
  ## Iterator that yields GffRecord objects from an open File
  ## 
  ## Automatically skips comment lines (starting with #) and empty lines
  ## The file must be opened before calling this iterator
  ## 
  ## Example:
  ## 
  ## .. code-block:: nim
  ##   var f = open("input.gff")
  ##   for record in readGff(f):
  ##     echo record.seqid
  ##   f.close()
  var lineNum = 0
  for line in f.lines:
    lineNum.inc
    let trimmed = line.strip()
    
    # Skip empty lines and comments
    if trimmed.len == 0 or trimmed.startsWith("#"):
      continue
    
    try:
      yield parseLine(trimmed)
    except GffError as e:
      raise newException(GffError, "Error at line " & $lineNum & ": " & e.msg)

proc `$`*(record: GffRecord): string =
  ## Convert a GffRecord to its string representation (GFF format)
  result = [
    record.seqid,
    record.source,
    record.featureType,
    $record.start,
    $record.stop,
    record.score,
    $record.strand,
    $record.phase,
    record.attributes
  ].join("\t")
