from cohortextractor import codelist_from_csv, combine_codelists, codelist

# Covid
covid_codes = codelist_from_csv(
    "codelists/user-RochelleKnight-confirmed-hospitalised-covid-19.csv",
    system="icd10",
    column="code",
)
covid_primary_care_positive_test = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-positive-test.csv",
    system="ctv3",
    column="CTV3ID",
)
covid_primary_care_code = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-clinical-code.csv",
    system="ctv3",
    column="CTV3ID",
)
covid_primary_care_sequalae = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-sequelae.csv",
    system="ctv3",
    column="CTV3ID",
)

# Ethnicity
opensafely_ethnicity_codes_6 = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)
primis_covid19_vacc_update_ethnicity = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-eth2001.csv",
    system="snomed",
    column="code",
    category_column="grouping_6_id",
)

# Smoking
smoking_clear = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)
smoking_unclear = codelist_from_csv(
    "codelists/opensafely-smoking-unclear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

# AMI
ami_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-ami_snomed.csv",
    system="snomed",
    column="code",
)
ami_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-ami_icd10.csv",
    system="icd10",
    column="code",
)
ami_prior_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-ami_prior_icd10.csv",
    system="icd10",
    column="code",
)

# Cancer
cancer_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-cancer_snomed.csv",
    system="snomed",
    column="code",
)
cancer_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-cancer_icd10.csv",
    system="icd10",
    column="code",
)

# COPD
copd_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-copd_snomed.csv",
    system="snomed",
    column="code",
)
copd_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-copd_icd10.csv",
    system="icd10",
    column="code",
)

# Dementia
dementia_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-dementia_snomed.csv",
    system="snomed",
    column="code",
)
dementia_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-dementia_icd10.csv",
    system="icd10",
    column="code",
)

# Dementia vascular 
dementia_vascular_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-dementia_vascular_snomed.csv",
    system="snomed",
    column="code",
)

dementia_vascular_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-dementia_vascular_icd10.csv",
    system="icd10",
    column="code",
)

# Liver disease
liver_disease_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-liver_disease_snomed.csv",
    system="snomed",
    column="code",
)
liver_disease_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-liver_disease_icd10.csv",
    system="icd10",
    column="code",
)

# Hypertension
hypertension_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-hypertension_icd10.csv",
    system="icd10",
    column="code",
)
hypertension_drugs_dmd = codelist_from_csv(
    "codelists/user-elsie_horne-hypertension_drugs_dmd.csv",
    system="snomed",
    column="dmd_id",
)
hypertension_snomed_clinical = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-hyp_cod.csv",
    system="snomed",
    column="code",
)

# Prostate
prostate_cancer_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-prostate_cancer_icd10.csv",
    system="icd10",
    column="code",
)
prostate_cancer_snomed_clinical = codelist_from_csv(
    "codelists/user-RochelleKnight-prostate_cancer_snomed.csv",
    system="snomed",
    column="code",
)

# Pregnancy
pregnancy_snomed_clinical = codelist_from_csv(
    "codelists/user-RochelleKnight-pregnancy_and_birth_snomed.csv",
    system="snomed",
    column="code",
)

# Stroke 
stroke_isch_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-stroke_isch_icd10.csv",
    system="icd10",
    column="code",
)
stroke_isch_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-stroke_isch_snomed.csv",
    system="snomed",
    column="code",
)

# BMI
bmi_obesity_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-bmi_obesity_snomed.csv",
    system="snomed",
    column="code",
)
bmi_obesity_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-bmi_obesity_icd10.csv",
    system="icd10",
    column="code",
)
bmi_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-bmi.csv",
    system="snomed",
    column="code",
)

# Carer codes
carer_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-carer.csv",
    system="snomed",
    column="code",
)

# No longer a carer codes
notcarer_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-notcarer.csv",
    system="snomed",
    column="code",
)

# Wider Learning Disability
learndis_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-learndis.csv",
    system="snomed",
    column="code",
)

# Employed by Care Home codes
carehome_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-carehome.csv",
    system="snomed",
    column="code",
)

# Employed by nursing home codes
nursehome_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-nursehome.csv",
    system="snomed",
    column="code",
)

# Employed by domiciliary care provider codes
domcare_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-domcare.csv",
    system="snomed",
    column="code",
)

# Patients in long-stay nursing and residential care
longres_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-longres.csv",
    system="snomed",
    column="code",
)
# High Risk from COVID-19 code
shield_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-shield.csv",
    system="snomed",
    column="code",
)

# Lower Risk from COVID-19 codes
nonshield_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-nonshield.csv",
    system="snomed",
    column="code",
)

#For JCVI groups
# Pregnancy codes 
preg_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-preg.csv",
    system="snomed",
    column="code",
)

# Pregnancy or Delivery codes
pregdel_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-pregdel.csv",
    system="snomed",
    column="code",
)

# High Risk from COVID-19 code
shield_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-shield.csv",
    system="snomed",
    column="code",
)

# Lower Risk from COVID-19 codes
nonshield_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-nonshield.csv",
    system="snomed",
    column="code",
)

