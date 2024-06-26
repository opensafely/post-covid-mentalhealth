library(tidyverse)
library(yaml)
library(here)
library(glue)
library(readr)
library(dplyr)

# Specify defaults -------------------------------------------------------------

defaults_list <- list(
  version = "3.0",
  expectations= list(population_size=200000L)
)

# Define active analyses -------------------------------------------------------

active_analyses <- read_rds("lib/active_analyses.rds")
active_analyses <- active_analyses[order(active_analyses$analysis,active_analyses$cohort,active_analyses$outcome),]
active_analyses <- active_analyses[active_analyses$cohort %in% c("prevax_extf","unvax_extf","vax"),]
cohorts <- unique(active_analyses$cohort)

# Specify active analyses requiring Stata --------------------------------------

run_stata <- c("cohort_prevax_extf-day0_sub_covid_hospitalised-depression",
               "cohort_prevax_extf-day0_sub_covid_hospitalised-serious_mental_illness",
               "cohort_vax-day0_main-eating_disorders",
               "cohort_prevax_extf-day0_sub_covid_hospitalised-anxiety_ptsd",
               "cohort_vax-day0_sub_covid_nonhospitalised-eating_disorders",
               "cohort_prevax_extf-day0_sub_age_60_79-depression",
               "cohort_prevax_extf-day0_sub_age_60_79-serious_mental_illness",
               "cohort_prevax_extf-day0_sub_age_80_110-depression",
               "cohort_prevax_extf-day0_sub_age_80_110-serious_mental_illness",
               "cohort_prevax_extf-day0_sub_ethnicity_black-serious_mental_illness",
               "cohort_prevax_extf-day0_sub_ethnicity_other-depression",
               "cohort_unvax_extf-day0_main-addiction",
               "cohort_unvax_extf-day0_main-anxiety_ptsd",
               "cohort_unvax_extf-day0_sub_age_60_79-serious_mental_illness",
               "cohort_unvax_extf-day0_sub_age_80_110-depression",
               "cohort_unvax_extf-day0_sub_covid_history-anxiety_general",
               "cohort_unvax_extf-day0_sub_covid_history-depression",
               "cohort_unvax_extf-day0_sub_ethnicity_other-depression",
               "cohort_vax-day0_sub_age_80_110-serious_mental_illness",
               "cohort_prevax_extf-day0_sub_history_recent-serious_mental_illness",
               "cohort_prevax_extf-day0_sub_covid_hospitalised-addiction",
               "cohort_prevax_extf-day0_sub_covid_hospitalised-anxiety_general",
               "cohort_prevax_extf-day0_sub_covid_hospitalised-eating_disorders",
               "cohort_prevax_extf-day0_sub_covid_hospitalised-self_harm",
               "cohort_prevax_extf-day0_sub_covid_nonhospitalised-addiction",
               "cohort_unvax_extf-day0_sub_age_60_79-depression",
               "cohort_unvax_extf-day0_sub_covid_hospitalised-addiction",
               "cohort_unvax_extf-day0_sub_covid_hospitalised-anxiety_ptsd",
               "cohort_unvax_extf-day0_sub_covid_hospitalised-serious_mental_illness",
               "cohort_vax-day0_sub_covid_hospitalised-anxiety_general",
               "cohort_vax-day0_sub_covid_hospitalised-depression",
               "cohort_prevax_extf-day0_main-anxiety_ptsd",
               "cohort_prevax_extf-day0_sub_sex_male-depression",
               "cohort_prevax_extf-day0_sub_history_notrecent-depression",
               "cohort_prevax_extf-day0_sub_history_notrecent-serious_mental_illness")

stata <- active_analyses[active_analyses$name %in% run_stata,]
stata$save_analysis_ready <- TRUE
stata$day0 <- grepl("1;",stata$cut_points)

# Create generic action function -----------------------------------------------

action <- function(
    name,
    run,
    dummy_data_file=NULL,
    arguments=NULL,
    needs=NULL,
    highly_sensitive=NULL,
    moderately_sensitive=NULL
){
  
  outputs <- list(
    moderately_sensitive = moderately_sensitive,
    highly_sensitive = highly_sensitive
  )
  outputs[sapply(outputs, is.null)] <- NULL
  
  action <- list(
    run = paste(c(run, arguments), collapse=" "),
    dummy_data_file = dummy_data_file,
    needs = needs,
    outputs = outputs
  )
  action[sapply(action, is.null)] <- NULL
  
  action_list <- list(name = action)
  names(action_list) <- name
  
  action_list
}

