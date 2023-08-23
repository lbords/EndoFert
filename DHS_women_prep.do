*--------------------------------------------------------------------*
* Lauren Lamson
* How Sex of Child Influences Fertility Preferences 
* Womens Data Prep
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
* Table of Contents
* 	0 - Project set up
*	1 - Children's data prep and collapse
*	2 - Merging supplemental data
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
* (0.1)	Setting Directories
*--------------------------------------------------------------------*

	global d_home "/raid/lfborden/Endogenous_Fertility"
	global d_raw "/home/jkanttilahughes/data"
	global d_recodes "/home/jkanttilahughes/data"
	//global d_supplemental "$d_home/data/supplemental_data"
	global d_do "$d_home/EndoFert"

*--------------------------------------------------------------------*
* (0.2)	Project Set Up
*--------------------------------------------------------------------*

	clear matrix
	clear mata
	capture log close
	set more off			
	set matsize 800	
	
	
*--------------------------------------------------------------------*
* (1.1)	Generating birth variables & dummies
*--------------------------------------------------------------------*

	use "$d_raw/child_recode/DHS_global_child_xsection.dta", clear 

// Generating recent birth dummy for children born within 12 months
// of DHS survey

	gen monthofbirth = ym(birth_year,birth_month)
		format monthofbirth %tm

	gen monthofsurvey = ym(interview_year,interview_month)
		format monthofsurvey %tm

	gen recentbirth = 0
		replace recentbirth = 1 if monthofsurvey-monthofbirth <= 12
		label var recentbirth "Recent birth"

// Filtering for first, second, third births and creating dummies

	gen firstborn = 0
		replace firstborn = 1 if birth_order == 1
		label var firstborn "First child"
		
	gen secondborn = 0 
		replace secondborn = 1 if birth_order == 2
		label var secondborn "Second child"
	
	gen thirdborn = 0 
		replace thirdborn = 1 if birth_order == 3
		label var thirdborn "Third child"

// Interacting births and recent births 

	gen recent_firstborn = 0
		replace recent_firstborn = 1 if recentbirth == 1 & firstborn == 1
		label var recent_firstborn "Recent firstborn" 
		
	gen recent_secondborn = 0
		replace recent_secondborn = 1 if recentbirth == 1 & secondborn == 1
		label var recent_secondborn "Recent secondborn" 	
	
	gen recent_thirdborn = 0
		replace recent_thirdborn = 1 if recentbirth == 1 & thirdborn == 1
		label var recent_thirdborn "Recent thirdborn" 

*--------------------------------------------------------------------*
* (1.2)	Generating gender dummies
*--------------------------------------------------------------------*

// Births by gender 

	gen firstborn_daughter = 0
		replace firstborn_daughter=1 if female == 1 & firstborn == 1
		label var firstborn_daughter "Firstborn daughter"

	gen firstborn_son = 0
		replace firstborn_son = 1 if male == 1 & firstborn == 1
		label var firstborn_son "Firstborn son"

	gen secondborn_daughter = 0
		replace secondborn_daughter=1 if female == 1 & secondborn == 1
		label var secondborn_daughter "Secondborn daughter"

	gen secondborn_son = 0
		replace secondborn_son = 1 if male == 1 & secondborn == 1
		label var secondborn_son "Secondborn son"	
		
	gen thirdborn_daughter = 0
		replace thirdborn_daughter=1 if female == 1 & thirdborn == 1
		label var thirdborn_daughter "Thirdborn daughter"

	gen thirdborn_son = 0
		replace thirdborn_son = 1 if male == 1 & thirdborn == 1
		label var thirdborn_son "Thirdborn son"	
			
			
// Recent births by gender 

	gen recent_firstborn_daughter = 0
		replace recent_firstborn_daughter = 1 if female == 1 & recent_firstborn == 1
		label var recent_firstborn_daughter "Recent firstborn daughter"
	
	gen recent_firstborn_son = 0
		replace recent_firstborn_son = 1 if male == 1 & recent_firstborn == 1
		label var recent_firstborn_son "Recent firstborn son"
		
	gen recent_secondborn_daughter = 0
		replace recent_secondborn_daughter = 1 if female == 1 & recent_secondborn == 1
		label var secondborn_daughter "Secondborn daughter"

	gen recent_secondborn_son = 0
		replace recent_secondborn_son = 1 if male == 1 & recent_secondborn == 1
		label var secondborn_son "Secondborn son"	
		
	gen recent_thirdborn_daughter = 0
		replace recent_thirdborn_daughter = 1 if female == 1 & recent_thirdborn == 1
		label var thirdborn_daughter "Thirdborn daughter"

	gen recent_thirdborn_son = 0
		replace recent_thirdborn_son = 1 if male == 1 & recent_thirdborn == 1
		label var thirdborn_son "Thirdborn son	

*--------------------------------------------------------------------*
* (1.3)	Collapsing child data 
*--------------------------------------------------------------------*

	collapse (max) recent_thirdborn_son recent_thirdborn_daughter recent_secondborn_son recent_secondborn_daughter secondborn_son thirdborn_daughter secondborn thirdborn monthofbirth monthofsurvey recentbirth firstborn birth_order recent_firstborn firstborn_daughter firstborn_son recent_firstborn_daughter recent_firstborn_son, by (country w_id)	
	save "$d_recodes/child_recodes/child_data_collapsed.dta", replace