# Asthma Diagnosis code
ast_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ast.csv",
    system="snomed",
    column="code",
)

# All BMI coded terms
bmi_stage_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-bmi_stage.csv",
    system="snomed",
    column="code",
)
# Severe Obesity code recorded
sev_obesity_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-sev_obesity.csv",
    system="snomed",
    column="code",
)
# Asthma Diagnosis code
ast_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ast.csv",
    system="snomed",
    column="code",
)

# Asthma Admission codes
astadm_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-astadm.csv",
    system="snomed",
    column="code",
)

# Asthma systemic steroid prescription codes
astrx_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-astrx.csv",
    system="snomed",
    column="code",
)
# Chronic Respiratory Disease
resp_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-resp_cov.csv",
    system="snomed",
    column="code",
)
# Chronic Neurological Disease including Significant Learning Disorder
cns_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-cns_cov.csv",
    system="snomed",
    column="code",
)

# Chronic heart disease codes
chd_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-chd_cov.csv",
    system="snomed",
    column="code",
)

# Asplenia or Dysfunction of the Spleen codes
spln_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-spln_cov.csv",
    system="snomed",
    column="code",
)
# Diabetes diagnosis codes
diab_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-diab.csv",
    system="snomed",
    column="code",
)
# Diabetes resolved codes
dmres_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-dmres.csv",
    system="snomed",
    column="code",
)
# Severe Mental Illness codes
sev_mental_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-sev_mental.csv",
    system="snomed",
    column="code",
)

# Remission codes relating to Severe Mental Illness
smhres_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-smhres.csv",
    system="snomed",
    column="code",
)

# Chronic heart disease codes
chd_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-chd_cov.csv",
    system="snomed",
    column="code",
)

# Chronic Kidney disease
ckd_snomed_clinical = codelist_from_csv(
    "codelists/user-elsie_horne-ckd_snomed.csv",
    system="snomed",
    column="code",
)

ckd_icd10 = codelist_from_csv(
    "codelists/user-elsie_horne-ckd_icd10.csv",
    system="icd10",
    column="code",
)

# Chronic kidney disease diagnostic codes
ckd_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ckd_cov.csv",
    system="snomed",
    column="code",
)

# Chronic kidney disease codes - all stages
ckd15_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ckd15.csv",
    system="snomed",
    column="code",
)

# Chronic kidney disease codes-stages 3 - 5
ckd35_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ckd35.csv",
    system="snomed",
    column="code",
)

# Chronic Liver disease codes
cld_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-cld.csv",
    system="snomed",
    column="code",
)
# Immunosuppression diagnosis codes
immdx_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-immdx_cov.csv",
    system="snomed",
    column="code",
)

# Immunosuppression medication codes
immrx_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-immrx.csv",
    system="snomed",
    column="code",
)

# to represent household contact of shielding individual
hhld_imdef_primis = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-hhld_imdef.csv",
    system="snomed",
    column="code",
)

# Diabetes
# Type 1 diabetes
diabetes_type1_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-type-1-diabetes.csv",
    system="ctv3",
    column="code",
)
# Type 1 diabetes secondary care
diabetes_type1_icd10 = codelist_from_csv(
    "codelists/opensafely-type-1-diabetes-secondary-care.csv",
    system="icd10",
    column="icd10_code",
)
# Type 2 diabetes
diabetes_type2_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-type-2-diabetes.csv",
    system="ctv3",
    column="code",
)
# Type 2 diabetes secondary care
diabetes_type2_icd10 = codelist_from_csv(
    "codelists/user-r_denholm-type-2-diabetes-secondary-care-bristol.csv",
    system="icd10",
    column="code",
)
# Non-diagnostic diabetes codes
diabetes_diagnostic_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-nondiagnostic-diabetes-codes.csv",
    system="ctv3",
    column="code",
)
# Other or non-specific diabetes
diabetes_other_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-other-or-nonspecific-diabetes.csv",
    system="ctv3",
    column="code",
)
# Gestational diabetes
diabetes_gestational_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-gestational-diabetes.csv",
    system="ctv3",
    column="code",
)
# Insulin medication 
insulin_snomed_clinical = codelist_from_csv(
     "codelists/opensafely-insulin-medication.csv",
     system="snomed",
     column="id",
)
# Antidiabetic drugs
antidiabetic_drugs_snomed_clinical = codelist_from_csv(
     "codelists/opensafely-antidiabetic-drugs.csv",
     system="snomed",
     column="id",
)
# Antidiabetic drugs - non metformin
non_metformin_dmd = codelist_from_csv(
    "codelists/user-r_denholm-non-metformin-antidiabetic-drugs_bristol.csv", 
    system="snomed", 
    column="id",
)
# Prediabetes
prediabetes_snomed = codelist_from_csv(
    "codelists/opensafely-prediabetes-snomed.csv",
    system="snomed",
    column="code",
)

##Quality assurance codes 

