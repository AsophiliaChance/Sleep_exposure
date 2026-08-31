# Sleep Exposure: Four-Night EEG/ERP Analysis Pipeline

## Study coding conventions

### Night folders

| Folder/file stem | Analysis label | Mixed-model level |
| --- | --- | --- |
| `day0` | Night 1 | `Days = 1` |
| `day1` | Night 2 | `Days = 2` |
| `day2` | Night 3 | `Days = 3` |
| `day3` | Night 4 | `Days = 4` |

In the mixed-effects analysis scripts, the manuscript variable **Night** is represented by `Days`. `Days` is treated as a **four-level categorical factor**, not as a continuous predictor.

### Canonical event codes

After preprocessing, stream-specific event markers are converted to a common coding system:

| Event code | Meaning |
| ---: | --- |
| `1` | Standard stimulus |
| `2` | Small deviant |
| `3` | Large deviant |

For the ERP mixed-effects analyses, `DeviantType` contains two categorical levels: `Small` and `Large`.

### ERP measures

Final ERP measures are calculated from the Deviant-minus-Standard differential response averaged across `FPz`, `C3`, and `C4`.

| Component | Measure |
| --- | --- |
| P2 | Mean differential amplitude and 50% positive fractional-area latency |
| P450 | Mean differential amplitude and 50% positive fractional-area latency |

The saved names `amplitude_mmn`, `latency_mmn`, `amplitude_p3`, and `latency_p3` are retained for compatibility with earlier scripts. In the present analysis, they represent P2 and P450 measures rather than canonical MMN and P3 components.

The four ERP outcomes analyzed with linear mixed-effects models are P2 amplitude, P450 amplitude, P2 latency, and P450 latency.

## Software requirements

The scripts require MATLAB, EEGLAB, EEGLAB BrainVision import support for `pop_loadbv`, FieldTrip, and the Statistics and Machine Learning Toolbox. Microsoft Excel is optionally required for ActiveX-based formatting in `SL05descriptivestat.m`.

Exact MATLAB, EEGLAB, FieldTrip, plugin, and toolbox versions are not recorded in all scripts. Record these versions when preparing an archival reproducibility release.

## Data requirements

Raw and intermediate data are not included in this repository. Depending on the analysis stage, the scripts expect:

* BrainVision recording files, including `.vhdr` and associated data/marker files;
* external trigger-timing `.dat` files;
* `possibletriger.mat`, containing the variable `possibel_triger` with this exact spelling;
* EEGLAB `.set` files produced by earlier processing stages;
* `exposure_dur.xlsx`, with participant identifiers in the first column and four night-duration columns;
* per-night ERP files such as `day0_nsubavg120.mat` through `day3_nsubavg120.mat`;
* `erp_statisticsdata_simple.mat`, containing the aligned P2/P450 amplitude and latency matrices used by the mixed-effects scripts.

All scripts currently contain author-specific absolute Windows paths. Update the path settings before running the pipeline.

## Analysis workflow

```text
BrainVision EEG recordings
        |
        v
SL01SeperateIntoFourData.m
        |
        v
SL02TriggerCorrection.m
        |
        v
SL03Preprocess.m
        |
        v
SL04Epoch.m
        |
        v
SL05AmplitudeLatency.m / SL05Figure2A.m
        |
        +----------------------------+-----------------------------+
        |                            |                             |
        v                            v                             v
SL05ExposureDurationLMM.m   SL05descriptivestat.m   SL06_RandomEffectsComparison.m
                                                        |
                                                        v
                                              ERP_ModelComparisonOnly.xlsx
                                                        |
                                                        v
                                              SL06LmmTtestFigure2B.m
                                                        |
                                                        v
                                                  SL07Figure3.m
```

## Script inventory

