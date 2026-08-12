# Sleep Exposure: Four-Night EEG/ERP Analysis Pipeline

## Study coding conventions

### Night folders

| Folder/file stem | Analysis label |
| ---------------- | -------------- |
| `day0`           | Night 1        |
| `day1`           | Night 2        |
| `day2`           | Night 3        |
| `day3`           | Night 4        |

### Canonical event codes

After preprocessing, stream-specific event markers are converted to a common coding system:

| Event code | Meaning           |
| ---------: | ----------------- |
|        `1` | Standard stimulus |
|        `2` | Small deviant     |
|        `3` | Large deviant     |

### ERP measures

Final ERP measures are calculated from the Deviant-minus-Standard differential response averaged across `FPz`, `C3`, and `C4`.

| Component | Measure                                                              |
| --------- | -------------------------------------------------------------------- |
| P2        | Mean differential amplitude and 50% positive fractional-area latency |
| P450      | Mean differential amplitude and 50% positive fractional-area latency |

The saved names `amplitude_mmn`, `latency_mmn`, `amplitude_p3`, and `latency_p3` are retained for compatibility with earlier scripts. In the present analysis, they represent P2 and P450 measures rather than canonical MMN and P3 components.

## Software requirements

The scripts require:

* MATLAB;
* EEGLAB;
* EEGLAB BrainVision import support for `pop_loadbv`;
* FieldTrip;
* Statistics and Machine Learning Toolbox;
* Microsoft Excel, optionally, for ActiveX-based formatting in `SL05descriptivestat.m`.

Exact MATLAB, EEGLAB, FieldTrip, plugin, and toolbox versions are not recorded in the scripts. Record these versions before producing a reproducible release.

## Data requirements

Raw and intermediate data are not included in this repository. Depending on the analysis stage, the scripts expect:

* BrainVision recording files, including `.vhdr` and associated data/marker files;
* external trigger-timing `.dat` files;
* `possibletriger.mat`, containing the variable `possibel_triger` with this exact spelling;
* EEGLAB `.set` files produced by earlier processing stages;
* `exposure_dur.xlsx`, with participant identifiers in the first column and four night-duration columns;
* per-night ERP files such as `day0_nsubavg120.mat` through `day3_nsubavg120.mat`.

All scripts currently contain author-specific absolute Windows paths. Update the path settings before running the pipeline.

## Analysis workflow

```text
BrainVision EEG recordings
        |
        v
SL01SeperateIntoFourData.m
  Separate the four prefixed recording streams
        |
        v
SL02TriggerCorrection.m
  Reconstruct and normalize stream-specific event markers
        |
        v
SL03Preprocess.m
  Filter EEG, remove long unused intervals, reject artifacts,
  validate event sequences, and recode events to 1/2/3
        |
        v
SL04Epoch.m
  Create Standard, Deviant, and Deviant-minus-Standard ERPs
        |
        v
SL05AmplitudeLatency.m / SL05Figure2A.m
  Average FPz/C3/C4, define P2/P450 windows, extract metrics,
  save aligned ERP matrices, and generate Figure 2A when required
        |
        +-------------------------+-------------------------+
        |                         |                         |
        v                         v                         v
SL05ExposureDurationLMM.m  SL05descriptivestat.m  SL06LmmTtestFigure2B.m
  Exposure-duration          Descriptive ERP        Primary LMM and
  summaries and LMM          Mean/SE table           Figure 2B plots
                                                        |
                                                        v
                                                SL07Figure3.m
                                                  Figure 3
```

## Script inventory

| Script                       | Purpose                                                                                                                                                                                                                                               | Main outputs                                                              |                                                        |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------ |
| `SL01SeperateIntoFourData.m` | Splits each multiplexed BrainVision recording into four stream-specific EEGLAB datasets and removes stream prefixes from channel labels                                                                                                               | `*_1.set` to `*_4.set`                                                    |                                                        |
| `SL02TriggerCorrection.m`    | Corrects/reconstructs event types, compares timing information with external `.dat` files, and retains the appropriate trigger family for each stream                                                                                                 | `*_MCor0.set`                                                             |                                                        |
| `SL03Preprocess.m`           | Applies 1-Hz high-pass, 30-Hz low-pass, and 49–51-Hz band-stop filters; removes long unused intervals; screens amplitude, gradient, and low-signal artifacts; validates event sequences; converts stream-specific events to codes 1/2/3               | `*_preprocessed1a.set`                                                    |                                                        |
| `SL04Epoch.m`                | Creates Standard and Deviant ERPs for Small and Large deviants, calculates Deviant-minus-Standard differential responses, and saves participant-level FieldTrip structures                                                                            | `dayX_nsubavg120.mat`                                                     |                                                        |
| `SL05AmplitudeLatency.m`     | Averages `FPz`, `C3`, and `C4`; detects P2/P450 windows; calculates mean amplitudes and 50% positive fractional-area latencies; aligns participant positions; saves ERP statistics matrices                                                           | `erp_statisticsdata_simple.mat`, `erp_statisticsdata.mat`, waveform TIFFs |                                                        |
| `SL05ExposureDurationLMM.m`  | Converts exposure-duration data to long format, summarizes duration by night, identifies valid ERP observations, and fits `Duration ~ Night + (1                                                                                                      | Subject)` models                                                          | Exposure-duration tables, text output, and PNG figures |
| `SL05Figure2A.m`             | Generates Figure 2A waveform panels and repeats the P2/P450 extraction and saving operations used in `SL05AmplitudeLatency.m`                                                                                                                         | `ERP1_gavg.tiff`, `ERP2_gavg.tiff`, ERP statistics `.mat` files           |                                                        |
| `SL05descriptivestat.m`      | Calculates nightly mean and standard error by component, measure, deviant type, and night                                                                                                                                                             | `ERP_Nightly_Mean_SE_TableFormat.xlsx`                                    |                                                        |
| `SL06LmmTtestFigure2B.m`     | Fits interaction-inclusive mixed-effects models, tests Night, Deviant Type, and their interaction, performs planned night comparisons, exports inferential statistics, and generates violin/raincloud-style amplitude and latency plots for Figure 2B | Statistical workbook and Figure 2B TIFFs                                  |                                                        |
| `SL07Figure3.m`              | Produces the combined P450 figure showing the Night effect and Deviant Type effect using waveforms and violin plots                                                                                                                                   | Combined Figure 3 TIFF                                                    |                                                        |