# Create generic comment function ----------------------------------------------

comment <- function(...){
  list_comments <- list(...)
  comments <- map(list_comments, ~paste0("## ", ., " ##"))
  comments
}


# Create function to convert comment "actions" in a yaml string into proper comments

convert_comment_actions <-function(yaml.txt){
  yaml.txt %>%
    str_replace_all("\\\n(\\s*)\\'\\'\\:(\\s*)\\'", "\n\\1")  %>%
    #str_replace_all("\\\n(\\s*)\\'", "\n\\1") %>%
    str_replace_all("([^\\'])\\\n(\\s*)\\#\\#", "\\1\n\n\\2\\#\\#") %>%
    str_replace_all("\\#\\#\\'\\\n", "\n")
}

# Create function to generate study population ---------------------------------

generate_study_population <- function(cohort){
  splice(
    comment(glue("Generate study population - {cohort}")),
    action(
      name = glue("generate_study_population_{cohort}"),
      run = glue("cohortextractor:latest generate_cohort --study-definition study_definition_{cohort} --output-format csv.gz"),
      needs = list("vax_eligibility_inputs","generate_index_dates"),
      highly_sensitive = list(
        cohort = glue("output/input_{cohort}.csv.gz")
      )
    )
  )
}

# Create function to preprocess data -------------------------------------------

preprocess_data <- function(cohort){
  splice(
    comment(glue("Preprocess data - {cohort}")),
    action(
      name = glue("preprocess_data_{cohort}"),
      run = glue("r:latest analysis/preprocess_data.R"),
      arguments = c(cohort),
      needs = list("generate_index_dates",glue("generate_study_population_{cohort}")),
      moderately_sensitive = list(
        describe = glue("output/describe_input_{cohort}_stage0.txt"),
        describe_venn = glue("output/describe_venn_{cohort}.txt")
      ),
      highly_sensitive = list(
        cohort = glue("output/input_{cohort}.rds"),
        venn = glue("output/venn_{cohort}.rds")
      )
    )
  )
}

# Create function for data cleaning --------------------------------------------

stage1_data_cleaning <- function(cohort){
  splice(
    comment(glue("Stage 1 - data cleaning - {cohort}")),
    action(
      name = glue("stage1_data_cleaning_{cohort}"),
      run = glue("r:latest analysis/stage1_data_cleaning.R"),
      arguments = c(cohort),
      needs = list("vax_eligibility_inputs",glue("preprocess_data_{cohort}")),
      moderately_sensitive = list(
        consort = glue("output/consort_{cohort}.csv"),
        consort_midpoint6 = glue("output/consort_{cohort}_midpoint6.csv")
      ),
      highly_sensitive = list(
        cohort = glue("output/input_{cohort}_stage1.rds")
      )
    ),
    action(
      name = glue("stage1_data_cleaning_v2_{cohort}"),
      run = glue("r:latest analysis/stage1_data_cleaning_v2.R"),
      arguments = c(cohort),
      needs = list("vax_eligibility_inputs",glue("preprocess_data_{cohort}")),
      moderately_sensitive = list(
        consort = glue("output/consort_{cohort}_v2.csv"),
        consort_midpoint6 = glue("output/consort_{cohort}_midpoint6_v2.csv")
      ),
      highly_sensitive = list(
        cohort = glue("output/input_{cohort}_stage1_v2.rds")
      )
    )
  )
}

# Create function for table1 --------------------------------------------

table1 <- function(cohort){
  splice(
    comment(glue("Table 1 - {cohort}")),
    action(
      name = glue("table1_{cohort}"),
      run = "r:latest analysis/table1.R",
      arguments = c(cohort),
      needs = list(glue("stage1_data_cleaning_{cohort}")),
      moderately_sensitive = list(
        table1 = glue("output/table1_{cohort}.csv"),
        table1_midpoint6 = glue("output/table1_{cohort}_midpoint6.csv")
      )
    ),
    action(
      name = glue("extendedtable1_{cohort}"),
      run = "r:latest analysis/extendedtable1.R",
      arguments = c(cohort),
      needs = list(glue("stage1_data_cleaning_{cohort}")),
      moderately_sensitive = list(
        extendedtable1 = glue("output/extendedtable1_{cohort}.csv"),
        extendedtable1_midpoint6 = glue("output/extendedtable1_{cohort}_midpoint6.csv")
      )
    )
  )
}

