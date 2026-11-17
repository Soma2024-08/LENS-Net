# Data

No dataset, frame or feature is distributed with this repository. Obtain each dataset from its original source and
respect its licence (most allow research use only and forbid redistribution).

## Source corpora (training and in-domain test)
| Dataset | Source |
|---|---|
| RLVS (Real Life Violence Situations) | Soliman et al., ICICIS 2019 (Kaggle release) |
| RWF-2000 | Cheng et al., ICPR 2020 (request from the authors) |
| Hockey Fights | Bermejo Nievas et al., CAIP 2011 |
| Bus Violence | Ciampi et al., Sensors 2022 |
| VID | Mahi et al., Data in Brief 2024 |

## External benchmarks (never used for training)
| Dataset | Source |
|---|---|
| XD-Violence (test videos, temporal annotations) | Wu et al., ECCV 2020 — roc-ng.github.io/XD-Violence |
| UCF-Crime (test videos, temporal annotations) | Sultani et al., CVPR 2018 |

## Unseen confirmation sets
| Dataset | Source |
|---|---|
| SCFD (Surveillance Camera Fight Dataset) | Akti et al., IPTA 2019 — github.com/seymanurakti/fight-detection-surv-dataset |
| SCVD | Aremu et al., SAI 2024 — Kaggle `toluwaniaremu/smartcity-cctv-violence-detection-dataset-scvd` (version 3) |
| VioPeru | Huillcen Baca et al., Sensors 2024 — github.com/hhuillcen/VioPeru |
| AIRTLab | Bianculli et al., Data in Brief 2020 — github.com/airtlab/A-Dataset-for-Automatic-Violence-Detection-in-Videos |
| CCTV-Fights | Perez et al., ICASSP 2019 — ROSE Lab, NTU (access request; `download_cctv_fights.py` downloads with your own login) |
| Movies | Bermejo Nievas et al., CAIP 2011 — Kaggle `naveenk903/movies-fight-detection-dataset` |
| UBI-Fights | Degardin and Proença, IJCB 2020 — socia-lab.di.ubi.pt/EventDetection (annotations: `fetch_ubi_annotations.py`) |
| AIE | da Silva and Pereira, J. Brazilian Computer Society 2024 — Kaggle `arnaldovitor/aie-dataset` |
| XD-Violence training subset | Hugging Face mirror `jherng/xd-violence`; the 600 videos are listed in `data_tables/xd_train_aie/xd_train_selection.csv` |

## Third-party code
- VadCLIP (Apache-2.0): clone github.com/nwpu-zxr/VadCLIP into `raw_data/journal/ext/VadCLIP` for `vadclip_run.py`.

## Expected locations (relative to the repository root)
| What | Where |
|---|---|
| Window manifests, near-duplicate edges (included) | `data_tables/manifests/` |
| Frame stores (built by the `video_data` utilities and `build_scfd_scvd.py` / `build_vioperu_airtlab.py`) | `source_benchmark/frames/`, `raw_data/{fresh,journal}/frames/` |
| Extracted features (built by `extract_compact.py`, `extract_vmae.py`) | `workspace/features/{l14,b16}/<set>/` |
| Run outputs and checkpoints | `workspace/runs*/` |

## Window tables included here
- `data_tables/manifests/source_windows.csv`: every 1.5-s window of the source corpora, with its split and
  near-duplicate component (the leakage-controlled split).
- `data_tables/scfd_scvd/`, `data_tables/vioperu_airtlab/`, `cctv_fights/`, `movies_ubi_fights/`, `xd_train_aie/`, `framelevel_xd_ucf/`: windows of the unseen sets and their near-duplicate checks.
