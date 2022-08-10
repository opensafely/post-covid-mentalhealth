# Based on common_variables in https://github.com/opensafely/post-covid-vaccinated/blob/main/analysis/common_variables.py

# Import statements

## Cohort extractor
from cohortextractor import (
    patients,
    codelist,
    filter_codes_by_category,
    combine_codelists,
    codelist_from_csv,
)

#study dates
from grouping_variables import (
    study_dates,
    days)
## Codelists from codelist.py (which pulls them from the codelist folder)
from codelists import *

## Datetime functions
from datetime import date

## Study definition helper
import study_definition_helper_functions as helpers

# Define pandemic_start
pandemic_start = study_dates["pandemic_start"]
# Define common variables function

# Mental Health Specific details: Recent Episode... / History of...
# 6 months adjustment ~ 6 x 28 = 168 days
# 6 months adjustment - 1 day = 169 days
# cov_recent_ = between(index_date - 168 days, index_date - 1 day)
# cov_history_ = on_or_before(index_date - 169 days)

def generate_common_variables(index_date_variable,end_date_variable,index_date_MH):
    dynamic_variables = dict(
    
# DEFINE EXPOSURES ------------------------------------------------------

    ## Date of positive SARS-COV-2 PCR antigen test
    tmp_exp_date_covid19_confirmed_sgss=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        between=[f"{index_date_variable}",f"{end_date_variable}"],
        return_expectations={
            "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
            "rate": "uniform",
            "incidence": 0.1,
        },
    ),
    ## First COVID-19 code (diagnosis, positive test or sequalae) in primary care
    tmp_exp_date_covid19_confirmed_snomed=patients.with_these_clinical_events(
        combine_codelists(
            covid_primary_care_code,
            covid_primary_care_positive_test,
            covid_primary_care_sequalae,
        ),
        returning="date",
        between=[f"{index_date_variable}",f"{end_date_variable}"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
            "rate": "uniform",
            "incidence": 0.1,
        },
    ),
    ## Start date of episode with confirmed diagnosis in any position
    tmp_exp_date_covid19_confirmed_hes=patients.admitted_to_hospital(
        with_these_diagnoses=covid_codes,
        returning="date_admitted",
        between=[f"{index_date_variable}",f"{end_date_variable}"],
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
            "rate": "uniform",
            "incidence": 0.1,
        },
    ),
    ## Date of death with SARS-COV-2 infection listed as primary or underlying cause
    tmp_exp_date_covid19_confirmed_death=patients.with_these_codes_on_death_certificate(
        covid_codes,
        returning="date_of_death",
        between=[f"{index_date_variable}",f"{end_date_variable}"],
        match_only_underlying_cause=True,
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
            "rate": "uniform",
            "incidence": 0.1
        },
    ),
    ## Generate variable to identify first date of confirmed COVID
    exp_date_covid19_confirmed=patients.minimum_of(
        "tmp_exp_date_covid19_confirmed_sgss","tmp_exp_date_covid19_confirmed_snomed","tmp_exp_date_covid19_confirmed_hes","tmp_exp_date_covid19_confirmed_death"
    ),

    # Define subgroups (for variables that don't have a corresponding covariate only)
    ## COVID-19 severity
    sub_date_covid19_hospital=patients.admitted_to_hospital(
        with_these_primary_diagnoses=covid_codes,
        returning="date_admitted",
        on_or_after="exp_date_covid19_confirmed",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
            "rate": "uniform",
            "incidence": 0.5,
        },
    ),
    ## History of COVID-19 
    ### Positive SARS-COV-2 PCR antigen test
    tmp_sub_bin_covid19_confirmed_history_sgss=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### COVID-19 code (diagnosis, positive test or sequalae) in primary care
    tmp_sub_bin_covid19_confirmed_history_snomed=patients.with_these_clinical_events(
        combine_codelists(
            covid_primary_care_code,
            covid_primary_care_positive_test,
            covid_primary_care_sequalae,
        ),
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Hospital episode with confirmed diagnosis in any position
    tmp_sub_bin_covid19_confirmed_history_hes=patients.admitted_to_hospital(
        with_these_diagnoses=covid_codes,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ## Generate variable to identify first date of confirmed COVID
    sub_bin_covid19_confirmed_history=patients.maximum_of(
        "tmp_sub_bin_covid19_confirmed_history_sgss","tmp_sub_bin_covid19_confirmed_history_snomed","tmp_sub_bin_covid19_confirmed_history_hes"
    ),

#################################
####  MENTAL HEALTH OUTCOMES ####
#################################

    ## Depression
        # Primary Care
    tmp_out_date_depression_snomed=patients.with_these_clinical_events(
        depression_snomed_clinical,
        returning="date",
        on_or_after=f"{index_date_variable}",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={
            "date": {"earliest": "index_date_MH", "latest" : "today"},
            "rate": "uniform",
            "incidence": 0.1,
        },
    ),
    #     # HES
    # tmp_out_date_depression_hes=patients.admitted_to_hospital(
    #     returning="date_admitted",
    #     with_these_diagnoses=depression_icd10,
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # ONS
    # tmp_out_date_depression_death=patients.with_these_codes_on_death_certificate(
    #     depression_icd10,
    #     returning="date_of_death",
    #     on_or_after=f"{index_date_variable}",
    #     match_only_underlying_cause=True,
    #     date_format="YYYY-MM-DD",
    #     return_expectations={
    #         "date": {"earliest": "index_date", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # Prescriptions
    # tmp_out_date_depression_prescriptions=patients.with_these_medications(
    #     antidepressants_prescriptions_bnf,
    #     returning="date",
    #     on_or_after=f"{index_date_variable} - 1 day",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.03,
    #     },
    # ),
    #     # Combined Depression [Main-Key outcome]
    # out_date_depression=patients.minimum_of(
    #     "tmp_out_date_depression_snomed", "tmp_out_date_depression_hes", "tmp_out_date_depression_death"
    # ),

    #     # Combined Depression [Prescription outcome]
    # out_date_depression_prescription=patients.minimum_of(
    #     "tmp_out_date_depression_snomed", "tmp_out_date_depression_hes", "tmp_out_date_depression_death", "tmp_out_date_depression_prescriptions"
    # ),

    # ## Anxiety - general
    #     # Primary Care
    # tmp_out_date_anxiety_general_snomed=patients.with_these_clinical_events(
    #     anxiety_general_snomed_clinical,
    #     returning="date",
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # HES
    # tmp_out_date_anxiety_general_hes=patients.admitted_to_hospital(
    #     returning="date_admitted",
    #     with_these_diagnoses=anxiety_icd10,
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # ONS
    # tmp_out_date_anxiety_general_death=patients.with_these_codes_on_death_certificate(
    #     anxiety_icd10,
    #     returning="date_of_death",
    #     on_or_after=f"{index_date_variable}",
    #     match_only_underlying_cause=True,
    #     date_format="YYYY-MM-DD",
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),  
    #    # Prescriptions
    # tmp_out_date_anxiolytics_snomed_prescriptions=patients.with_these_medications(
    #     anxiolytics_prescriptions_bnf,
    #     returning="date",
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # Combined Anxiety [Main-Key outcome]
    # out_date_anxiety_general=patients.minimum_of(
    #     "tmp_out_date_anxiety_general_snomed", "tmp_out_date_anxiety_general_hes", "tmp_out_date_anxiety_general_death"
    # ),
    #     # Combined Anxiety General [Prescription outcome]
    # out_date_anxiety_general_prescription=patients.minimum_of(
    #     "tmp_out_date_anxiety_general_snomed", "tmp_out_date_anxiety_general_hes", "tmp_out_date_anxiety_general_death", "tmp_out_date_anxiolytics_snomed_prescriptions"
    # ),

    # ## Anxiety - Obsessive Compulsive Disorder
    #     # Primary care
    # tmp_out_date_anxiety_ocd_snomed=patients.with_these_clinical_events(
    #     anxiety_ocd_snomed_clinical,
    #     returning="date",
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # HES
    # tmp_out_date_anxiety_ocd_hes=patients.admitted_to_hospital(
    #     returning="date_admitted",
    #     with_these_diagnoses=ocd_icd10,
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # ONS
    # tmp_out_date_anxiety_ocd_death=patients.with_these_codes_on_death_certificate(
    #     ocd_icd10,
    #     returning="date_of_death",
    #     on_or_after=f"{index_date_variable}",
    #     match_only_underlying_cause=True,
    #     date_format="YYYY-MM-DD",
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.03
    #     },
    # ),  
    #     # Combined Anxiety OCD [Main outcome]
    # out_date_anxiety_ocd=patients.minimum_of(
    #     "tmp_out_date_anxiety_ocd_snomed", "tmp_out_date_anxiety_ocd_hes", "tmp_out_date_anxiety_ocd_death"
    # ),

    # ## Anxiety - Post Traumatic Stress Disorder
    #     # Primary care
    # tmp_out_date_anxiety_ptsd_snomed=patients.with_these_clinical_events(
    #     anxiety_ptsd_snomed_clinical,
    #     returning="date",
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # HES
    # tmp_out_date_anxiety_ptsd_hes=patients.admitted_to_hospital(
    #     returning="date_admitted",
    #     with_these_diagnoses=ptsd_icd10,
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.03,
    #     },
    # ),
    #     # ONS
    # tmp_out_date_anxiety_ptsd_death=patients.with_these_codes_on_death_certificate(
    #     ptsd_icd10,
    #     returning="date_of_death",
    #     on_or_after=f"{index_date_variable}",
    #     match_only_underlying_cause=True,
    #     date_format="YYYY-MM-DD",
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ), 
    #     # Combined Anxiety PTSD [Main outcome]
    # out_date_anxiety_ptsd=patients.minimum_of(
    #     "tmp_out_date_anxiety_ptsd_snomed", "tmp_out_date_anxiety_ptsd_hes", "tmp_out_date_anxiety_ptsd_death"
    # ),    

    # ## Eating disorders
    #     # Primary care
    # tmp_out_date_eating_disorders_snomed=patients.with_these_clinical_events(
    #     eating_disorders_snomed_clinical,
    #     returning="date",
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # HES
    # tmp_out_date_eating_disorders_hes=patients.admitted_to_hospital(
    #     returning="date_admitted",
    #     with_these_diagnoses=eating_disorder_icd10,
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # ONS
    # tmp_out_date_eating_disorders_death=patients.with_these_codes_on_death_certificate(
    #     eating_disorder_icd10,
    #     returning="date_of_death",
    #     on_or_after=f"{index_date_variable}",
    #     match_only_underlying_cause=True,
    #     date_format="YYYY-MM-DD",
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ), 
    #     # Combined Eating Disorders [Main outcome]
    # out_date_eating_disorders=patients.minimum_of(
    #     "tmp_out_date_eating_disorders_snomed", "tmp_out_date_eating_disorders_hes", "tmp_out_date_eating_disorders_death"
    # ),

    # ## Serious Mental Illness
    #     # Primary care
    # tmp_out_date_serious_mental_illness_snomed=patients.with_these_clinical_events(
    #     serious_mental_illness_snomed_clinical,
    #     returning="date",
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # HES 
    # tmp_out_date_serious_mental_illness_hes=patients.admitted_to_hospital(
    #     returning="date_admitted",
    #     with_these_diagnoses=serious_mental_illness_icd10,
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # ONS
    # tmp_out_date_serious_mental_illness_death=patients.with_these_codes_on_death_certificate(
    #     serious_mental_illness_icd10,
    #     returning="date_of_death",
    #     on_or_after=f"{index_date_variable}",
    #     match_only_underlying_cause=True,
    #     date_format="YYYY-MM-DD",
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ), 
    #     # Prescriptions
    # tmp_out_date_serious_mental_illness_prescriptions=patients.with_these_medications(
    #     antipsychotics_prescriptions_bnf,
    #     returning="date",
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.03,
    #     },
    # ),
    #     # Combined Serious Mental Illness [Main-Key outcome]
    # out_date_serious_mental_illness=patients.minimum_of(
    #     "tmp_out_date_serious_mental_illness_snomed", "tmp_out_date_serious_mental_illness_hes", "tmp_out_date_serious_mental_illness_death"
    # ),
    #     # Serious Mental Illness [Prescription Outcome]
    # out_date_serious_mental_illness_prescription=patients.minimum_of(
    #     "tmp_out_date_serious_mental_illness_snomed", "tmp_out_date_serious_mental_illness_hes", "tmp_out_date_serious_mental_illness_death", "tmp_out_date_serious_mental_illness_prescriptions"
    # ),

    # ## # SELF HARM
    #     # Primary care
    # tmp_out_date_self_harm_snomed=patients.with_these_clinical_events(
    #     self_harm_15_10_combined_snomed,
    #     returning="date",
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # HES
    # tmp_out_date_self_harm_hes=patients.admitted_to_hospital(
    #     returning="date_admitted",
    #     with_these_diagnoses=self_harm_15_10_combined_icd,
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # ONS
    # tmp_out_date_self_harm_death=patients.with_these_codes_on_death_certificate(
    #     self_harm_15_10_combined_icd,
    #     returning="date_of_death",
    #     on_or_after=f"{index_date_variable}",
    #     match_only_underlying_cause=True,
    #     date_format="YYYY-MM-DD",
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ), 
    #     # Combined Self Harm [Main-Key Outcome]
    # out_date_self_harm=patients.minimum_of(
    #     "tmp_out_date_self_harm_snomed", "tmp_out_date_self_harm_hes", "tmp_out_date_self_harm_death"
    # ),

    # ## Suicide
    #     # HES
    # tmp_out_date_suicide_hes=patients.admitted_to_hospital(
    #     returning="date_admitted",
    #     with_these_diagnoses=suicide_icd10,
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # ONS
    # tmp_out_date_suicide_death=patients.with_these_codes_on_death_certificate(
    #     suicide_icd10,
    #     returning="date_of_death",
    #     on_or_after=f"{index_date_variable}",
    #     match_only_underlying_cause=True,
    #     date_format="YYYY-MM-DD",
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # Combined Suicide [Main Outcome]
    # out_date_suicide=patients.minimum_of(
    #     "tmp_out_date_suicide_hes", "tmp_out_date_suicide_death"
    # ),     

    # ## Addiction
    #     # Primary care
    # tmp_out_date_addiction_snomed=patients.with_these_clinical_events(
    #     addiction_snomed_clinical,
    #     returning="date",
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # HES
    # tmp_out_date_addiction_hes=patients.admitted_to_hospital(
    #     returning="date_admitted",
    #     with_these_diagnoses=opioid_misuse_icd10,
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ),
    #     # ONS
    # tmp_out_date_addiction_death=patients.with_these_codes_on_death_certificate(
    #     opioid_misuse_icd10,
    #     returning="date_of_death",
    #     on_or_after=f"{index_date_variable}",
    #     match_only_underlying_cause=True,
    #     date_format="YYYY-MM-DD",
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.1,
    #     },
    # ), 
    #     # Prescription
    # tmp_out_date_opioid_snomed_prescriptions=patients.with_these_medications(
    #     opioids_prescriptions_bnf,
    #     returning="date",
    #     on_or_after=f"{index_date_variable}",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date_variable", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.03,
    #     },
    # ),
    #     # Combined Addiction [Main Outcome]
    # out_date_addiction=patients.minimum_of(
    #     "tmp_out_date_addiction_snomed", "tmp_out_date_addiction_hes","tmp_out_date_addiction_death"
    # ),
    #     # Combined Addiction [Prescription Outcome]
    # out_date_addiction_prescription=patients.minimum_of(
    #     "tmp_out_date_addiction_snomed", "tmp_out_date_addiction_hes","tmp_out_date_addiction_death", "tmp_out_date_opioid_snomed_prescriptions"
    # ),

