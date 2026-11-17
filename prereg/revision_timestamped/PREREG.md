# LENS-Net pre-registration (NCC 2027 paper)

Status: written 2026-09-24, before any LENS-Net feature was extracted or any model trained. The user
approved the design ("complete the evaluation for LENS-Net"). The file is frozen by the md5 recorded in
`logs/prereg_md5.txt`. Later changes go only into a "Deviations" section appended at the end, and the text
above it is never edited.

## 0. Question and gap
Violence detectors report 94-99 % on RWF-2000, Hockey and RLVS under random or official splits. In our audit,
24-56 % of test videos under a random 80/20 split have a near-duplicate in training. Our audited-split MAST-Net
scores 96.10 ROC-AUC on audited test but 52.45 on UCF-test and 76.74 on XD-test (3-seed means over
42/43/44, from `dataset_v2/eval/binary_hybrid_seed4*_cap8/metrics.json`). Question: does an architecture built to rely on semantic, motion-centred
evidence close this cross-corpus gap, without losing in-benchmark accuracy?

## 1. Architecture (fixed)
- **Encoder (frozen):** OpenCLIP `ViT-L-14`, `pretrained='openai'`, fp16. Its input is the 16 frames chosen by
  `mastnet_model.temporal_indices(32, 16)` from the cached 32-frame window (the same frames MAST-Net
  evaluates). Each frame is resized to 224x224 bilinear and given CLIP mean/std normalization.
- **Stored tokens per frame (17 x 768, fp16):** the projected CLS embedding, plus the 16x16 patch tokens after
  `ln_post`, average-pooled to a 4x4 grid and multiplied by the CLIP projection, so they lie in the same joint
  space as the CLS token.
- **(C2) Motion tokens:** m_t = z_t - z_{t-1}, with m_1 = 0.
- **(C3) Scene residual:** r_t = z_t - mean_t z_t (per token position).
- **Fusion:** Linear(2x768 -> 384) applied to [r_t ; m_t], then learned spatial (17) and temporal (16)
  embeddings. A 2-layer pre-LN transformer encoder (d=384, 4 heads, MLP 4x, dropout 0.1) runs over the 272
  tokens, followed by mean pooling and Linear(384 -> 768), giving u, which is L2-normalized.
- **(C4) Language-anchored cosine classifier:** logit_c = 30 * <u, w_c/||w_c||>. w_c is initialized to the
  normalized mean text embedding of the class prompts (Sec. 2). The loss adds 0.5 * sum_c ||w_c - w_c^0||^2.

## 2. Prompts (fixed, never tuned)
Each prompt is inserted into the templates "a video frame of {}." and "a surveillance camera image of {}."
- violence: "people fighting", "a violent fight", "people punching and kicking each other",
  "a brawl between people", "a physical assault on a person".
- non-violence: "people walking calmly", "people talking to each other", "a peaceful everyday scene",
  "people playing a sport without fighting", "a calm crowd of people".

## 3. Training (fixed)
- **Optimisation:** AdamW with lr 3e-4 and weight decay 0.05 (none on w or embeddings). Batch 128, 30 epochs,
  1 warm-up epoch then cosine decay, label smoothing 0.1, gradient clipping 1.0.