STOP

*--------------------------------------------------------------------*
* (2.1)	Merging with Women's DHS by women_id & country
*--------------------------------------------------------------------*

	// use "$d_raw/womens_recode/global_xsection_mother.dta", clear
	
	// sort country w_id
	
	// merge m:1 country w_id using "$d_recodes/child_recodes/child_data_collapsed.dta"
	// 	drop _merge 

*--------------------------------------------------------------------*
* (2.2)	Standardizing admin regions & generating codes for FE
*--------------------------------------------------------------------*

// Cleaning admin region info
	
	// sort country adm_region
	
	// merge m:m adm_region country using "$d_supplemental/DHS_global_std_adm_region.dta"
		drop _merge
	
	// do "/Users/lauren/Desktop/thesis/do_files/data_prep/universal_prep/std_adm_to_dhs_regions.do"
	
// Generating non-string codes 

	// egen country_code = group(country)
	// egen dhsid_code = group(country dhsid)
	// egen std_adm_region_code = group(std_adm_region)
	egen std_adm_region_cc_code = group(country std_adm_region)
	
*--------------------------------------------------------------------*
* (2.3)	Merging plough countries & generating plow variables
*--------------------------------------------------------------------*
	
	merge m:m dhscc using "$d_supplemental/alesina_xcountry_prep4merge.dta"
		drop _merge
		
	gen high_plow = 0
		replace high_plow = 1 if plow > .85
		label var high_plow "High plow intensity"

	gen low_plow = 0
		replace low_plow = 1 if plow < .15
		label var low_plow "Low plow intensity"

*--------------------------------------------------------------------*
* (2.4)	Merging population data to generate weights
*--------------------------------------------------------------------*		
	
	capture drop _merge
	sort dhscc
	
	merge m:1 dhscc using "$d_supplemental/wb_population_yr2000.dta"
		keep if _merge == 3
		drop _merge

	bysort dhscc survey_year: gen onesurvey = (_n==1)
	bysort dhscc: egen totalsurveys = sum(onesurvey)
	bysort dhscc survey_year, sort: gen surveysize = _N
	
// Adjusts for DHS weight, size of country, and number of surveys
	gen wght_avg_pop = (dhs_smpl_wgt_adj/surveysize) * (pop2000) * (1/totalsurveys)

		
*--------------------------------------------------------------------*
* (3.0)	Censoring & cleaning data 
*--------------------------------------------------------------------*	
	
// Truncating ideal children 
	* Note: DHS truncates ideal girls, boys, and either at 6. Any higher 
	* numbers are country specific or 96/99 (prefer not to answer/don't know)

	gen w_ideal_kids_trunc =  w_ideal_num_kids 
		replace w_ideal_kids_trunc = 12 if w_ideal_num_kids > 12 & !missing(w_ideal_num_kids)
		label var w_ideal_kids_trunc "Ideal number of children"
			
	gen w_ideal_girls_trunc = w_ideal_num_girls
		replace w_ideal_girls_trunc = 6 if w_ideal_num_girls > 6 & !missing(w_ideal_num_girls)
		label var w_ideal_girls_trunc "Ideal number of girls"
			
	gen w_ideal_boys_trunc = w_ideal_num_boys
		replace w_ideal_boys_trunc = 6 if w_ideal_num_boys > 6 & !missing(w_ideal_num_boys)
		label var w_ideal_boys_trunc "Ideal number of boys"

// Some education variables are > 90. Censoring these data. 

	gen edu_yrs_trunc = edu_singleyrs
		replace edu_yrs_trunc  = . if edu_yrs_trunc > 25 
		label var edu_yrs_trunc "Education (single years)"

// Some age at first birth variables are < 12. Censoring these data. 		
		
	gen age_firstbirth_trunc = age_firstbirth
		replace age_firstbirth_trunc = 12 if age_firstbirth < 12 & !missing(age_firstbirth)
		label var age_firstbirth_trunc "Age at first birth"

// Creating poor dummy
	gen poor = 0 
		replace poor = 1 if hh_wealth_ind <=3
		label var poor "Poor household"

*--------------------------------------------------------------------*
* (4.0)	Generating data for fertility levels
*--------------------------------------------------------------------*

// High-fertility countries:

	local high_fertility_countries ///
		`" "AF" "AO" "BD" "BJ" "BO" "BT" "BF" "BU" "KM" "CM" "CF" "CV" "TD" "KM" "CG" "CD" "CI" "DR" EC" "EG"  "ES" "EK" "ER" "ET" "GA" "GM" GH" "GU" GN" GY" "HT" "HN" "IA" JO" "KE" "LA" "LS" "LB" "MD" "MW" "MV" "ML" "MR" "MX" "MA" MZ" "MM" "NM" "NP" "NC" "NI" "NG" "PK" "PY" "PE" "PH" "RW" "WS" "ST" "SN" "SL" "ZA" "SD" "SZ" "TJ" "TZ" "TL" "TG" "TM" "UG" "UZ" "YE" "ZM" "ZW" "'
		
	gen high_fertility_country = .
		foreach country of local high_fertility_countries {
		replace high_fertility = 1 if dhscc == `"`country'"'
		}
	
