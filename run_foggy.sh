#!/usr/bin/env bash
set -euo pipefail

# ==== Edit these paths for your server ====
TRAIN_LIST="./data/VOC0712/train_foggy_mixed.txt"
TEST_LIST="./data/VOC0712/test_foggy.txt"
NAMES_FILE="./data/voc.names"
CLEAN_OR_RESUME_WEIGHTS="./results/YOLOV3_VOC_clean/best.pth.tar"
EXP_NAME="YOLOV3_VOC_foggy_mixed"
EPOCHS="10"
LATENT_DICT="./train_latent_dict.pickle"
# ==========================================

export TRAIN_LIST TEST_LIST NAMES_FILE CLEAN_OR_RESUME_WEIGHTS EXP_NAME EPOCHS

cd "$(dirname "$0")"

if [[ ! -f "$LATENT_DICT" ]]; then
  echo "Missing latent dictionary: $LATENT_DICT"
  exit 1
fi
cp "$LATENT_DICT" ./train_latent_dict.pickle

python - <<'PY'
from pathlib import Path
import yaml
import os

train_list = os.environ["TRAIN_LIST"]
test_list = os.environ["TEST_LIST"]
names_file = os.environ["NAMES_FILE"]
resume_weights = os.environ["CLEAN_OR_RESUME_WEIGHTS"]
exp_name = os.environ["EXP_NAME"]
epochs = int(os.environ["EPOCHS"])

voc_data = Path("data/voc.data")
voc_data.write_text(
    f"classes=20\ntrain={train_list}\ntest={test_list}\nnames={names_file}\n"
)

train_cfg_path = Path("configs/train/YOLOV3_VOC.yaml")
train_cfg = yaml.safe_load(train_cfg_path.read_text())
train_cfg["EXP_NAME"] = exp_name
train_cfg["DATASET_CONFIG_NAME"] = "./data/voc.data"
train_cfg["TRAIN"]["HYP"]["EPOCHS"] = epochs
train_cfg["TRAIN"]["CHECKPOINT"]["PRETRAINED_MODEL_WEIGHTS_PATH"] = ""
train_cfg["TRAIN"]["CHECKPOINT"]["RESUME_MODEL_WEIGHTS_PATH"] = resume_weights
train_cfg_path.write_text(yaml.safe_dump(train_cfg, sort_keys=False))
print("Configured data/voc.data and configs/train/YOLOV3_VOC.yaml")
PY

python train_adverse.py
