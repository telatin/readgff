## Example: Advanced GFF parsing features
## 
## This example demonstrates more advanced features of the readgff library

import readgff
import tables
import strutils

# Create a comprehensive GFF file
let sampleGff = """##gff-version 3
##sequence-region chr1 1 50000
chr1	RefSeq	gene	1000	9000	.	+	.	ID=gene001;Name=BRCA1;product=breast cancer type 1 susceptibility protein;Note=tumor suppressor
chr1	RefSeq	mRNA	1000	9000	.	+	.	ID=transcript001;Parent=gene001;Name=BRCA1-201
chr1	RefSeq	five_prime_UTR	1000	1050	.	+	.	ID=utr001;Parent=transcript001
chr1	RefSeq	CDS	1050	1500	.	+	0	ID=cds001;Parent=transcript001;product=BRCA1 protein
chr1	RefSeq	CDS	3000	3500	.	+	0	ID=cds002;Parent=transcript001;product=BRCA1 protein
chr1	RefSeq	three_prime_UTR	8500	9000	.	+	.	ID=utr002;Parent=transcript001
chr2	RefSeq	gene	15000	20000	.	-	.	ID=gene002;Name=TP53;biotype=protein_coding;description=tumor protein p53
chr2	RefSeq	mRNA	15000	20000	.	-	.	ID=transcript002;Parent=gene002
chr2	RefSeq	CDS	15200	15800	.	-	0	ID=cds003;Parent=transcript002
chr3	miRBase	miRNA	5000	5100	.	+	.	ID=mir001;Name=hsa-mir-21;product=microRNA 21
"""

writeFile("/tmp/advanced_example.gff", sampleGff)

echo "="
echo "Example 1: Count features by type"
echo "="
var featureCounts = initTable[string, int]()
for record in readGff("/tmp/advanced_example.gff"):
  let ftype = record.featureType
  if ftype in featureCounts:
    featureCounts[ftype] += 1
  else:
    featureCounts[ftype] = 1

echo "Feature type counts:"
for ftype, count in featureCounts:
  echo "  ", ftype, ": ", count

echo ""
echo "="
echo "Example 2: Extract genes with metadata"
echo "="
for record in readGff("/tmp/advanced_example.gff"):
  if record.featureType == "gene":
    let attrs = parseAttributes(record.attributes)
    echo "Gene: ", attrs.getOrDefault("Name", "Unknown")
    echo "  ID: ", attrs.getOrDefault("ID", "N/A")
    echo "  Location: ", record.seqid, ":", record.start, "-", record.stop, " (", record.strand, ")"
    if "product" in attrs:
      echo "  Product: ", attrs["product"]
    if "description" in attrs:
      echo "  Description: ", attrs["description"]
    if "Note" in attrs:
      echo "  Note: ", attrs["Note"]
    echo ""

echo "="
echo "Example 3: Calculate total CDS length per chromosome"
echo "="
var cdsLengths = initTable[string, int]()
for record in readGff("/tmp/advanced_example.gff"):
  if record.featureType == "CDS":
    let length = record.stop - record.start + 1
    if record.seqid in cdsLengths:
      cdsLengths[record.seqid] += length
    else:
      cdsLengths[record.seqid] = length

for chr, length in cdsLengths:
  echo chr, ": ", length, " bp of CDS"

echo ""
echo "="
echo "Example 4: Find parent-child relationships"
echo "="
var geneTranscripts = initTable[string, seq[string]]()
for record in readGff("/tmp/advanced_example.gff"):
  if record.featureType == "mRNA":
    let parent = record.getAttribute("Parent")
    let id = record.getAttribute("ID")
    if parent != "":
      if parent notin geneTranscripts:
        geneTranscripts[parent] = @[]
      geneTranscripts[parent].add(id)

echo "Gene to transcript mapping:"
for gene, transcripts in geneTranscripts:
  echo "  ", gene, " -> ", transcripts.join(", ")

echo ""
echo "="
echo "Example 5: Filter by genomic region"
echo "="
let targetChr = "chr1"
let regionStart = 1000
let regionEnd = 5000

echo "Features in ", targetChr, ":", regionStart, "-", regionEnd, ":"
for record in readGff("/tmp/advanced_example.gff"):
  if record.seqid == targetChr and 
     record.start <= regionEnd and 
     record.stop >= regionStart:
    echo "  ", record.featureType, " at ", record.start, "-", record.stop
