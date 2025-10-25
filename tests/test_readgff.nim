import unittest
import readgff
import tables
import os
import strutils

proc collectRecords(path: string): seq[GffRecord] =
  result = @[]
  for record in readGff(path):
    result.add(record)

suite "GFF parsing tests":
  
  setup:
    # Create a temporary test GFF file
    let testGffContent = """##gff-version 3
# This is a comment
chr1	AUGUSTUS	gene	1000	2000	.	+	.	ID=gene1;Name=TestGene
chr1	AUGUSTUS	mRNA	1000	2000	.	+	.	ID=transcript1;Parent=gene1
chr1	AUGUSTUS	exon	1000	1200	.	+	0	ID=exon1;Parent=transcript1
chr2	manual	CDS	5000	5500	100	-	0	ID=cds1;product=hypothetical protein
chr3	test	region	100	200	.	.	.	.
"""
    let testFile = "/tmp/test_gff.gff"
    writeFile(testFile, testGffContent)
  
  teardown:
    if fileExists("/tmp/test_gff.gff"):
      removeFile("/tmp/test_gff.gff")
  
  test "can parse basic GFF file":
    var count = 0
    for record in readGff("/tmp/test_gff.gff"):
      count.inc
    check count == 5
  
  test "parses seqid correctly":
    var first = true
    for record in readGff("/tmp/test_gff.gff"):
      if first:
        check record.seqid == "chr1"
        first = false
        break
  
  test "parses feature type correctly":
    var records: seq[GffRecord] = @[]
    for record in readGff("/tmp/test_gff.gff"):
      records.add(record)
    check records[0].featureType == "gene"
    check records[1].featureType == "mRNA"
    check records[2].featureType == "exon"
  
  test "parses coordinates correctly":
    var first = true
    for record in readGff("/tmp/test_gff.gff"):
      if first:
        check record.start == 1000
        check record.stop == 2000
        first = false
        break
  
  test "parses strand correctly":
    var records: seq[GffRecord] = @[]
    for record in readGff("/tmp/test_gff.gff"):
      records.add(record)
    check records[0].strand == '+'
    check records[3].strand == '-'
    check records[4].strand == '.'
  
  test "parses phase correctly":
    var records: seq[GffRecord] = @[]
    for record in readGff("/tmp/test_gff.gff"):
      records.add(record)
    check records[2].phase == '0'
    check records[4].phase == '.'
  
  test "parseAttributes works correctly":
    let attrs = parseAttributes("ID=gene1;Name=TestGene;Note=something")
    check attrs["ID"] == "gene1"
    check attrs["Name"] == "TestGene"
    check attrs["Note"] == "something"
  
  test "parseAttributes handles empty string":
    let attrs = parseAttributes(".")
    check attrs.len == 0
  
  test "getAttribute returns correct value":
    var first = true
    for record in readGff("/tmp/test_gff.gff"):
      if first:
        check record.getAttribute("ID") == "gene1"
        check record.getAttribute("Name") == "TestGene"
        check record.getAttribute("missing", "default") == "default"
        first = false
        break
  
  test "record to string conversion":
    var first = true
    for record in readGff("/tmp/test_gff.gff"):
      if first:
        let str = $record
        check str.contains("chr1")
        check str.contains("AUGUSTUS")
        check str.contains("gene")
        first = false
        break
  
  test "skips comment lines":
    # The test file has 2 comment lines, but we should only get 5 records
    var count = 0
    for record in readGff("/tmp/test_gff.gff"):
      count.inc
    check count == 5
  
  test "handles file with open File handle":
    var f = open("/tmp/test_gff.gff")
    var count = 0
    for record in readGff(f):
      count.inc
    f.close()
    check count == 5

suite "GFF error handling":
  
  test "raises error for invalid line":
    let invalidContent = """chr1	AUGUSTUS	gene	1000
"""
    let testFile = "/tmp/test_invalid.gff"
    writeFile(testFile, invalidContent)
    
    expect GffError:
      for record in readGff(testFile):
        discard
    
    removeFile(testFile)
  
  test "raises error for invalid start position":
    let invalidContent = """chr1	AUGUSTUS	gene	ABC	2000	.	+	.	ID=gene1
"""
    let testFile = "/tmp/test_invalid_start.gff"
    writeFile(testFile, invalidContent)
    
    expect GffError:
      for record in readGff(testFile):
        discard
    
    removeFile(testFile)
  
  test "raises error for non-existent file":
    expect IOError:
      for record in readGff("/tmp/nonexistent_file_xyz.gff"):
        discard

suite "GFF fixture integration tests":

  const fixturesDir = "tests/files"

  test "handles empty example fixture":
    let records = collectRecords(joinPath(fixturesDir, "example.gff"))
    check records.len == 0

  test "parses vista fixture correctly":
    let records = collectRecords(joinPath(fixturesDir, "vista.gff"))
    check records.len == 6
    if records.len > 0:
      check records[0].featureType == "CDS"

  test "parses genes fixture correctly":
    let records = collectRecords(joinPath(fixturesDir, "genes.gff"))
    check records.len == 395
    if records.len > 0:
      check records[0].seqid == "chr01"
      check records[0].getAttribute("ID") == "YAL069W"

  test "ignores FASTA section in prokka fixture":
    let records = collectRecords(joinPath(fixturesDir, "prokka.gff"))
    check records.len == 8
    if records.len > 0:
      check records[^1].seqid == "NODE_1_length_29600_cov_2807.600820"
      check records[^1].getAttribute("ID") == "gene8"
