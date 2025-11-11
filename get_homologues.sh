#!/bin/bash
#
# This script runs a pan-genome analysis workflow using get_homologues.pl
#

# --- 1. CONFIGURATION ---
# Stop the script if any command fails
echo "LANGKAH 1: Konfigurasi"
set -e

# Path to the get_homologues executables
TOOL_DIR="$HOME/miniconda3/envs/get_homologues/bin"

# Path to your .gbk or .gff files
INPUT_DIR="annotation/gbk"

# Main output directory that get_homologues will create
BASE_OUTPUT_DIR="gbk_homologues"

# Get the base name of the input dir (e.g., 'gbk') for file naming
INPUT_PREFIX=$(basename $INPUT_DIR)

# Number of CPU threads to use
THREADS=8

echo "--- Pan-Genome Tutorial Started ---"
echo "Input Directory: $INPUT_DIR"
echo "Tool Directory:    $TOOL_DIR"
echo "Output Directory:  $BASE_OUTPUT_DIR"
echo "Threads:           $THREADS"
echo "-----------------------------------"


# --- 2. PRE-COMPUTE DIAMOND SEARCHES ---
echo "LANGKAH 2: Pre-computing DIAMOND searches..."
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -n $THREADS -X -o


# --- 3. CALCULATE CORE-GENOMES (BDBH, OMCL, COG) ---
echo "LANGKAH 3.1: Menghitung core-genome dengan BDBH"
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -n $THREADS -X

echo "LANGKAH 3.2: Menghitung core-genome dengan OMCL..."
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -n $THREADS -M -X

echo "LANGKAH 3.3: Menghitung core-genome dengan COG..."
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -n $THREADS -G -X


# --- 4. CALCULATE CONSENSUS CORE-GENOME (SYNTENIC) ---
echo "LANGKAH 4: Menghitung consensus syntenic core-genome..."
CORE_SYN_DIR="consensus_core_synteny"

# Get the base name of the input dir for prefixing
INPUT_PREFIX=$(basename $INPUT_DIR)

$TOOL_DIR/compare_clusters.pl -s -n -o $CORE_SYN_DIR -d \
$BASE_OUTPUT_DIR/${INPUT_PREFIX}_f0_alltaxa_algCOG_e0_,\
$BASE_OUTPUT_DIR/${INPUT_PREFIX}_f0_alltaxa_algOMCL_e0_,\
$BASE_OUTPUT_DIR/${INPUT_PREFIX}_f0_alltaxa_algBDBH_e0_


# --- 5. CALCULATE CORE-GENOME (TETTELIN-STYLE) ---
echo "LANGKAH 5: Menghitung core-genome (50% Cov, 50% ID)..."
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -M -C 50 -S 50 -n $THREADS -X

# --- 6. CALCULATE CORE INTERGENIC CLUSTERS ---
echo "LANGKAH 6: Menghitung core intergenic clusters..."
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -g -n $THREADS -X


# --- 7. ESTIMATE CORE & PAN-GENOME SIZES (FOR PLOTTING) ---
echo "LANGKAH 7.1: Estimating sizes (BDBH)..."
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -c -n $THREADS -X

echo "LANGKAH 7.2: Estimating sizes (OMCL)..."
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -M -c -n $THREADS -X

echo "LANGKAH 7.3: Estimating sizes (COG)..."
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -G -c -n $THREADS -X


# --- 8. CALCULATE FULL PAN-GENOME (t=0) & AAI ---
# We add the -A flag to the OMCL run to generate the AAI matrix.
echo "LANGKAH 8.1: Menghitung full pan-genome (OMCL, t=0) and AAI Matrix..."
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -M -t 0 -A -n $THREADS -X

echo "LANGKAH 8.2: Menghitung full pan-genome (COG, t=0)..."
$TOOL_DIR/get_homologues.pl -d $INPUT_DIR -G -t 0 -n $THREADS -X


# --- 9. BUILD CONSENSUS PAN-GENOME MATRIX & TREE ---
echo "LANGKAH 9: Building consensus pan-genome matrix and tree..."
PAN_MATRIX_DIR="consensus_pangenome_matrix"

# Get the base name of the input dir for prefixing
INPUT_PREFIX=$(basename $INPUT_DIR)

$TOOL_DIR/compare_clusters.pl -o $PAN_MATRIX_DIR -m -T -d \
$BASE_OUTPUT_DIR/${INPUT_PREFIX}_f0_0taxa_algCOG_e0_,\
$BASE_OUTPUT_DIR/${INPUT_PREFIX}_f0_0taxa_algOMCL_e0_


# --- 10. PARSE & PLOT PAN-GENOME MATRIX ---
echo "LANGKAH 10: Parsing matrix untuk membuat plot..."
MATRIX_FILE="${PAN_MATRIX_DIR}/pangenome_matrix_t0.tab"
$TOOL_DIR/parse_pangenome_matrix.pl -m $MATRIX_FILE -s


# --- 11. CREATE AAI HEATMAP ---
# This plots the AAI matrix generated in LANGKAH 8.1
echo "LANGKAH 11: Membuat AAI (Average Amino Acid Identity) heatmap..."
AAI_MATRIX_FILE="${BASE_OUTPUT_DIR}/${INPUT_PREFIX}_f0_0taxa_CDS_algOMCL_e0_Avg_identity.tab"
if [ -f "$AAI_MATRIX_FILE" ]; then
    $TOOL_DIR/plot_matrix_heatmap.sh -i $AAI_MATRIX_FILE \
      -d 2 -t "Average Amino Acid Identity (AAI)" -o pdf
else
    echo "WARNING: AAI Matrix file not found at $AAI_MATRIX_FILE. Skipping LANGKAH 11."
fi


# --- 12. CREATE PAN-GENOME PRESENCE/ABSENCE HEATMAP ---
# This plots the pan-genome matrix from LANGKAH 9
echo "LANGKAH 12: Membuat pan-genome presence/absence heatmap..."
if [ -f "$MATRIX_FILE" ]; then
    $TOOL_DIR/plot_matrix_heatmap.sh -i $MATRIX_FILE -o pdf \
       -H 8 -W 14 -m 28 -t "Mycobacterium Pan-genome" -k "Genes per cluster"
else
    echo "WARNING: Pan-genome matrix file not found at $MATRIX_FILE. Skipping LANGKAH 12."
fi


echo "-----------------------------------"
echo "--- Pan-Genome Tutorial Finished ---"
echo "Main results are in: $BASE_OUTPUT_DIR"
echo "Consensus Core-Genome: $CORE_SYN_DIR"
echo "Consensus Pan-Genome Matrix: $PAN_MATRIX_DIR"
echo "Heatmaps (PDF) are in: $BASE_OUTPUT_DIR and $PAN_MATRIX_DIR"
