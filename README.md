# ICT

ICT is a command-line workflow for recovering marker-supported full-length representative sequences from long accurate reads and assigning taxonomy with `skani`. The pipeline uses DIAMOND for marker prefiltering, HMMER for marker validation, `seqkit` for marker/flanking-region extraction, MMseqs2 and minimap2 for sequence clustering, MCL for graph clustering, and `skani` for final taxonomy assignment.

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Database setup](#database-setup)
- [Usage](#usage)
- [Output](#output)

## Requirements

ICT is intended to run on Linux or macOS with Bash, Perl, and Conda/Mamba. The required command-line tools are defined in `environment.yml`:

- `diamond=2.2.0`
- `hmmer=3.4`
- `mmseqs2=18.8cc5c`
- `minimap2=2.31`
- `mcl=22.282`
- `seqkit=2.13.0`
- `prodigal=2.6.3`
- `python=3.11.5`
- `pigz=2.8`
- `skani=0.3.2`

The workflow also requires an external GTDB-compatible `skani` database directory, provided at runtime with `--skani-db`.
https://data.gtdb.aau.ecogenomic.org/releases/release232/232.0/auxillary_files/gtdbtk_package/full_package/gtdbtk_r232_data.tar.gz

tar -zxvf gtdbtk_r232_data.tar.gz

path of gz file/release232/skani/database

## Installation

### 1. Clone or download the repository

```bash
git clone <repository-url>
cd ICT_package
```

If you downloaded a ZIP archive instead:

```bash
unzip ICT_package.zip
cd ICT_package
```

### 2. Create the Conda environment

Using Conda:

```bash
conda env create -f environment.yml
conda activate ICT
```

Using Mamba, which is usually faster:

```bash
mamba env create -f environment.yml
mamba activate ICT
```

### 3. Make scripts executable

The workflow can be run with `bash ICT`, but setting executable permissions is convenient:

```bash
chmod +x ICT cat-file.sh
```

### 4. Check the installation

```bash
bash ICT --help
```

You should see the ICT usage message and the list of required arguments and options.

## Database setup

ICT uses two database resources:

### 1. Bundled marker database

The marker database is included in the repository under `DB/`. It must contain:

```text
DB/markers.consensus.fa.dmnd
DB/*.hmm
```

Do not move or rename the `DB/` directory unless you also modify the `DB_DIR` variable in the `ICT` script.

### 2. External skani database

The final taxonomy assignment step requires a GTDB-compatible `skani` database directory. Pass this directory to ICT using `--skani-db`:

```bash
tar -zxvf gtdbtk_r232_data.tar.gz
--skani-db path of gz file/release232/skani/database
```

The directory must already exist before running ICT.

## Usage

### Basic command

```bash
bash ICT \
  -i reads.fastq.gz \
  -o ICT_output \
  --skani-db path of gz file/release232/skani/database
```

### Recommended command for larger datasets

```bash
bash ICT \
  -i reads.fastq.gz \
  -o ICT_output \
  -t 32 \
  --hmmsearch-threads 2 \
  --mmseqs-threads 4 \
  --minimap2-threads 4 \
  --skani-db path of gz file/release232/skani/database
```

### Input

`-i, --input` accepts a long accurate read file in FASTQ format only, optionally gzipped. FASTQ input is because downstream representative selection uses quality information.

Examples:

```text
reads.fastq
reads.fastq.gz
reads.fasta
reads.fa.gz
```

### Required arguments

| Argument | Description |
| --- | --- |
| `-i, --input FILE` | Input long accurate reads file, FASTQ/FASTA, optionally gzipped. |
| `-o, --output DIR` | Output directory. It will be created if it does not exist. |
| `--skani-db DIR` | GTDB-compatible `skani` database directory. |

### General options

| Argument | Default | Description |
| --- | ---: | --- |
| `-t, --threads INT` | `8` | Total CPU thread budget. |
| `-h, --help` | - | Show help message and exit. |
| `-v, --version` | - | Show ICT version and exit. |

### Per-task thread options

| Argument | Default | Description |
| --- | ---: | --- |
| `--diamond-threads INT` | total threads | Threads for the single DIAMOND `blastx` task. |
| `--hmmsearch-threads INT` | `2` | Threads per `hmmsearch` task. Multiple marker jobs may run in parallel. |
| `--mmseqs-threads INT` | `4` | Threads per `mmseqs easy-linclust` task. Multiple marker jobs may run in parallel. |
| `--minimap2-threads INT` | `4` | Threads per minimap2 overlap-detection task. Multiple marker jobs may run in parallel. |
| `--skani-threads INT` | total threads | Threads for the single `skani search` task. |

ICT computes the number of parallel jobs for HMMER, MMseqs2, and minimap2 from the total thread budget and the per-task thread settings.

## Output

ICT creates the following output structure:

```text
<output_dir>/
├── 01.diamond/
├── 02.hmmsearch/
├── 03.extract_marker_flanking/
├── 04.mmseqs_linclust/
├── 05.overlap_minimap2/
├── 06.mcl_cluster/
├── 07.select_representatives/
├── 08.full_length_sequences/
└── 09.skani_taxonomy/
```

Important output files include:

| File | Description |
| --- | --- |
| `<output_dir>/used.marker.ID` | Marker IDs retained after DIAMOND prefiltering and HMM validation. |
| `<output_dir>/03.extract_marker_flanking/extracted_by_seqkit.fastq` | Marker regions plus 2 kb flanking sequences extracted from the input reads. |
| `<output_dir>/08.full_length_sequences/all.expanded.cluster.rep.fullseq.fasta` | Merged full-length representative sequences selected from marker-supported clusters. |
| `<output_dir>/09.skani_taxonomy/used.marker.Cluster.Taxonomy.skani.out` | Final `skani search` taxonomy assignment output. |

When the workflow finishes successfully, the main script prints the path to the final taxonomy file:

```text
<output_dir>/09.skani_taxonomy/used.marker.Cluster.Taxonomy.skani.out
```



# ICT
# ICT