- **Sampling:** a weighted sampler with the frozen baseline's capped-hybrid weights (`strategy_weights(...,
  "hybrid", cap=0.05)`), with one epoch equal to the number of training windows.
- **Feature augmentation:** with p=0.5, the columns of the 4x4 grid are mirrored (the CLS token is left
  unchanged). Token dropout 0.1 is applied to whole (frame, token) positions.
- **Selection and threshold:** the best epoch is chosen by validation pooled ROC-AUC, as for the baseline. The
  threshold is `select_threshold` on validation.
- **Seeds:** 42, 43 and 44.

## 4. Configurations
| id | description |
|---|---|
| ZS | zero-shot CLIP: mean-over-frames CLS vs the text anchors, no training |
| LP | linear probe (cosine classifier with C4 init) on the mean-over-frames CLS |
| -M | full model without C2 (input [r_t ; 0]) |
| -S | full model without C3 (z_t in place of r_t) |
| -A | full model without C4 (random init of w, no anchor penalty) |
| LENS | full model |

## 5. Stage P: validation-only pilot and go/no-go (no test rows are read)
- **Models:** LENS and LP, seed 42 only, default settings, no tuning.
- **Pilot LODO:** for each held-out D in {HockeyFights, RLVS, RWF2000}, train on the LODO training rows
  (`dataset_v2/lodo/<D>/`), select on the LODO validation rows, and score **D's frozen-val rows only**
  (90 / 851 / 879 windows).
- **Reference:** MAST-Net LODO seed 42 (`dataset_v2/runs/lodo_<D>/.../test_predictions.csv`) scored on the
  identical rows.
- **Audited validation:** LENS trained on the frozen train split, scored on the frozen val split.
- **GO** only if both hold:
  1. mean pilot-LODO AUC(LENS) >= mean(MAST-Net) + 5.0 points;
  2. audited val AUC(LENS) >= 95.69 - 1.0.
- **NO-GO:** the NCC paper falls back to the audit paper, and LENS-Net is reported to the user as not supported.

## 6. Stage F: full evaluation (only after GO; everything below is fixed now)
- **F1 Audited split.** All configurations x 3 seeds, scored on audited test with the same metrics as
  `evaluate_v2.py` (pooled, per-dataset, macro, worst dataset, within-group). The paired comparison LENS vs
  MAST-Net (seeds 42-44) uses a component-cluster bootstrap with 2000 resamples.
- **F2 LODO.** Held-out BusViolence, HockeyFights, RLVS, RWF2000 and VID, 3 seeds. The primary rows are D's
  rows **excluding D's frozen-val rows**, because those were used in Stage P. MAST-Net (seed 42 only) is
  scored on identical rows.
- **F3 External.** XD-test and UCF-test with the exclusions of `evaluate_v2.py`, the threshold frozen from
  audited val, and a video-cluster bootstrap.
- **F4 Standard protocols (SOTA comparison).**
  - RWF-2000: the official train/val split (`extensions/public_split_audit/results/rwf_official_split_videos.csv`).
    Validation is 10 % of the official train videos (stratified, seed 0). The score is video-level accuracy
    (mean of window probabilities, threshold chosen on that validation set).
  - Hockey and RLVS: stratified 5-fold video-level cross-validation, with 10 % of each training fold as
    validation.
  - Published numbers are cited only from primary sources, with each source's protocol stated. The number of
    original videos missing from our benchmark is reported, and the leak rate of each protocol is reported
    from our audit.
- **F5 Retrained baseline under identical conditions.** VideoMAE-B (Kinetics-400 fine-tuned) is fine-tuned on
  the audited split, seed 42, and scored on F1/F3, if GPU time allows before 8 Oct 2026. If it is not run,
  the paper says so.
- **Primary claim, fixed now:** LENS vs MAST-Net on F3 (XD, UCF AUC) and the F2 mean AUC, as 3-seed means
  with bootstrap CIs. A claim is made only where the CI of the difference excludes 0.
- **Secondary claims:** F1, F4 and the ablations. A component is called "helpful" only if its paired
  3-seed CI excludes 0.

## 7. Integrity
- Frozen v1/v2 artifacts are never modified. All outputs go under `ncc2027/lensnet/` and `<home>/lensnet_features/`.
- The test split is not read before Stage F, and LODO held-out rows other than D-val are not read before Stage F.
- Every number in the paper traces to a JSON written by a script.

## Deviations
1. 2026-09-24 21:20. The inference batch size in `predict` was reduced from 512 to 64 after CUDA OOM on the
   shared GPU0. This is engineering only: it has no effect on predictions beyond floating-point order. The
   failed LENS pilot runs were deleted and rerun unchanged. The LP pilot runs had completed and were kept.
2. 2026-09-24 22:50. **LENS-Net v2 redesign**, written before any v2 feature or run exists and approved by the
   user. It was motivated only by Stage-P validation evidence. On HockeyFights held-out val rows, v1 LENS scored
   91.82 against 99.20 for LP; the v1 RLVS run's validation AUC fell from epoch 3 onward while its training loss
   dropped to 0.21. The pre-registered v1 pilot is completed and reported unchanged, and v1 becomes an ablation.
   - **Block 0 (anchor path, = LP):** u = normalized mean-over-frames of the normalized CLS. The logits are
     30*<u, w/||w||>, with w initialized from and penalized toward the class anchors, as in C4.
   - **Block 1, Prompt-Projected Semantic Signals (PPS):** every token (CLS + 4x4 grid) of every frame is L2-normalized
     and projected onto the 10 fixed prompt embeddings. Each prompt is the mean of its 2 templates, normalized, and the
     prompts are those of Sec. 2. This gives s in R^{16 x 17 x 10}. The spatial summaries per frame are the CLS
     similarity, the grid max and the grid top-2 mean. The temporal summaries of each are the mean, max, std and
     mean |s_t - s_{t-1}|. That makes 3 x 4 x 10 = 120 features, followed by BatchNorm1d(120), Linear(120,32), GELU,
     Dropout 0.1 and Linear(32,2), which give delta.
   - **Block 2, zero-initialized gate:** logits = anchor logits + g*delta, where g is a learnable scalar initialized to 0.
   - **Block 3, cross-corpus invariance (V-REx):** a loss term of 1.0 * Var over the source datasets present in the
     batch of their mean CE loss.
   - The training settings of Sec. 3 are unchanged (AdamW 3e-4, wd 0.05 except w/g, batch 128, 30 epochs, warm-up
     1 + cosine, label smoothing 0.1, hybrid sampler, selection by val pooled AUC, F1 threshold on val). The PPS
     features are flip-invariant, so grid mirroring is a no-op and is dropped.
   - **Candidates (exactly two):** V2a = Blocks 0+1+2 and V2b = Blocks 0+1+2+3.
   - **Selection rule:** seed 42, the Stage-P protocol (pilot-LODO on D's frozen-val rows for D in {Hockey, RLVS,
     RWF}). Choose the higher mean held-out-val AUC. If the two means are within 0.10, choose the higher audited val
     AUC. The chosen model is called **LENS-Net** in the paper. No other variant or hyperparameter is tried.
   - **Stage F** then runs as in Sec. 6 with LENS = the chosen v2. The ablations are LP (no PPS), -G (delta added with
     no gate), -T (temporal summaries reduced to the mean only), -Sp (CLS similarity only, no grid), the other
     candidate, and v1 (the original architecture). The primary claims of Sec. 6 are unchanged.
3. 2026-09-24 23:05. **Encoder misconfiguration found and corrected.** OpenCLIP `ViT-L-14` + `pretrained='openai'` had
   built the model with GELU, but the OpenAI weights require QuickGELU (open_clip printed a warning that was
   missed). On 64 frames, the per-frame cosine similarity between the misconfigured and correct image embeddings
   had mean 0.93 and min 0.88. All features, LP pilot runs and v1 pilot runs produced so far are therefore
   **invalid**. They are kept under `invalid_gelu/` and `<home>/lensnet_features_INVALID_gelu` for the record,
   and none of them may be reported. The encoder is now `ViT-L-14-quickgelu` + `pretrained='openai'`, the intended
   OpenAI CLIP ViT-L/14, and the extractor asserts QuickGELU. Stage P (v1 LENS + LP) and the v2 selection of
   deviation 2 are rerun on the corrected features with their rules unchanged. The Stage-P evidence that motivated
   deviation 2 came from the invalid features. The v2 design is kept as fixed, and v1 is still run and reported,
   so the v1-vs-v2 comparison is made on valid features.
4. 2026-09-25 12:10. **SOTA comparisons (tracks A and B)**, fixed before any run, at the user's request ("do both").
   Stage F had shown that LENS (V2b) does not reach the published in-domain accuracy (RWF official 86.52 % vs
   CUE-Net 94.00 %).
   - **A. Cross-dataset SOTA.** Two SOTA-class video backbones are fully fine-tuned under identical conditions:
     **VideoMAE-B** (`MCG-NJU/videomae-base-finetuned-kinetics`) and **Video Swin-T** (torchvision `swin3d_t`,
     KINETICS400_V1). The input is the v2 training transform (16 frames, 224, ImageNet normalization, crop/flip
     jitter) and the evaluation transform `clip_tensor_from_jpegs`, with a 2-class head. Training uses AdamW with lr
     5e-5 for the backbone and 5e-4 for the head, weight decay 0.05, 6 epochs, 1 warm-up epoch + cosine, micro-batch 4
     x accumulation 4, label smoothing 0.1, AMP and grad clip 1.0. Selection is the best val AUC epoch, and the
     threshold is val F1.
     - **A1 pooled:** audited train with the hybrid sampler, scored on audited test and on XD/UCF with the
       `evaluate_v2` exclusions.
     - **A2 single-source (the literature's cross-dataset setting):** RWF-2000 official train (`std_rwf`, uniform
       sampling), scored on RWF official test (video accuracy) and transferred to HockeyFights, RLVS, BusViolence
       and VID (all windows) and to XD/UCF. Target windows whose source unit has a verified near-duplicate edge to
       any `std_rwf` train unit are excluded, and the count is reported. LENS (V2b) and LP are scored on the same A2
       sets from their existing `std_rwf` runs.
     - **Seeds:** seed 42 is required. Seeds 43/44 are run if they finish by 2026-10-03, and the paper states how many
       seeds each row has.
     - Published cross-dataset numbers (e.g. ViolenceNet) are cited only after their protocol is checked in the
       primary source, and are labelled "different protocol" unless the train→test pair matches.
   - **B. In-domain RWF-2000 (LENS-FT).** OpenAI CLIP ViT-L/14 (quickgelu) tokens entering block 21 are cached for
     all RWF-2000 windows. Blocks 21-24, `ln_post` and `proj` are unfrozen (lr 1e-5), and the V2b head is placed on
     top (lr 3e-4), with the same PPS/anchor/gate/V-REx definitions. V-REx is inactive with a single source. Training
     is 10 epochs, batch 16 windows, weight decay 0.05, warm-up 1 + cosine, label smoothing 0.1, no augmentation, on
     `std_rwf` train, selected on `std_rwf` val (window AUC), with the threshold on val videos. The score is official
     test video accuracy. Seed 42 is required and 43/44 are run if time allows. Transfer of LENS-FT to XD/UCF is also
     reported, to show the in-domain vs transfer trade-off.
   - **Claim rule:** "exceeds published SOTA" is written only if the mean official-test accuracy over the available
     seeds exceeds the published figure *and* the paper reports the seed count and the binomial 95 % CI (398 test
     videos). Otherwise the result is reported as it is.
   - The GPU used is recorded per run.
5. 2026-09-25 12:25. **Third track-A baseline, R(2+1)D-18** (3D-CNN family), added at the user's request before any
   run: torchvision `r2plus1d_18`, KINETICS400_V1. It gets the same 16 frames as the other baselines, taken from the
   v2 transform after undoing the ImageNet normalization, bilinearly resized to its native 112x112 and normalized with
   the Kinetics mean/std of its weights. The fc layer is replaced by 2 classes. All other training, selection,
   evaluation and seed rules are those of deviation 4 (A1 and A2).
6. 2026-09-25 14:40. **LENS-M (motion-augmented LENS-Net)**, fixed before any motion feature is extracted or any fresh
   data is downloaded. The user approved it ("do it").
   - **Motivation, stated honestly:** in protocol A2 (seed 42), fine-tuned VideoMAE-B beat LENS on the
     BusViolence and VID transfer targets. **This design is therefore post hoc with respect to all previously used
     test data**, and its results on those data are labelled exploratory in the paper.
   - **Motion features:** frozen VideoMAE-B (`MCG-NJU/videomae-base-finetuned-kinetics`, Kinetics weights only,
     never trained on our data). The input is the same 16-frame evaluation clip as the baselines, and the feature is
     the mean-pooled final hidden state after `fc_norm` (768-d), extracted once for every window.
   - **Architecture (no tuning, no candidate selection):** logits = anchor logits + g_p*delta_PPS + g_m*delta_M.
     delta_PPS is exactly as in V2b. delta_M = Linear(32,2)(Dropout 0.1(GELU(Linear(768,32)(BatchNorm1d(768)(m))))),
     and g_m is a scalar initialized to 0. V-REx 1.0 as in V2b. All training settings are those of V2b.
   - **Reference configs:** MP = motion probe (the delta_M head alone as the logits, no anchor, no gate), and
     LENS (V2b) as it stands.
   - **Runs:** all protocols already used (audited + XD/UCF, LODO x5, std protocols, A2 transfer) x seeds 42-44.
     These are exploratory.
   - **Confirmatory evaluation (primary for LENS-M):** two fresh CCTV datasets never used before, the Surveillance
     Camera Fight dataset (Akti et al. 2019) and SCVD (Kaggle `toluwaniaremu/smartcity-cctv-violence-detection-dataset-scvd`;
     violence and weaponized violence = 1, normal = 0).
     - **Windowing:** 1.5-s windows as in `make_external_windows_v2` (32 frames, 256 px). Every window takes its
       video's label.
     - **Near-duplicate exclusion, fixed now:** a fresh window is excluded if the cosine similarity between its
       mean-over-frames CLIP CLS and any audited-train or std_rwf-train window is >= 0.95. The count is reported.
     - **Models scored:** LENS-M, LENS, LP, MP, VideoMAE-FT / Swin-T-FT / R(2+1)D-FT (A1 and A2, all available seeds)
       and MAST-Net (3 seeds). Each uses its own validation-derived threshold, and AUC is primary.
     - **Primary confirmatory claims:** (i) LENS-M vs LENS and (ii) LENS-M vs the best fine-tuned baseline, in AUC on
       each fresh dataset, as 3-seed means with a video-cluster bootstrap (2000 resamples). A claim is made only if
       the CI of the difference excludes 0.
     - If a dataset cannot be obtained or decoded, that is reported and nothing is substituted.
7. 2026-09-25 16:00. **Naming (not a new analysis).** Following the pre-specified confirmatory result of deviation 6
   (LENS-M > LENS on both fresh CCTV sets, CIs excluding 0), the user designated LENS-M as the final architecture.
   In the paper **"LENS-Net" = LENS-M** (semantic PPS stream + gated frozen-VideoMAE motion stream), and V2b is
   reported as the ablation "LENS-Net w/o motion". No result changes.