| Script | Purpose | Main outputs |
| --- | --- | --- |
| `SL01SeperateIntoFourData.m` | Splits each multiplexed BrainVision recording into four stream-specific EEGLAB datasets and removes stream prefixes from channel labels | `*_1.set` to `*_4.set` |
| `SL02TriggerCorrection.m` | Corrects/reconstructs event types, compares timing information with external `.dat` files, and retains the appropriate trigger family for each stream | `*_MCor0.set` |
| `SL03Preprocess.m` | Applies filtering, removes long unused intervals, screens artifacts, validates event sequences, and converts stream-specific events to codes 1/2/3 | `*_preprocessed1a.set` |
| `SL04Epoch.m` | Creates Standard and Deviant ERPs for Small and Large deviants and calculates Deviant-minus-Standard differential responses | `dayX_nsubavg120.mat` |
| `SL05AmplitudeLatency.m` | Averages `FPz`, `C3`, and `C4`, defines P2/P450 windows, calculates amplitudes and latencies, and saves ERP statistics matrices | `erp_statisticsdata_simple.mat`, `erp_statisticsdata.mat`, waveform TIFFs |
| `SL05ExposureDurationLMM.m` | Summarizes exposure duration and fits exposure-duration mixed-effects models | Exposure-duration tables, text output, and PNG figures |
| `SL05Figure2A.m` | Generates Figure 2A waveform panels and repeats P2/P450 extraction and saving operations | `ERP1_gavg.tiff`, `ERP2_gavg.tiff`, ERP statistics `.mat` files |
| `SL05descriptivestat.m` | Calculates nightly mean and standard error by component, measure, deviant type, and night | `ERP_Nightly_Mean_SE_TableFormat.xlsx` |
| `SL06_RandomEffectsComparison.m` | Compares participant random-intercept and participant random-intercept-plus-Night-slope structures for each of the four ERP outcomes and evaluates models with versus without Exposure | `ERP_ModelComparisonOnly.xlsx` |
| `SL06LmmTtestFigure2B.m` | Fits the primary interaction-inclusive mixed-effects models, performs planned night comparisons, exports inferential statistics, and generates Figure 2B source plots | Statistical workbook and Figure 2B TIFFs |
| `SL07Figure3.m` | Produces the combined P450 figure showing the Night effect and Deviant Type effect | Combined Figure 3 TIFF |

## Recommended execution order

1. Replace all absolute local paths with paths appropriate for the current computer.
2. Add EEGLAB and FieldTrip to the MATLAB path and record software versions.
3. Run `SL01SeperateIntoFourData.m`.
4. Run `SL02TriggerCorrection.m`.
5. Run `SL03Preprocess.m`.
6. Run the ERP-construction section of `SL04Epoch.m` for all four nights.
7. Run one controlled ERP metric-extraction workflow: either `SL05AmplitudeLatency.m`, or `SL05Figure2A.m` when Figure 2A must also be generated.
8. Run `SL05ExposureDurationLMM.m` and `SL05descriptivestat.m` as needed.
9. Run `SL06_RandomEffectsComparison.m` to document the random-effects and Exposure model comparisons for the four ERP outcomes.
10. Retain `ERP_ModelComparisonOnly.xlsx` together with the comparison script as the model-selection record.
11. Run `SL06LmmTtestFigure2B.m` for the primary mixed-effects analysis and Figure 2B source plots.
12. Run `SL07Figure3.m` after confirming that all displayed significance annotations match the final statistical results.

`SL05AmplitudeLatency.m` and `SL05Figure2A.m` overlap substantially and write the same ERP statistics filenames. Running both can overwrite existing outputs.

## Random-effects model comparison

`SL06_RandomEffectsComparison.m` evaluates the random-effects structure separately for P2 amplitude, P450 amplitude, P2 latency, and P450 latency.

For each outcome, `Days` (Night) is treated as a four-level categorical factor and `DeviantType` as a two-level categorical factor.

The following structures are compared while keeping the fixed-effects structure the same:

```text
Random-intercept model:
Y ~ Days * DeviantType + Exposure + (1 | Subjects)

Random-intercept-plus-Night-slope model:
Y ~ Days * DeviantType + Exposure + (1 + Days | Subjects)
```

The random-effects comparison is fitted using restricted maximum likelihood (REML), because the candidate models have the same fixed-effects structure.

For each outcome, the comparison script stores:

* log likelihood for both candidate models;
* AIC for both candidate models;
* BIC for both candidate models;
* AIC and BIC differences;
* likelihood-ratio comparison p value when successfully returned by MATLAB;
* selected random-effects structure;
* comparison status.

The corresponding output is stored in:

```text
ERP_ModelComparisonOnly.xlsx
```

under the `RandomEffectsComparison` sheet.

Across the four ERP outcomes, the model comparisons did not provide consistent support for retaining the substantially more complex participant-specific Night-slope structure. The primary reported analyses therefore use a participant random-intercept specification.

In manuscript terminology, the reported random-effects structure is:

```text
(1 | Participant)
```

rather than:

```text
(1 + Night | Participant)
```

## Exposure model comparison

After establishing the random-effects structure, `SL06_RandomEffectsComparison.m` compares candidate models with versus without exposure duration using maximum likelihood (ML):