## Recommended execution order

1. Replace all absolute local paths with paths appropriate for the current computer.
2. Add EEGLAB and FieldTrip to the MATLAB path and record software versions.
3. Run `SL01SeperateIntoFourData.m`.
4. Run `SL02TriggerCorrection.m`.
5. Run `SL03Preprocess.m`.
6. Run the ERP-construction section of `SL04Epoch.m` for all four nights.
7. Run one controlled ERP metric-extraction workflow:

   * use `SL05AmplitudeLatency.m` for metric extraction; or
   * use `SL05Figure2A.m` when Figure 2A must also be generated.
8. Run `SL05ExposureDurationLMM.m` and `SL05descriptivestat.m` as needed.
9. Run `SL06LmmTtestFigure2B.m` for the primary mixed-effects analysis and Figure 2B source plots.
10. Run `SL07Figure3.m` after confirming that all displayed significance annotations match the final statistical results.

`SL05AmplitudeLatency.m` and `SL05Figure2A.m` overlap substantially and write the same ERP statistics filenames. Running both can overwrite existing outputs. Use a controlled order and retain a record of which script generated the final files.

## Primary statistical analysis and Figure 2B

`SL06LmmTtestFigure2B.m` analyzes four outcomes:

* P2 amplitude;
* P2 latency;
* P450 amplitude;
* P450 latency.

For each outcome, it compares:

```text
Model without Exposure:
Y ~ Days * DeviantType + (1|Subjects)

Model with Exposure:
Y ~ Days * DeviantType + Exposure + (1|Subjects)
```

The candidate models are compared using maximum likelihood. The selected model is refitted using restricted maximum likelihood. The script uses effects coding and Satterthwaite degrees of freedom.

The script reports:

* model-comparison statistics;
* fixed-effect estimates and confidence intervals;
* omnibus Night, Deviant Type, and Night × Deviant Type effects;
* partial eta squared;
* planned Night 2, Night 3, and Night 4 versus Night 1 comparisons;
* Bonferroni-adjusted p values for the planned comparisons;
* effect-size `r` for contrasts;
* Night 1 right-tailed amplitude tests.

It also generates two Figure 2B source files:

```text
ERP_Amplitude_dayChange_DeviantType_4days_NoFDR_BonfPairwise.tif
ERP_Latency_dayChange_DeviantType_4days_NoFDR_BonfPairwise.tif
```

Each plot contains P2 and P450 panels with:

* half-violin kernel-density distributions;
* jittered individual observations;
* mean values;
* standard-error bars;
* Bonferroni-based planned-comparison brackets and significance stars when retained by the script.

The corresponding statistical workbook is:

```text
ERP_stats_NightByDeviantType_EffectsCoding_4days_NoFDR_BonfPairwise.xlsx
```

## Main output files

| Output                                                                                 | Description                                                                          |
| -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `day0_nsubavg120.mat` to `day3_nsubavg120.mat`                                         | Participant-level Standard, Deviant, and differential ERPs by night and deviant type |
| `erp_statisticsdata_simple.mat`                                                        | Aligned P2/P450 amplitude and latency matrices                                       |
| `erp_statisticsdata.mat`                                                               | Original amplitude/latency structures before participant-position alignment          |
| `ERP_Nightly_Mean_SE_TableFormat.xlsx`                                                 | Descriptive nightly mean and standard-error table                                    |
| `ERP_stats_NightByDeviantType_EffectsCoding_4days_NoFDR_BonfPairwise.xlsx`             | Primary interaction-inclusive mixed-model results                                    |
| `ERP1_gavg.tiff`, `ERP2_gavg.tiff`                                                     | Figure 2A source waveforms for Small and Large changes                               |
| `ERP_Amplitude_dayChange_DeviantType_4days_NoFDR_BonfPairwise.tif`                     | Figure 2B amplitude plot                                                             |
| `ERP_Latency_dayChange_DeviantType_4days_NoFDR_BonfPairwise.tif`                       | Figure 2B latency plot                                                               |
| `ERP_combined_long_figure_P450_only_spacing1p3_labels_shifted_down_P450up_final2.tiff` | Combined Figure 3                                                                    |

