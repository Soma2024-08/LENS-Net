# Result summaries

Every number, table and figure of the paper is generated from these files by `paper/make_tables.py`,
`src/revision/make_revision_macros*.py` and the `paper/fig_*.py` scripts. Short file names follow the section IDs of
the pre-registration documents in `prereg/` (for example `c1` is Part C1 of `PREREG_revision.md`), so each result
can be traced to the plan that fixed it before it was computed.

## Main study (`PREREG.md`, `PREREG_journal.md`)

| File | Contents | Paper |
|---|---|---|
| `clip_methods_results.json` | pooled training (P1) and single-source (P3) results of every model; VadCLIP, X-CLIP, prompt study | Tables 5, 7a, J.1 |
| `A1_results.json` | fine-tuned video baselines under pooled training (VideoMAE-B, Video Swin-T, R(2+1)D-18) | Table 5 |
| `A2_results.json` | single-source training on RWF-2000 (P3), per seed | Table 7a, Fig. D.1 |
| `a2_mean_boot.json` | P3: bootstrap test of the mean-transfer differences | §5.5 |
| `stageF_results.json` | leave-one-dataset-out (P2), LENS-AG, efficient variants, prompt sets | Tables 7b, J.1 |
| `fresh_results.json` | SCFD and SCVD (fresh sets for the motion stream) | §5.6 |
| `conf_results.json` | VioPeru and AIRTLab | §5.7 |
| `cfights_results.json` | CCTV-Fights | §5.7 |
| `conf2_results.json` | LENS-FG confirmation on Movies and UBI-Fights | App. J.2 |
| `fg_dev_window.json` | LENS-FG on the development sets (exploratory) | Table J.1 |
| `conf3_results.json` | LENS-Net-A confirmation on the XD-Violence training sample and AIE | Table 12 |
| `anchor_safe_exploratory.json`, `ensemble_control.txt` | anchor fusion on the development sets; seed-ensembling and symmetric-fusion control | §6.2 |
| `framelevel_results.json` | frame-level protocol on XD-Violence and UCF-Crime | Table 11 |
| `public_split_audit.json` | same-source overlap under the public splits | §4, Fig. 3, Table 7c |
| `robust_results.json` | robustness to blur, low light, noise and JPEG | App. F |
| `error_analysis.json` | per-category results | App. E |
| `efficiency.json`, `efficiency_journal.json`, `latency.json`, `fig_efficiency_values.json` | GFLOPs, latency, accuracy versus cost | App. J.3, Fig. J.1 |
| `fig_prompts_values.json` | prompt discriminability before training | Fig. B.1 |
| `pilot_decision.json`, `design_selection.json` | pre-registered pilot gate and design selection | §3.8 |
| `prereg_md5.txt` | dated checksum log of the plans | §3.8 |

## Controls and fusion studies (`results/revision/`, `PREREG_revision.md`)

| File | Plan part | Contents | Paper |
|---|---|---|---|
| `stats.json` | B1, B2, B5 | seed-aware paired tests, primary claims with Holm correction, symmetric fusion | Tables 6, 8 |
| `filtering.json` | B3 | every unseen set with and without the test-side filter | §4.2 |
| `ten_seeds.json` | B7 | ten seeds for the frozen-feature heads | §5.11 |
| `c1_results.json`, `splits/` | C1 | random versus source-controlled splits | Table 4 |
| `c2_laion.json` | C2 | OpenCLIP (LAION-2B) control | Tables 10, C.1 |
| `c3_dg.json` | C3 | V-REx sweep, IRM, GroupDRO | Table 10 |
| `c45.json` | C4, C5 | learning-rate search and LoRA for the fine-tuned baselines | Table 9, Fig. 5 |
| `c6_confirmB.json` | C6 | second untouched XD-Violence sample | §6.2 |
| `c7_filter090.json` | C7 | stricter test-side filter (cosine 0.90) | Table C.2 |
| `d1_labels_final.json`, `d1_labels_round1.json`, `human_labels_*.csv`, `label_key_HIDDEN.csv` | D1 | human validation of the audit; the key that maps anonymous pair IDs to strata was hidden from the labeller | App. A |
| `e1_clipft.json` | E1 | CLIP probe with the last four CLIP blocks fine-tuned | Table 9 |
| `e23.json` | E2, E3 | sensitivity to s and λ_A; invariance objectives on the motion probe | §5.3 |
| `e4_amb.json` | E4 | ambiguous windows added as negatives | §4.2 |
| `e5_fusion.json` | E5 | eight decision-level fusion rules on nine member pairs | Table 13 |
| `e6_diversity.json` | E6 | member diversity versus fusion gain | §6.4, Fig. 6 |
| `explore_anchored_selection.json`, `explore_partner_select.json` | F (exploratory) | anchored ensemble selection on the development sets | §6.5 |
| `f_aes_confirm.json`, `f_aes_diagnosis.json` | F | pre-registered confirmation of AES and its diagnosis | Table 14, §6.5 |
| `explore_aes_fixes_dev.json` | F (exploratory) | AES-bal and rank normalisation on the development sets | §6.5 |
| `explore_saaf*.json`, `explore_coadapt*.json`, `explore_partner.json` | exploratory | label-free weighting, cross-view co-adaptation, fusion-aware partner (no robust gain) | §6.5 |
| `g_partG.json`, `g_partG_dev.json` | G | fusion rules on the two further untouched samples | Table 15, §6.6 |
| `h_partH.json` | H | calibrated, Dempster–Shafer, confidence-weighted fusion and TENT | Tables 15, I.1, Fig. 7 |
| `i_partI.json` | I | complementarity of the anchor and LENS-Net | Fig. 8 |
