*--------------------------------------------------------------------*
* Lauren Lamson
* How Sex of Child Influences Fertility Preferences 
* Women's Driver - Regression Output
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
* Table of Contents
*
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
* (0.1)	Setting Directories
*--------------------------------------------------------------------*

	global d_home "/Users/lauren/Desktop/thesis" 
	global d_data "$d_home/data"	
	global d_recodes "$d_data/recodes/womens_recodes" 
	global d_do "$d_home/do_files/womens/_regressions"
	global d_output "$d_home/output/tables/womens_regressions/"

*--------------------------------------------------------------------*
* (0.2)	Project Set Up
*--------------------------------------------------------------------*

	clear matrix
	clear mata
	capture log close
	set more off			
	set matsize 800	

	use "$d_recodes/womens_culled.dta"
	
*--------------------------------------------------------------------*
* (1.0)	Read in do files
*--------------------------------------------------------------------*	

// Women's fertility preferences - entires women's sample
	*do "$d_do/_womens_fertility_preferences.do"
	
// Women's fertility preferences - high fertility countries
	*do "$d_do/_womens_high_fertility_countries.do"
	
// Women's fertility preferences - low fertility countries
	*do "$d_do/_womens_low_fertility_countries.do"
	
// Women's fertility preferences - high fertility individuals
	*do "$d_do/_womens_high_fertility_individuals.do"
	
// Women's fertility preferences - low fertility individuals
	*do "$d_do/_womens_low_fertility_individuals.do"
	
// Women's fertility preferences - no India sample
	*do "$d_do/_womens_no_india.do"
	
// Women's fertility preferences - first pregnancy only sample
	*do "$d_do/_womens_first_pregnancy.do"
	
// Women's fertility preferences - high SRB ratio
	*do "$d_do/_womens_high_SRB.do"

// Women's fertility preferences - low SRB ratio
	*do "$d_do/_womens_low_SRB.do"
	
// Women's fertility preferences - natural SRB ratio
	*do "$d_do/_womens_natural_SRB.do"
	
// Women's fertility preferences - age range kids
	*do "$d_do/_womens_age_range_kids.do"	
	
// Women's fertility preferences - age range girls
	*do "$d_do/_womens_age_range_girls.do"	
	
// Women's fertility preferences - age range boys
	*do "$d_do/_womens_age_range_boys.do"
		
// Women's fertility preferences - high plow sample
	*do "$d_do/_womens_high_plow.do"	
	
// Women's fertility preferences - low plow sample
	*do "$d_do/_womens_low_plow.do"	
		
	
	
	
	
	
	
	
