/*************************************************************
*  dhs_extract_prep.do
*
*	20210811	- new simple data flow using DHS Database dataset
*				- combines old dhs_extract and child_xsection dofiles 
*				- generates child level and woman level datasets
* 
*************************************************************/


*****************************************************
* I. Initialize, define necessary globals

clear
clear matrix
clear mata
set more off
capture log close
capture set maxvar 12000
capture set matsize 11000

**************
/* For Luc: */
set trace on
**************

log using "dhs_extract_prep.txt", text replace

* Define OS for automated file opening etc
global stata_os "UNIX"
/*global stata_os "MAC"*/
/*global stata_os "WIN"*/

	**********************
	*Luc/Akash Cadejo server dirs:
	global home_dir "/raid/lfborden/Endogenous_Fertility"
	global data_dir "$home_dir/DHS_Database"
	global dofiles_dir "$home_dir/EndoFert"
	
	global dhs_dir "$data_dir/raw_dhs_data"
	global dhs_output_dir "$data_dir/clean_output"
	**********************

	/* Jesse office home data bulk and DHS dirs:
	* JAH office directories
	global dropbox_base "C:\Users\jkanttilahughes\Dropbox"

	global home_dir "$dropbox_base\Research\DHS Core Code"
	global data_dir "$home_dir\data"
	global dofiles_dir "$home_dir/dofiles"
	
	global dhs_dir "$dropbox_base\DHS Database\raw_dhs_data"
	global dhs_output_dir "C:\bulk\DHS"
	**********************/

	/**********************
	* Gordon directories:
	global dropbox_base "C:\Users\gmccord\Dropbox\"

	global home_dir "$dropbox_base\Shared\DHS Core Code"
	global data_dir "$home_dir\data"
	global dofiles_dir "$home_dir/dofiles"
	
	global dhs_dir "$dropbox_base\Shared\DHS Database\raw_dhs_data"
	global dhs_output_dir "C:\Users\gmccord\Dropbox\Shared\DHS Database\clean_output"
	**********************/
	

	* File suffixes
	global dhs_data_suffix "-dhs.dta"
	global child_level_suffix "-child-xsection.dta"
	global mom_level_suffix "-mom-xsection.dta"
	global child_anthro_suffix "-child-anthro-xc.dta"

	* Birth Variables - 
	global birth_var_stubs "bord b0 b1 b2 b3 b4 b7 b11 b12"
	global maternity_var_stubs "m4 m5 m10 m18 m19 m34 m38 m55a m55b m55c m55d m55e m55f m55g m55h m55i h11 h12 h21 h22 h31 h32z hw2 hw3 hw4 hw5 hw6 hw7 hw8 hw9 hw10"
	global stub_suffixes "01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20"

	****************
	* Countries to exclude from extract
	global restrictedCountriesList "botswana cape_verde mauritania samoa turkmenistan" // for now all bc lacking DHS data permissions


*****************************************************
** II. Extract DHS architecture from folder structure
* 			First, get a master list of countries from the base dhs_dir
* 			Then, make a subdir_country global for each country so we can call all the files in the next loop
*			note that the general structure of country>surveys>subdirs>*IR*.dta file must be in place (for now)
	global countriesList "" /* Declaring macro variable and establishing that it will be a text string */
	
	cd "$dhs_dir" /* Changing directory to dhs_raw_data */