# Create function to make model input and run a model --------------------------

apply_model_function <- function(name, cohort, analysis, ipw, strata, 
                                 covariate_sex, covariate_age, covariate_other, 
                                 cox_start, cox_stop, study_start, study_stop,
                                 cut_points, controls_per_case,
                                 total_event_threshold, episode_event_threshold,
                                 covariate_threshold, age_spline){
  
  splice(
    action(
      name = glue("make_model_input-{name}"),
      run = glue("r:latest analysis/make_model_input.R {name}"),
      needs = as.list(glue("stage1_data_cleaning_{cohort}")),
      highly_sensitive = list(
        model_input = glue("output/model_input-{name}.rds")
      )
    ),
    
    action(
      name = glue("cox_ipw-{name}"),
      run = glue("cox-ipw:v0.0.27 --df_input=model_input-{name}.rds --ipw={ipw} --exposure=exp_date --outcome=out_date --strata={strata} --covariate_sex={covariate_sex} --covariate_age={covariate_age} --covariate_other={covariate_other} --cox_start={cox_start} --cox_stop={cox_stop} --study_start={study_start} --study_stop={study_stop} --cut_points={cut_points} --controls_per_case={controls_per_case} --total_event_threshold={total_event_threshold} --episode_event_threshold={episode_event_threshold} --covariate_threshold={covariate_threshold} --age_spline={age_spline} --save_analysis_ready=FALSE --run_analysis=TRUE --df_output=model_output-{name}.csv"),
      needs = list(glue("make_model_input-{name}")),
      moderately_sensitive = list(model_output = glue("output/model_output-{name}.csv"))
    )
    
  )
}

# Create function to make Table 2 ----------------------------------------------

table2 <- function(cohort, focus){
  
  table2_names <- gsub("out_date_","",unique(active_analyses[active_analyses$cohort=={cohort},]$name))
  
  if (focus=="severity") {
    table2_names <- table2_names[grepl("-day0_main-",table2_names) | grepl("-day0_sub_covid_hospitalised",table2_names) | grepl("-day0_sub_covid_nonhospitalised",table2_names)]
  }
  
  if (focus=="history") {
    table2_names <- table2_names[grepl("-day0_sub_history_",table2_names)]
  }
  
  splice(
    comment(glue("Table 2 - {focus} - {cohort}")),
    action(
      name = glue("table2_{focus}_{cohort}"),
      run = "r:latest analysis/table2.R",
      arguments = c(cohort, focus),
      needs = c(as.list(paste0("make_model_input-",table2_names))),
      moderately_sensitive = list(
        table2 = glue("output/table2_{focus}_{cohort}.csv"),
        table2_midpoint6 = glue("output/table2_{focus}_{cohort}_midpoint6.csv")
      )
    )
  )
}

# Create function to make Venn data --------------------------------------------

venn <- function(cohort){
  
  venn_outcomes <- gsub("out_date_","",unique(active_analyses[active_analyses$cohort=={cohort},]$outcome))
  
  splice(
    comment(glue("Venn - {cohort}")),
    action(
      name = glue("venn_{cohort}"),
      run = "r:latest analysis/venn.R",
      arguments = c(cohort),
      needs = c(as.list(glue("preprocess_data_{cohort}")),
                as.list(paste0(glue("make_model_input-cohort_{cohort}-day0_main-"),venn_outcomes))),
      moderately_sensitive = list(
        venn = glue("output/venn_{cohort}.csv"),
        venn_midpoint6 = glue("output/venn_{cohort}_midpoint6.csv")
      )
    )
  )
}

# Create function to make Stata models -----------------------------------------

