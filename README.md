# readgff

A Nim library to parse GFF (General Feature Format) files. The API is modeled to be similar to [readfx](https://github.com/quadram-institute-bioscience/readfx) for consistency and ease of use.

## Features

- 🚀 Fast and memory-efficient GFF parsing using iterators
- 📝 Support for GFF3 format
- 🔍 Easy attribute extraction with helper functions
- ⚡ Simple, intuitive API similar to readfx
- 🛡️ Comprehensive error handling
- ✅ Well-tested and documented

## Installation

```bash
nimble install readgff
```

Or add to your `.nimble` file:

```nim
requires "readgff"
```

## Quick Start

```nim
import readgff

# Iterate through all records in a GFF file
for record in readGff("input.gff"):
  echo record.seqid, "\t", record.featureType, "\t", record.start, "-", record.stop
```

## Usage

### Basic Parsing

The main way to use readgff is through the `readGff` iterator:

```nim
import readgff

for record in readGff("genes.gff"):
  echo "Feature: ", record.featureType
  echo "  Location: ", record.seqid, ":", record.start, "-", record.stop
  echo "  Strand: ", record.strand
```

### GFF Record Structure

Each `GffRecord` contains the following fields:

- `seqid: string` - Sequence ID (column 1)
- `source: string` - Source of the feature (column 2)
- `featureType: string` - Type of feature (column 3, e.g., "gene", "mRNA", "exon")
- `start: int` - Start position (1-based, inclusive, column 4)
- `stop: int` - End position (1-based, inclusive, column 5)
- `score: string` - Score (column 6)
- `strand: char` - Strand ('+', '-', or '.', column 7)
- `phase: char` - Phase (0, 1, 2, or '.', column 8)
- `attributes: string` - Raw attributes string (column 9)

### Working with Attributes

GFF attributes (column 9) can be parsed and accessed easily:

```nim
import readgff

for record in readGff("genes.gff"):
  # Get a specific attribute with a default value
  let geneName = record.getAttribute("Name", "Unknown")
  let geneId = record.getAttribute("ID")
  
  echo "Gene ID: ", geneId, ", Name: ", geneName

# Or parse all attributes at once
for record in readGff("genes.gff"):
  let attrs = parseAttributes(record.attributes)
  for key, value in attrs:
    echo key, " = ", value
```

### Filtering Records

```nim
import readgff

# Filter for specific feature types
for record in readGff("genes.gff"):
  if record.featureType == "gene":
    echo "Found gene: ", record.getAttribute("Name")

# Filter by location
for record in readGff("genes.gff"):
  if record.seqid == "chr1" and record.start >= 1000 and record.stop <= 5000:
    echo "Feature in region: ", record.featureType
```

### Using with File Handles

You can also pass an open file handle:

```nim
import readgff

var f = open("genes.gff")
for record in readGff(f):
  echo record.featureType
f.close()
```

### Converting Records Back to GFF Format

```nim
import readgff

for record in readGff("input.gff"):
  # Convert record back to GFF format string
  echo $record
```

## API Reference

### Types

- `GffRecord` - Represents a single GFF record
- `GffError` - Exception type for GFF parsing errors

### Iterators

- `readGff(filename: string): GffRecord` - Iterate over records in a file
- `readGff(f: File): GffRecord` - Iterate over records from an open file handle

### Procedures

- `parseAttributes(attrStr: string): Table[string, string]` - Parse attributes string into a table
- `getAttribute(record: GffRecord, key: string, default: string = ""): string` - Get a specific attribute value

## Examples

See the `examples/` directory for more examples:

- `basic_usage.nim` - Demonstrates basic parsing and attribute extraction

Run examples with:

```bash
nim c -r --path:src examples/basic_usage.nim
```

## Testing

Run the test suite:

```bash
nim c -r --path:src tests/test_readgff.nim
```

## GFF Format

The GFF (General Feature Format) is a tab-delimited text format for describing genomic features. Each line represents a single feature with 9 columns:

1. **seqid** - Sequence ID
2. **source** - Source of the feature
3. **type** - Feature type (e.g., gene, exon, CDS)
4. **start** - Start position (1-based, inclusive)
5. **end** - End position (1-based, inclusive)
6. **score** - Score (or '.' if not applicable)
7. **strand** - Strand ('+', '-', or '.')
8. **phase** - Phase for CDS features (0, 1, 2, or '.')
9. **attributes** - Semicolon-separated list of tag=value pairs

Lines starting with `#` are comments and are automatically skipped.

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

telatin