prostate_cancer_snomed_clinical = codelist_from_csv(
    "codelists/user-RochelleKnight-prostate_cancer_snomed.csv",
    system="snomed",
    column="code",
)
prostate_cancer_icd10 = codelist_from_csv(
    "codelists/user-RochelleKnight-prostate_cancer_icd10.csv",
    system="icd10",
    column="code",
)
pregnancy_snomed_clinical = codelist_from_csv(
    "codelists/user-RochelleKnight-pregnancy_and_birth_snomed.csv",
    system="snomed",
    column="code",
)

##############################
### MENTAL HEALTH OUTCOMES ###
##############################

# MENTAL HEALTH RELATED CODE LISTS

# Depression 
depression_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-depression-symptoms-and-diagnoses.csv",
    system="snomed",
    column="code",
)

# Anxiety - general
anxiety_general_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-anxiety-symptoms-and-diagnoses.csv",
    system="snomed",
    column="code",
)

# Anxiety - obsessive compulsive disorder
anxiety_ocd_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-obsessive-compulsive-disorder-ocd.csv",
    system="snomed",
    column="code",
)

# Anxiety - post traumatic stress disorder
anxiety_ptsd_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-post-traumatic-stress-disorder.csv",
    system="snomed",
    column="code",
)

# Eating disorders
eating_disorders_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-diagnoses-eating-disorder.csv",
    system="snomed",
    column="code",
)

# Serious mental illness
serious_mental_illness_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-severe-mental-illness.csv",
    system="snomed",
    column="code",
)

# Self harm - aged >= 10 years
self_harm_10plus_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-intentional-self-harm-aged10-years.csv",
    system="snomed",
    column="code",
)

# Self harm - aged >= 15 years
self_harm_15plus_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-undetermined-intent-self-harm-aged15-years.csv",
    system="snomed",
    column="code",
)

# Self harm undetermined intent - combined

self_harm_15_10_combined_snomed = combine_codelists(
    self_harm_10plus_snomed_clinical,
    self_harm_15plus_snomed_clinical
)

# OCD ICD10
ocd_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-ocd_icd10.csv",
    system="icd10",
    column="code",
)

# Suicide
suicide_icd10 = codelist_from_csv(
    "codelists/user-hjforbes-suicide-icd-10.csv",
    system="icd10",
    column="code",
)

# Addiction
addiction_snomed_clinical = codelist_from_csv(
    "codelists/user-hjforbes-opioid-dependency-clinical-diagnosis.csv",
    system="snomed",
    column="code",
)

# Opioid misuse ICD10
opioid_misuse_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-opioid_misuse_icd10.csv",
    system = "icd10", 
    column = "code",
)

# Alcohol misuse ICD10
alcohol_misuse_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-alcohol_misuse_icd10.csv",
    system="icd10",
    column="code",
)

# Anxiety ICD10
anxiety_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-anxiety_icd10.csv",
    system="icd10",
    column="code",
)

# Bipolar and other mood disorders ICD10
bipolar_other_mood_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-bipolar_and_mood_disorders_icd10.csv",
    system="icd10",
    column="code",
)

# Depression ICD10
depression_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-depression_icd10.csv",
    system="icd10",
    column="code",
)

# Drug misuse ICD10
drug_misuse_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-drug_misuse_icd10.csv",
    system="icd10",
    column="code",
)

# Other mental health ICD10
mental_health_other_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-other_mental_health_conditions_icd10.csv",
    system="icd10",
    column="code",
)

# Mixed depression and anxiety ICD10
mixed_depression_anxiety_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-mixed_depression_and_anxiety_icd10.csv",
    system="icd10",
    column="code",
)

# Other Psychotic disorders ICD10
psychotic_disorders_other_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-other-psychotic_disorders_icd10.csv",
    system="icd10",
    column="code",
)

# PTSD ICD10
ptsd_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-ptsd_icd10.csv",
    system="icd10",
    column="code",
)

# Schizophrenia ICD10
schizophrenia_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-schizophrenia_icd10.csv",
    system="icd10",
    column="code",
)

# Self harm intentional 10 years ICD10
self_harm_intent_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-self_harm_intentional_10_years_icd10.csv",
    system="icd10",
    column="code",
)

# Self harm undetermined intent 15 years 
self_harm_undet_intent_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-self_harm_undetermined_intent_15_years_icd10.csv",
    system="icd10",
    column="code",
)

# Self harm undetermined intent 15 years - combined

self_harm_15_10_combined_icd = combine_codelists(
    self_harm_intent_icd10,
    self_harm_undet_intent_icd10
)

# Eating Disorder ICD10
eating_disorder_icd10 = codelist_from_csv(
    "codelists/user-kurttaylor-eating_disorder_icd10.csv",
    system="icd10",
    column="code",
)

# Combined serious mental illness HES

serious_mental_illness_icd10 = combine_codelists(
    bipolar_other_mood_icd10,
    psychotic_disorders_other_icd10,
    schizophrenia_icd10
)

# Combined anxiety covariate primary care

anxiety_combined_snomed_cov = combine_codelists(
    anxiety_general_snomed_clinical,
    anxiety_ocd_snomed_clinical,
    anxiety_ptsd_snomed_clinical
)

# Combined anxiety covariate HES

anxiety_combined_hes_cov = combine_codelists(
    anxiety_icd10,
    ocd_icd10,
    ptsd_icd10
)