apply_stata_model_function <- function(name, cohort, analysis, ipw, strata, 
                                       covariate_sex, covariate_age, covariate_other, 
                                       cox_start, cox_stop, study_start, study_stop,
                                       cut_points, controls_per_case,
                                       total_event_threshold, episode_event_threshold,
                                       covariate_threshold, age_spline, day0){
  splice(
    action(
      name = glue("ready-{name}"),
      run = glue("cox-ipw:v0.0.27 --df_input=model_input-{name}.rds --ipw={ipw} --exposure=exp_date --outcome=out_date --strata={strata} --covariate_sex={covariate_sex} --covariate_age={covariate_age} --covariate_other={covariate_other} --cox_start={cox_start} --cox_stop={cox_stop} --study_start={study_start} --study_stop={study_stop} --cut_points={cut_points} --controls_per_case={controls_per_case} --total_event_threshold={total_event_threshold} --episode_event_threshold={episode_event_threshold} --covariate_threshold={covariate_threshold} --age_spline={age_spline} --save_analysis_ready=TRUE --run_analysis=FALSE --df_output=model_output-{name}.csv"),
      needs = list(glue("make_model_input-{name}")),
      highly_sensitive = list(ready = glue("output/ready-{name}.csv.gz"))
    ),
    action(
      name = glue("stata_cox_ipw-{name}"),
      run = "stata-mp:latest analysis/cox_model.do",
      arguments = c(name, day0),
      needs = c(as.list(glue("ready-{name}"))),
      moderately_sensitive = list(
        stata_fup = glue("output/stata_fup-{name}.csv"),
        stata_model_output = glue("output/stata_model_output-{name}.txt")
      )
    )
  )
}

# Define and combine all actions into a list of actions ------------------------

