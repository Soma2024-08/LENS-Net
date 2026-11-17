# LENS-Net journal extensions: pre-registration

Status: **FROZEN 2026-09-26** (md5 in `logs/prereg_md5.txt`); nothing had been run when it was frozen. The NCC draft
was finished and frozen first; on 2026-09-26 the user approved starting the journal work before the NCC submission. Any
later change is logged as a deviation, as in `PREREG.md`.

The NCC version of LENS-Net (= LENS-M, `PREREG.md` deviations 6-7) stays frozen. The journal reports it unchanged and adds
the extensions below as clearly labelled additions.

## 0. Why these extensions
Each extension targets a limitation the NCC paper itself states:
- E1: fusing motion costs 4.50 AUC points on XD-Violence (movie-style footage) under P1.
- E2: inference is costly, because two frozen encoders run on 16 frames each.
Both motivations come from test results that have already been seen. **Results on all previously used test sets (audited
test, XD, UCF, LODO, P3 targets, SCFD, SCVD) are therefore exploratory for E1/E2.** Confirmatory claims rest only on
the untouched set of Sec. 3.

## 1. E1: input-adaptive motion gate (LENS-AG)
- **Change (the only one):** LENS-M's scalar motion gate g_M becomes g_M(x) = g_M + w^T h(x), where
  h(x) = GELU(Linear(120+32 -> 16)([s_PPS(x); z_M(x)])). s_PPS is the 120-d PPS summary (already computed), and z_M is the
  32-d hidden layer of the motion MLP. g_M and w are initialised to 0, so at initialisation the model equals LENS-M at
  initialisation. It adds about 2.5k parameters.
- **No other change:** prompts, anchors, the PPS stream, V-REx (beta = 1), the optimiser, epochs, batch size, the sampler and
  the seeds (42-44) are exactly those of LENS-M.
- **No candidate search:** one configuration, fixed now. The width (16) and the inputs of h are not tuned.
- **Hypothesis H1:** LENS-AG >= LENS-M on the untouched set (Sec. 3). Exploratory expectation: a smaller XD-Violence loss relative
  to the semantic-only variant, with the fresh-CCTV gains retained.
- **Reported regardless of outcome**, including a result where LENS-AG is worse.

## 2. E2: efficient variants (LENS-Lite)
Pre-specified variants. All of them are reported; none is selected on test data:
- L1: 8 frames instead of 16 for both encoders (every second frame of the existing 16).
- L2: CLIP ViT-B/16 (`ViT-B-16-quickgelu`, openai; QuickGELU asserted, as in the NCC extraction) in place of ViT-L/14,
  with 16 frames. Prompts and head as in LENS-M, and the token projection sized to ViT-B/16's width.
- L3: L1 + L2.
- **Cost:** GFLOPs per window and latency, measured with `scripts/efficiency.py` on the same GPU as the NCC measurements.
- **Hypothesis H2 (non-inferiority):** a variant is "non-inferior" if the lower 95% CI bound of (variant - LENS-M) AUC is
  > -1.0 point on the untouched set. The -1.0 margin is fixed now.

## 3. Confirmation data (fixed now; no model has seen these datasets)
- **VioPeru** (Huillcen Baca et al., Sensors 24(2):668, 2024; github.com/hhuillcen/VioPeru): real municipal CCTV from
  Apurimac, Peru, which the authors describe as never released on YouTube or social media. Label 1 = `train/Fight` and `val/Fight`
  (140 videos). Label 0 = `train/NonFight`, `val/NonFight` and `false_positives_validation` (227 videos). All of these are
  used for evaluation only; the authors' train/val split is irrelevant here.
- **AIRTLab** (Bianculli et al., Data in Brief 33:106587, 2020; github.com/airtlab/A-Dataset-for-Automatic-Violence-Detection-in-Videos):
  350 staged clips in one room, seen by two cameras. Label 1 = `violent`, label 0 = `non-violent`. **Cluster = (label, clip
  number)**: `cam1/k` and `cam2/k` show the same action and are resampled together.
- **Licence:** both are released for research use without an explicit licence file. We use them for evaluation only,
  cite them, and redistribute nothing.
- **Windowing (as for SCFD/SCVD, `build_fresh.py`):** 1.5-s non-overlapping windows, at most 8 per video spread evenly,
  32 frames at 256 px. Every window takes its video's label.
