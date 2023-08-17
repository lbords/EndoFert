
*----------------------------------------------------------------------*
* Fertility Preferences by Age - Kids
*----------------------------------------------------------------------*


	reghdfe w_ideal_kids_trunc recent_firstborn_daughter recent_firstborn ///
	edu_yrs_trunc rural poor ever_miscarried [aweight=wght_avg_pop] ///
	if age >=15 & age <= 20, absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)
	
	outreg2 using "$d_output/womens_age_range_kids.tex", ///
	label excel dec(3) replace addtext(Age 15-20)

	reghdfe w_ideal_kids_trunc recent_firstborn_daughter recent_firstborn ///
	edu_yrs_trunc rural poor ever_miscarried [aweight=wght_avg_pop] ///
	if age > 20 & age <= 25, absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)
	
	outreg2 using "$d_output/womens_age_range_kids.tex", ///
	label excel dec(3) append addtext(Age 21-25)

	reghdfe w_ideal_kids_trunc recent_firstborn_daughter recent_firstborn ///
	edu_yrs_trunc rural poor ever_miscarried [aweight=wght_avg_pop] ///
	if age > 25 & age <= 30, absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)

	outreg2 using "$d_output/womens_age_range_kids.tex", ///
	label excel dec(3) append addtext(Age 26-30)
		
	reghdfe w_ideal_kids_trunc recent_firstborn_daughter recent_firstborn ///
	edu_yrs_trunc rural poor ever_miscarried [aweight=wght_avg_pop] ///
	if age > 30 & age <= 35, absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)
	
	outreg2 using "$d_output/womens_age_range_kids.tex", ///
	label excel dec(3) append addtext(Age 31-35)

	reghdfe w_ideal_kids_trunc recent_firstborn_daughter recent_firstborn ///
	edu_yrs_trunc rural poor ever_miscarried [aweight=wght_avg_pop] ///
	if age > 35 & age <= 40, absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)
	
	outreg2 using "$d_output/womens_age_range_kids.tex", ///
	label excel dec(3) append addtext(Age 36-40)

	reghdfe w_ideal_kids_trunc recent_firstborn_daughter recent_firstborn ///
	edu_yrs_trunc rural poor ever_miscarried [aweight=wght_avg_pop] ///
	if age > 40, absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)

	outreg2 using "$d_output/womens_age_range_kids.tex", ///
	label excel dec(3) append addtext(Over 40)