actions_list <- splice(
  
  ## Post YAML disclaimer ------------------------------------------------------
  
  comment("# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #",
          "DO NOT EDIT project.yaml DIRECTLY",
          "This file is created by create_project_actions.R",
          "Edit and run create_project_actions.R to update the project.yaml",
          "# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #"
  ),
  
  ## Generate vaccination eligibility information ------------------------------
  comment("Generate vaccination eligibility information"),
  
  action(
    name = glue("vax_eligibility_inputs"),
    run = "r:latest analysis/metadates.R",
    highly_sensitive = list(
      study_dates_json = glue("output/study_dates.json"),
      vax_jcvi_groups= glue("output/vax_jcvi_groups.csv.gz"),
      vax_eligible_dates= ("output/vax_eligible_dates.csv.gz")
    )
  ),
  
  ## Generate prelim study_definition ------------------------------------------
  comment("Generate prelim study_definition"),
  
  action(
    name = "generate_study_population_prelim",
    run = "cohortextractor:latest generate_cohort --study-definition study_definition_prelim --output-format csv.gz",
    needs = list("vax_eligibility_inputs"),
    highly_sensitive = list(
      cohort = glue("output/input_prelim.csv.gz")
    )
  ),
  
  ## Generate dates for all study cohorts --------------------------------------
  comment("Generate dates for all study cohorts"), 
  
  action(
    name = "generate_index_dates",
    run = "r:latest analysis/prelim.R",
    needs = list("vax_eligibility_inputs","generate_study_population_prelim"),
    highly_sensitive = list(
      index_dates = glue("output/index_dates.csv.gz")
    )
  ),
  
  ## Generate study population -------------------------------------------------
  
  splice(
    unlist(lapply(cohorts, 
                  function(x) generate_study_population(cohort = x)), 
           recursive = FALSE
    )
  ),
  
  ## Preprocess data -----------------------------------------------------------
  
  splice(
    unlist(lapply(cohorts, 
                  function(x) preprocess_data(cohort = x)), 
           recursive = FALSE
    )
  ),
  
  ## Stage 1 - data cleaning -----------------------------------------------------------
  
  splice(
    unlist(lapply(cohorts, 
                  function(x) stage1_data_cleaning(cohort = x)), 
           recursive = FALSE
    )
  ),
  
  ## Table 1 -------------------------------------------------------------------
  
  splice(
    unlist(lapply(unique(active_analyses$cohort), 
                  function(x) table1(cohort = x)), 
           recursive = FALSE
    )
  ),

  ## Run models ----------------------------------------------------------------
  comment("Run models"),
  
  splice(
    unlist(lapply(1:nrow(active_analyses), 
                  function(x) apply_model_function(name = active_analyses$name[x],
                                                   cohort = active_analyses$cohort[x],
                                                   analysis = active_analyses$analysis[x],
                                                   ipw = active_analyses$ipw[x],
                                                   strata = active_analyses$strata[x],
                                                   covariate_sex = active_analyses$covariate_sex[x],
                                                   covariate_age = active_analyses$covariate_age[x],
                                                   covariate_other = active_analyses$covariate_other[x],
                                                   cox_start = active_analyses$cox_start[x],
                                                   cox_stop = active_analyses$cox_stop[x],
                                                   study_start = active_analyses$study_start[x],
                                                   study_stop = active_analyses$study_stop[x],
                                                   cut_points = active_analyses$cut_points[x],
                                                   controls_per_case = active_analyses$controls_per_case[x],
                                                   total_event_threshold = active_analyses$total_event_threshold[x],
                                                   episode_event_threshold = active_analyses$episode_event_threshold[x],
                                                   covariate_threshold = active_analyses$covariate_threshold[x],
                                                   age_spline = active_analyses$age_spline[x])), 
           recursive = FALSE
    )
  ),
  
  splice(
    unlist(lapply(1:nrow(stata), 
                  function(x) apply_stata_model_function(name = stata$name[x],
                                                         cohort = stata$cohort[x],
                                                         analysis = stata$analysis[x],
                                                         ipw = stata$ipw[x],
                                                         strata = stata$strata[x],
                                                         covariate_sex = stata$covariate_sex[x],
                                                         covariate_age = stata$covariate_age[x],
                                                         covariate_other = stata$covariate_other[x],
                                                         cox_start = stata$cox_start[x],
                                                         cox_stop = stata$cox_stop[x],
                                                         study_start = stata$study_start[x],
                                                         study_stop = stata$study_stop[x],
                                                         cut_points = stata$cut_points[x],
                                                         controls_per_case = stata$controls_per_case[x],
                                                         total_event_threshold = stata$total_event_threshold[x],
                                                         episode_event_threshold = stata$episode_event_threshold[x],
                                                         covariate_threshold = stata$covariate_threshold[x],
                                                         age_spline = stata$age_spline[x],
                                                         day0 = stata$day0[x])), 
           recursive = FALSE
    )
  ),
  
  ## Table 2 -------------------------------------------------------------------
  
  splice(
    unlist(lapply(unique(active_analyses$cohort), 
                  function(x) table2(cohort = x, focus = "severity")), 
           recursive = FALSE
    )
  ),
  
  splice(
    unlist(lapply(unique(active_analyses$cohort), 
                  function(x) table2(cohort = x, focus = "history")), 
           recursive = FALSE
    )
  ),
  
  ## Venn data -----------------------------------------------------------------
  
  splice(
    unlist(lapply(unique(active_analyses$cohort), 
                  function(x) venn(cohort = x)), 
           recursive = FALSE
    )
  ),
  
  ## Cohort overlap ------------------------------------------------------------
  
  comment(glue("Cohort overlap")),
  action(
    name = glue("cohortoverlap"),
    run = "r:latest analysis/cohortoverlap.R",
    needs = as.list(paste0("stage1_data_cleaning_",c("prevax_extf","vax","unvax_extf"))),
    moderately_sensitive = list(
      cohortoverlap = glue("output/cohortoverlap.csv"),
      cohortoverlap_midpoint6 = glue("output/cohortoverlap_midpoint6.csv")
    )
  ),
  
  ## Cohort covid --------------------------------------------------------------
  
  comment(glue("Cohort covid")),
  action(
    name = glue("cohortcovid"),
    run = "r:latest analysis/cohortcovid.R",
    needs = as.list(paste0("stage1_data_cleaning_",c("prevax_extf","vax","unvax_extf"))),
    moderately_sensitive = list(
      cohortoverlap = glue("output/cohortcovid.csv"),
      cohortoverlap_midpoint6 = glue("output/cohortcovid_midpoint6.csv")
    )
  ),
  
  ## Make outputs --------------------------------------------------------------
  
  comment("Stage 6 - make output"),
  
  action(
    name = "make_model_output",
    run = "r:latest analysis/make_model_output.R",
    needs = as.list(c(paste0("cox_ipw-",setdiff(active_analyses$name,stata$name)),
                    paste0("stata_cox_ipw-",stata$name))),
    moderately_sensitive = list(
      model_output = glue("output/model_output.csv"),
      model_output_midpoint6 = glue("output/model_output_midpoint6.csv")
    )
  ),

  action(
    name = "make_consort_output",
    run = "r:latest analysis/make_other_output.R consort prevax_extf;vax;unvax_extf",
    needs = list("stage1_data_cleaning_prevax_extf",
                 "stage1_data_cleaning_vax",
                 "stage1_data_cleaning_unvax_extf"),
    moderately_sensitive = list(
      consort_output_midpoint6 = glue("output/consort_output_midpoint6.csv")
    )
  ),
  
  action(
    name = "make_table1_output",
    run = "r:latest analysis/make_other_output.R table1 prevax_extf;vax;unvax_extf",
    needs = list("table1_prevax_extf",
                 "table1_vax",
                 "table1_unvax_extf"),
    moderately_sensitive = list(
      table1_output_midpoint6 = glue("output/table1_output_midpoint6.csv")
    )
  ),
  
  action(
    name = "make_extendedtable1_output",
    run = "r:latest analysis/make_other_output.R extendedtable1 prevax_extf;vax;unvax_extf",
    needs = list("extendedtable1_prevax_extf",
                 "extendedtable1_vax",
                 "extendedtable1_unvax_extf"),
    moderately_sensitive = list(
      table1_output_midpoint6 = glue("output/extendedtable1_output_midpoint6.csv")
    )
  ),
  
  action(
    name = "make_table2_severity_output",
    run = "r:latest analysis/make_other_output.R table2_severity prevax_extf;vax;unvax_extf",
    needs = list("table2_severity_prevax_extf",
                 "table2_severity_vax",
                 "table2_severity_unvax_extf"),
    moderately_sensitive = list(
      table2_output_midpoint6 = glue("output/table2_severity_output_midpoint6.csv")
    )
  ),
  
  action(
    name = "make_table2_history_output",
    run = "r:latest analysis/make_other_output.R table2_history prevax_extf;vax;unvax_extf",
    needs = list("table2_history_prevax_extf",
                 "table2_history_vax",
                 "table2_history_unvax_extf"),
    moderately_sensitive = list(
      table2_output_midpoint6 = glue("output/table2_history_output_midpoint6.csv")
    )
  ),
  
  action(
    name = "make_venn_output",
    run = "r:latest analysis/make_other_output.R venn prevax_extf;vax;unvax_extf",
    needs = list("venn_prevax_extf",
                 "venn_vax",
                 "venn_unvax_extf"),
    moderately_sensitive = list(
      venn_output_midpoint6 = glue("output/venn_output_midpoint6.csv")
    )
  ),
  
  comment("Make absolute excess risk (AER) input"),
  
  action(
    name = "make_aer_input",
    run = "r:latest analysis/make_aer_input.R day0_main",
    needs = as.list(paste0("make_model_input-",active_analyses[grepl("-day0_main-",active_analyses$name),]$name)),
    moderately_sensitive = list(
      aer_input = glue("output/aer_input-day0_main.csv"),
      aer_input_midpoint6 = glue("output/aer_input-day0_main-midpoint6.csv")
    )
  ),
  
  comment("Calculate median (IQR) for age"),
  
  action(
    name = "median_iqr_age",
    run = "r:latest analysis/median_iqr_age.R",
    needs = list("stage1_data_cleaning_prevax_extf",
                 "stage1_data_cleaning_vax",
                 "stage1_data_cleaning_unvax_extf"),
    moderately_sensitive = list(
      model_output = glue("output/median_iqr_age.csv")
    )
  )
  
)

# Combine actions into project list --------------------------------------------

project_list <- splice(
  defaults_list,
  list(actions = actions_list)
)

# Convert list to yaml, reformat, and output a .yaml file ----------------------

as.yaml(project_list, indent=2) %>%
  # convert comment actions to comments
  convert_comment_actions() %>%
  # add one blank line before level 1 and level 2 keys
  str_replace_all("\\\n(\\w)", "\n\n\\1") %>%
  str_replace_all("\\\n\\s\\s(\\w)", "\n\n  \\1") %>%
  writeLines("project.yaml")

# Return number of actions -----------------------------------------------------

print(paste0("YAML created with ",length(actions_list)," actions."))