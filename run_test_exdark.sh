#!/usr/bin/env bash
set -euo pipefail

# ==== Edit these paths for your server ====
TEST_LIST="./data/ExDark/test.txt"
NAMES_FILE="./data/voc.names"
WEIGHTS_PATH="./results/YOLOV3_VOC_lowlight_mixed/best.pth.tar"
# ==========================================

export TEST_LIST NAMES_FILE WEIGHTS_PATH

cd "$(dirname "$0")"

python - <<'PY'
from pathlib import Path
import yaml
import os

test_list = os.environ["TEST_LIST"]
names_file = os.environ["NAMES_FILE"]
weights_path = os.environ["WEIGHTS_PATH"]

voc_data = Path("data/voc.data")
current = voc_data.read_text().splitlines()
train_line = next((x for x in current if x.startswith("train=")), "train=./data/VOC0712/train.txt")
voc_data.write_text(
    f"classes=20\n{train_line}\ntest={test_list}\nnames={names_file}\n"
)

test_cfg_path = Path("configs/test/YOLOV3_VOC.yaml")
test_cfg = yaml.safe_load(test_cfg_path.read_text())
test_cfg["DATASET_CONFIG_NAME"] = "./data/voc.data"
test_cfg["MODEL"]["YOLO"]["WEIGHTS_PATH"] = weights_path
test_cfg_path.write_text(yaml.safe_dump(test_cfg, sort_keys=False))
print("Configured data/voc.data and configs/test/YOLOV3_VOC.yaml")
PY

python test.py
