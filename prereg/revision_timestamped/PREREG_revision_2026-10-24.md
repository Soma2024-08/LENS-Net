# Revision analyses (reviewer response), fixed 2026-10-15 before any of them was run

Context: two reviews of the journal draft (R1-R3 and major/minor comments). All analyses below re-use saved
per-window predictions (no retraining), except B7, which trains additional seeds of the frozen-feature heads only.
Every result is reported whatever its outcome. All test sets involved have been seen before; the purpose is to
re-test existing claims with better statistics, not to select models.

## B1 Seed-aware paired test (reviewer 1, R2.3)
Statistic: difference of per-seed-mean ROC-AUC, Delta = mean_r AUC(A_r) - mean_r AUC(B_r) (the quantity the tables
report). Hierarchical bootstrap, 2000 resamples, numpy rng 0: in each resample, (i) clusters are drawn with
replacement (same clusters as the paper), (ii) for each model independently, seeds are drawn with replacement from
its available seeds; Delta_b = mean over drawn seeds of AUC on the resampled windows. 95% percentile interval.
The old seed-averaged-score test is reported alongside. Comparisons: LENS-Net and LENS-Net-A vs every comparator
of Table V on the audited test split and the nine unseen sets.

## B2 Primary claims and multiplicity (reviewer 1, R2.4; reviewer 2, item 7)
The reframed paper makes exactly these confirmatory-style claims; every other comparison is labelled descriptive.
Holm-Bonferroni at family-wise alpha = 0.05 over the family below, with one-sided bootstrap p-values from B1
(p = (1 + #{Delta_b <= delta0}) / (B + 1); two-sided claims use 2 x min of the two tails):
  H1  CLIP probe - VideoMAE-B FT, mean over the nine unseen sets, two-sided (delta0 = 0)
  H2  CLIP probe - LENS-Net, nine-set mean, two-sided
  H3  LENS-Net - VideoMAE-B FT, nine-set mean, two-sided
  H4  LENS-Net - w/o motion on SCFD (fresh CCTV), better (delta0 = 0)
  H5  LENS-Net - w/o motion on SCVD (fresh CCTV), better
  K1-K4 anchor-fusion confirmation exactly as pre-registered (Sec. 10 of PREREG_journal): K1, K4 better (delta0 = 0);
        K2, K3 non-inferior (delta0 = -1), primary score (max window probability per video).
Nine-set means: clusters are resampled independently within each set; the per-set Deltas are averaged with equal
weight. These claims were declared after all results were known; Holm controls multiplicity, not selection, and the
paper says so.

## B3 With versus without test-side near-duplicate filtering (reviewer 1, R3.1; reviewer 2, item 5)
For every unseen set with removals (XD, UCF via excluded_contamination; SCFD, SCVD, CCTV-F, UBI-Fights via the CLIP
cosine rule), report every model's AUC on the filtered and on the unfiltered window set, the Kendall tau between the
two model rankings, and LENS-Net / LENS-Net-A minus each comparator under both.

## B4 Near-duplicate graph diagnostics (reviewer 1, R3.2; minor 10, 14)
Component-size distribution (windows, videos), composition of the largest component, whether any component spans
corpora that appear in a test split, and the statement (verified in code) that leak rates count direct verified
edges only. Stage counts and thresholds of the three-stage audit from the frozen audit outputs. Precision of the
verified stage on the existing visually labelled calibration pairs; a larger labelled sample (>= 500 pairs) is
prepared for human labelling and reported when labelled.

## B5 Symmetric fusion control (reviewer 2, item 6)
Every comparator averaged with the CLIP probe (same seed index), nine-set mean and minimum, next to LENS-Net-A.

## B6 Ambiguous windows (reviewer 1, M5)
Number of windows discarded by the 50% / 1 s rule per dataset; where ambiguous windows exist with scores, the model
ranking when they are kept as negatives.

## B7 More seeds for the frozen-feature heads (reviewer 2, item 7)
Seeds 45-51 (ten in total) for LENS-Net, CLIP probe, w/o motion and motion probe under P1, identical recipe; scored on
the audited test split and the nine unseen sets (and the anchor-fusion confirmation sets if their compact features
exist). Tables keep the three-seed values for comparability with the baselines and add the ten-seed means and SDs.
Baselines keep three seeds (GPU cost); B1 accounts for seed variance.

# Part C: new experiments requested by the reviewers, fixed 2026-10-16 before any of them was run
All results are reported whatever their outcome. Seeds 42-44 unless stated; GPU recipe = the shared fine-tuning
recipe of the baselines (AdamW, body lr 5e-5, head 10x, 6 epochs, batch 4 x accumulation 4, label smoothing 0.1,
best-validation-AUC epoch) unless stated.

## C1 Random versus source-controlled splits (reviewer 1, R3.3)
Corpora: RWF-2000 and Hockey Fights, all windows of the source manifest. Two video-level splits per corpus, seed 42,
stratified by label, test = 20% of videos, validation = 10% of videos, the rest train:
  R (random): videos drawn at random;  S (source-controlled): whole same-source components drawn at random.
Models: VideoMAE-B FT and R(2+1)D-18 FT (GPU, shared recipe), CLIP probe and LENS-Net (frozen features, CPU); three
seeds each. The CNN-BiGRU is added if its trainer accepts the split files without code changes to the model.
Outcomes: (O1) own-test window ROC-AUC and video accuracy at the validation threshold, R minus S (independent test
sets; cluster bootstrap over components of each test set, seeds resampled); (O2) within the R test set, AUC of test
videos linked to training videos versus unlinked ones; (O3) transfer to XD-Violence and UCF-Crime (external windows)
of R-trained versus S-trained models, seed-aware paired test. All C1 comparisons are descriptive (no Holm family);
the direction is not predicted.

## C2 Frozen-encoder pre-training control (reviewer 1, R3.4)
Replace CLIP ViT-L/14 (OpenAI) by OpenCLIP ViT-L/14 laion2b_s32b_b82k (public training data), everything else
identical: re-extract the CLIP tokens and compact features for the source benchmark and the nine unseen test sets,
retrain the CLIP probe, the model without motion and LENS-Net (seeds 42-44), score the nine unseen sets. Report the
per-set and nine-set mean AUCs and the seed-aware test of (LAION probe - VideoMAE-B FT) and (LAION LENS-Net -
VideoMAE-B FT) on the nine-set mean, and of LAION vs OpenAI versions of each model. Interpretation fixed now: if the
LAION probe also transfers better than VideoMAE-B, the main finding does not depend on OpenAI's undisclosed data.

## C3 Domain-generalisation baselines on frozen features (reviewer 1, M3; reviewer 2, items 6, 10)
On the same frozen features and heads as LENS-Net: (a) V-REx weight beta in {0, 0.3, 1, 3, 10}; (b) IRM penalty
(IRMv1, weight 1 after one warm-up epoch) and (c) GroupDRO (eta = 0.01) over source corpora, each replacing V-REx,
for LENS-Net and for the CLIP probe; seeds 42-44; nine-set mean, minimum and per-set AUC; descriptive.

## C4 Equal learning-rate search for the fine-tuned backbones (reviewer 1, M2; reviewer 2, item 6)
VideoMAE-B, Video Swin-T and R(2+1)D-18 under P1: body lr in {2e-5, 5e-5 (existing runs), 1.25e-4}, seed 42,
selection by validation ROC-AUC only. If the selected lr differs from 5e-5, seeds 43-44 are trained at it and the
tuned model replaces the shared-recipe one in a re-run of claims H1 and H3 (reported next to the original).

## C5 Compute-matched LoRA baseline (reviewer 1, M1)
VideoMAE-B with LoRA (rank 8, alpha 16) on the query and value projections of every attention layer plus a linear
head; backbone otherwise frozen. lr in {1e-4, 5e-4} chosen on validation with seed 42, then seeds 43-44; shared recipe
otherwise; P1; nine unseen sets.

## C6 Further untouched confirmation of anchor fusion (reviewer 1, R2.1/R2.4)
A second fixed, seeded sample (seed 2026) of 600 XD-Violence training videos, disjoint from the first sample: 300
violent (fighting, shooting or abuse) and 300 normal, same mirror, same scoring (dense windows, maximum window
probability), clusters = source film or channel. No model has been trained or scored on these videos. Claims K1-K4
are re-tested with their pre-registered margins and the seed-aware test, Holm-corrected over the four.

## D1 Human validation of the overlap criteria (reviewer 1, R3.1)
A stratified sample of 500 pairs: 150 verified same-source edges, 100 candidates rejected by verification, 50 random
cross-video pairs of the source benchmark, 150 unseen-set windows removed by the cosine rule (>= 0.95) with their
nearest training window, 50 unseen-set windows at cosine 0.90-0.95 (kept). Each pair is shown as two frame strips;
the labeller (blind to stratum and score) answers: same clip / same camera or scene / different source. Precision
and recall of each criterion are estimated with stratum weights. Labelling is done by the authors.

## C6 deviation (recorded 2026-10-16, before any download or scoring)
The eligible pool of the XD-Violence training mirror has 463 violent videos (fighting, shooting, abuse), of which the
first sample used 300; only 163 remain. The second sample is therefore all 163 remaining violent videos plus 163
normal videos drawn with seed 2026 from the 1,047 unused normal ones (326 videos). Everything else in C6 is unchanged;
the smaller sample widens the intervals.
C6 clarification (recorded before scoring): sample B contains XD-Violence videos only, so it re-tests the two
XD-Violence claims, K1 (LENS-Net-A better than LENS-Net) and K3 (LENS-Net-A non-inferior to the CLIP probe), with Holm
correction over these two; K2 and K4 concern AIE, for which no further untouched data exist.

## C7 Stricter test-side near-duplicate filter (prompted by D1; recorded 2026-10-16, before any computation)
D1 found that 10 of 10 labelled Movies/UBI-Fights windows at cosine 0.90-0.95 to their nearest training window were
judged same source by the labeller. The existing window-level rule (exclude a test window if its maximum cosine to any
training window is >= 0.95) is therefore repeated at >= 0.90 for the seven unseen sets that carry this score (SCFD,
SCVD, VioPeru, AIRTLab, CCTV-F, Movies, UBI-Fights); XD-Violence and UCF-Crime keep their own contamination rule.
Reported: windows removed per set; every model's AUC per set at 0.95 and at 0.90; Kendall tau between the two model
rankings per set; and claims H1-H3 (nine-set mean, seed-aware test) re-computed at 0.90 next to the original.
Interpretation fixed now: if the H1-H3 decisions are unchanged, the 0.95 rule is retained as primary and 0.90 is
reported as a sensitivity analysis; if any decision changes, both are reported and the change is stated in the
abstract and the conclusions.

## D1 deviation (recorded 2026-10-16, after labelling, before this note was used in any text)
Only the first 200 of the 500 shuffled pairs were labelled (all five strata are represented: 59 verified, 44 rejected,
17 random, 61 removed, 19 kept at 0.90-0.95). One author labelled them through a web form. After a consistency check
of 12 pairs by a second reader, the labeller revisited 5 flagged pairs and changed 4 (hockey pairs from different
games, "same camera or scene" -> "different source"); both the original and the revised labels are kept
(review/human_labels_round1.csv, review/human_labels_final.csv) and the revised ones are reported. Recall is estimated
among the audit's candidate pairs with stratum weights; precision and recall of the cosine rule are not estimated with
weights because the population of windows below 0.90 was not sampled.

## Part E (recorded 2026-10-19, before any of these runs or analyses; requested items R1 M1, M3, M5, rev. 2 item 10, R3)
E1 Fine-tuned CLIP baseline (M1). OpenAI CLIP ViT-L/14 with blocks 20-23, ln_post and proj fine-tuned (lr 1e-5) and the
   anchored CLIP classifier on top (the CLIP probe head, lr 3e-4, same anchors, s and lambda_A), i.e. the CLIP probe with
   the last four encoder blocks trained ("CLIP-FT"). Frames decoded on the fly (no token cache; disk limit). P1 audited
   split, hybrid sampler as for the heads, AdamW wd 0.05, 5 epochs, micro-batch 4 x 4 accumulation, warm-up + cosine,
   label smoothing 0.1, fp16 autocast, selection by validation window AUC, seeds 42-44. Scored on the audited test and
   the nine unseen sets with the same windows as every other model. Reported: per-set and nine-set AUC, seed-aware
   tests (CLIP-FT - CLIP probe, CLIP-FT - VideoMAE-B FT tuned, LENS-Net-A - CLIP-FT), descriptive.
E2 Sensitivity to s and lambda_A (rev. 2 item 10). CLIP probe and LENS-Net (V-REx beta = 1) retrained, one factor at a
   time: s in {15, 60} at lambda_A = 0.5, and lambda_A in {0, 0.1, 2} at s = 30; seeds 42-44. Reported: nine-set mean and
   minimum next to the published setting (s = 30, lambda_A = 0.5); descriptive.
E3 DG objectives on the VideoMAE-B features (M3). The motion probe (head on frozen VideoMAE-B features only) trained
   with IRM, GroupDRO and V-REx (beta = 1) in place of plain ERM, settings as in C3, seeds 42-44; plus ERM ("none") as a
   reproduction check of the published motion probe. Reported: nine-set mean and minimum; descriptive.
E4 Ambiguous windows (M5). In every unseen set whose window labels come from temporal annotations, the windows that the
   labelling rule ignored (neither >= 50% inside an event nor >= 1 s outside) are built with the same windowing,
   extracted and scored by every model, and added as negatives. Reported: windows added per set, every model's AUC on
   the labelled set and with the ambiguous windows as negatives, Kendall tau between the two rankings, best model.
   Interpretation fixed now: rankings with tau >= 0.9 and the same best model count as unchanged.
D1b Human labels for the remaining 300 pairs (P201-P500) of the pre-registered sample, same form and instructions;
   estimates recomputed on all labelled pairs with the same rules. If a second person labels pairs, Cohen's kappa
   between labellers is reported on the pairs both labelled.
E4 clarification (recorded 2026-10-19, before any ambiguous window was built): the window-level sets with temporal
annotations are CCTV-Fights (CCTV subset), UBI-Fights, XD-Violence and UCF-Crime. For XD-Violence and UCF-Crime every
frame, ambiguous ones included, is already scored by the frame-level protocol (Section V-H), so E4 builds ambiguous
windows for CCTV-Fights and UBI-Fights only. Per video, up to 4 ambiguous grid windows are taken, spread evenly (the
per-class cap of the original windowing), from the same 1.5-s grid; frames, features and scores are produced with the
pipelines of the original windows. Models: every model of Table V whose scoring pipeline accepts a new window set.

## D1 deviation 2 (recorded 2026-10-21, after the fact)
While the labelling page was faulty (an editing error removed part of its script on 2026-10-19), the labeller re-labelled
P036-P169 (134 pairs) a second time, which overwrote the stored answers on the page. The first-pass labels, saved
before, remain the primary labels (review/human_labels_final.csv); the second pass (review/human_labels_pass2.csv) is
reported only as intra-rater (test-retest) agreement. No label of P201-P500 existed at this point.

## D1b status (recorded 2026-10-21)
The remaining 300 pairs (P201-P500) were not labelled; the D1 estimates therefore rest on the first 200 pairs of the
pre-registered sample, as reported.

## E5 Fusion rules under domain shift (recorded 2026-10-24, before any fused score was computed)
Question: do decision-level fusion rules fitted on the source corpora transfer to unseen datasets, and which fixed rules
are robust? Computed from saved per-window predictions only; no model is retrained.
Members (three seeds each, fused seed by seed): CLIP probe (the anchor), LENS-Net, LENS-Net without motion, motion
probe, VideoMAE-B fine-tuned with the validation-selected learning rate, VideoMAE-B with LoRA, CLIP-FT, VadCLIP.
Pairs: the anchor with each of the seven other members, plus two pairs without the anchor (LENS-Net + tuned
VideoMAE-B, LENS-Net + LoRA): nine pairs.
Rules: fixed - (R1) mean of probabilities (the published LENS-Net-A rule), (R2) mean of logits, (R3) normalised
geometric mean of probabilities, (R4) max, (R5) min, (R6) rank average (ranks within each evaluation set, no labels);
learned on the source validation windows only - (R7) weighted mean of probabilities, weight in {0, 0.05, ..., 1}
maximising validation ROC-AUC, (R8) logistic stacking on the two members' logits (L2, C = 1). Frozen-head validation
predictions are recomputed from the saved checkpoints.
Outcomes: nine-set mean and minimum ROC-AUC and per-set AUC of every (pair, rule); validation AUC of every rule; the
learned weights. Primary family (Holm, two-sided, alpha 0.05, seed-aware test of the nine-set mean): for the pair
anchor + LENS-Net, each of R2-R8 minus R1 (seven comparisons). Descriptive: R7 and R8 minus R1 for every other pair;
each fused pair minus its better member. Interpretation fixed now: if R7/R8 are not better than R1, the lesson that
fusion weights fitted on source data do not transfer extends to decision-level fusion; differences of R2-R6 from R1
are reported whatever their sign.