global list $dhs_dirs_list : dir . dirs "*" /* Creating a global macro variable which lists all folders within dhs_raw_data */
STOP
foreach d in "$dhs_dirs_list" { /* Creates a loop that assigns the current folder to a local variable "d" */
    if substr("`d'", 1, 1) != "." & substr("`d'", 1, 1) != "_" {  /* if a non-country admin data folder, we exclude */
        global currCountry "`d'" /* Assign d as a global macro var "currCountry" */
        global countriesList "$countriesList `currCountry'" /* Specify that countriesList should be populatied with a list of the results from currCountry*/ 
        global subdirs ""  /* Declaring macro variable subdirs and establishing that it will be a text string */
        qui cd "`d'" /* quietly change directory to local variable (currCountry)*/
        global list $dhs_dirs_list_special : dir . dirs "*" *dhs_????  *dhs_????? *dhs_?????? *dhs_??????? /* check for all dhs folders that don't have the "special" string in them, and hence are 4-7 char long */
        foreach subd in "$dhs_dirs_list_special" {
            local currSurvey "`subd'"
            qui cd "`subd'"
            global list $dhs_dirs_list_ir : dir . dirs "*" *IR* /* IR for individual recode */
            foreach subsubd in "$dhs_dirs_list_ir" {
                qui cd "`subsubd'"
                global list $dhs_dirs_list_ind_ir : dir . dirs "*" *IR*.dta /* get all indiv recode files */
                foreach dhs_file in "$dhs_dirs_list_ind_ir" {
                    global subdirs "$subdirs `subd'/`subsubd'/`dhs_file'"
                }
                display "$subdirs"
                qui cd ..
            }
            qui cd ..
        }
        global subd_`currCountry' "$subdirs"
        qui cd ..
}




* note there should only be one variable from this, so the loop is just for catching purposes
foreach var of varlist *{
* trim off the file extension
global currFile = substr("`var'",1,strlen("`var'")-3)
global currFile "$currFile.dta"
global currCountryCode = substr("`var'",1,2)
}
use "$currFile", clear
!rm *ir


//


*********************************
* for single / few country analysis:
* 
* global countriesList "guinea"
* global countriesList "bolivia zambia"
*
*********************************

	

*****************************************************
** III. Extract DHS IR data files to generate clean data files for each country (old *dhs_extract*)

foreach country of global countriesList{
		global firstCountryObs "TRUE"
		global currCountry "`country'"
		
		if regexm("$restrictedCountriesList","`country'*")==0 { // check to make sure country not in restricted list
			foreach survey of global subd_`country'{
				display "`survey'"
				capture use "$dhs_dir/`country'/`survey'", clear
				if _rc != 0{
					continue, break
				}	
				
				gen country = "`country'" // 
				
				capture confirm variable v024
				if _rc != 0{
					capture decode(v101), gen(adm_region)
					if _rc != 0{
						gen adm_region = v101
					}
				}
				else{
					capture decode(v024), gen(adm_region)
				}

				* Starting coding things in.
				* note mass capture to make sure that any missing vars are ignored
				* note we also have to delete some vars just to make space...
					
					* cluster id
					capture gen long cluster_id = v001
					
					* country code and phase
					capture gen dhscc = substr(v000,1,2)
					capture gen dhsphase = substr(v000,3,1)
					
					* survey sample weight
					* https://www.youtube.com/watch?v=YpXPWMUsb94 
					capture gen dhs_smpl_wgt_raw = v005
						capture gen dhs_smpl_wgt_adj = dhs_smpl_wgt_raw/1000000
					
					* Based on notes for DHS Forum
					scalar TOTWT=1 
						quietly summarize dhs_smpl_wgt_raw
						scalar T=r(sum)
						capture gen dhs_smple_wgt_pop_adj = dhs_smpl_wgt_raw*TOTWT/T
							* drop dhs_smpl_wgt_raw
					
					*Generate Strata
					capture confirm variable v022
						if _rc != 0{
							capture gen strata = v023
							}
					else{
						capture gen strata = v022
						}
					
					
					* afghanistan needs conversion to gregorian, using code from https://userforum.dhsprogram.com/index.php?t=msg&th=5916&goto=11967&S=Google
					if regexm("$currCountry", "afghan")|regexm("$currCountry", "Afghan"){
						do "$dofiles_dir/afghan_dates_fix.do"
					}
					
					
					* Survey timing info
					gen interview_month = v006
					gen interview_year = v007
					gen interview_date = v008
						capture gen interview_day = v016

			
						* Dates given in Nepali calendar, which is 56.7 years ahead of Gregorian, so adding 56*12 + (.7*12 ~ 8 months) to CMC code and converting
						if regexm("$currCountry", "Nepal")|regexm("$currCountry", "nepal"){
							capture gen new_cmc = v008 - (56*12 + 8)
							capture replace interview_year =  1900 + int((new_cmc - 1) / 12)
							capture replace interview_month =  new_cmc - ((interview_year -1900) / 12)
								capture drop new_cmc
						}
						
						* for ethiopia see: https://userforum.dhsprogram.com/index.php?t=msg&th=47&goto=67&#msg_67
						if regexm("$currCountry", "ethiopia")|regexm("$currCountry", "ethiopia"){ 
							gen new_cmc=v008+92
							replace interview_year = int((new_cmc-1)/12)
							replace interview_month = new_cmc - 12*interview_year
								replace interview_year = interview_year+1900
							drop new_cmc
						}
						
					replace interview_year = 1900 + interview_year if interview_year <1000 & interview_year > 20
					replace interview_year = 2000 + interview_year if interview_year <20 
					
					* new survey_year gen! 2021.8.13
					egen survey_year = min(interview_year)
			
					* Women's birth date info
					capture gen w_birth_month = v009
					capture gen w_birth_year = v010
						* Note: Dates given in Nepali calendar, which is 56.7 years ahead of Gregorian, so adding 56*12 + (.7*12 ~ 8 months) to CMC code and converting
						if regexm("$currCountry", "Nepal")|regexm("$currCountry", "nepal"){
							display "what up"
							capture gen new_cmc = v011 - (56*12 + 8)
							capture replace w_birth_year =  1900 + int((new_cmc - 1) / 12)
							capture replace w_birth_month =  new_cmc - ((w_birth_year -1900) / 12)
								capture drop new_cmc
						}
						
						if regexm("$currCountry", "ethiopia")|regexm("$currCountry", "ethiopia"){ // see: https://userforum.dhsprogram.com/index.php?t=msg&th=47&goto=67&#msg_67
							gen new_cmc=v011+92
							replace w_birth_year = int((new_cmc-1)/12)
							replace w_birth_month = new_cmc-12*w_birth_year 
								replace w_birth_year = w_birth_year+1900
								drop new_cmc
						}
						
					capture replace w_birth_year = 1900 + w_birth_year if w_birth_year <1000
					capture gen age = interview_year-w_birth_year
					capture gen age2 = age^2

					* urban / rural
					capture gen byte rural = v102 == 2 if !missing(v102)
					capture gen byte urban = v102 == 1 if !missing(v102)
					capture gen byte old_rural = v134 == 3 if v134<.
					capture gen byte old_urban = (v134 == 0) | (v134 == 1) if v134<.
					capture gen byte major_urban = v134 == 0 if v134<.
					capture gen byte town = v134 == 2 if v134<.
					capture gen byte rural_or_town = (v134 == 2) | (v134 == 3) if v134<.
					capture gen rural_urban_type = v134

								
					* Highest education level attained 
					capture gen byte edu_none = v106 == 0 if v106<.
					capture gen byte edu_primary = v106 == 1 if v106<.
					capture gen byte edu_secondary = v106 == 2 if v106<.
					capture gen byte edu_higher = v106 == 3 if v106<.
					capture gen edu_singleyrs = v133 if v133<98

					
					* Household items 
					capture gen byte has_electric = v119 == 1 if v119 <.
					capture gen byte has_radio = v120 == 1 if v120 <.
					capture gen byte has_tv = v121 == 1 if v121 <.
					capture gen byte has_refrig = v122 == 1 if v122 <.
					capture gen byte has_phone = v153 == 1 if v153 <.
					
					* Transport items 
					capture gen byte has_bicycle = v123 == 1 if v123 <.
					capture gen byte has_motorcycle = v124 == 1 if v124 <.
					capture gen byte has_auto = v125 == 1 if v125 <.
					
					* Housing construction materials; varies by country
					capture gen floor_material = v127
					capture gen wall_material = v128
					capture gen roof_material = v129
			
					*building materials coded as in original - but sub-categories may not be comparable, so code down to large categories that have been standardized
					*across countries - 'natural' 'rudimentary' 'finished'. Replace 'other' to missing, and replace values < 10 that should not be in there to missing (lose about 3.5% of obs).
					*must revise w older codes to avoid losing N. Also fo wall_material & roof_material
					* Note: keeping a raw version of this variable for factor analysis reasons (need it to not be a constant for all values, which can happen w the truncation)
					foreach material in floor_material wall_material roof_material { 
						capture gen `material'_detailed = `material' 
						*if floor_material < 96
							capture replace `material' = . if `material' < 10 | `material' >= 96 | `material' == 41
							capture replace `material' = 1 if `material' >= 10 & `material' < 20
							capture replace `material' = 2 if `material' >= 20 & `material' < 30
							capture replace `material' = 3 if `material' >= 30 & `material' < 40
					}
					
					
					* Literacy and info gathering
					capture gen byte w_literate_atall = v155 >0 if v155 <.
						capture gen illiterate = v155 == 0
						capture gen semiliterate = v155 == 1
						capture gen literate = v155 == 2
					capture gen freq_read_news = v157 if v157<9
					capture gen freq_listen_radio = v158 if v158<8
					capture gen freq_watch_tv = v159 if v159<9
						
					
					* Marital status
					capture gen byte unmarried = v501 == 0 if v501<.
					capture gen byte married = v501 == 1 if v501<.
					capture gen byte widowed = v501 == 2 if v501<.
					capture gen byte divorced = v501 == 4 if v501<.
					capture gen marriage_month = v507
					capture gen marriage_year = v508
						capture replace marriage_year = 1900 + marriage_year if marriage_year <1000 & marriage_year > 20
						capture replace marriage_year = 2000 + marriage_year if marriage_year <20 
						
					
					
					* First sex
					capture gen w_age_intercourse = v525 if v525 <96
					capture gen age_firstbirth = v212 if v212 <96
					capture gen age_firstmarriage = v511 if v511 <96
					capture gen child_bride = v511 < 14 if !missing(v511)

					capture gen w_bfeeding_survey = v404==1 if v404<96
					
					* Contraception use start date, w current partner
					capture gen contra_start_month = v315 if v315 <.
					capture gen contra_start_year = v316 if v316 <.
					
					* Sterilization (v312 ==6 or == 7)
					capture gen byte sterilized = (v312 ==6 | v312 == 7) if v312 <.
						capture gen sterilized_month = contra_start_month if contra_start_month<. & sterilized
						capture gen sterilized_year = contra_start_year if contra_start_year<. & sterilized
					
					* Fertility Preferences
					* note have to gate for coding
					capture gen w_ideal_num_kids = v613 if v613<90
						capture gen w_ideal_num_boys = v627 if v627<90
						capture gen w_ideal_num_girls = v628 if v628<90
					
					
					capture gen byte w_pref_kid_in2yrs = v605 == 1
					capture gen byte w_pref_kid_after2yrs = v605 == 2
					capture gen byte w_pref_nomorekids = v605 == 5
					capture gen byte w_pref_sterilized = v605 == 6
					capture gen byte w_pref_infecud = v605 == 7
					
					* Female anthropometry data, gathered only for women with recent births v417>0
					* kg and cm measures to first decimal so div by 10
					* removing the logic gating so errors need to be checked after assembly
						capture gen w_weight_kg = v437 
						capture gen w_height_cm = v438 
						
						capture gen w_hgt_4_age_pctile = v439 
						capture gen w_hgt_4_age_dev_med = v440 
						capture gen w_wgt_4_hgt_pct_med = v442 
						capture gen w_wgt_4_hgt_dev_dhs = v444a
						
						*PK Adds...
						capture gen w_bmi_dhs = v445 / 100
						capture gen w_rohr_ind_dhs = v446 / 100
						
					*PK Add...ALTERNATE Female anthropometry data, MAYBE NOT JUST FOR MOTHERS... REVIEW with JAH!!
					capture gen fem_weight_kg = ha2
					capture gen fem_height_cm = ha3
					capture gen fem_bmi_dhs = ha40
						
			
					* Migration info
					* note that v104 is coded so that visitors are 96 and never-moveds are 95
					capture gen w_years_resident = v104 if v104<90
					capture gen never_moved = v104 == 95 if v104<96
					capture gen visitor = v104 == 96 if v104<=96
					
					* Partner Info
					capture gen husb_age = v730 if v730<96
						capture gen w_husb_age_gap = age - husb_age 
				
					* Partner's Highest education level attained 
					capture gen byte husb_edu_none = v701 == 0 if v701<.
					capture gen byte husb_edu_primary = v701 == 1 if v701<.
					capture gen byte husb_edu_secondary = v701 == 2 if v701<.
					capture gen byte husb_edu_higher = v701 == 3 if v701<.
					capture gen husb_edu_yrs = v715 if v715<97
					capture gen husb_edu_coded = v729
						capture recode husb_edu_coded (8 9 98 99 = .)

					* Employment info
					capture gen husb_work = v705
						capture gen husb_ag_worker = (v704 <20) if !missing(v704)
						capture gen husb_unskilled_labor = (v704 >=20) & (v704 <40)
						capture gen husb_skilled_labor = (v704 >=40) & (v704 <60)
					
					capture gen w_worked_this_year = v731 == 1
					capture gen w_working_now = v731 == 2
						capture gen w_works_all_year = v732==1
						capture gen w_works_seasonally = v732==2
						capture gen w_works_rarely = v732==3			
						capture gen w_employed = (v716 >0) & (v716 <90)


					* Woman can make decisions regarding...
					capture gen w_ctrl_health = v743a
					capture gen w_ctrl_bigpurchases = v743b
					capture gen w_ctrl_dailypurchases = v743c
					capture gen w_ctrl_visits = v743d
					capture gen w_ctrl_food = v743e
							*women's decision making: take out missing, and for simplicity, recode as 'woman involved in decision making, yes or no'
							capture{
							foreach var in w_ctrl_health w_ctrl_big_spend w_ctrl_daily_spend w_ctrl_fam_vis w_ctrl_food {
								gen `var'_w = 0 if !missing(`var')
									replace `var'_w = 1 if `var' == 0
								gen `var'_m = 0 if !missing(`var')
									replace `var'_m = 1 if `var' == 4
								gen `var'_wo = 0 if !missing(`var')
									replace `var'_wo = 1 if `var' == 2 | `var' == 3 
								gen `var'_o = 0 if !missing(`var')
									replace `var'_o = 1 if `var' == 5 	
								}
							}		
					
					* Violence attitudes and outcomes
					capture gen w_wife_viol_ok_out = (v744a == 1) if v744a <9
						capture gen w_wife_viol_ok_kids = (v744b == 1) if v744b <9
						capture gen w_wife_viol_ok_argue = (v744c== 1) if v744c <9
						capture gen w_wife_viol_ok_sex = (v744d== 1) if v744d <9 
						capture gen w_wife_viol_ok_food = (v744e== 1) if v744e <9

					capture gen w_wife_viol_ok_any = w_wife_viol_ok_out 
						capture replace w_wife_viol_ok_any = 1 if w_wife_viol_ok_kids ==1
						capture replace w_wife_viol_ok_any = 1 if w_wife_viol_ok_argue ==1
						capture replace w_wife_viol_ok_any = 1 if w_wife_viol_ok_sex ==1
						capture replace w_wife_viol_ok_any = 1 if w_wife_viol_ok_food ==1
					
					capture gen w_viol_out_no_answr = v744a>=9
						capture gen w_viol_kids_no_answr = v744b>=9
						capture gen w_viol_argue_no_answr = v744c>=9
						capture gen w_viol_sex_no_answr = v744d>=9
						capture gen w_viol_feed_no_answr = v744e>=9
						
					
					capture gen w_exp_mild_viol = d106 if d106<.
					capture gen w_exp_sev_viol = d107 if d107<.
					capture gen w_exp_sex_viol = d108 if d108<.
					
					capture gen w_first_viol = d109 if d109<.
					
					capture gen h_drinks = d113 
					capture gen h_times_drnk = d114 
					
					capture gen w_first_sex_unwntd = d123
					capture gen w_nnprt_frc_sex_12mo = d124
					capture gen w_any_forced_sex = d125
					capture gen w_age_1st_frcd_sex = d126
					
					
					
					** Anemia vars
					capture gen w_hgb_unadj = v453
					capture gen w_hgb_alt_adj = v456
					capture gen w_anemia = v457

						capture replace w_hgb_alt_adj = . if w_hgb_alt_adj>=998
						capture replace w_hgb_unadj = . if w_hgb_unadj>=998
						capture replace hgb_alt_adj_c_1 = . if hgb_alt_adj_c_1 >=998
						capture replace w_anemia =. if w_anemia>=9
						capture gen w_anemic = w_anemia<4
						capture gen w_very_anemic = w_anemic<3
						*w_hgb has some weird high values. looks like coding error. in both cases, cut at 200g/dl, based on eyeballing distribution.
						*LH tail does not make a lot of sense, but tapers off smoothly, by way of contrast to RH. leave, at least for now.
						capture replace w_hgb_unadj = . if w_hgb_unadj > 200
						capture replace w_hgb_alt = . if w_hgb_alt > 200
			
					
			
					***FLAG: essentially, dug well is omitted category (with rain water and bottled water. Perhaps recode s.t. unprotected dug well is grouped with surface water,
					***protected well with well water? Surface could then used as a dummy for 'not improved'.
					* water source is major code (i.e., first digit) consistent across countries
					
					*OLD HH water source variables
					capture gen hh_water_piped = v113 >= 10 & v113 <=19
					capture gen hh_water_well = v113 >= 20 & v113 <=29
					capture gen hh_water_surface = v113 >= 40 & v113 <=49
					capture gen hh_water_transport = v113 >= 60 & v113 <=69
					
					*For New HH water source variables
					capture decode v113, gen(water_source_string)
					capture gen water_source_v113 = v113
					
					if strmatch("$currCountry", "Cambodia")	{
						capture decode v113d, gen(d_water_source) 
						capture decode v113w, gen(w_water_source)
						capture decode sv113a, gen(d_water_source) 
						capture decode sv113b, gen(w_water_source)
					}
					
					* toilet facilities 'improved' if there is at least a pit toilet
					capture gen toilet improved = v116 < 30
					capture replace toilet_improved =. if v116 > 96
			
					* DHS Wealth Quintile Variables
					capture gen hh_wealth_ind = v190 
					
					
					* Total mortality and child gender vars
					capture gen total_children = v201
					capture gen total_sons = v202 + v204 + v206
					capture gen total_daughters = v203 + v205 + v207
					
					capture gen total_sons_mort = v206
					capture gen total_daughts_mort = v207
					capture gen total_child_mort = total_sons_mort + total_daughts_mort			
					
					***FLAG: recode to allow for missing values
					capture gen ever_miscarried = v228 
						capture replace ever_miscarried = . if v228 == 9

						
					
					*Ethnicity
					capture decode v131, generate(ethnicity_string_v131)
					capture confirm variable ethnicity_string_v131
						if _rc != 0{
							gen ethnicity_string_v131 = "" 
						}
					
					*Religion
					capture decode v130, generate(religion_string_v130)
					capture confirm variable religion_string_v130
						if _rc != 0{
							gen religion_string_v130 = "" 
						}
								
							
					capture gen total_hh_women = v138

					capture rename case_id caseid // only Egypt 1988 afaik

				********
				** Drop DHS original vars
				* Note: generate country_code_dhs last for appropriate bracketing of keep command
				
				gen last_var = 1 // placeholder variable deleted at end for dividing data
					
				local keepers "caseid country-last_var"
					local woman_only_data_keepers "`keepers'"
				
				foreach b_var of global birth_var_stubs{
					capture confirm var `b_var'_01
					if _rc == 0{
						local keepers "`keepers' `b_var'_*"
					}
				}
				
				local maternity_vars " "
				* Note that earlier variables had leading zeroes, later ones no
				foreach b_var of global maternity_var_stubs{
					capture confirm var `b_var'_1
					if _rc == 0{
						local keepers "`keepers' `b_var'_*"
						local maternity_vars "`maternity_vars' `b_var'_*" 
					}

					capture confirm var `b_var'_01
					if _rc == 0{
						local keepers "`keepers' `b_var'_*"
						local maternity_vars "`maternity_vars' `b_var'_*" 
					}
				}	
				
				
				keep `keepers'

				display "`maternity_vars'"
				* Put a leading zero in front of any maternity and health vars lacking them so that kids can be matched up
				* Note need to check there are any, first
				if  strlen("`maternity_vars'") >2 {
					foreach var of varlist `maternity_vars' {
							* if there's no leading zero in the variable name, put one in
							if strpos("`var'","_0") == 0 {  
								local newvar = subinstr("`var'","_","_0",1)
								rename `var' `newvar'
							}
					}
				}

				
				* If this is the first observation, start the short file, else append 
				if strmatch("$firstCountryObs","TRUE") {	
					save "$dhs_output_dir/$currCountry$dhs_data_suffix",replace
					global firstCountryObs "FALSE"
				}
				else {
					append using "$dhs_output_dir/$currCountry$dhs_data_suffix"
					save "$dhs_output_dir/$currCountry$dhs_data_suffix",replace
				}	
								 
			}
			
			* Capture any non-string versions of adm_region (Mexico only?) and convert to string
			capture confirm string var adm_region
			if _rc!=0{	
				tostring adm_region, replace
			} 
			
			qui compress
			
			
			
			* Generate the unique woman's id across all surveys within a country
			sort caseid w_birth_year
			gen w_id = _n
			sort w_id	
			
			* generater woman only data without maternity or birth vars
			preserve
				keep `woman_only_data_keepers' w_id
				save "$dhs_output_dir/$currCountry$mom_level_suffix",replace
			restore
			
			drop last_var	
					
			save "$dhs_output_dir/$currCountry$dhs_data_suffix",replace 
			clear
		}	
	}



	
	STOP
	
	
	
	
	
*****************************************************
* IV. Create child-level datasets (prev: child_xsection_prep)

foreach country of global countriesList{
	global currCountry "`country'"
	if regexm("$restrictedCountriesList","`country'*")==0 { // check to make sure country not in restricted list
			
		use "$dhs_output_dir/$currCountry$dhs_data_suffix", clear
	
		global birth_vars " "
		foreach var of global birth_var_stubs{
			capture confirm var `var'_01
			if _rc==0 global birth_vars "$birth_vars `var'"
		}
		
		foreach var of global maternity_var_stubs{
			capture confirm var `var'_01
			if _rc==0 global birth_vars "$birth_vars `var'"
		}
		
		

		reshape long $birth_vars, i(w_id) j(birth) string

		* Generate year, compensating for difference in coding styles between waves
		gen birth_year = b2
		gen birth_month = b1
		
		
		if regexm("$currCountry", "ethiopia")|regexm("$currCountry", "ethiopia"){ // see: https://userforum.dhsprogram.com/index.php?t=msg&th=47&goto=67&#msg_67
			gen new_cmc=b3+92
			replace birth_year = int((new_cmc-1)/12)
			replace birth_month = new_cmc-12*birth_year
				replace birth_year = birth_year +1900
				drop new_cmc
		}
		
		if regexm("$currCountry", "Nepal")|regexm("$currCountry", "nepal"){
			capture gen new_cmc = b3 - (56*12 + 8)
			capture replace birth_year =  1900 + int((new_cmc - 1) / 12)
			capture replace birth_month =  new_cmc - ((birth_year -1900) / 12)
				capture drop new_cmc
		}
		
		
		replace birth_year = birth_year +1900 if birth_year <1000 & birth_year >10
		replace birth_year = birth_year +2000 if birth_year <20

		
		drop birth
				
		
		drop if birth_year ==.

		**
		* Birth history vars from *merge_prep.do
		* Birth dummies
		capture gen birth_order = bord
		capture gen byte male = 0 
			capture replace male = 1 if b4 ==1
		capture gen byte female = 0 
			capture replace female = 1 if b4 ==2
		capture gen byte twin = 0 
			capture replace twin = 1 if b0!=. & b0>0
		capture gen child_birth_weight = m19 if m19 <9996	

		
		*Birth interval Variables
		capture gen prec_birth_int = b11 if b11<.
		capture gen succ_birth_int = b12 if b12<.
		
		* Low birth weight from other lit is <2500 grams
		capture gen child_low_birth_weight = child_birth_weight <2500 if child_birth_weight<.
			capture label var child_birth_weight "Birthweight (g)"
			capture label var child_low_birth_weight "Low birthweight (1/0)"

		
		* Fix the weird subj birth weight var (coded 1 is huge, 5 is small; flip it)
		capture gen child_birth_subj_size = 5-m18 if m18 <8
		
		*IF child wanted
		capture gen child_born_wanted_then = m10 == 1 if m10<9
		capture gen child_born_wanted_later = m10 == 2 if m10<9
		capture gen child_born_not_wanted = m10 == 3 if m10<9
		
		
		*Age of Child in Months
		capture gen intdateinmonts = interview_year*12 + interview_month
		capture gen b_month = birth_year*12 + birth_month
		capture gen child_age_mnths = intdateinmonts - b_month
			capture drop intdateinmonts

		**************
		*BREASTFEEDING VARIABLES
		
		*Months of breastfeeding
		capture gen child_bf_m4 = m4
		capture gen child_bf_m5 = m5 //94 = NEVER BREASTFED, 95 = STILL BREASTFED
		
		capture gen child_bf_never = (m5==94) | (m5==0) if !missing(m5) 

		capture gen child_bf_mnths = child_bf_m5 if child_bf_m5<93 
		capture replace child_bf_mnths = 0 if child_bf_never==1
		
		*BF under 12 or 6 months
		capture gen child_bf_under12mnths = m5<12 if m5<93
		capture gen child_bf_under6mnths = m5<6 if m5<93
		
		*Child Still BF
		capture gen child_still_bf = (m5==95) if !missing(m5)

		
		*PK to do...CHECK THIS IN THE GLOBAL SAMPLE.....
			capture replace child_still_bf = 1 if child_age_mnths==child_bf_mnths & !missing(child_bf_mnths)

		
		*time after birth that the child was first breastfed
		capture gen child_bf_m34 = m34 // Use this to check the created responses against

		capture gen child_bf_imediate_ab = .
			capture replace child_bf_imediate_ab = 1 if m34==0 | m34==000 | m34==100 
			capture replace child_bf_imediate_ab = 0 if m34>0 & m34!=.
			
		capture gen child_bf_hrs_ab = m34-100 if m34>=100 & m34<200
		capture gen child_bf_days_ab = m34-200 if m34>=200	
		
		
		*Kid's anthropometric Variables
		* fixed as of 10/5/2016 - JAH
		capture gen child_weight_kg = hw2/10 if hw2 < 994 // see: tab child_weight_kg if child_weight_kg >=900
		capture gen child_height_cm = hw3/10 if hw3 < 2000 & hw3 > 200 // 
		
		capture gen child_hght4age_pctile_raw = hw4 if hw4<9998
			capture gen child_hght4age_pctile_low = (child_hght4age_pctile_raw < 1000) if !missing(child_hght4age_pctile_raw)
			capture gen child_hght4age_pctile_new = child_hght4age_pctile_raw
			replace child_hght4age_pctile_new = child_hght4age_pctile_new *10 if child_hght4age_pctile_raw< 1000 & child_hght4age_pctile_raw>=100
			replace child_hght4age_pctile_new = child_hght4age_pctile_new *100 if child_hght4age_pctile_raw< 100 
			replace child_hght4age_pctile_new = . if child_hght4age_pctile_new >=9980
			
			
		capture gen child_hght4age_std_dev_raw = hw5if hw5<9998
		capture gen child_hght4age_perc_mean_raw = hw6 if hw6<9998
		
		capture gen child_wght4age_pctile_raw = hw7 if hw7<9998
			capture gen child_wght4age_pctile_low = (child_wght4age_pctile_raw < 1000) if !missing(child_wght4age_pctile_raw)
			capture gen child_wght4age_pctile_new = child_wght4age_pctile_raw
			replace child_wght4age_pctile_new = child_wght4age_pctile_new *10 if child_wght4age_pctile_raw<1000 & child_wght4age_pctile_raw>=100 
			replace child_wght4age_pctile_new = child_wght4age_pctile_new *100 if child_wght4age_pctile_raw<100 
			replace child_wght4age_pctile_new = . if child_wght4age_pctile_new >=9980
			
			
		capture gen child_wght4age_std_dev_raw = hw8 if hw8<9998
		capture gen child_wght4age_perc_mean_raw = hw9 if hw9<9998
		
		capture gen child_wght4hght_pctile_raw = hw10 if hw10<9998
			capture gen child_wght4hght_pctile_low = (child_wght4hght_pctile_raw < 1000) if !missing(child_wght4hght_pctile_raw)
			capture gen child_wght4hght_pctile_new = child_wght4hght_pctile_raw
			replace child_wght4hght_pctile_new = child_wght4hght_pctile_new *10 if child_wght4hght_pctile_raw<1000 & child_wght4hght_pctile_raw>100 
			replace child_wght4hght_pctile_new = child_wght4hght_pctile_new *100 if child_wght4hght_pctile_raw<100 
			replace child_wght4hght_pctile_new = . if child_wght4hght_pctile_new >=9980
					
		
		capture gen child_wght4hght_std_dev_raw = hw11 if hw11<9998
		capture gen child_wght4hght_perc_mean_raw = hw12 if hw12<9998
		* 
		
		capture gen child_diarrhea_24hr = h11 == 1 if h11<.
		capture gen child_diarrhea_2wks = h11 == 2 if h11<.
		
		capture gen child_fever_2wks = h22 if h22<8
		
		capture gen child_cough_24hr = h31 == 1 if h31<.
		capture gen child_cough_2wks = h31 == 2 if h31<.
		
		capture gen child_congested = h31b if h31b < 8
		
		
		
		* generate mortality info
		capture gen b_month = birth_year*12 + birth_month
			capture gen mortality_month = b_month + b7 if b7<.
			capture gen year_mort = floor(mortality_month/12) if b7<.
			capture gen month_mort = mod(mortality_month,12) if b7<.
				capture replace month_mort = 12 if month_mort ==0 
				capture drop mortality_month b_month
			capture gen child_mortality = b7<.
			capture gen child_mortality_age = b7
			capture gen infant_mortality = b7<=12
			capture gen underfive_mort = b7>12 & b7<=60
		
		*Age of Dealth in Days if < 1 month
		capture gen child_mort_age_b6 = b6
		capture gen child_mort_age_days = b6-100 if b6>=100 & b6<200 
			capture replace child_mort_age_days = . if child_mort_age_days>90 // Anything above 90 is a special response
		
		*Generate Dummy variable for Age of mother at birth of Child
		capture gen w_age_child_born = age - (interview_year - birth_year)
		gen w_teen_child_born = w_age_child_born<20		
		gen w_20s_child_born = w_age_child_born>=20 & w_age_child_born<30
		gen w_30s_child_born = w_age_child_born>=30 & w_age_child_born<40
		gen w_40s_child_born = w_age_child_born>=40

		
		
		foreach var of varlist $birth_vars{
			capture drop `var'
		}
		
		* generate the dhsid for matching
		gen dhsyear = interview_year // change 2021/08/11  must check!
				replace dhsyear = 2008 if (dhsyear == 2009 | dhsyear == 2007) & (country == "Albania")				
				replace dhsyear = 2006 if (dhsyear == 2007 | dhsyear == 2005) & (country == "Angola")				
				replace dhsyear = 2000 if (dhsyear == 2001 | dhsyear == 1999) & (country == "Bangladesh")				
				replace dhsyear = 1999 if (dhsyear == 2000 | dhsyear == 1998) & (country == "BurkinaFaso")			
				replace dhsyear = 1994 if (dhsyear == 1995 | dhsyear == 1993) & (country == "CAR")				
				replace dhsyear = 1998 if (dhsyear == 1999 | dhsyear == 1997) & (country == "CotedIvoire")			
				replace dhsyear = 2010 if (dhsyear == 2011 | dhsyear == 2009) & (country == "Ethiopia")
				replace dhsyear = 2006 if (dhsyear == 2007 | dhsyear == 2005) & (country == "Haiti")			
				replace dhsyear = 2003 if (dhsyear == 2004 | dhsyear == 2002) & (country == "Indonesia")				
				replace dhsyear = 2008 if (dhsyear == 2009 | dhsyear == 2007) & (country == "Kenya")			
				replace dhsyear = 2008 if (dhsyear == 2009 | dhsyear == 2007) & (country == "Madagascar")			
				replace dhsyear = 1996 if (dhsyear == 1997 | dhsyear == 1995) & (country == "Mali")				
				replace dhsyear = 2003 if (dhsyear == 2004 | dhsyear == 2002) & (country == "Morocco")				
				replace dhsyear = 2006 if (dhsyear == 2007 | dhsyear == 2005) & (country == "Namibia")			
				replace dhsyear = 1993 if (dhsyear == 1994 | dhsyear == 1992) & (country == "Senegal")			
				replace dhsyear = 2008 if (dhsyear == 2009 | dhsyear == 2007) & (country == "Senegal")	
				replace dhsyear = 2010 if (dhsyear == 2011 | dhsyear == 2009) & (country == "Senegal")
				replace dhsyear = 2006 if (dhsyear == 2007 | dhsyear == 2005) & (country == "Swaziland")				
				replace dhsyear = 2009 if (dhsyear == 2010 | dhsyear == 2008) & (country == "TimorLeste")				
				replace dhsyear = 2000 if (dhsyear == 2001 | dhsyear == 1999) & (country == "Uganda")	
				replace dhsyear = 2014 if (dhsyear == 2016 | dhsyear == 2015) & (country == "Uganda")	
				replace dhsyear = 2005 if (dhsyear == 2006 | dhsyear == 2004) & (country == "Zimbabwe")			
				replace dhsyear = 2010 if (dhsyear == 2011 | dhsyear == 2009) & (country == "Zimbabwe")
			gen str8 dhscluster_stem = string(cluster_id, "%08.0f") 
			gen dhsid = dhscc + string(dhsyear) + dhscluster_stem
		
		
		compress
		
		capture sort dhsid w_id birth_order
		capture gen k_id = _n
				
	save "$dhs_output_dir/$currCountry$child_level_suffix",replace
	}
}		



************************************
* V. Create Global DHS Kid Level Data Set for anthro subsample kids (was enso_child_xsection_merge)

foreach country of global countriesList{
		global currCountry "`country'"
		display "`currCountry''"
		
		if regexm("$restrictedCountriesList","`country'*")==0 { // check to make sure country not in restricted list
			use "$dhs_output_dir/$currCountry$child_level_suffix",clear
			keep if (child_weight_kg<.) | (child_height_cm<.) // need at least some anthro
			capture tab country
			if r(N) >0 {
				
						cd "$data_dir/igrowup_stata"
						gen str150 reflib="."
							lab var reflib "Directory of reference tables"
						gen str150 datalib="."
							lab var datalib "Directory for datafiles"
						
						// name of the file to be output //
						local datalab "$currCountry" +"_child_anthro"
							display "`data_lab'" 
						gen str30 datalab="`data_lab'" 
							lab var datalab "Working file"
						
						gen gender = female + 1 // 1 for males and 2 for females
							label var gender "Gender: 1=male, 2=female"

						rename age w_age
						gen age = child_age_mnths
						lab var age "Age in month"

						/* define your ageunit */ 
						gen str6 ageunit="months" 
						lab var ageunit "=months"

						/* check the variable for body "weight" which must be in kilograms*/
						gen weight = child_weight_kg
						*NOTE: in DHS both weight and height given with one decimal place, without actually drawing the decimal point. If the units are not as igrowup wants them, the whole thing will keep producing junk.

						/*  check the variable for "height" which must be in centimeters*/
						gen height = child_height_cm

						/* check the variable for "measure", whether lying or standing height*/ 
						gen str1 measure="h"

						/*  check the variable for "oedema"*/ 
						gen str1 oedema="n"

						/* check the variable for "sw" for the sampling weight*/ 
						gen sw=1

						
						keep k_id-sw
						order k_id reflib datalib datalab gender age ageunit weight height measure oedema sw
							capture drop _merge

						/*  Fill in the macro parameters to run the command */ 
						*igrowup_restricted_unix reflib datalib datalab gender age ageunit weight height measure oedema sw
						igrowup_restricted reflib datalib datalab gender age ageunit weight height measure oedema sw
						use "$data_dir/igrowup_stata/`data_lab'_z_rc.dta", clear
							rename _zwei child_who_wght4age_z
							rename _zlen child_who_hght4age_z
							rename _zbmi child_who_bmi4age_z
							rename _zwfl child_who_wght4hght_z
							
							rename _fwei child_who_wght4age_fl
							rename _flen child_who_hght4age_fl
							rename _fbmi child_who_bmi4age_fl
							rename _fwfl child_who_wght4hght_fl
							
							keep k_id child_who*
							sort k_id

						merge 1:1 k_id using "$dhs_output_dir/$currCountry$child_level_suffix"
						tab _merge
						
						
						drop _merge

					* Normalize vars so to a 0-100 percentile scale
					foreach var of varlist child_wght4age_pctile_new child_hght4age_pctile_new child_wght4hght_pctile_new{
						replace `var' = `var'/100
					}
				
					save "$dhs_output_dir/$currCountry$child_anthro_suffix", replace
			}	
			else{ 
				display "`currCountry' has no anthro data"
			}
		}
	}
	
	


		
*****************************************************
* . Close out.

log close




