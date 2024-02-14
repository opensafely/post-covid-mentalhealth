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
def generate_common_variables(index_date_variable,exposure_end_date_variable,outcome_end_date_variable):

    dynamic_variables = dict(
    
        # Exposure variables ----------------------------------------------------------------------

            ## COVID-19 
            
                ### SGSS
                tmp_exp_date_covid19_confirmed_sgss=patients.with_test_result_in_sgss(
                    pathogen="SARS-CoV-2",
                    test_result="positive",
                    returning="date",
                    find_first_match_in_period=True,
                    date_format="YYYY-MM-DD",
                    between=[f"{index_date_variable}",f"{exposure_end_date_variable}"],
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### Primary care
                tmp_exp_date_covid19_confirmed_snomed=patients.with_these_clinical_events(
                    combine_codelists(
                        covid_primary_care_code,
                        covid_primary_care_positive_test,
                        covid_primary_care_sequalae,
                    ),
                    returning="date",
                    between=[f"{index_date_variable}",f"{exposure_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### SUS (start date of episode with confirmed diagnosis in any position)
                tmp_exp_date_covid19_confirmed_hes=patients.admitted_to_hospital(
                    with_these_diagnoses=covid_codes,
                    returning="date_admitted",
                    between=[f"{index_date_variable}",f"{exposure_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### Death registry (listed as primary or underlying cause)
                tmp_exp_date_covid19_confirmed_death=patients.with_these_codes_on_death_certificate(
                    covid_codes,
                    returning="date_of_death",
                    between=[f"{index_date_variable}",f"{exposure_end_date_variable}"],
                    match_only_underlying_cause=True,
                    date_format="YYYY-MM-DD",
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1
                    },
                ),

                ### Combined
                exp_date_covid19_confirmed=patients.minimum_of(
                    "tmp_exp_date_covid19_confirmed_sgss","tmp_exp_date_covid19_confirmed_snomed","tmp_exp_date_covid19_confirmed_hes","tmp_exp_date_covid19_confirmed_death"
                ),

        # Inclusion/exclusion variables -----------------------------------------------------------
            
            ## Follow-up for six months prior to study start
                has_follow_up_previous_6months=patients.registered_with_one_practice_between(
                    start_date=f"{index_date_variable} - 6 months",
                    end_date=f"{index_date_variable}",
                    return_expectations={"incidence": 0.95},
                ),

            ## Death flag
                has_died = patients.died_from_any_cause(
                    on_or_before = f"{index_date_variable}",
                    returning="binary_flag",
                    return_expectations={"incidence": 0.01}
                ),

            ## Registration at start flag
                registered_at_start = patients.registered_as_of(
                    f"{index_date_variable}",
                ),

            ## Deregistraton date
                deregistraton_date=patients.date_deregistered_from_all_supported_practices( 
                    date_format = 'YYYY-MM-DD',
                    return_expectations={
                    "date": {"earliest": "2000-01-01", "latest": "today"},
                    "rate": "uniform",
                    "incidence": 0.01
                    },
                ),

        # Subgroup variables ----------------------------------------------------------------------

            ## COVID-19 severity
                sub_date_covid19_hospital = patients.admitted_to_hospital(
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

                ### SGSS
                tmp_sub_bin_covid19_confirmed_history_sgss=patients.with_test_result_in_sgss(
                    pathogen="SARS-CoV-2",
                    test_result="positive",
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),

                ### Primary care
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

                ### SUS (any position)
                tmp_sub_bin_covid19_confirmed_history_hes=patients.admitted_to_hospital(
                    with_these_diagnoses=covid_codes,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),

                ### Combined
                sub_bin_covid19_confirmed_history=patients.maximum_of(
                    "tmp_sub_bin_covid19_confirmed_history_sgss","tmp_sub_bin_covid19_confirmed_history_snomed","tmp_sub_bin_covid19_confirmed_history_hes"
                ),

        # Outcome variables -----------------------------------------------------------------------

            ## Depression
            
                ### Primary Care
                tmp_out_date_depression_snomed=patients.with_these_clinical_events(
                    depression_snomed_clinical,
                    returning="date",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### SUS
                tmp_out_date_depression_hes=patients.admitted_to_hospital(
                    returning="date_admitted",
                    with_these_diagnoses=depression_icd10,
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### Death registry
                tmp_out_date_depression_death=patients.with_these_codes_on_death_certificate(
                    depression_icd10,
                    returning="date_of_death",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    match_only_underlying_cause=True,
                    date_format="YYYY-MM-DD",
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),
            
                ### Combined
                out_date_depression=patients.minimum_of(
                    "tmp_out_date_depression_snomed", "tmp_out_date_depression_hes", "tmp_out_date_depression_death"
                ),

            ## Anxiety - General
                
                ### Primary Care
                tmp_out_date_anxiety_general_snomed=patients.with_these_clinical_events(
                    anxiety_general_snomed_clinical,
                    returning="date",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### SUS
                tmp_out_date_anxiety_general_hes=patients.admitted_to_hospital(
                    returning="date_admitted",
                    with_these_diagnoses=anxiety_icd10,
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### Death registry
                tmp_out_date_anxiety_general_death=patients.with_these_codes_on_death_certificate(
                    anxiety_icd10,
                    returning="date_of_death",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    match_only_underlying_cause=True,
                    date_format="YYYY-MM-DD",
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),  

                ### Combined
                out_date_anxiety_general=patients.minimum_of(
                    "tmp_out_date_anxiety_general_snomed", "tmp_out_date_anxiety_general_hes", "tmp_out_date_anxiety_general_death"
                ),

            ## Anxiety - Post Traumatic Stress Disorder
                
                ### Primary care
                tmp_out_date_anxiety_ptsd_snomed=patients.with_these_clinical_events(
                    anxiety_ptsd_snomed_clinical,
                    returning="date",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### SUS
                tmp_out_date_anxiety_ptsd_hes=patients.admitted_to_hospital(
                    returning="date_admitted",
                    with_these_diagnoses=ptsd_icd10,
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.03,
                    },
                ),

                ### Death registry
                tmp_out_date_anxiety_ptsd_death=patients.with_these_codes_on_death_certificate(
                    ptsd_icd10,
                    returning="date_of_death",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    match_only_underlying_cause=True,
                    date_format="YYYY-MM-DD",
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ), 

                ### Combined
                out_date_anxiety_ptsd=patients.minimum_of(
                    "tmp_out_date_anxiety_ptsd_snomed", "tmp_out_date_anxiety_ptsd_hes", "tmp_out_date_anxiety_ptsd_death"
                ),    

            ## Eating disorders
            
                ### Primary care
                tmp_out_date_eating_disorders_snomed=patients.with_these_clinical_events(
                    eating_disorders_snomed_clinical,
                    returning="date",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### SUS
                tmp_out_date_eating_disorders_hes=patients.admitted_to_hospital(
                    returning="date_admitted",
                    with_these_diagnoses=eating_disorder_icd10,
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### Death registry
                tmp_out_date_eating_disorders_death=patients.with_these_codes_on_death_certificate(
                    eating_disorder_icd10,
                    returning="date_of_death",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    match_only_underlying_cause=True,
                    date_format="YYYY-MM-DD",
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ), 

                ### Combined
                out_date_eating_disorders=patients.minimum_of(
                    "tmp_out_date_eating_disorders_snomed", "tmp_out_date_eating_disorders_hes", "tmp_out_date_eating_disorders_death"
                ),

            ## Serious Mental Illness
                
                ### Primary care
                tmp_out_date_serious_mental_illness_snomed=patients.with_these_clinical_events(
                    serious_mental_illness_snomed_clinical,
                    returning="date",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### SUS
                tmp_out_date_serious_mental_illness_hes=patients.admitted_to_hospital(
                    returning="date_admitted",
                    with_these_diagnoses=serious_mental_illness_icd10,
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### Death registry
                tmp_out_date_serious_mental_illness_death=patients.with_these_codes_on_death_certificate(
                    serious_mental_illness_icd10,
                    returning="date_of_death",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    match_only_underlying_cause=True,
                    date_format="YYYY-MM-DD",
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ), 
            
                ### Combined
                out_date_serious_mental_illness=patients.minimum_of(
                    "tmp_out_date_serious_mental_illness_snomed", "tmp_out_date_serious_mental_illness_hes", "tmp_out_date_serious_mental_illness_death"
                ),

            ## Self-harm

                ### Primary care
                tmp_out_date_self_harm_snomed=patients.with_these_clinical_events(
                    self_harm_15_10_combined_snomed,
                    returning="date",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### SUS
                tmp_out_date_self_harm_hes=patients.admitted_to_hospital(
                    returning="date_admitted",
                    with_these_diagnoses=self_harm_15_10_combined_icd,
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### Death registry
                tmp_out_date_self_harm_death=patients.with_these_codes_on_death_certificate(
                    self_harm_15_10_combined_icd,
                    returning="date_of_death",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    match_only_underlying_cause=True,
                    date_format="YYYY-MM-DD",
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ), 

                ### Combined
                out_date_self_harm=patients.minimum_of(
                    "tmp_out_date_self_harm_snomed", "tmp_out_date_self_harm_hes", "tmp_out_date_self_harm_death"
                ),

            ## Suicide

               out_date_suicide=patients.with_these_codes_on_death_certificate(
                    suicide_icd10,
                    returning="date_of_death",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    match_only_underlying_cause=True,
                    date_format="YYYY-MM-DD",
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

            ## Addiction

                ### Primary care
                tmp_out_date_addiction_snomed=patients.with_these_clinical_events(
                    addiction_snomed_clinical,
                    returning="date",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### HES
                tmp_out_date_addiction_hes=patients.admitted_to_hospital(
                    returning="date_admitted",
                    with_these_diagnoses=opioid_misuse_icd10,
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    date_format="YYYY-MM-DD",
                    find_first_match_in_period=True,
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ),

                ### Death registry
                tmp_out_date_addiction_death=patients.with_these_codes_on_death_certificate(
                    opioid_misuse_icd10,
                    returning="date_of_death",
                    between=[f"{index_date_variable}",f"{outcome_end_date_variable}"],
                    match_only_underlying_cause=True,
                    date_format="YYYY-MM-DD",
                    return_expectations={
                        "date": {"earliest": study_dates["pandemic_start"], "latest" : "today"},
                        "rate": "uniform",
                        "incidence": 0.1,
                    },
                ), 

                ### Combined
                out_date_addiction=patients.minimum_of(
                    "tmp_out_date_addiction_snomed", "tmp_out_date_addiction_hes","tmp_out_date_addiction_death"
                ),

        # Covariate variables ---------------------------------------------------------------------
        
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

            ## Consultation rate (2019)

                cov_num_consulation_rate=patients.with_gp_consultations(
                    between=["2019-01-01", "2019-12-31"],
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

            ## Dementia

                ### Primary care
                tmp_cov_bin_dementia_snomed=patients.with_these_clinical_events(
                    dementia_snomed_clinical,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),
                ### SUS
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
                ### SUS - vascular
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

                ### SUS
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

                ### SUS
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

                ### SUS
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

                ### SUS
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

            ## Diabetes
            
                ### Type 1 diabetes primary care
                cov_bin_diabetes_type1_snomed=patients.with_these_clinical_events(
                    diabetes_type1_snomed_clinical,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),

                ### Type 1 diabetes SUS
                cov_bin_diabetes_type1_hes=patients.admitted_to_hospital(
                returning='binary_flag',
                with_these_diagnoses=diabetes_type1_icd10,
                on_or_before=f"{index_date_variable} - 1 day",
                return_expectations={"incidence": 0.1},
                ),

                ### Type 2 diabetes primary care
                cov_bin_diabetes_type2_snomed=patients.with_these_clinical_events(
                    diabetes_type2_snomed_clinical,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),

                ### Type 2 diabetes SUS
                cov_bin_diabetes_type2_hes=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=diabetes_type2_icd10,
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),

                ### Other or non-specific diabetes
                cov_bin_diabetes_other=patients.with_these_clinical_events(
                    diabetes_other_snomed_clinical,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),

                ### Gestational diabetes
                cov_bin_diabetes_gestational=patients.with_these_clinical_events(
                    diabetes_gestational_snomed_clinical,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),

                ### Diabetes medication
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

                ### Any diabetes covariate
                cov_bin_diabetes=patients.maximum_of(
                    "cov_bin_diabetes_type1_snomed", "cov_bin_diabetes_type1_hes",
                    "cov_bin_diabetes_type1_snomed", "cov_bin_diabetes_type1_hes", 
                    "cov_bin_diabetes_type1_snomed", "cov_bin_diabetes_type1_hes", 
                    "cov_bin_diabetes_type2_snomed", "cov_bin_diabetes_type2_hes",
                    "cov_bin_diabetes_other", "cov_bin_diabetes_gestational",
                    "tmp_cov_bin_insulin_snomed", "tmp_cov_bin_antidiabetic_drugs_snomed",
                ),

            ## Obesity
            
                cov_bin_obesity=patients.categorised_as(
                    {
                        "TRUE": """
                            snomed = 1 OR hes = 1 OR (bmi >= 30 AND bmi < 70)
                        """,
                        "FALSE": "DEFAULT",
                    },
                    return_expectations={
                        "category": {"ratios": {"TRUE": 0.1, "FALSE": 0.9}}
                    },
                    snomed=patients.with_these_clinical_events(
                        bmi_obesity_snomed_clinical,
                        returning='binary_flag',
                        on_or_before=f"{index_date_variable} - 1 day",
                        return_expectations={"incidence": 0.1},
                    ),
                    hes=patients.admitted_to_hospital(
                        returning='binary_flag',
                        with_these_diagnoses=bmi_obesity_icd10,
                        on_or_before=f"{index_date_variable} - 1 day",
                        return_expectations={"incidence": 0.1},
                    ),
                    bmi=patients.most_recent_bmi(
                        on_or_before=f"{index_date_variable} - 1 day",
                        minimum_age_at_measurement=18,
                        include_measurement_date=True,
                        date_format="YYYY-MM"
                    ),
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

            ## Acute myocardial infarction

                ### Primary care
                tmp_cov_bin_ami_snomed=patients.with_these_clinical_events(
                    ami_snomed_clinical,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),

                ### SUS
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

            ## Ischeamic stroke

                ### Primary care
                tmp_cov_bin_stroke_isch_snomed=patients.with_these_clinical_events(
                    stroke_isch_snomed_clinical,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),

                ### SUS
                tmp_cov_bin_stroke_isch_hes=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=stroke_isch_icd10,
                    on_or_before=f"{index_date_variable} - 1 day",
                    return_expectations={"incidence": 0.1},
                ),

                ### Combined 
                cov_bin_stroke_isch=patients.maximum_of(
                    "tmp_cov_bin_stroke_isch_hes", "tmp_cov_bin_stroke_isch_snomed",
                ),

            ## History of depression 

                cov_cat_history_depression=patients.categorised_as(
                    {
                        "recent": """
                            depression_recent_snomed = 1 OR depression_recent_icd10 = 1
                        """,
                        "notrecent": """
                            (depression_history_snomed = 1 OR depression_history_icd10 = 1) AND 
                            depression_recent_snomed = 0 AND 
                            depression_recent_icd10 = 0
                        """,
                        "none": """ 
                            depression_history_snomed = 0 AND 
                            depression_history_icd10 = 0 AND 
                            depression_recent_snomed = 0 AND 
                            depression_recent_icd10 = 0
                        """,
                        "missing": "DEFAULT",
                    },
                    return_expectations={
                        "category": {"ratios": {"recent": 0.2, "notrecent": 0.2, "none": 0.6, "missing": 0}}
                    },
                    depression_history_snomed=patients.with_these_clinical_events(
                    depression_snomed_clinical,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 169 days",
                    ),
                    depression_history_icd10=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=depression_icd10,
                    on_or_before=f"{index_date_variable} - 169 days",
                    ),
                    depression_recent_snomed=patients.with_these_clinical_events(
                    depression_snomed_clinical,
                    returning='binary_flag',
                    between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
                    ),
                    depression_recent_icd10=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=depression_icd10,
                    between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
                    ),
                ),

            ## History of anxiety - general
            
                cov_cat_history_anxiety_general=patients.categorised_as(
                    {
                        "recent": """
                            anxiety_general_recent_snomed = 1 OR anxiety_general_recent_icd10 = 1
                        """,
                        "notrecent": """
                            (anxiety_general_history_snomed = 1 OR anxiety_general_history_icd10 = 1) AND 
                            anxiety_general_recent_snomed = 0 AND 
                            anxiety_general_recent_icd10 = 0
                        """,
                        "none": """ 
                            anxiety_general_history_snomed = 0 AND 
                            anxiety_general_history_icd10 = 0 AND 
                            anxiety_general_recent_snomed = 0 AND 
                            anxiety_general_recent_icd10 = 0
                        """,
                        "missing": "DEFAULT",
                    },
                    return_expectations={
                        "category": {"ratios": {"recent": 0.2, "notrecent": 0.2, "none": 0.6, "missing": 0}}
                    },
                    anxiety_general_history_snomed=patients.with_these_clinical_events(
                    anxiety_combined_snomed_cov,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 169 days",
                    ),
                    anxiety_general_history_icd10=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=anxiety_combined_hes_cov,
                    on_or_before=f"{index_date_variable} - 169 days",
                    ),
                    anxiety_general_recent_snomed=patients.with_these_clinical_events(
                    anxiety_combined_snomed_cov,
                    returning='binary_flag',
                    between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
                    ),
                    anxiety_general_recent_icd10=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=anxiety_combined_hes_cov,
                    between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
                    ),
                ),

            ## History of eating disorders

                cov_cat_history_eating_disorders=patients.categorised_as(
                    {
                        "recent": """
                            eating_disorders_recent_snomed = 1 OR eating_disorders_recent_icd10 = 1
                        """,
                        "notrecent": """
                            (eating_disorders_history_snomed = 1 OR eating_disorders_history_icd10 = 1) AND 
                            eating_disorders_recent_snomed = 0 AND 
                            eating_disorders_recent_icd10 = 0
                        """,
                        "none": """ 
                            eating_disorders_history_snomed = 0 AND 
                            eating_disorders_history_icd10 = 0 AND 
                            eating_disorders_recent_snomed = 0 AND 
                            eating_disorders_recent_icd10 = 0
                        """,
                        "missing": "DEFAULT",
                    },
                    return_expectations={
                        "category": {"ratios": {"recent": 0.2, "notrecent": 0.2, "none": 0.6, "missing": 0}}
                    },
                    eating_disorders_history_snomed=patients.with_these_clinical_events(
                    eating_disorders_snomed_clinical,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 169 days",
                    ),
                    eating_disorders_history_icd10=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=eating_disorder_icd10,
                    on_or_before=f"{index_date_variable} - 169 days",
                    ),
                    eating_disorders_recent_snomed=patients.with_these_clinical_events(
                    eating_disorders_snomed_clinical,
                    returning='binary_flag',
                    between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
                    ),
                    eating_disorders_recent_icd10=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=eating_disorder_icd10,
                    between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
                    ),
                ),

            ## History of serious mental illness

                cov_cat_history_serious_mental_illness=patients.categorised_as(
                    {
                        "recent": """
                            serious_mental_illness_recent_snomed = 1 OR serious_mental_illness_recent_icd10 = 1
                        """,
                        "notrecent": """
                            (serious_mental_illness_history_snomed = 1 OR serious_mental_illness_history_icd10 = 1) AND 
                            serious_mental_illness_recent_snomed = 0 AND 
                            serious_mental_illness_recent_icd10 = 0
                        """,
                        "none": """ 
                            serious_mental_illness_history_snomed = 0 AND 
                            serious_mental_illness_history_icd10 = 0 AND 
                            serious_mental_illness_recent_snomed = 0 AND 
                            serious_mental_illness_recent_icd10 = 0
                        """,
                        "missing": "DEFAULT",
                    },
                    return_expectations={
                        "category": {"ratios": {"recent": 0.2, "notrecent": 0.2, "none": 0.6, "missing": 0}}
                    },
                    serious_mental_illness_history_snomed=patients.with_these_clinical_events(
                    serious_mental_illness_snomed_clinical,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 169 days",
                    ),
                    serious_mental_illness_history_icd10=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=serious_mental_illness_icd10,
                    on_or_before=f"{index_date_variable} - 169 days",
                    ),
                    serious_mental_illness_recent_snomed=patients.with_these_clinical_events(
                    serious_mental_illness_snomed_clinical,
                    returning='binary_flag',
                    between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
                    ),
                    serious_mental_illness_recent_icd10=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=serious_mental_illness_icd10,
                    between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
                    ),
                ),

            ## History of self harm

                cov_cat_history_self_harm=patients.categorised_as(
                    {
                        "recent": """
                            self_harm_recent_snomed = 1 OR self_harm_recent_icd10 = 1
                        """,
                        "notrecent": """
                            (self_harm_history_snomed = 1 OR self_harm_history_icd10 = 1) AND 
                            self_harm_recent_snomed = 0 AND 
                            self_harm_recent_icd10 = 0
                        """,
                        "none": """ 
                            self_harm_history_snomed = 0 AND 
                            self_harm_history_icd10 = 0 AND 
                            self_harm_recent_snomed = 0 AND 
                            self_harm_recent_icd10 = 0
                        """,
                        "missing": "DEFAULT",
                    },
                    return_expectations={
                        "category": {"ratios": {"recent": 0.2, "notrecent": 0.2, "none": 0.6, "missing": 0}}
                    },
                    self_harm_history_snomed=patients.with_these_clinical_events(
                    self_harm_15_10_combined_snomed,
                    returning='binary_flag',
                    on_or_before=f"{index_date_variable} - 169 days",
                    ),
                    self_harm_history_icd10=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=self_harm_15_10_combined_icd,
                    on_or_before=f"{index_date_variable} - 169 days",
                    ),
                    self_harm_recent_snomed=patients.with_these_clinical_events(
                    self_harm_15_10_combined_snomed,
                    returning='binary_flag',
                    between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
                    ),
                    self_harm_recent_icd10=patients.admitted_to_hospital(
                    returning='binary_flag',
                    with_these_diagnoses=self_harm_15_10_combined_icd,
                    between=[f"{index_date_variable} - 168 days", f"{index_date_variable} - 1 day"],
                    ),
                ),

        # Quality assurance variables -------------------------------------------------------------

            ## Prostate cancer

                ### Primary care
                prostate_cancer_snomed=patients.with_these_clinical_events(
                    prostate_cancer_snomed_clinical,
                    returning='binary_flag',
                    return_expectations={
                        "incidence": 0.03,
                    },
                ),

                ### SUS
                prostate_cancer_hes=patients.admitted_to_hospital(
                    with_these_diagnoses=prostate_cancer_icd10,
                    returning='binary_flag',
                    return_expectations={
                        "incidence": 0.03,
                    },
                ),

                ### Death registry
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

            ## HRT or COCP 

                tmp_cocp=patients.with_these_medications(
                        cocp_dmd, 
                        returning='binary_flag',
                        on_or_before=f"{index_date_variable}",
                        return_expectations={"incidence": 0.1},
                    ),

                tmp_hrt=patients.with_these_medications(
                        hrt_dmd, 
                        returning='binary_flag',
                        on_or_before=f"{index_date_variable}",
                        return_expectations={"incidence": 0.1},
                    ),
                
                qa_bin_hrtcocp=patients.maximum_of(
                    "tmp_cocp", "tmp_hrt"
                ),

        )
    
    return dynamic_variables
