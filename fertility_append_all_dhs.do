/*************************************************************
*  fertility_append_all_dhs.do
*
*	20210813	- uses new simple DHS Database data flow 
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


* Define OS for automated file opening etc
global stata_os "UNIX"
*global stata_os "MAC"
*global stata_os "WIN"

	**********************
	*Luc/Akash Cadejo server dirs:
	global home_dir "raid/lfborden/Endogenous_Fertility"
	global data_dir "$home_dir/DHS_Database"
	global dofiles_dir "$home_dir/EndoFert"
	
	global dhs_dir "$data_dir/raw_dhs_data"
	global dhs_output_dir "raid/lfborden/Endogenous_Fertility/DHS_Database/clean_output"
	**********************


	/**********************
	* Jesse office home data bulk and DHS dirs:
	* JAH office directories
	global dropbox_base "C:\Users\jkanttilahughes\Dropbox"

	global home_dir "$dropbox_base\Research\Endogenous Fertility"
	global data_dir "$home_dir\data"
	global dofiles_dir "$home_dir/dofiles"
	global output_dir "$home_dir/output"
	
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
	
	
	global mom_data_keepers "caseid country survey_year adm_region cluster_id dhscc dhsphase dhs_smpl_wgt_raw dhs_smpl_wgt_adj interview_month interview_year interview_day w_birth_month w_birth_year age rural urban edu_none edu_primary edu_secondary edu_higher edu_singleyrs illiterate semiliterate literate unmarried married widowed divorced sterilized marriage_year w_age_intercourse age_firstbirth age_firstmarriage total_children total_sons total_daughters total_sons_mort total_daughts_mort total_child_mort w_ideal_num_kids w_ideal_num_boys w_ideal_num_girls w_pref_kid_in2yrs w_pref_kid_after2yrs w_pref_nomorekids w_pref_sterilized w_pref_infecud b3_01 b4_01 b5_01  b8_01 v008 interview_date"
	
*****************************************************
** Cycle over all adult women's data in main directory and append

cd "$dhs_output_dir"
local first_CountryObs = 1

fs *-dhs.dta
foreach dhs_file in `r(files)' {
    use "`dhs_file'", clear

	local keepers " "
	foreach w_var of global mom_data_keepers{
	    display "`w_var'"
		capture confirm var `w_var'
		if _rc == 0{
			local keepers "`keepers' `w_var'"
		}
	}
	
	display "`keepers'"
	keep `keepers'
	
	if `first_CountryObs' == 1{
	    local first_CountryObs = 0
	    save "$dhs_output_dir/fertility_global_mom_xsection.dta", replace
	}
	else{
	    append using "$dhs_output_dir/fertility_global_mom_xsection.dta"
		save "$dhs_output_dir/fertility_global_mom_xsection.dta", replace
	}
	
}


		* Standardize adm_region names
		sort dhscc adm_region
		merge m:1 dhscc adm_region using "$dropbox_base/Research/DHS Core Code/data/dhs_dhscc_global_std_adm_region.dta"
		drop if _merge ==2
			drop _merge	

		replace std_adm_region = adm_region if missing(std_adm_region)
			
		* note: incorporate these into the standardized adm region data file above, and then tidy up again
		do "$dropbox_base/Research/DHS Core Code/dofiles/std_adm_to_dhsregna.do"


	***** New weights by Gordon:
	** Get total number of surveys per country
	bysort dhscc survey_year: gen onesurvey = (_n==1)
	bysort dhscc: egen totalsurveys = sum(onesurvey)
	bysort dhscc survey_year, sort: gen surveysize = _N
	gen wght_avgcountry = (dhs_smpl_wgt_adj/surveysize) * (1/totalsurveys) * 100000 // Adjusts for DHS weight and number of surveys
	
	* sex ratio and similar dor adm-level figures
	gen w_ideal_pct_boys= w_ideal_num_boys/w_ideal_num_kids
	gen w_ideal_pct_girls= w_ideal_num_girls/w_ideal_num_kids
	gen w_pct_sons = total_sons/total_children
	gen w_pct_daughts = total_daughters/total_children

	
	gen youngest_child_age_months = interview_date - b3_01 if !missing(b3_01)
	gen recent_first_birth = (youngest_child_age_months <=12 ) & (total_children ==1) & ( total_child_mort==0)
	gen recent_first_son = recent_first_birth==1 & b4_01 == 1
	gen recent_first_daught = recent_first_birth==1 & b4_01 == 2

save "$dhs_output_dir/fertility_global_mom_xsection.dta", replace

*
global collapse_vars  "w_ideal_num_kids w_ideal_num_boys w_ideal_num_girls w_ideal_pct_boys w_ideal_pct_girls total_children total_sons total_daughters w_pct_sons w_pct_daughts"

preserve
collapse (mean ) $collapse_vars [aweight=wght_avgcountry] , by(dhscc country std_adm_region)
	gen w_ideal_sex_ratio = (w_ideal_num_boys/ w_ideal_num_girls)*100
	save "$dhs_output_dir/fertility_adm_xsection.dta", replace
restore

preserve
keep if recent_first_son ==1
	collapse (mean ) $collapse_vars [aweight=wght_avgcountry] , by(dhscc country std_adm_region)
	gen w_ideal_sex_ratio = (w_ideal_num_boys/ w_ideal_num_girls)*100
	foreach var of varlist $collapse_vars w_ideal_sex_ratio{
		rename `var' `var'_fb_male
	}
	merge 1:1 dhscc country std_adm_region using "$dhs_output_dir/fertility_adm_xsection.dta"
		tab _merge
		drop _merge
	save "$dhs_output_dir/fertility_adm_xsection.dta", replace
restore
	
preserve
keep if recent_first_daught ==1
	collapse (mean ) $collapse_vars [aweight=wght_avgcountry] , by(dhscc country std_adm_region)
	gen w_ideal_sex_ratio = (w_ideal_num_boys/ w_ideal_num_girls)*100
	foreach var of varlist $collapse_vars w_ideal_sex_ratio{
		rename `var' `var'_fb_female
	}
	merge 1:1 dhscc country std_adm_region using "$dhs_output_dir/fertility_adm_xsection.dta"
		tab _merge
		drop _merge
	save "$dhs_output_dir/fertility_adm_xsection.dta", replace
restore

