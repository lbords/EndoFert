
*--------------------------------------------------------------------*
* Do file running women's fertility preferences 
* First pregnancy only sample
*--------------------------------------------------------------------*
	
*--------------------------------------------------------------------*
* (1.0)	Ideal number of children regressions
*--------------------------------------------------------------------*	
	
// First birth controls
	reghdfe w_ideal_kids_trunc recent_firstborn_daughter recent_firstborn [aweight=wght_avg_pop] if ever_miscarried == 0, ///
	absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)

	outreg2 using "$d_output/womens_first_pregnancy.tex", ///
	label excel dec(3) replace addtext(First births controls, YES, Demographic controls, NO)
	
// First birth controls + demographic controls
	reghdfe  w_ideal_kids_trunc recent_firstborn_daughter recent_firstborn age age_firstbirth_trunc ///
	edu_yrs_trunc rural total_children poor [aweight=wght_avg_pop] if ever_miscarried == 0, ///
	absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)

	outreg2 using "$d_output/womens_first_pregnancy.tex", ///
	label excel dec(3) append addtext(First births controls, YES, Demographic controls, YES)
	
*--------------------------------------------------------------------*
* (2.0)	Ideal number of girls regressions
*--------------------------------------------------------------------*	

// First birth controls
	reghdfe w_ideal_girls_trunc recent_firstborn_daughter recent_firstborn [aweight=wght_avg_pop] if ever_miscarried == 0, ///
	absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)
	
	outreg2 using "$d_output/womens_first_pregnancy.tex", ///
	label excel dec(3) append addtext(First births controls, YES, Demographic controls, NO)
	
// First birth controls + demographic controls
	reghdfe w_ideal_girls_trunc recent_firstborn_daughter recent_firstborn age age_firstbirth_trunc ///
	edu_yrs_trunc rural total_children poor [aweight=wght_avg_pop] if ever_miscarried == 0, ///
	absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)
	
	outreg2 using "$d_output/womens_first_pregnancy.tex", ///
	label excel dec(3) append addtext(First births controls, YES, Demographic controls, YES)
	
*--------------------------------------------------------------------*
* (3.0)	Ideal number of boys regressions
*--------------------------------------------------------------------*	

// First birth controls
	reghdfe w_ideal_boys_trunc recent_firstborn_daughter recent_firstborn [aweight=wght_avg_pop] if ever_miscarried == 0, ///
	absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)

	outreg2 using "$d_output/womens_first_pregnancy.tex", ///
	label excel dec(3) append addtext(First births controls, YES, Demographic controls, NO)
	
// First birth controls + demographic controls
	reghdfe w_ideal_boys_trunc recent_firstborn_daughter recent_firstborn age age_firstbirth_trunc ///
	edu_yrs_trunc rural total_children poor [aweight=wght_avg_pop] if ever_miscarried == 0, ///
	absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)
	
 	outreg2 using "$d_output/womens_first_pregnancy.tex", ///
	label excel dec(3) append addtext(First births controls, YES, Demographic controls, YES)
	
	
