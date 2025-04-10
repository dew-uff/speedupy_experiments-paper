#!/bin/bash

# Capture start time
START_TIME=$(date +%s)
echo "Experiment started at: $(date '+%Y-%m-%d %H:%M:%S')"

# Clean previous outputs
rm -f *.txt
if [ -d outputs ]; then
    rm -f outputs/*
else
    mkdir outputs
fi

# Install dependencies
pip install -r speedupy/requirements.txt

# Define paths
ROOT_PATH="$(pwd)"
SOURCE_DIR="$ROOT_PATH/speedupy"

# Experiment configuration
DESTINATIONS=(
    "$ROOT_PATH/speedupy_experiments/01pilots/01pilots_exp03_quicksort/quicksort.py"
    "$ROOT_PATH/speedupy_experiments/04benchproglangs/04benchpl_exp02_look_and_say/look_and_say.py"
    "$ROOT_PATH/speedupy_experiments/04benchproglangs/04benchpl_exp11_gauss_legendre_quadrature/gauss_legendre_quadrature.py"
)

ARGUMENTS_0=("1e1" "1e2" "1e3" "1e4" "1e5")  # quicksort
ARGUMENTS_1=("25" "30" "35" "40" "45")       # look_and_say
ARGUMENTS_2=("1000" "2000" "3000" "4000" "5000")  # gauss_legendre

# Copy speedupy to each experiment directory
for DEST in "${DESTINATIONS[@]}"; do
    DEST_DIR=$(dirname "$DEST")
    if [ ! -d "$DEST_DIR/speedupy" ]; then
        cp -r "$SOURCE_DIR" "$DEST_DIR"
        echo "Copied speedupy to $DEST_DIR"
    fi
done

run_experiment_mode() {
    local mode=$1
    local suffix=$2
    local cache_scope=$3
    
    echo -e "\nRunning mode: $mode (cache: $cache_scope)"
    
    # Initialize output files
    for i in "${!DESTINATIONS[@]}"; do
        OUTPUT_FILE="$ROOT_PATH/outputs/$(basename ${DESTINATIONS[i]} .py)_${suffix}.txt"
        > "$OUTPUT_FILE"
    done

    # Execute 3 rounds
    for round in {1..3}; do
        echo "Round $round/3"
        
        # Setup cache for round/experiment scope
        if [[ "$cache_scope" == "round" || "$cache_scope" == "experiment" ]]; then
            for DEST in "${DESTINATIONS[@]}"; do
                DEST_DIR=$(dirname "$DEST")
                python3.12 "$DEST_DIR/speedupy/setup_exp/setup.py" "$DEST"
            done
        fi

        # Process all arguments in order (0..4)
        for arg_idx in {0..4}; do
            # Execute all experiments for current argument
            for i in "${!DESTINATIONS[@]}"; do
                # Get experiment details
                DEST="${DESTINATIONS[i]}"
                DEST_DIR=$(dirname "$DEST")
                PYTHON_FILE="$DEST"
                OUTPUT_FILE="$ROOT_PATH/outputs/$(basename $PYTHON_FILE .py)_${suffix}.txt"
                
                # Get current argument if exists
                ARGUMENTS_VAR="ARGUMENTS_$i[@]"
                ARGUMENTS=("${!ARGUMENTS_VAR}")
                if [ $arg_idx -lt ${#ARGUMENTS[@]} ]; then
                    ARG="${ARGUMENTS[arg_idx]}"
                    
                    # Setup cache for execution/argument scope
                    if [[ "$cache_scope" == "execution" || "$cache_scope" == "argument" ]]; then
                        python3.12 "$DEST_DIR/speedupy/setup_exp/setup.py" "$PYTHON_FILE"
                    fi
                    
                    # Execute the experiment
                    cd "$DEST_DIR"
                    echo "  Running $(basename $PYTHON_FILE) with $ARG (round $round)"
                    python3.12 "$PYTHON_FILE" "$ARG" --exec-mode "$mode" | tail -n 1 | cut -d':' -f2 >> "$OUTPUT_FILE"
                    
                    # Cleanup cache after execution if needed
                    if [ "$cache_scope" == "execution" ]; then
                        rm -rf "$DEST_DIR/.speedupy/"
                    fi
                fi
            done
            
            # Cleanup after all experiments for current argument (argument scope)
            if [ "$cache_scope" == "argument" ]; then
                for DEST in "${DESTINATIONS[@]}"; do
                    rm -rf "$(dirname "$DEST")/.speedupy/"
                done
            fi
        done
        
        # Cleanup after round if round scope
        if [ "$cache_scope" == "round" ]; then
            for DEST in "${DESTINATIONS[@]}"; do
                DEST_DIR=$(dirname "$DEST")
                rm -rf "$DEST_DIR/.speedupy/" "$DEST_DIR/speedupy/"
            done
        fi
    done
    
    # Final cleanup for experiment scope
    if [ "$cache_scope" == "experiment" ]; then
        for DEST in "${DESTINATIONS[@]}"; do
            DEST_DIR=$(dirname "$DEST")
            rm -rf "$DEST_DIR/.speedupy/" "$DEST_DIR/speedupy/"
        done
    fi
}

# Execute all modes
run_experiment_mode "no-cache" "output_no_cache" "execution"
run_experiment_mode "manual" "output_spdpy_intra_args" "argument"
run_experiment_mode "manual" "output_spdpy_intra_exec" "execution"
run_experiment_mode "manual" "output_spdpy_intra_exp" "round"

# Calculate and display execution time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
printf "\nExperiment completed at: $(date '+%Y-%m-%d %H:%M:%S')"
printf "\nTotal execution time: %02d:%02d:%02d\n" $((ELAPSED/3600)) $((ELAPSED%3600/60)) $((ELAPSED%60))
echo "All outputs saved in outputs/ directory"
