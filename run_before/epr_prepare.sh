#!/bin/bash
ROOT_PATH="$(pwd)"

cd "$ROOT_PATH/exps/epr/"
find . -type f ! -name "*.py" -delete

pip install matplotlib
python3.12 source.py 900 0.5
python3.12 station_py39.py SrcLeft.npy.gz
python3.12 station_py39.py SrcRight.npy.gz
cd $ROOT_PATH
