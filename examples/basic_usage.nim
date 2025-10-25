## Example: Basic GFF parsing
## 
## This example demonstrates basic usage of the readgff library

import readgff

# Create a sample GFF file
let sampleGff = """##gff-version 3
##sequence-region chr1 1 10000
chr1	Ensembl	gene	1000	9000	.	+	.	ID=ENSG00000000001;Name=GENE1;biotype=protein_coding
chr1	Ensembl	mRNA	1000	9000	.	+	.	ID=ENST00000000001;Parent=ENSG00000000001;Name=GENE1-201
chr1	Ensembl	exon	1000	1200	.	+	.	ID=exon1;Parent=ENST00000000001
chr1	Ensembl	CDS	1050	1200	.	+	0	ID=cds1;Parent=ENST00000000001
chr1	Ensembl	exon	3000	3500	.	+	.	ID=exon2;Parent=ENST00000000001
chr1	Ensembl	CDS	3000	3500	.	+	2	ID=cds2;Parent=ENST00000000001
chr2	Ensembl	gene	5000	8000	.	-	.	ID=ENSG00000000002;Name=GENE2;biotype=lncRNA
"""

writeFile("/tmp/example.gff", sampleGff)

echo "Example 1: Iterating through all records"
echo "=========================================="
for record in readGff("/tmp/example.gff"):
  echo record.seqid, "\t", record.featureType, "\t", record.start, "-", record.stop, "\t", record.strand

echo ""
echo "Example 2: Filtering for specific feature types"
echo "================================================"
for record in readGff("/tmp/example.gff"):
  if record.featureType == "gene":
    echo "Gene: ", record.getAttribute("Name"), " on ", record.seqid, " (", record.strand, ")"

echo ""
echo "Example 3: Extracting attributes"
echo "================================="
for record in readGff("/tmp/example.gff"):
  if record.featureType == "gene":
    let geneName = record.getAttribute("Name", "Unknown")
    let geneId = record.getAttribute("ID", "NoID")
    let biotype = record.getAttribute("biotype", "unspecified")
    echo "ID: ", geneId, ", Name: ", geneName, ", Biotype: ", biotype

echo ""
echo "Example 4: Converting record back to GFF format"
echo "================================================"
for record in readGff("/tmp/example.gff"):
  if record.featureType == "exon":
    echo $record
    break