- **Near-duplicate exclusion:** a window is removed if its mean-over-frames CLIP CLS cosine to any audited-train or
  std_rwf-train window is >= 0.95. Counts are reported.
- **Metric and statistics:** window-level ROC-AUC per dataset, as 3-seed means. Differences use seed-averaged predictions
  and a cluster bootstrap (2000 resamples; clusters are videos for VioPeru and action pairs for AIRTLab).
- **Scoring happens only after all E1/E2 runs have finished and their checkpoints are fixed.** Every model is scored once.
- **Claims:**
  - H1 (E1): LENS-AG minus LENS-M, per dataset. "Better" only if the 95% CI > 0. "Non-inferior" if the lower bound is > -1.0.
  - H2 (E2): each Lite variant minus LENS-M; "non-inferior" if the lower bound is > -1.0.
  - Secondary replication of the NCC result: LENS-M vs VideoMAE-B / Swin-T / R(2+1)D-18 FT (P1 checkpoints), same rule.
- Both datasets are small (367 and 350 videos), so the intervals will be wide. That is reported, not tuned around.

## 4. Resolved items
1. Confirmation datasets: Sec. 3.
2. GPU: the user approved LENS-Net journal work on both GPUs on 2026-09-26 (NMC-Net stays paused).
3. Order: E1 -> E2 -> error analysis / robustness (no training) -> LENS-FT.
4. Storage: /DATA1 is full, so the new data and features go under <home>/journal_data.

## 5. Robustness and error analysis (added 2026-09-26, before any run; no training)
Both test sets used below have already been scored clean, so everything in this section is **descriptive/exploratory**.
No model or threshold is changed.
- **Corruptions** are applied to the stored 256-px frames of each window, identically for every model, by one wrapper
  around the frame store. Corrupted frames are re-encoded losslessly (PNG), except for the JPEG condition.
  - blur: Gaussian, sigma = 1, 2, 3 px
  - low light: intensity x 0.5, 0.3, 0.15
  - noise: Gaussian, sigma = 8, 16, 32 (0-255 scale); rng seeded per window and frame, so identical for all models
  - JPEG: quality 30, 15, 5
  That makes 12 conditions plus clean.
- **Test sets:** the audited test split (1,844 windows; clusters = near-duplicate components) and VioPeru (1,101 windows;
  clusters = videos).
- **Models (P1 checkpoints, seeds 42-44):** LENS-Net (LENS-M), LENS-Net w/o motion (V2b), motion probe (MP),
  VideoMAE-B FT, Video Swin-T FT, R(2+1)D-18 FT and CNN-BiGRU. LENS heads use features recomputed from the corrupted frames
  with the same frozen CLIP ViT-L/14 and VideoMAE-B encoders.
- **Reported:**
  - window ROC-AUC per model x condition x set (seed means);
  - the mean over the 12 conditions, and the drop from clean;
  - paired LENS-Net minus VideoMAE-B FT per condition (seed-averaged predictions, cluster bootstrap, 2000 resamples, rng 0).
  There are 24 comparisons, so no single one is highlighted as a finding. The summary is the mean drop.