// Low-fertility countries:

	local low_fertility_countries ///
		`" "AL" "AM" "AZ" "BR" "CO" "KK" "KY" "ID" "MB" "LK" "TH" "TR" "TN" "TT" "UA" "VN" "UZ" "'

	gen low_fertility_country = .
		foreach country of local low_fertility_countries {
		replace low_fertility = 1 if dhscc == `"`country'"'
		}
				
// High/low-fertility individuals:

	gen high_fertility_individual = .
		replace high_fertility_individual = 1 if w_ideal_kids_trunc > 3
		label var high_fertility_individual "Desired fertililty over 3"
		
	gen low_fertility_individual = .
		replace low_fertility_individual = 1 if w_ideal_kids_trunc <= 3
		label var low_fertility_individual "Desired fertililty 3 and under"

	save "$d_recods/womens_recodes/womens_dhs_merged", replace

		
*--------------------------------------------------------------------*
* (5.0) Dropping unnecessary data 
*--------------------------------------------------------------------*	
	
	drop *literate* 
	drop marriage*
	drop contra*
	drop visitor
	drop h_*
	drop ethnicity*
	drop religion*
	drop d_water*
	drop age2
	drop edu_none
	drop edu_prim*
	drop edu_high*
	drop has_*
	drop floor*
	drop wall*
	drop roof*
	drop freq*
	drop contra*
	drop sterilized*
	drop w_weight*
	drop w_hgt*
	drop w_wgt*
	drop w_bmi*
	drop husb*
	drop w_work*
	drop w_ctrl*
	drop w_exp*
	drop w_first*
	drop w_nnprt*
	drop w_any_*
	drop w_age_1st*
	drop w_hgb*
	drop w_anem*
	drop w_very*
	drop hh_water*
	drop water*
	drop myid
	drop tropical*
	drop large_*
	drop political*
	drop economic*
	drop european*
	
	compress

*--------------------------------------------------------------------*
* (5.0) Labeling data 
*--------------------------------------------------------------------*	
	
	label var child_bride "Child bride"
	label var age_firstmarriage "Age at first marriage"
	label var w_pref_nomorekids "Prefers no more children"
	label var total_children "Total children"
	label var total_sons "Total sons"
	label var total_daughters "Total daughters"
	label var total_child_mort "Total child mortality"
	label var ever_miscarried "Previous pregnacy"
	label var country "Country"
	label var sub_s_africa "Sub-Saharan Africa"
	label var recent_thirdborn_son "Recent thirdborn son"
	label var recent_thirdborn_daughter "Recent thirdborn daughter"
	label var recent_secondborn_son "Recent secondborn son"
	label var recent_secondborn_daughter "Recent secondborn daughter"
	label var recent_firstborn_son "Recent firstborn son"
	label var recent_firstborn_daughter "Recent firstborn daughter"
	label var thirdborn_son "Thirdborn son"
	label var thirdborn_daughter "Thirdborn daughter"
	label var secondborn_son "Secondborn son"
	label var secondborn_daughter "Secondborn daughter"
	label var firstborn_son "Firstborn son"
	label var firstborn_daughter "Firstborn daughter"
	label var secondborn "Second child"
	label var thirdborn "Third child"
	label var recentbirth "Recent birth"
	label var firstborn "First child"
	label var recent_firstborn "Recent firstborn"
	label var rural "Rural household"
	
	
*--------------------------------------------------------------------*
* (6.0)	Generating SRB samples
*--------------------------------------------------------------------*			
	
	local high_SRB `" "AL" "AM" "AZ" "IA" "LS" "MD" "MW" "NP" "PK" "WS" "TN" "'
	
	gen high_SRB = .
		foreach a of local high_SRB {
		replace high_SRB = 1 if dhscc == "`a'"
		}
	
	local low_SRB `" "AO" "SZ" "EK" "GA" "GN" "KE" "MZ" "TZ" "MM" "RW" "ST" "SL" "TG" "UG" "ZA" "ZW" "' 
	
	gen low_SRB = .
		foreach b of local low_SRB {
		replace low_SRB = 1 if dhscc == "`b'"
		}
	
	local natural_SRB `" "AF" "BD" "BJ" "BO" "BT" "BR" "ER" "ET" "GH" "GU" "GY" "HT" "HN" "ID" "JD" "KK" "KY" "LA" "LB" "MV" "ML" "MR" "MX" "MO" "NC" "NI" "MA" "NG" "PY" "PE" "PH" "SN" "ZA" "LK" "SD" "TJ" "TT" "TR" "TM" "UA" "UZ" "YE" "'

	gen natural_SRB = .
		foreach c of local natural_SRB {
		replace natural_SRB = 1 if dhscc == "`c'"
		}
	
*--------------------------------------------------------------------*			
		
	save "$d_recods/womens_recodes/womens_culled", replace

	
	
	
	
	
	
	
	



