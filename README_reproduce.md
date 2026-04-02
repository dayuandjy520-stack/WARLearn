# WARLearn Remote Linux Reproduction Guide

This guide is for your workflow: **Windows client + VS Code Remote-SSH + Linux GPU server**.

It keeps the official training/testing code intact and only adds small wrappers to make path edits centralized.

---

## 1) Server setup (once)

```bash
# on the Linux server
cd /path/to
git clone <YOUR_WARLEARN_REPO_URL> WARLearn
cd WARLearn

conda create -n warlearn_env python=3.10 -y
conda activate warlearn_env

pip install -r requirements.txt
pip install tensorboard
```

---

## 2) Prepare dataset lists and directory layout

Expected examples (you can place datasets elsewhere; just update paths in run scripts):

- `./data/VOC0712/train.txt`
- `./data/VOC0712/test.txt`
- `./data/VOC0712/train_foggy_mixed.txt`
- `./data/VOC0712/train_lowlight_mixed.txt`
- `./data/VOC0712/test_foggy.txt`
- `./data/VOC0712/test_lowlight.txt`
- `./data/RTTS/test.txt`
- `./data/ExDark/test.txt`

Generate VOC train/test txt annotations:

```bash
python scripts/voc_annotation.py \
  --data_path data/VOC0712 \
  --train_annotation data/VOC0712/train.txt \
  --test_annotation data/VOC0712/test.txt
```

Generate foggy images (writes to `data/VOC0712/images/test_foggy/` by current official script):

```bash
python scripts/data_make_foggy.py
```

Generate low-light images (writes to `data/VOC0712/images/train_lowlight/` by current official script):

```bash
python scripts/data_make_lowlight.py
```

Generate RTTS test txt list:

```bash
python scripts/voc_RTTS.py --data_path data/RTTS --test_annotation data/RTTS/test.txt
```

---

## 3) Train clean baseline

Edit variables at the top of `run_clean.sh` if needed, then run:

```bash
bash run_clean.sh
```

Output checkpoint default:

- `results/YOLOV3_VOC_clean/best.pth.tar`

---

## 4) Export latent dictionary (required for adverse training)

`train_adverse.py` expects `train_latent_dict.pickle` at repo root.

Use the project’s own note in `test.py` comments:

- point test loader to training list temporarily
- uncomment lines related to saving latent dict in `test.py`
- run `python test.py` once to produce `train_latent_dict.pickle`

(Official logic kept unchanged; this step follows the original repo workflow.)

---

## 5) Train foggy and low-light WARLearn models

Edit paths at top of each script if needed, then run:

```bash
bash run_foggy.sh
bash run_lowlight.sh
```

Expected outputs:

- `results/YOLOV3_VOC_foggy_mixed/best.pth.tar`
- `results/YOLOV3_VOC_lowlight_mixed/best.pth.tar`

---

## 6) Test on RTTS and ExDark

Edit weight/test-list vars at the top of scripts, then run:

```bash
bash run_test_rtts.sh
bash run_test_exdark.sh
```

Both wrappers update `data/voc.data` + `configs/test/YOLOV3_VOC.yaml` automatically before running `test.py`.

---

## 7) All configurable dataset/weight paths (single place)

### A) Primary files used by training/testing code

- `data/voc.data`
  - `train=...`
  - `test=...`
  - `names=...`
- `configs/train/YOLOV3_VOC.yaml`
  - `TRAIN.CHECKPOINT.PRETRAINED_MODEL_WEIGHTS_PATH`
  - `TRAIN.CHECKPOINT.RESUME_MODEL_WEIGHTS_PATH`
- `configs/test/YOLOV3_VOC.yaml`
  - `MODEL.YOLO.WEIGHTS_PATH`

### B) Wrapper scripts (recommended edit point)

- `run_clean.sh`
- `run_foggy.sh`
- `run_lowlight.sh`
- `run_test_rtts.sh`
- `run_test_exdark.sh`

These scripts are the intended place to edit dataset and checkpoint paths for your remote server.

---

## 8) One-shot command sequence (server)

```bash
cd /path/to/WARLearn
conda activate warlearn_env

# (optional) regenerate lists
python scripts/voc_annotation.py --data_path data/VOC0712 --train_annotation data/VOC0712/train.txt --test_annotation data/VOC0712/test.txt
python scripts/voc_RTTS.py --data_path data/RTTS --test_annotation data/RTTS/test.txt

# train
bash run_clean.sh
# generate train_latent_dict.pickle per Step 4
bash run_foggy.sh
bash run_lowlight.sh

# test
bash run_test_rtts.sh
bash run_test_exdark.sh
```