```text
Without Exposure:
Y ~ Days * DeviantType + selected random-effects structure

With Exposure:
Y ~ Days * DeviantType + Exposure + selected random-effects structure
```

The output is stored in the `ExposureComparison` sheet of `ERP_ModelComparisonOnly.xlsx`.

## Primary statistical analysis and Figure 2B

`SL06LmmTtestFigure2B.m` analyzes the same four ERP outcomes: P2 amplitude, P450 amplitude, P2 latency, and P450 latency.

The fixed-effects structure contains Night, Deviant Type, and the Night × Deviant Type interaction:

```text
Y ~ Days * DeviantType
```

where `Days` is the four-level categorical representation of Night.

The participant-level random-effects structure used for the reported primary analyses is:

```text
(1 | Subjects)
```

Therefore, the reported primary model is:

```text
Y ~ Days * DeviantType + (1 | Subjects)
```

Equivalent manuscript notation is:

```text
Y ~ Night * DeviantType + (1 | Participant)
```

The script uses effects coding for the interaction-inclusive categorical predictors and Satterthwaite degrees of freedom for inference.

The primary analysis reports fixed-effect estimates and confidence intervals, omnibus Night, Deviant Type, and Night × Deviant Type effects, partial eta squared, planned Night 2/3/4 versus Night 1 comparisons, Bonferroni-adjusted p values, effect-size `r` for contrasts, and Night 1 right-tailed amplitude tests.

It also generates:

```text
ERP_Amplitude_dayChange_DeviantType_4days_NoFDR_BonfPairwise.tif
ERP_Latency_dayChange_DeviantType_4days_NoFDR_BonfPairwise.tif
```

The corresponding statistical workbook is:

```text
ERP_stats_NightByDeviantType_EffectsCoding_4days_NoFDR_BonfPairwise.xlsx
```

## Model-selection documentation

To preserve a reproducible record of the random-effects decision, retain these files together:

```text
SL06_RandomEffectsComparison.m
ERP_ModelComparisonOnly.xlsx
```

For each of the four ERP outcomes, the model-comparison record should allow retrieval of the exact candidate formulas, number of observations, log likelihood, AIC, BIC, likelihood-ratio comparison result, and selected random-effects structure.

## Terminology mapping

| Manuscript term | Repository/MATLAB term |
| --- | --- |
| Night | `Days` |
| Participant | `Subjects` |
| Deviant Type | `DeviantType` |
| P2 amplitude | `amplitude_mmn` |
| P2 latency | `latency_mmn` |
| P450 amplitude | `amplitude_p3` |
| P450 latency | `latency_p3` |

## Main output files

| Output | Description |
| --- | --- |
| `day0_nsubavg120.mat` to `day3_nsubavg120.mat` | Participant-level Standard, Deviant, and differential ERPs by night and deviant type |
| `erp_statisticsdata_simple.mat` | Aligned P2/P450 amplitude and latency matrices |
| `erp_statisticsdata.mat` | Original amplitude/latency structures before participant-position alignment |
| `ERP_Nightly_Mean_SE_TableFormat.xlsx` | Descriptive nightly mean and standard-error table |
| `ERP_ModelComparisonOnly.xlsx` | Random-effects and Exposure model-comparison record for P2/P450 amplitude and latency |
| `ERP_stats_NightByDeviantType_EffectsCoding_4days_NoFDR_BonfPairwise.xlsx` | Primary interaction-inclusive mixed-model results |
| `ERP1_gavg.tiff`, `ERP2_gavg.tiff` | Figure 2A source waveforms for Small and Large changes |
| `ERP_Amplitude_dayChange_DeviantType_4days_NoFDR_BonfPairwise.tif` | Figure 2B amplitude plot |
| `ERP_Latency_dayChange_DeviantType_4days_NoFDR_BonfPairwise.tif` | Figure 2B latency plot |
| `ERP_combined_long_figure_P450_only_spacing1p3_labels_shifted_down_P450up_final2.tiff` | Combined Figure 3 |

## Reproducibility note

The executable analysis scripts, their comments, the exported model-comparison workbook, this README, and the manuscript should use the same final model specification.

For the reported primary ERP analyses, that specification is:

```text
Y ~ Days * DeviantType + (1 | Subjects)
```

or, in manuscript terminology:

```text
Y ~ Night * DeviantType + (1 | Participant)
```

Any older comments or formula strings referring to a participant-specific Night slope should not be interpreted as the specification used for the reported primary results unless explicitly identified as a candidate model in the model-comparison script.
