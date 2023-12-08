# post-covid-mentalhealth

## Repository navigation

-   If you are interested in how we defined our code lists, look in the [`codelists`](./codelists) folder.

-   Analyses scripts are in the [`analysis`](./analysis) directory:

    -   If you are interested in how we defined our variables, we use study definition scripts to define three cohorts: pre-vaccination, vaccinated and unvaccinated. Study start dates (i.e., index) and end dates differ by cohort and are all described in the protocol. Hence, we have a study definition for each; these are written in `python`. Extracted data is then combined to create our final cohorts, in the [preprocess data script](analysis/preprocess_data.R).
    -   This directory also contains all the R scripts that process, describe, and analyse the extracted data.

-   The [`lib/`](./lib) directory contains a list of active analyses.

-   The [`project.yaml`](.project.yaml) defines run-order and dependencies for all the analysis scripts. This file should not be edited directly. To make changes to the yaml, edit and run the [`create_project.R`](./analysis/create_project.R) script which generates all the actions.

-   Descriptive and Model outputs, including figures and tables are in the [`released_outputs`](./release_outputs) directory.

## Manuscript

The manuscript associated with this code is currently under review at a journal. Please check out our [preprint](https://www.medrxiv.org/content/10.1101/2023.12.06.23299602v1).

## Code

The [`project.yaml`](./project.yaml) defines project actions, run-order and dependencies for all analysis scripts. **This file should *not* be edited directly**. To make changes to the yaml, edit and run the [`create_project.R`](./analysis/create_project.R) script instead. Project actions are then run securely using [OpenSAFELY Jobs](https://jobs.opensafely.org/investigating-events-following-sars-cov-2-infection/post-covid-mentalhealth-v2). Any published outputs from this project can be found at this link as well.

## Output

### consort_\*.csv

| Variable           | Description                                                    |
|--------------------|----------------------------------------------------------------|
|     Description    | criterion applied to cohort                               |
|     N              | number of people in the cohort after criterion applied time    |
|     removed        | number of people removed due to criterion being applied        |


### table1_\*.csv

| Variable                  | Description                                                      |
|---------------------------|------------------------------------------------------------------|
|     Characteristic        | patient characteristic under consideration                       |
|     Subcharacteristic     | patient sub characteristic under   consideration                 |
|     N (%)                 | number of people with characteristic,   alongside % of total     |
|     COVID-19 diagnoses    | number of people with characteristic and   COVID-19              |

### table2_\*.csv

| Variable                     | Description                                                             |
|------------------------------|-------------------------------------------------------------------------|
|     name                     | unique identifier for analysis                                          |
|     cohort                   | cohort used for the analysis                                            |
|     exposure                 | exposure used for the analysis                                          |
|     outcome                  | outcome used for the analysis                                           |
|     analysis                 | string to identify whether this is the ‘main’ analysis or a subgroup    |
|     unexposed_person_days    | number of person days before or without exposure in the analysis        |
|     unexposed_events         | number of unexposed people with the outcome in the analysis             |   
|     exposed_person_days      | number of person days after exposure in the analysis                    |
|     exposed_events           | number of exposed people with the outcome in the analysis               |  
|     total_person_days        | number of person days in the analysis                                   |
|     total_events             | number of people with the outcome in the analysis                       |
|     day0_events              | number of people with the exposure and outcome on the same day          |
|     total_exposed            | number of people with the exposure in the analysis                      |
|     sample_size              | number of people in the analysis                                        |
### venn_\*.csv

| Variable                | Description                                                                 |
|-------------------------|-----------------------------------------------------------------------------|
|     outcome             | outcome under consideration                                                 |
|     only_snomed         | outcome identified in primary care only                                     |
|     only_hes            | outcome identified in secondary care only                                   |
|     only_death          | outcome identified in death registry only                                   |
|     snomed_hes          | outcome identified in primary and secondary care                            |
|     snomed_death        | outcome identified in primary care and death registry                       |
|     hes_death           | outcome identified in secondary care and death registry                     |
|     snomed_hes_death    | outcome identified in primary care, secondary care, and death registry      |
|     total_snomed        | total outcomes identified in primary care                                   |
|     total_hes           | total outcomes identified in secondary care                                 |
|     total_death         | total outcomes identified in death registry                                 |
|     total               | total outcomes identified                                                   |
|     cohort              | cohort under consideration                                                  |

### *model_output.csv

| Variable                   | Description                                                                   |
|----------------------------|-------------------------------------------------------------------------------|
|     name                   | unique identifier for analysis                                                |
|     cohort                 | cohort used for the analysis                                                  |
|     outcome                | outcome used for the analysis                                                 |
|     analysis               | string to identify whether this is the ‘main’ analysis or a subgroup          |
|     error                  | captured error message if analysis did not run                                |
|     model                  | string to identify whether the model adjustment                               |
|     term                   | string to identify the term in the analysis                                   |
|     lnhr                   | log hazard ratio for the analysis                                             |
|     se_lnhr                | standard error for the log hazard ratio for the analysis                      |
|     hr                     | hazard ratio for the analysis                                                 |
|     conf_low               | lower confidence limit for the analysis                                       |
|     conf_high              | higher confidence limit for the analysis                                      |
|     N_total                | total number of people in the analysis                                        |
|     N_exposed              | total number of people with the exposure in the analysis                      |
|     N_events               | total number of people with the outcome following exposure in the analysis    |
|     person_time_total      | total person time included in the analysis                                    |
|     outcome_time_median    | median time to outcome following exposure                                     |
|     strata_warning         | string to identify strata variables that may cause model faults               |
|     surv_formula           | survival formula for the analysis                                             |

## About the OpenSAFELY framework

The OpenSAFELY framework is a Trusted Research Environment (TRE) for electronic health records research in the NHS, with a focus on public accountability and research quality. Read more at [OpenSAFELY.org](https://opensafely.org).

## Licences

As standard, research projects have a MIT license.