#####################
# DEFINE COVARIATES #
#####################

    ## Age
    cov_num_age = patients.age_as_of(
        f"{index_date_variable} - 1 day",
        return_expectations = {
        "rate": "universal",
        "int": {"distribution": "population_ages"},
        "incidence" : 0.001
        },
    ),

    ## Ethnicity 
    cov_cat_ethnicity=patients.categorised_as(
        helpers.generate_ethnicity_dictionary(6),
        cov_ethnicity_sus=patients.with_ethnicity_from_sus(
            returning="group_6", use_most_frequent_code=True
        ),
        cov_ethnicity_gp_opensafely=patients.with_these_clinical_events(
            opensafely_ethnicity_codes_6,
            on_or_before=f"{index_date_variable} - 1 day",
            returning="category",
            find_last_match_in_period=True,
        ),
        cov_ethnicity_gp_primis=patients.with_these_clinical_events(
            primis_covid19_vacc_update_ethnicity,
            on_or_before=f"{index_date_variable} -1 day",
            returning="category",
            find_last_match_in_period=True,
        ),
        cov_ethnicity_gp_opensafely_date=patients.with_these_clinical_events(
            opensafely_ethnicity_codes_6,
            on_or_before=f"{index_date_variable} -1 day",
            returning="category",
            find_last_match_in_period=True,
        ),
        cov_ethnicity_gp_primis_date=patients.with_these_clinical_events(
            primis_covid19_vacc_update_ethnicity,
            on_or_before=f"{index_date_variable} - 1 day",
            returning="category",
            find_last_match_in_period=True,
        ),
        return_expectations=helpers.generate_universal_expectations(5,True),
    ),

    ## Deprivation
    cov_cat_deprivation=patients.categorised_as(
        helpers.generate_deprivation_ntile_dictionary(10),
        index_of_multiple_deprivation=patients.address_as_of(
            f"{index_date_variable} - 1 day",
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
        ),
        return_expectations=helpers.generate_universal_expectations(10,False),
    ),

    ## Region
    cov_cat_region=patients.registered_practice_as_of(
        f"{index_date_variable} - 1 day",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and The Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East": 0.1,
                    "London": 0.2,
                    "South East": 0.1,
                    "South West": 0.1,
                },
            },
        },
    ),

    ## Smoking status
    cov_cat_smoking_status=patients.categorised_as(
        {
            "S": "most_recent_smoking_code = 'S'",
            "E": """
                most_recent_smoking_code = 'E' OR (
                most_recent_smoking_code = 'N' AND ever_smoked
                )
            """,
            "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
            "M": "DEFAULT",
        },
        return_expectations={
            "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
        },
        most_recent_smoking_code=patients.with_these_clinical_events(
            smoking_clear,
            find_last_match_in_period=True,
            on_or_before=f"{index_date_variable} -1 day",
            returning="category",
        ),
        ever_smoked=patients.with_these_clinical_events(
            filter_codes_by_category(smoking_clear, include=["S", "E"]),
            on_or_before=f"{index_date_variable} -1 day",
        ),
    ),

    ## Care home status
    cov_bin_carehome_status=patients.care_home_status_as_of(
        f"{index_date_variable} -1 day", 
        categorised_as={
            "TRUE": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='Y'
              AND LocationRequiresNursing='N'
            """,
            "TRUE": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='N'
              AND LocationRequiresNursing='Y'
            """,
            "TRUE": "IsPotentialCareHome",
            "FALSE": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"TRUE": 0.30, "FALSE": 0.70},},
        },
    ),

    ## Acute myocardial infarction
    ### Primary care
    tmp_cov_bin_ami_snomed=patients.with_these_clinical_events(
        ami_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_ami_prior_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=ami_prior_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    tmp_cov_bin_ami_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=ami_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_ami=patients.maximum_of(
        "tmp_cov_bin_ami_snomed", "tmp_cov_bin_ami_prior_hes", "tmp_cov_bin_ami_hes",
    ),

    ## All stroke
    ### Primary care
    tmp_cov_bin_stroke_isch_snomed=patients.with_these_clinical_events(
        stroke_isch_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    tmp_cov_bin_stroke_sah_hs_snomed=patients.with_these_clinical_events(
        stroke_sah_hs_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_stroke_isch_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=stroke_isch_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    tmp_cov_bin_stroke_sah_hs_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=stroke_sah_hs_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
        ### Combined
    cov_bin_all_stroke=patients.maximum_of(
        "tmp_cov_bin_stroke_isch_hes", "tmp_cov_bin_stroke_isch_snomed", "tmp_cov_bin_stroke_sah_hs_hes", "tmp_cov_bin_stroke_sah_hs_snomed",
    ),

        ### Combined Stroke Ischeamic
    cov_bin_stroke_isch=patients.maximum_of(
        "tmp_cov_bin_stroke_isch_hes", "tmp_cov_bin_stroke_isch_snomed",
    ),

    ## Other Arterial Embolism
    ### Primary care
    tmp_cov_bin_other_arterial_embolism_snomed=patients.with_these_clinical_events(
        other_arterial_embolism_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_other_arterial_embolism_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=ami_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_other_arterial_embolism=patients.maximum_of(
        "tmp_cov_bin_other_arterial_embolism_snomed", "tmp_cov_bin_other_arterial_embolism_hes",
    ),
    
    ## Venous thrombolism events
    ### Primary care
    tmp_cov_bin_vte_snomed=patients.with_these_clinical_events(
        all_vte_codes_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_vte_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=all_vte_codes_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_vte=patients.maximum_of(
        "tmp_cov_bin_vte_snomed", "tmp_cov_bin_vte_hes",
    ),

    ## Heart failure
    ### Primary care
    tmp_cov_bin_hf_snomed=patients.with_these_clinical_events(
        hf_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_hf_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=hf_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_hf=patients.maximum_of(
        "tmp_cov_bin_hf_snomed", "tmp_cov_bin_hf_hes",
    ),

    ## Angina
    ### Primary care
    tmp_cov_bin_angina_snomed=patients.with_these_clinical_events(
        angina_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_angina_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=angina_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_angina=patients.maximum_of(
        "tmp_cov_bin_angina_snomed", "tmp_cov_bin_angina_hes",
    ),

    ## Dementia
    ### Primary care
    tmp_cov_bin_dementia_snomed=patients.with_these_clinical_events(
        dementia_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC (Hospital Episode Statistics Admitted Patient Care)
    tmp_cov_bin_dementia_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=dementia_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Primary care - vascular
    tmp_cov_bin_dementia_vascular_snomed=patients.with_these_clinical_events(
        dementia_vascular_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC - vascular
    tmp_cov_bin_dementia_vascular_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=dementia_vascular_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_dementia=patients.maximum_of(
        "tmp_cov_bin_dementia_snomed", "tmp_cov_bin_dementia_hes", "tmp_cov_bin_dementia_vascular_snomed", "tmp_cov_bin_dementia_vascular_hes",
    ),    

    ## Liver disease
     ### Primary care
    tmp_cov_bin_liver_disease_snomed=patients.with_these_clinical_events(
        liver_disease_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_liver_disease_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=liver_disease_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_liver_disease=patients.maximum_of(
        "tmp_cov_bin_liver_disease_snomed", "tmp_cov_bin_liver_disease_hes",
    ),

    ## Chronic kidney disease
    ### Primary care
    tmp_cov_bin_chronic_kidney_disease_snomed=patients.with_these_clinical_events(
        ckd_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_chronic_kidney_disease_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=ckd_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_chronic_kidney_disease=patients.maximum_of(
        "tmp_cov_bin_chronic_kidney_disease_snomed", "tmp_cov_bin_chronic_kidney_disease_hes",
    ),

    ## Cancer
    ### Primary care
    tmp_cov_bin_cancer_snomed=patients.with_these_clinical_events(
        cancer_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_cancer_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=cancer_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_cancer=patients.maximum_of(
        "tmp_cov_bin_cancer_snomed", "tmp_cov_bin_cancer_hes",
    ),

    ## Hypertension
    ### Primary care
    tmp_cov_bin_hypertension_snomed=patients.with_these_clinical_events(
        hypertension_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_hypertension_hes=patients.admitted_to_hospital(
       returning='binary_flag',
       with_these_diagnoses=hypertension_icd10,
       on_or_before=f"{index_date_variable} - 1 day",
       return_expectations={"incidence": 0.1},
    ),
    ### DMD
    tmp_cov_bin_hypertension_drugs_dmd=patients.with_these_medications(
        hypertension_drugs_dmd,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_hypertension=patients.maximum_of(
        "tmp_cov_bin_hypertension_snomed", "tmp_cov_bin_hypertension_hes", "tmp_cov_bin_hypertension_drugs_dmd",
    ),

    ## Type 1 diabetes primary care
    cov_bin_diabetes_type1_snomed=patients.with_these_clinical_events(
        diabetes_type1_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ## Type 1 diabetes HES
    cov_bin_diabetes_type1_hes=patients.admitted_to_hospital(
       returning='binary_flag',
       with_these_diagnoses=diabetes_type1_icd10,
       on_or_before=f"{index_date_variable} - 1 day",
       return_expectations={"incidence": 0.1},
    ),
    ## Type 2 diabetes primary care
    cov_bin_diabetes_type2_snomed=patients.with_these_clinical_events(
        diabetes_type2_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ## Type 2 diabetes HES
    cov_bin_diabetes_type2_hes=patients.admitted_to_hospital(
       returning='binary_flag',
       with_these_diagnoses=diabetes_type2_icd10,
       on_or_before=f"{index_date_variable} - 1 day",
       return_expectations={"incidence": 0.1},
    ),
    ## Other or non-specific diabetes
    cov_bin_diabetes_other=patients.with_these_clinical_events(
        diabetes_other_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ## Gestational diabetes
    cov_bin_diabetes_gestational=patients.with_these_clinical_events(
        diabetes_gestational_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ## Diabetes medication
    tmp_cov_bin_insulin_snomed=patients.with_these_medications(
        insulin_snomed_clinical,
        returning="binary_flag",
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.05},
    ),

    tmp_cov_bin_antidiabetic_drugs_snomed=patients.with_these_medications(
        antidiabetic_drugs_snomed_clinical,
        returning="binary_flag",
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.05},
    ),

    ## Any diabetes covariate
    cov_bin_diabetes=patients.maximum_of(
        "cov_bin_diabetes_type1_snomed", "cov_bin_diabetes_type1_hes", 
        "cov_bin_diabetes_type2_snomed", "cov_bin_diabetes_type2_hes",
        "cov_bin_diabetes_other", "cov_bin_diabetes_gestational",
        "tmp_cov_bin_insulin_snomed", "tmp_cov_bin_antidiabetic_drugs_snomed",
    ),

        ## Prediabetes
    cov_bin_prediabetes=patients.with_these_clinical_events(
        prediabetes_snomed,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),

    ## Obesity
    ### Primary care
    tmp_cov_bin_obesity_snomed=patients.with_these_clinical_events(
        bmi_obesity_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_obesity_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=bmi_obesity_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_obesity=patients.maximum_of(
        "tmp_cov_bin_obesity_snomed", "tmp_cov_bin_obesity_hes",
    ),

    ## Chronic obstructive pulmonary disease
    ### Primary care
    tmp_cov_bin_chronic_obstructive_pulmonary_disease_snomed=patients.with_these_clinical_events(
        copd_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES APC
    tmp_cov_bin_chronic_obstructive_pulmonary_disease_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses= copd_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined
    cov_bin_chronic_obstructive_pulmonary_disease=patients.maximum_of(
        "tmp_cov_bin_chronic_obstructive_pulmonary_disease_snomed", "tmp_cov_bin_chronic_obstructive_pulmonary_disease_hes",
    ),

    ## Lipid medications
    cov_bin_lipid_medications=patients.with_these_medications(
        lipid_lowering_dmd,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),

    ## Antiplatelet_medications
    cov_bin_antiplatelet_medications=patients.with_these_medications(
        antiplatelet_dmd,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),

    ## Anticoagulation_medications
    cov_bin_anticoagulation_medications=patients.with_these_medications(
        anticoagulant_dmd, 
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),

    ## Combined oral contraceptive pill
    ### dmd: dictionary of medicines and devices
    cov_bin_combined_oral_contraceptive_pill=patients.with_these_medications(
        cocp_dmd, 
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),

    ## Hormone replacement therapy
    cov_bin_hormone_replacement_therapy=patients.with_these_medications(
        hrt_dmd, 
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.1},
    ),

    ## Total Cholesterol
    tmp_cov_num_cholesterol=patients.max_recorded_value(
        cholesterol_snomed,
        on_most_recent_day_of_measurement=True, 
        between=[f"{index_date_variable} - 5years", f"{index_date_variable} - 1 day"],
        date_format="YYYY-MM-DD",
        return_expectations={
            "float": {"distribution": "normal", "mean": 5.0, "stddev": 2.5},
            "date": {"earliest":study_dates["earliest_expec"], "latest": "today"}, ##return_expectations can't take dynamic variable se default are kept here! 
            "incidence": 0.80,
        },
    ),

############################
# Mental Health Covariates # 
############################

### Mental health covariates: General
    ## Depression
    ### Primary care
    tmp_cov_bin_depression_snomed=patients.with_these_clinical_events(
        depression_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.03},
    ),
     ### HES
    tmp_cov_bin_depression_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=depression_icd10,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.03},
    ),
     ### Combined Depression
    sub_bin_depression=patients.maximum_of(
        "tmp_cov_bin_depression_snomed", "tmp_cov_bin_depression_icd10",
    ), 

    ## Anxiety - general
    ### Primary care
    tmp_cov_bin_anxiety_general_snomed=patients.with_these_clinical_events(
        anxiety_combined_snomed_cov,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.03},
    ),
     ### HES
    tmp_cov_bin_anxiety_general_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=anxiety_combined_hes_cov,
        on_or_before=f"{index_date_variable} - 1 day",
        return_expectations={"incidence": 0.03},
    ),
     ### Combined Anxiety
    sub_bin_anxiety_general=patients.maximum_of(
        "tmp_cov_bin_anxiety_general_snomed", "tmp_cov_bin_anxiety_general_hes",
    ),   

    ## Serious mental illness
    ### Primary care
    tmp_cov_bin_serious_mental_illness_snomed=patients.with_these_clinical_events(
        serious_mental_illness_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} + 1 day",
        return_expectations={"incidence": 0.03},
    ),
     ### HES
    tmp_cov_bin_serious_mental_illness_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=serious_mental_illness_icd10,
        on_or_before=f"{index_date_variable} + 1 day",
        return_expectations={"incidence": 0.03},
    ),
     ### Combined serious mental illness
    sub_bin_serious_mental_illness=patients.maximum_of(
        "tmp_cov_bin_serious_mental_illness_snomed", "tmp_cov_bin_serious_mental_illness_icd10",
    ),       

    ## SELF HARM
    ### Primary care
    tmp_cov_bin_self_harm_snomed=patients.with_these_clinical_events(
        self_harm_15_10_combined_snomed,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} + 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### HES
    tmp_cov_bin_self_harm_hes=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=self_harm_15_10_combined_icd,
        on_or_before=f"{index_date_variable} + 1 day",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined Self harm
    sub_bin_self_harm=patients.maximum_of(
        "tmp_cov_bin_self_harm_snomed", "tmp_cov_bin_self_harm_hes",
    ), 

#####################
### History of... ###
#####################

## History of depression 
     ### Primary care
    tmp_cov_bin_history_depression_snomed=patients.with_these_clinical_events(
        depression_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 169 days",
        return_expectations={"incidence": 0.1},
    ),
     ### HES
    tmp_cov_bin_history_depression_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=depression_icd10,
        on_or_before=f"{index_date_variable} - 169 days",
        return_expectations={"incidence": 0.1},
    ),
     ### Combined History of Depression
    cov_bin_history_depression=patients.maximum_of(
        "tmp_cov_bin_history_depression_snomed", "tmp_cov_bin_history_depression_icd10",
    ),

     ### Depression history
    # sub_bin_history_depression=patients.maximum_of(
    #     "tmp_cov_bin_depression_snomed", "tmp_cov_bin_depression_icd10",
    # ), 

    ## History of anxiety
     ### Primary care
    tmp_cov_bin_history_anxiety_general=patients.with_these_clinical_events(
        anxiety_combined_snomed_cov,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 169 days",
        return_expectations={"incidence": 0.1},
    ),
     ### HES
    tmp_cov_bin_history_anxiety_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=anxiety_combined_hes_cov,
        on_or_before=f"{index_date_variable} - 169 days",
        return_expectations={"incidence": 0.1},
    ),    
    ### Combined History of anxiety
    cov_bin_history_anxiety=patients.maximum_of(
        "tmp_cov_bin_history_anxiety_general", "tmp_cov_bin_history_anxiety_icd10",
    ),

    ### Combined History of anxiety
    # sub_bin_history_anxiety=patients.maximum_of(
    #     "tmp_cov_bin_history_anxiety_general", "tmp_cov_bin_history_anxiety_icd10",
    # ),

    ## History of Eating disorders
    ### Primary care
    tmp_cov_bin_history_eating_disorders=patients.with_these_clinical_events(
        eating_disorders_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 169 days",
        return_expectations={"incidence": 0.1},
    ),
    ### HES
    tmp_cov_bin_history_eating_disorders_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=eating_disorder_icd10,
        on_or_before=f"{index_date_variable} - 169 days",
        return_expectations={"incidence": 0.1},
    ),
    ### Combined History of eating disorders
    cov_bin_history_eating_disorders=patients.maximum_of(
        "tmp_cov_bin_history_eating_disorders", "tmp_cov_bin_history_eating_disorders_icd10",
    ),

    ## History of Serious mental illness
    ### Primary Care
    tmp_cov_bin_history_serious_mental_illness=patients.with_these_clinical_events(
        serious_mental_illness_snomed_clinical,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 169 days",
        return_expectations={"incidence": 0.1},
    ),
    ### HES
    tmp_cov_bin_history_serious_mental_illness_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=serious_mental_illness_icd10,
        on_or_before=f"{index_date_variable} - 169 days",
        return_expectations={"incidence": 0.1},
    ), 
    ### Combined History of Serious mental illness
    cov_bin_history_serious_mental_illness=patients.maximum_of(
        "tmp_cov_bin_history_serious_mental_illness", "tmp_cov_bin_history_serious_mental_illness_icd10",
    ),

    ### Combined History of Serious mental illness
    # sub_bin_history_serious_mental_illness=patients.maximum_of(
    #     "tmp_cov_bin_history_serious_mental_illness", "tmp_cov_bin_history_serious_mental_illness_icd10",
    # ),

    ## SELF HARM - HISTORY
    # History report snomed
    tmp_cov_bin_history_self_harm_snomed=patients.with_these_clinical_events(
        self_harm_15_10_combined_snomed,
        returning='binary_flag',
        on_or_before=f"{index_date_variable} - 169 days",
        return_expectations={"incidence": 0.1},
    ),
    # History report icd10
    tmp_cov_bin_history_self_harm_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=self_harm_15_10_combined_icd,
        on_or_before=f"{index_date_variable} - 169 days",
        return_expectations={"incidence": 0.1},
    ), 

    ### Combined History Report of Self harm
    cov_bin_history_self_harm=patients.maximum_of(
        "tmp_cov_bin_history_self_harm_snomed", "tmp_cov_bin_history_self_harm_icd10",
    ),

    ### Combined History Report of Self harm
    # sub_bin_history_self_harm=patients.maximum_of(
    #     "tmp_cov_bin_history_self_harm_snomed", "tmp_cov_bin_history_self_harm_icd10",
    # ),

############################
### Recent Episode of... ###
############################

    ## Recent Episode of depression
    ### Primary care
    tmp_cov_bin_recent_depression_snomed=patients.with_these_clinical_events(
        depression_snomed_clinical,
        returning='binary_flag',
        between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
        return_expectations={"incidence": 0.1},
    ),
     ### HES
    tmp_cov_bin_recent_depression_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=depression_icd10,
        between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
        return_expectations={"incidence": 0.1},
    ),
     ### Combined Recent Episode of depression
     cov_bin_recent_depression=patients.maximum_of(
        "tmp_cov_bin_recent_depression_snomed", "tmp_cov_bin_recent_depression_icd10",
    ), 

     ### Depression recent
    # sub_bin_recent_depression=patients.maximum_of(
    #     "tmp_cov_bin_depression_snomed", "tmp_cov_bin_depression_icd10",
    # ), 

    # Recent Episode of anxiety
     ### Primary care
    tmp_cov_bin_recent_anxiety_general=patients.with_these_clinical_events(
        anxiety_combined_snomed_cov,
        returning='binary_flag',
        between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"], 
        return_expectations={"incidence": 0.1},
    ),
     ### HES
    tmp_cov_bin_recent_anxiety_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=anxiety_combined_hes_cov,
        between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
        return_expectations={"incidence": 0.1},
    ),    
     ### Combined Recent Episode of of anxiety
    cov_bin_recent_anxiety=patients.maximum_of(
        "tmp_cov_bin_recent_anxiety_general", "tmp_cov_bin_recent_anxiety_icd10",
    ),

     ### Combined Recent Episode of of anxiety
    # sub_bin_recent_anxiety=patients.maximum_of(
    #     "tmp_cov_bin_recent_anxiety_general", "tmp_cov_bin_recent_anxiety_icd10",
    # ),

    ## Recent Diagnosis of eating disorders
        ### Primary care
    tmp_cov_bin_recent_eating_disorders=patients.with_these_clinical_events(
        eating_disorders_snomed_clinical,
        returning='binary_flag',
        between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 days"],
        return_expectations={"incidence": 0.1},
    ),
        ### HES
    tmp_cov_bin_recent_eating_disorders_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=eating_disorder_icd10,
        between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 days"],
        return_expectations={"incidence": 0.1},
    ), 
    ### Combined Recent diagnostic of eating disorders
    cov_bin_recent_eating_disorders=patients.maximum_of(
        "tmp_cov_bin_recent_eating_disorders", "tmp_cov_bin_recent_eating_disorders_icd10",
    ),

    ## Recent Report of a serious mental illness
    ### Primary Care
    tmp_cov_bin_recent_serious_mental_illness=patients.with_these_clinical_events(
        serious_mental_illness_snomed_clinical,
        returning='binary_flag',
        between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 days"], 
        return_expectations={"incidence": 0.1},
    ),
    ### HES
    tmp_cov_bin_recent_serious_mental_illness_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=serious_mental_illness_icd10,
        between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 days"], 
        return_expectations={"incidence": 0.1},
    ), 
    ### Combined Report of a Serious mental illness
    cov_bin_recent_serious_mental_illness=patients.maximum_of(
        "tmp_cov_bin_recent_serious_mental_illness", "tmp_cov_bin_recent_serious_mental_illness_icd10",
    ),

    ### Combined Report of a Serious mental illness
    # sub_bin_recent_serious_mental_illness=patients.maximum_of(
    #     "tmp_cov_bin_recent_serious_mental_illness", "tmp_cov_bin_recent_serious_mental_illness_icd10",
    # ),

    ## SELF HARM - RECENT
    # Recent report snomed
    tmp_cov_bin_recent_self_harm_snomed=patients.with_these_clinical_events(
        self_harm_15_10_combined_snomed,
        returning='binary_flag',
        between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
        return_expectations={"incidence": 0.1},
    ),

    # Recent report icd10
    tmp_cov_bin_recent_self_harm_icd10=patients.admitted_to_hospital(
        returning='binary_flag',
        with_these_diagnoses=self_harm_15_10_combined_icd,
        between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
        return_expectations={"incidence": 0.1},
    ),   

    ### Combined Recent Report of Self harm
    cov_bin_recent_self_harm=patients.maximum_of(
        "tmp_cov_bin_recent_self_harm_snomed", "tmp_cov_bin_recent_self_harm_icd10",
    ),

    ### Combined Recent Report of Self harm
    # sub_bin_recent_self_harm=patients.maximum_of(
    #     "tmp_cov_bin_recent_self_harm_snomed", "tmp_cov_bin_recent_self_harm_icd10",
    # ),

############################
############################

    ## HDL Cholesterol
    tmp_cov_num_hdl_cholesterol=patients.max_recorded_value(
        hdl_cholesterol_snomed,
        on_most_recent_day_of_measurement=True, 
        between=[f"{index_date_variable}- 5years", f"{index_date_variable} - 1 day"],
        date_format="YYYY-MM-DD",
        return_expectations={
            "float": {"distribution": "normal", "mean": 2.0, "stddev": 1.5},
            "date": {"earliest": study_dates["earliest_expec"] , "latest": "today"},
            "incidence": 0.80,
        },
    ),

    ## BMI
    # taken from: https://github.com/opensafely/BMI-and-Metabolic-Markers/blob/main/analysis/common_variables.py 
    cov_num_bmi=patients.most_recent_bmi(
        on_or_before=f"{index_date_variable} -1 day",
        minimum_age_at_measurement=18,
        include_measurement_date=True,
        date_format="YYYY-MM",
        return_expectations={
            "date": {"earliest": "2010-02-01", "latest": "2022-02-01"}, ##How do we obtain these dates ? 
            "float": {"distribution": "normal", "mean": 28, "stddev": 8},
            "incidence": 0.7,
        },
    ),
     ### Categorising BMI
    cov_cat_bmi_groups = patients.categorised_as(
        {
            "Underweight": "cov_num_bmi < 18.5 AND cov_num_bmi > 12", 
            "Healthy_weight": "cov_num_bmi >= 18.5 AND cov_num_bmi < 25", 
            "Overweight": "cov_num_bmi >= 25 AND cov_num_bmi < 30",
            "Obese": "cov_num_bmi >=30 AND cov_num_bmi <70", 
            "Missing": "DEFAULT", 
        }, 
        return_expectations = {
            "rate": "universal", 
            "category": {
                "ratios": {
                    "Underweight": 0.05, 
                    "Healthy_weight": 0.25, 
                    "Overweight": 0.4,
                    "Obese": 0.3, 
                }
            },
        },
        
    ),

############################
##### DEFINE SUBGROUPS #####
############################

 ## COVID-19 severity
    # sub_date_covid19_hospital=patients.admitted_to_hospital(
    #     with_these_primary_diagnoses=covid_codes,
    #     returning="date_admitted",
    #     on_or_after="exp_date_covid19_confirmed",
    #     date_format="YYYY-MM-DD",
    #     find_first_match_in_period=True,
    #     return_expectations={
    #         "date": {"earliest": "index_date", "latest" : "today"},
    #         "rate": "uniform",
    #         "incidence": 0.5,
    #     },
    # ),
    ## History of COVID-19 
    ### Positive SARS-COV-2 PCR antigen test
    # tmp_sub_bin_covid19_confirmed_history_sgss=patients.with_test_result_in_sgss(
    #     pathogen="SARS-CoV-2",
    #     test_result="positive",
    #     returning='binary_flag',
    #     on_or_before=f"{index_date_variable} - 1 day",
    #     return_expectations={"incidence": 0.1},
    # ),
    ### COVID-19 code (diagnosis, positive test or sequalae) in primary care
    # tmp_sub_bin_covid19_confirmed_history_snomed=patients.with_these_clinical_events(
    #     combine_codelists(
    #         covid_primary_care_code,
    #         covid_primary_care_positive_test,
    #         covid_primary_care_sequalae,
    #     ),
    #     returning='binary_flag',
    #     on_or_before=f"{index_date_variable} - 1 day",
    #     return_expectations={"incidence": 0.1},
    # ),
    ### Hospital episode with confirmed diagnosis in any position
    # tmp_sub_bin_covid19_confirmed_history_hes=patients.admitted_to_hospital(
    #     with_these_diagnoses=covid_codes,
    #     returning='binary_flag',
    #     on_or_before=f"{index_date_variable} - 1  day",
    #     return_expectations={"incidence": 0.1},
    # ),
    ## Generate variable to identify first date of confirmed COVID
    # sub_bin_covid19_confirmed_history=patients.maximum_of(
    #     "tmp_sub_bin_covid19_confirmed_history_sgss","tmp_sub_bin_covid19_confirmed_history_snomed","tmp_sub_bin_covid19_confirmed_history_hes"
    # ),

############################
############################

# Define quality assurances

    ## Prostate cancer
        ### Primary care
        prostate_cancer_snomed=patients.with_these_clinical_events(
            prostate_cancer_snomed_clinical,
            returning='binary_flag',
            return_expectations={
                "incidence": 0.03,
            },
        ),
        ### HES APC
        prostate_cancer_hes=patients.admitted_to_hospital(
            with_these_diagnoses=prostate_cancer_icd10,
            returning='binary_flag',
            return_expectations={
                "incidence": 0.03,
            },
        ),
        ### ONS
        prostate_cancer_death=patients.with_these_codes_on_death_certificate(
            prostate_cancer_icd10,
            returning='binary_flag',
            return_expectations={
                "incidence": 0.02
            },
        ),
        ### Combined
        qa_bin_prostate_cancer=patients.maximum_of(
            "prostate_cancer_snomed", "prostate_cancer_hes", "prostate_cancer_death"
        ),

    ## Pregnancy
        qa_bin_pregnancy=patients.with_these_clinical_events(
            pregnancy_snomed_clinical,
            returning='binary_flag',
            return_expectations={
                "incidence": 0.03,
            },
        ),
    
    ## Year of birth
        qa_num_birth_year=patients.date_of_birth(
            date_format="YYYY",
            return_expectations={
                "date": {"earliest": study_dates["earliest_expec"], "latest": "today"},
                "rate": "uniform",
            },
        ),
        # Define fixed covariates other than sex
# NB: sex is required to determine vaccine eligibility covariates so is defined in study_definition_electively_unvaccinated.py

    ## 2019 consultation rate
        cov_num_consulation_rate=patients.with_gp_consultations(
            between=[days(study_dates["pandemic_start"],-365), days(study_dates["pandemic_start"],-1)],
            returning="number_of_matches_in_period",
            return_expectations={
                "int": {"distribution": "poisson", "mean": 5},
            },
        ),

    ## Healthcare worker    
    cov_bin_healthcare_worker=patients.with_healthcare_worker_flag_on_covid_vaccine_record(
        returning='binary_flag', 
        return_expectations={"incidence": 0.01},
    ),

    )
    return dynamic_variables