- **Error analysis (clean predictions that already exist, each model's validation threshold):**
  (a) XD-Violence and UCF-Crime per-category AUC and recall for LENS-Net vs VideoMAE-B FT;
  (b) AIRTLab: false-alarm rate per non-violent action class and miss rate per violent action class (from the dataset's
      action-class CSVs);
  (c) VioPeru: false-alarm rate on `false_positives_validation` vs the other non-violent videos;
  (d) examples chosen by a fixed rule: the 3 most confident false alarms and the 3 most confident misses per set for
      LENS-Net. Figures blur heads, as in the NCC paper.

## 6. TCSVT additions (added 2026-09-27, before any of these runs)
Target journal: IEEE TCSVT. Three experiments answer the questions a reviewer is most likely to raise. All test sets
available now have been used before, so every result below is **exploratory**, except the confirmatory test in 6B.
Settings are fixed here. The only selection allowed is the validation-only learning-rate choice in 6A.

### 6A. CLIP-based competitor: official VadCLIP under our protocol
- Code: official repository github.com/nwpu-zxr/VadCLIP (Apache-2.0), model `CLIPVAD` and losses (CLAS2 + CLASM + 1e-4 x
  text-orthogonality) unchanged. Only the input length and the label map are adapted.
- Input: the frozen per-frame CLIP image embeddings of our windows (16 frames; the "bag" of VadCLIP's MIL = one window;
  window label = bag label). Two backbones:
  - **A-B16 (native):** ViT-B/16 embeddings (512-d; VadCLIP's own backbone).
  - **A-L14 (matched):** ViT-L/14 embeddings (768-d; the same backbone as LENS-Net), using VadCLIP's clip loader with ViT-L/14.
- Fixed adaptations: visual_length 16; attn_window 4 (VadCLIP's 1:4 ratio of window to length); heads 1, layers 1,
  prompt prefix/postfix 10 (their defaults); label map {Normal: "normal", Violence: "violence"} (binary mode of their
  code); 10 epochs, AdamW, MultiStep x0.1 at epochs 3 and 6 (their defaults); batch 96; our capped-hybrid sampler.
- **Learning rate:** chosen from {1e-5 (their default), 1e-4, 3e-4} by validation AUC with seed 42 only, then fixed for seeds 43/44.
  This gives the baseline a validation-only selection that LENS-Net did not get.
- Checkpoint: best validation AUC. **Window score:** mean of the top-2 frame probabilities of the coarse branch
  (sigmoid(logits1)), i.e. the same top-k (k = int(16/16) + 1 = 2) as their MIL loss.
- Protocols: P1 and P3, seeds 42-44. Evaluated on the audited test, XD, UCF, SCFD, SCVD, VioPeru and AIRTLab.
  Paired LENS-Net minus VadCLIP on seed-averaged predictions (cluster bootstrap, 2000, rng 0).
- GVD: no public code or weights were found (checked 2026-09-27), so it is not reproduced; the paper says so.

### 6B. Prompt study
- **B1 sensitivity:** LENS-Net (LENS-M) retrained, unchanged, with two alternative prompt sets written now (5 + 5 each,
  same two templates):
  - `para` violent: "two people fighting each other", "a violent physical fight", "people hitting and kicking someone",
    "a group of people brawling", "a person being attacked"; non-violent: "people walking peacefully", "people having
    a conversation", "an ordinary everyday scene", "people playing sports calmly", "a quiet group of people".
  - `surv` violent: "a fight caught on a security camera", "people assaulting someone on CCTV", "a violent struggle
    between people", "people punching someone on the street", "an attack on a person in public"; non-violent:
    "people walking past a security camera", "people chatting on CCTV", "a normal day in a public place", "people
    queueing calmly", "a calm street scene on CCTV".
  - Reported: the spread of AUC across the three sets (original, para, surv) per test set, and paired differences.
- **B2 broad, event-specific set** (`broad`, 8 + 8), addressing the recall gap on weapons, riots and explosions:
  - violent: the 5 original + "a person shooting a gun at people", "a riot with people throwing objects",
    "a person attacking someone with a knife";
  - non-violent: the 5 original + "a person holding a tool while working", "a crowd cheering at a public event",
    "people dancing at a party".
  - The PPS dimension becomes 3 x 4 x 16 = 192; nothing else changes.
- Runs: P1 and P3, seeds 42-44, per set. Zero-shot per set.
- **Confirmatory test for B2 (only if new data are obtained):** CCTV-Fights (NTU ROSE Lab; requested by the user), windowed
  and deduplicated as in Sec. 3. Claim: `broad` minus original, "better" if CI > 0, "non-inferior" if the lower bound is > -1.
  Everything else in 6B is exploratory; the per-category recall on XD/UCF is compared descriptively.

### 6C. Video-language baseline and latency
- **X-CLIP** (HF `microsoft/xclip-base-patch32`, 8 frames at 224 px, Kinetics-400 video-text pretraining).
  - The 8 frames are every second frame of our 16, renormalised from ImageNet to CLIP statistics.
  - (i) **Zero-shot:** class score = mean similarity to the 5 violent minus the 5 non-violent original prompts.
  - (ii) **Full fine-tuning** under P1 (and P3 if time allows), seeds 42-44, with exactly the fine-tuning recipe of the
    existing video baselines (`train_video_baseline.py`), and a linear head on the video embedding.
- **Latency:** every model, batch 1 window, fp16, one GPU, 10 warm-up then the median of 100 runs, measured only
  when no other process uses that GPU. The GPU model and driver are reported.

### 6D. X-CLIP learning-rate selection (added 2026-09-28, before these runs)
- **Why:** with the shared recipe (body lr 5e-5), X-CLIP's validation AUC collapsed after epoch 1 (seed 42: 81.6 -> 71.9)
  and its test results were implausibly low. This was seen on validation logs *and* on test results, so the rerun is
  reported as a follow-up that gives X-CLIP a fair chance, not as a pre-planned result.
- **Selection (validation only):** body lr in {5e-6, 1e-5, 2e-5} (head lr = 10x body), seed 42, P1. The existing 5e-5 run
  is the fourth candidate. The lr with the best validation AUC is fixed, then run for seeds 43/44. Everything else is
  identical to the shared recipe.
- **Reporting:** both the shared-recipe and the selected-lr results are reported; the comparison with LENS-Net uses the
  selected-lr runs.

## 7. CCTV-Fights confirmation (added 2026-09-30, before any window, feature or prediction exists)
- **Data:** CCTV-Fights (Perez, Kot and Rocha, ICASSP 2019; ROSE Lab, NTU), obtained after an access request and
  downloaded on 2026-09-30: 1,000 videos in the original format and `groundtruth.json` (md5 808493308485c03922b96fc78fc74b08), which gives a
  source for each video (CCTV 280, Mobile 707, Car 4, Other 9), an official subset (training/validation/testing) and 2,414
  temporal `Fight` segments. **Evaluation only**: no model is trained, tuned, calibrated or selected on it. Nothing is
  redistributed.
- **Windows (as for XD-Violence/UCF-Crime):** a 1.5-s non-overlapping grid over each video. Positive = at least 50% of
  the window lies inside a Fight segment. Negative = the window lies outside every Fight segment by at least 1.0 s (the
  UCF guard). All other windows are ignored. Per video, at most 8 windows: up to 4 positives and 4 negatives, each spread
  evenly over the video; if one class has fewer than 4, the other may fill the remaining places. 32 frames at 256 px,
  JPEG q92 (frame store `cfights`).
- **Near-duplicate exclusion:** the Sec. 3 rule (mean CLIP CLS cosine to any audited-train or std_rwf-train window
  >= 0.95 removes the window). Counts are reported per source.
- **Sets:** primary = all **CCTV** videos (source = CCTV, every official subset, 280 videos). Secondary = all 1,000
  videos, and the official *testing* subset (250 videos) for comparison with published numbers (which were trained on
  CCTV-Fights, so the comparison is descriptive only).
- **Models (checkpoints already fixed; each is scored once):** LENS-M (P1, P3), LENS-AG, LENS-Lite L1-L3, LENS-M w/o
  motion, CLIP zero-shot; fine-tuned VideoMAE-B, Video Swin-T, R(2+1)D-18 and X-CLIP (selected lr 5e-6) under P1 (A1) and
  P3 (A2) where they exist; official VadCLIP (L14, B16; lr 1e-4); CNN-BiGRU. Three seeds each.
- **Metric and statistics:** window-level ROC-AUC, 3-seed means +- SD. Paired differences on seed-averaged predictions
  with a video-cluster bootstrap (2,000 resamples, rng 0).
- **Claims (primary set = CCTV):** LENS-M (P1) minus each P1 comparator (VideoMAE-B, Swin-T, R(2+1)D-18, X-CLIP, VadCLIP-L14),
  and LENS-M (P3) minus each A2 comparator. "Better" only if the 95% CI is above 0; "worse" if below 0; otherwise "no
  difference shown". Every result is reported, whatever its direction; no subset is added or dropped after scoring.

## 8. Standard frame-level protocol on XD-Violence and UCF-Crime (added 2026-09-30, before any frame-level score exists)
- **Why:** video anomaly-detection papers report frame-level ROC-AUC on the full UCF-Crime test set and frame-level AP
  on the full XD-Violence test set. Our window-level results cannot be placed in those tables. No model here was
  trained on either dataset, so the setting is cross-dataset (trained on the five source corpora only).
- **Test sets:** the official test lists. XD-Violence: 800 test videos (799 are on disk; the missing normal video is
  reported). UCF-Crime: 290 test videos; the 150 normal test videos missing from our copy are taken from a Kaggle
  mirror (`thelazygenius/ucfcrime-only-normal-videos`), and their file sizes match an independent full mirror.
- **Ground truth:** the official temporal annotations (XD frame indices at 24 fps; UCF frame indices at 30 fps; UCF -1
  marks no second interval). Every frame of every test video is labelled 1 inside an annotated interval, else 0.
- **Scoring (no post-processing):** each video is cut into consecutive non-overlapping 1.5-s windows from frame 0; if
  frames remain, one extra window is aligned to the video end. Each window is scored exactly as in all other
  evaluations (same frame sampling, 32 frames at 256 px, same model inputs). Each frame takes the score of the window that
  covers it (for the end-aligned window, only its previously uncovered frames). No smoothing, no thresholds.
- **Metrics:** primary: UCF-Crime frame-level ROC-AUC (all 290 videos, every anomaly class positive) and XD-Violence
  frame-level AP (all test videos). Secondary: XD frame-level ROC-AUC; UCF AUC restricted to the normal videos plus
  the violent classes (Abuse, Assault, Fighting, Robbery, Shooting), because the models detect violence and UCF-Crime
  also contains non-violent anomalies (theft, arson, road accidents); and both metrics after removing the 9 external
  videos marked `same_footage` in the contamination review.
- **Models (checkpoints fixed; scored once; P1 only, because this protocol targets the published tables):**
  LENS-Net (LENS-M), LENS-Lite L3, LENS-Net w/o motion, CLIP zero-shot, VideoMAE-B / Video Swin-T / R(2+1)D-18 /
  X-CLIP (lr 5e-6) fine-tuned (A1), official VadCLIP (L14, lr 1e-4), CNN-BiGRU. Three seeds; mean +- SD.
- **Statistics:** paired differences LENS-Net minus each comparator on seed-averaged frame scores, video-cluster
  bootstrap (2,000 resamples, rng 0); better = CI > 0, worse = CI < 0.
- **Literature comparison (descriptive only):** published frame-level numbers of training-free / zero-shot methods
  (e.g., LAVAD) and of weakly supervised methods trained on these datasets are quoted from their papers, with the
  difference in training data stated. No claim of significance is made against published numbers.
- **Storage:** frames are written and deleted in chunks (the full test sets would need about 60 GB); features and
  per-window predictions are kept.

- **Addendum (2026-10-01, after the Sec. 8 results were seen; exploratory):** the Sec. 8 results showed that the motion
  stream lowers XD-Violence AP by 17 points. LENS-AG (E1, checkpoints fixed since 2026-09-26) was therefore also scored
  on this protocol, with the identical procedure. Because it was added after seeing results, it is reported as
  exploratory and carries no claim flag.

## 9. Footage-aware motion gate, LENS-FG (added 2026-10-01, before any LENS-FG training or any confirmation data)
- **Why:** Sec. 3, 7 and 8 showed that the motion stream helps on surveillance footage and costs accuracy on edited
  footage (XD-Violence frame AP 57.8 with motion vs 74.5 without). The learned gate of E1 cannot learn this from
  source corpora that contain almost no edited footage.
- **What was seen before this section was written (disclosed):** all results of Sec. 1-8, and one training-free
  feasibility check of the footage-type score below on the existing sets (share of windows with p_raw > 0.5: CCTV sets
  96-100%, XD-Violence 28-29%, Hockey 9%, RLVS 42%, AIRTLab 99.7%). All existing test sets are therefore
  **development data** for LENS-FG; results on them are exploratory.
- **Footage-type prompts (fixed; written before the feasibility check; text "<prompt>." encoded by the frozen CLIP text encoder):**
  raw: "footage from a surveillance camera", "CCTV footage of a public place", "a security camera recording",
  "a video filmed on a mobile phone by a bystander"; edited: "a scene from a movie", "a television sports broadcast",
  "a television news broadcast", "a professionally filmed and edited video", "a video game recording",
  "an animated cartoon".
- **Gate:** with u the normalised clip embedding of the anchor path and f_j the normalised prompt embeddings,
  p_raw(x) = sum over raw prompts of softmax_j(100 <u, f_j>). **LENS-FG:** logits = l_A + g_P d_P + g_M p_raw(x) d_M.
  No trained parameter is added (31,926 as LENS-Net). Training is identical to LENS-Net (same loss, optimiser,
  schedule, sampler, epoch selection); seeds 42-44; P1 (audited) and P3 (std_rwf).
- **LENS-FG-post (secondary):** the unchanged LENS-Net checkpoints with the same gate applied at inference only.
- **Development evaluation (exploratory):** every existing set, window level and the Sec. 8 frame-level protocol.
- **Confirmation data (no model of this study has been trained or scored on them):**
  - **Movies** (Bermejo Nievas et al., CAIP 2011; Kaggle `naveenk903/movies-fight-detection-dataset`): 200 clips, fights
    from films and non-fight clips from action-recognition datasets. It was excluded from the source benchmark and never
    used for training. Windows as in Sec. 3 (1.5-s grid, at most 8 per video, video label). Cluster = video.
    Known limitation, stated now: fight and non-fight clips come from different kinds of footage, so results are also
    reported per class (mean score of fight and of non-fight windows).
  - **UBI-Fights** (Degardin and Proenca, 2020; Kaggle mirror `smmohiuddinkhanshiam/ubi-fights`): 1,000 surveillance
    videos with frame-level fight annotations. Windows as in Sec. 7 (positive if >= 50% inside a fight, negative if
    >= 1.0 s outside every fight, at most 4 of each class per video, the other class filling free places). Cluster = video.
  - Near-duplicate exclusion as in Sec. 3. Every model is scored once: LENS-FG (P1, P3), LENS-FG-post, LENS-Net (P1, P3),
    LENS-Net w/o motion, LENS-AG, CLIP zero-shot, the fine-tuned baselines (A1; X-CLIP lr 5e-6), VadCLIP-L14, CNN-BiGRU.
- **Claims (P1, window ROC-AUC, seed-averaged predictions, video-cluster bootstrap, 2,000 resamples, 95% CI):**
  - C1 (edited footage): LENS-FG - LENS-Net on Movies: CI > 0.
  - C2 (surveillance): LENS-FG - LENS-Net on UBI-Fights: lower bound > -1.0 (non-inferior).
  - C3 (motion kept where it helps): LENS-FG - LENS-Net w/o motion on UBI-Fights: CI > 0.
  - C4: LENS-FG - LENS-Net w/o motion on Movies: lower bound > -1.0.
  - "Confirmed" only if C1-C4 all hold. Otherwise each claim is reported as it fell. The same four comparisons are
    reported for LENS-FG-post and for P3 as secondary results.
- LENS-Net (LENS-M) remains the NCC model; LENS-FG is a journal extension whatever the outcome.

## 10. Anchor fusion, LENS-Net-A (added 2026-10-08, while the confirmation videos were downloading and before any was inspected or scored)
- **Why:** over the nine unseen sets of Sec. 3-9 the anchored CLIP probe (LP) had the highest mean AUC and LENS-Net
  the best worst case. An exploratory check on those (already seen) sets, with existing checkpoints and no training,
  showed that averaging the two models' probabilities gave mean 87.61 and minimum 77.67 (LENS-Net 84.59 / 74.68,
  LP 86.11 / 72.38), whereas ordinary two-model ensembles did not (two LENS-Net seeds 84.77; two probe seeds 86.13;
  logs/anchor_safe_exploratory.json). All nine sets are therefore development data for this section.
- **Model (no parameter is chosen):** p_A(x) = (p_LP(x) + p_LENS-Net(x)) / 2, with the P1 checkpoints of the same seed
  (42-44); 33,462 trained parameters in total; the same frozen features, so inference cost equals LENS-Net's.
  Secondary: the same average of the P3 checkpoints.
- **Confirmation data (never used by any model of this study):**
  - **XD-Violence training subset** (Wu et al., ECCV 2020; Hugging Face mirror jherng/xd-violence): 300 violent
    (labels B1 fighting, B2 shooting, B5 abuse only) and 300 normal (label A) training videos, drawn by a seeded rule
    (seed 20261008) from the training videos that were never copied into any folder of this project
    (conf3/xd_train_selection.csv, md5 190197e9bb96c454f65f3eb474b94f34). Video-level labels.
  - **AIE** (da Silva and Pereira, J. Brazilian Computer Society 30(1), 2024; Kaggle arnaldovitor/aie-dataset): indoor
    CCTV clips; label 1 = assault, 0 = non-assault; "alert" clips are excluded as ambiguous.
- **Windows and scores:** every video/clip is cut into consecutive non-overlapping 1.5-s windows from frame 0 plus one
  end-aligned window (Sec. 8 rule; at most 64 windows per video, spread evenly if more), 32 frames at 256 px. Windows
  that are near-duplicates of training windows (Sec. 3 rule) are removed; a video with no remaining window is
  dropped and counted. **Video score = maximum window probability** (primary); mean of the top three (secondary).
- **Metric and statistics:** video-level ROC-AUC; seed-averaged probabilities; cluster bootstrap (2,000 resamples,
  rng 0). Clusters: XD source (file-name prefix before "__", i.e. the film or video id); AIE source footage as given by
  the dataset's file names (if the names carry no source id, each clip is its own cluster; reported).
- **Claims (P1; all four must hold for "confirmed"):**
  - K1: LENS-Net-A - LENS-Net on XD-train: CI > 0.
  - K2: LENS-Net-A - LENS-Net on AIE: lower bound > -1.0.
  - K3: LENS-Net-A - CLIP probe on XD-train: lower bound > -1.0.
  - K4: LENS-Net-A - CLIP probe on AIE: CI > 0.
- **Also scored once (descriptive):** LENS-Net w/o motion, motion probe, CLIP zero-shot, LENS-FG, and VadCLIP-L14
  (P1, lr 1e-4). Fine-tuned video baselines are not scored on these sets.
- LENS-Net remains the NCC model whatever the outcome; LENS-Net-A would be reported as a journal extension.

## Deviations
1. 2026-09-26, before any E2 run. **L1/L3 frame count applies to CLIP only.** VideoMAE-B's Kinetics checkpoint has
   fixed position embeddings for 16 frames (8 temporal tubelets). An 8-frame input would require changing the
   pretrained model. So in L1 and L3 the CLIP stream uses 8 frames (every second of the 16) and the motion stream keeps its
   16-frame input. The cost reported for L1/L3 reflects this. Nothing else changes.
2. 2026-09-26, recorded after the E2 cost measurement. **Cost script.** The E2 GFLOPs were measured with
   `scripts/efficiency_journal.py`, an extension of `scripts/efficiency.py` using the same method (torch FlopCounterMode, CPU fp32).
   It reproduces the NCC LENS-Net value exactly (1,930.7 GFLOPs/window). Latency was not measured, because both GPUs were in use.
3. 2026-09-27/28, recorded before any Sec. 6 result was looked at. **Data loss and re-extraction.** An `rm -rf *` in
   <home> (not part of this project's scripts) deleted the extracted features and the fresh/confirmation video and
   frame folders. All results, checkpoints and predictions were on /DATA1 and are unaffected.
   - Everything was rebuilt under <project-root>/ncc2027/{data,features}. The rebuilt window
     tables are identical to the saved ones.
   - To save space, features are written by `scripts/extract_compact.py` (the same arithmetic as extract_clip_tokens +
     make_compact, without keeping the full token arrays).
   - Verification against saved predictions: ViT-L/14 (16 and 8 frames) max |diff| 3e-8. ViT-B/16 max |diff| 1.8e-4,
     because the original B16 extraction used batch 16 and the rebuild used batch 8 (fp16 GPU arithmetic); the effect on AUC
     is negligible. Sec. 4 item 4 (storage under /home) is superseded.
   - The first prompt-study launch (6B) crashed before training, because the motion features were not yet written; it was
     relaunched unchanged.
4. 2026-09-28. **Latency GPU state.** Both GPUs were shared. Latency was measured on GPU 0 (Quadro RTX 5000), where another
   user's process held 7.8 GB of memory but used 0% compute before and after the measurement. The plan asked for no other
   process on the GPU; this is as close as the shared machine allowed. The full measurement was run twice (the first run
   omitted L2), and the second, complete run is reported.
