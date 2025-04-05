#!/bin/bash

# === Check for required argument ===
if [ -z "$1" ]; then
    echo "Error: You must provide an integer indicating how many times each experiment should run per mode and input argument." >&2
    echo "Usage: $0 <num_executions>" >&2
    exit 1
fi

# Verifica se é um número inteiro positivo
if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -eq 0 ]; then
    echo "Error: The number of executions must be a positive integer greater than zero." >&2
    exit 1
fi

NUM_RUNS="$1"
echo "Number of executions per mode and input argument: $NUM_RUNS"


# Capture start time / Captura o horário de início
START_TIME=$(date +%s)
echo "Start time: $(date '+%H:%M:%S')" / "Horário de início: $(date '+%H:%M:%S')"

# Clean old outputs / Limpa saídas antigas
rm -f outputs/*.txt 2>/dev/null
mkdir -p outputs

# Framework pre-configurations / Pré-configurações do framework
pip install -r speedupy/requirements.txt

# Prepare experiments / Prepara experimentos
for prep_script in dnacc_prepare.sh epr_prepare.sh qho2_prepare.sh heat_prepare.sh; do
    chmod +x "$prep_script" && ./"$prep_script"
done

# Define paths / Define caminhos
ROOT_PATH="$(pwd)"
SOURCE_DIR="$ROOT_PATH/speedupy"

# Experiment configuration / Configuração dos experimentos
declare -a DESTINATIONS=(
    "$ROOT_PATH/speedupy_experiments/01pilots/01pilots_exp03_quicksort/quicksort.py"
    "$ROOT_PATH/speedupy_experiments/04benchproglangs/04benchpl_exp02_look_and_say/look_and_say.py"
    "$ROOT_PATH/speedupy_experiments/04benchproglangs/04benchpl_exp11_gauss_legendre_quadrature/gauss_legendre_quadrature.py"
    # "$ROOT_PATH/speedupy_experiments/01pilots/01pilots_exp04_heat_distribution_lu/heat_distribution_lu.py"
    # "$ROOT_PATH/speedupy_experiments/04benchproglangs/04benchpl_exp08_fft/fft_speedupy.py"
    # "$ROOT_PATH/speedupy_experiments/04benchproglangs/04benchpl_exp14_pernicious_numbers/pernicious_numbers.py"
    # "$ROOT_PATH/speedupy_experiments/05msrgithubexps/05msrgithubexps_exp02_cvar/cvar_speedupy.py"
    # "$ROOT_PATH/speedupy_experiments/04benchproglangs/04benchpl_exp06_belief_propagation/belief_propagation_speedupy.py"
    # "$ROOT_PATH/DNACC-with-speedupy/adapted_for_speedupy/examples/basic/basic_spheres.py"
    # "$ROOT_PATH/DNACC-with-speedupy/adapted_for_speedupy/examples/walking_colloid/walking_colloid.py"
    # "$ROOT_PATH/diversity-with-speedupy/Diversity_sims/vince_sim_speedupy.py"
    # "$ROOT_PATH/Tiny-GSGP-with-speedupy/adapted_for_speedupy/TINY_GSHCGP.py"
    # "$ROOT_PATH/epr-with-speedupy/analyse_speedupy.py"
    # "$ROOT_PATH/qho-with-speedupy/qho2_speedupy.py"
    # "$ROOT_PATH/speedupy_experiments/05msrgithubexps/05msrgithubexps_exp04_curves/curves_speedupy.py"
)

ARGUMENTS_0=("1e1" "1e2" "1e3" "1e4" "1e5")
ARGUMENTS_1=("25" "30" "35" "40" "45")
ARGUMENTS_2=("1000" "2000" "3000" "4000" "5000")
# ARGUMENTS_3=("0.1" "0.05" "0.01" "0.005" "0.001")
# ARGUMENTS_4=("1000" "2000" "3000" "4000" "5000")
# ARGUMENTS_5=("20000" "25000" "30000" "35000" "39000")
# ARGUMENTS_6=("1e6" "5e6" "10e6" "50e6" "100e6")
# ARGUMENTS_7=("1000" "2000" "3000" "4000" "5000")
# ARGUMENTS_8=("40" "1000" "10000" "100000" "1000000")
# ARGUMENTS_9=("-10" "-20" "-30" "-40" "-50")
# ARGUMENTS_10=("1000000" "2000000" "3000000" "4000000" "5000000")
# ARGUMENTS_11=("1" "3" "5" "7" "9")
# ARGUMENTS_12=("100" "200" "300" "400" "500")
# ARGUMENTS_13=("100" "500" "1000" "5000" "6000")
# ARGUMENTS_14=(
#     "-11124 -11124 62412 1412 107501 201635 15678 57849"
#     "1576862 -8567453 1648423 542312 512 -20135 1455678 52349"
#     "4341212 -12312419 123123 5423672 107 20135 145678 52349"
#     "4341241 -1231219 1231423 5423672 10547 20135 145678 52349"
#     "-1112434 -1241223 6212412 5281412 107501 20142265 3455678 5467849"
# )

# Função para obter argumentos dinamicamente
get_argument() {
    local exp_index=$1
    local arg_index=$2
    local var_name="ARGUMENTS_${exp_index}[$arg_index]"
    echo "${!var_name}"
}

# Copy speedupy to each destination / Copia speedupy para cada destino
for dest in "${DESTINATIONS[@]}"; do
    dest_dir=$(dirname "$dest")
    [ -d "$dest_dir/speedupy" ] || cp -r "$SOURCE_DIR" "$dest_dir"
done


### MODE 1: no-cache ###
echo "=== MODE 1: no-cache ===" / "=== MODO 1: sem cache ==="
# for run in {1..5}; do
for ((run=1; run<=NUM_RUNS; run++)); do
    echo "---- Run $run ----" / "---- Rodada $run ----"
    for arg_index in {0..4}; do
            arg=$(get_argument $i $arg_index)
            echo "Running ${DESTINATIONS[i]} with argument index $arg_index (arg=$arg, Run $run)"
        for i in "${!DESTINATIONS[@]}"; do
            dest_dir=$(dirname "${DESTINATIONS[i]}")
            cd "$dest_dir"
            
            python3.12 "speedupy/setup_exp/setup.py" "${DESTINATIONS[i]}"
            # python3.12 "${DESTINATIONS[i]}" ${ARGUMENTS[i][arg_index]} --exec-mode no-cache | \
            python3.12 "${DESTINATIONS[i]}" $(get_argument $i $arg_index) --exec-mode no-cache | \

                tail -n1 | cut -d':' -f2 >> "$ROOT_PATH/outputs/$(basename ${DESTINATIONS[i]} .py)_no_cache.txt"
            
            rm -rf "$dest_dir/.speedupy/"
        done
    done
done


### MODE 2: intra-args - VERSÃO CORRIGIDA ###
echo "=== MODE 2: intra-args ===" / "=== MODO 2: intra-args ==="
# for run in {1..5}; do
for ((run=1; run<=NUM_RUNS; run++)); do
    echo "---- Run $run ----" / "---- Rodada $run ----"
    
    # Setup para TODOS experimentos ANTES de executar qualquer um
    for i in "${!DESTINATIONS[@]}"; do
        DEST_DIR=$(dirname "${DESTINATIONS[i]}")
        cd "$DEST_DIR"
        
        # Garante que o speedupy está no diretório
        [ -d "speedupy" ] || cp -r "$SOURCE_DIR" .
        
        # Setup para cada argumento
        for arg_index in {0..4}; do
            arg=$(get_argument $i $arg_index)
            echo "Running ${DESTINATIONS[i]} with argument index $arg_index (arg=$arg, Run $run)"
            export SPEEDUPY_CACHE_DIR=".speedupy_arg${arg_index}"
            echo "Running setup for ${DESTINATIONS[i]}, argument $arg_index" /
            # echo "Executando setup para ${DESTINATIONS[i]}, argumento $arg_index"
            python3.12 "speedupy/setup_exp/setup.py" "${DESTINATIONS[i]}"
        done
    done
    
    # Execução normal
    for arg_index in {0..4}; do
            arg=$(get_argument $i $arg_index)
            echo "Running ${DESTINATIONS[i]} with argument index $arg_index (arg=$arg, Run $run)"
        for i in "${!DESTINATIONS[@]}"; do
            DEST_DIR=$(dirname "${DESTINATIONS[i]}")
            cd "$DEST_DIR"
            export SPEEDUPY_CACHE_DIR=".speedupy_arg${arg_index}"
            
            arg=$(get_argument $i $arg_index)
            echo "Processing ${DESTINATIONS[i]} with $arg (Run $run)" /
            # echo "Processando ${DESTINATIONS[i]} com $arg (Rodada $run)"
            
            python3.12 "${DESTINATIONS[i]}" $arg --exec-mode manual | \
                tail -n1 | cut -d':' -f2 >> "$ROOT_PATH/outputs/$(basename ${DESTINATIONS[i]} .py)_intra_args.txt"
        done
    done
    
    # Limpeza
    for arg_index in {0..4}; do
            arg=$(get_argument $i $arg_index)
            echo "Running ${DESTINATIONS[i]} with argument index $arg_index (arg=$arg, Run $run)"
        for i in "${!DESTINATIONS[@]}"; do
            rm -rf "$(dirname "${DESTINATIONS[i]}")/.speedupy_arg${arg_index}"
        done
    done
done


### MODE 3: intra-exec ###
echo "=== MODE 3: intra-exec ===" / "=== MODO 3: intra-exec ==="
# for run in {1..5}; do
for ((run=1; run<=NUM_RUNS; run++)); do
    echo "---- Run $run ----" / "---- Rodada $run ----"
    for arg_index in {0..4}; do
            arg=$(get_argument $i $arg_index)
            echo "Running ${DESTINATIONS[i]} with argument index $arg_index (arg=$arg, Run $run)"
        for i in "${!DESTINATIONS[@]}"; do
            dest_dir=$(dirname "${DESTINATIONS[i]}")
            cd "$dest_dir"
            
            python3.12 "speedupy/setup_exp/setup.py" "${DESTINATIONS[i]}"
            # python3.12 "${DESTINATIONS[i]}" ${ARGUMENTS[i][arg_index]} --exec-mode manual | \
            python3.12 "${DESTINATIONS[i]}" $(get_argument $i $arg_index) --exec-mode manual | \
                tail -n1 | cut -d':' -f2 >> "$ROOT_PATH/outputs/$(basename ${DESTINATIONS[i]} .py)_intra_exec.txt"
            
            rm -rf "$dest_dir/.speedupy/"
        done
    done
done


### MODE 4: intra-exp ###
echo "=== MODE 4: intra-exp ===" / "=== MODO 4: intra-exp ==="
# for run in {1..5}; do
for ((run=1; run<=NUM_RUNS; run++)); do
    echo "---- Run $run ----" / "---- Rodada $run ----"
    
    # Setup all experiments
    for i in "${!DESTINATIONS[@]}"; do
        dest_dir=$(dirname "${DESTINATIONS[i]}")
        cd "$dest_dir"
        python3.12 "speedupy/setup_exp/setup.py" "${DESTINATIONS[i]}"
    done
    
    # Execute all arguments for each experiment
    for i in "${!DESTINATIONS[@]}"; do
        dest_dir=$(dirname "${DESTINATIONS[i]}")
        cd "$dest_dir"
        
        for arg_index in {0..4}; do
            arg=$(get_argument $i $arg_index)
            echo "Running ${DESTINATIONS[i]} with argument index $arg_index (arg=$arg, Run $run)"
            # python3.12 "${DESTINATIONS[i]}" ${ARGUMENTS[i][arg_index]} --exec-mode manual | \
            python3.12 "${DESTINATIONS[i]}" $(get_argument $i $arg_index) --exec-mode manual | \

                tail -n1 | cut -d':' -f2 >> "$ROOT_PATH/outputs/$(basename ${DESTINATIONS[i]} .py)_intra_exp.txt"
        done
    done
    
    # Clean all caches
    for i in "${!DESTINATIONS[@]}"; do
        rm -rf "$(dirname "${DESTINATIONS[i]}")/.speedupy"
    done
done


# Remove speedupy copiado para cada destino ao final de todas execuções
for dest in "${DESTINATIONS[@]}"; do
    dest_dir=$(dirname "$dest")
    rm -rf "$dest_dir/speedupy"
done


# Finalization / Finalização
cd "$ROOT_PATH"
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo "=== Results ===" / "=== Resultados ==="
ls -l outputs/*.txt 2>/dev/null || echo "No outputs found" / "Nenhum resultado encontrado"

echo -e "\nTotal execution time: / Tempo total de execução:"
printf "%02d:%02d:%02d (hh:mm:ss)\n" $((ELAPSED/3600)) $((ELAPSED%3600/60)) $((ELAPSED%60))
echo "=== COMPLETED ===" / "=== CONCLUÍDO ==="
