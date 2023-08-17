
*--------------------------------------------------------------------*
* Do file running women's fertility preferences 
* Family Composition Regressions
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
* (1.1)	Ideal number of children - all girls 
*--------------------------------------------------------------------*	

// Ideal number of children if two children are girls 
	reghdfe w_ideal_kids_trunc recent_secondborn_daughter recentbirth ///
		[aweight=wght_avg_pop] ///
		if firstborn_daughter == 1, ///
		absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
		vce(cluster i.std_adm_region_code)
	
		outreg2 using "$d_output/family_comp.tex", ///
		label excel dec(3) replace addtext(Recent birth controls, YES, Demographic controls, NO)
		
// Ideal number of children if two children are girls - controls added
	reghdfe w_ideal_kids_trunc recent_secondborn_daughter recentbirth ///
		age age_firstbirth_trunc edu_yrs_trunc rural total_children poor ///
		[aweight=wght_avg_pop] ///
		if firstborn_daughter == 1, ///
		absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
		vce(cluster i.std_adm_region_code)

		outreg2 using "$d_output/family_comp.tex", ///
		label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, YES)
		
*--------------------------------------------------------------------*
* (1.2)	Ideal number of children - all boys
*--------------------------------------------------------------------*	

// Ideal number of children if two children are boys 
	reghdfe w_ideal_kids_trunc recent_secondborn_son recentbirth ///
		[aweight=wght_avg_pop] ///
		if firstborn_son == 1, ///
		absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
		vce(cluster i.std_adm_region_code)
		
		outreg2 using "$d_output/family_comp.tex", ///
		label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, NO)
	
// Ideal number of children if two children are boys - controls added
	reghdfe w_ideal_kids_trunc recent_secondborn_son recentbirth ///
		age age_firstbirth_trunc edu_yrs_trunc rural total_children poor ///
		[aweight=wght_avg_pop] ///
		if firstborn_son == 1, ///
		absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
		vce(cluster i.std_adm_region_code)
		
		outreg2 using "$d_output/family_comp.tex", ///
		label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, YES)
	
*--------------------------------------------------------------------*
* (2.1)	Ideal number of girls - all girls 
*--------------------------------------------------------------------*	

// Ideal number of children if two children are girls 
	reghdfe w_ideal_girls_trunc recent_secondborn_daughter recentbirth ///
		[aweight=wght_avg_pop] ///
		if firstborn_daughter == 1, ///
		absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
		vce(cluster i.std_adm_region_code)
	
	outreg2 using "$d_output/family_comp.tex", ///
	label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, NO)
	
// Ideal number of children if two children are girls - controls added
	reghdfe w_ideal_girls_trunc recent_secondborn_daughter recentbirth ///
		age age_firstbirth_trunc edu_yrs_trunc rural total_children poor ///
		[aweight=wght_avg_pop] ///
		if firstborn_daughter == 1, ///
		absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
		vce(cluster i.std_adm_region_code)

	outreg2 using "$d_output/family_comp.tex", ///
	label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, YES)
	
*--------------------------------------------------------------------*
* (2.2)	Ideal number of girls - all boys
*--------------------------------------------------------------------*	

// Ideal number of children if two children are boys 
	reghdfe w_ideal_girls_trunc recent_secondborn_son recentbirth ///
		[aweight=wght_avg_pop] ///
		if firstborn_son == 1, ///
		absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
		vce(cluster i.std_adm_region_code)
	
		outreg2 using "$d_output/family_comp.tex", ///
		label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, NO)
			
// Ideal number of children if two children are boys - controls added
	reghdfe w_ideal_girls_trunc recent_secondborn_son recentbirth ///
		age age_firstbirth_trunc edu_yrs_trunc rural total_children poor ///
		[aweight=wght_avg_pop] ///
		if firstborn_son == 1, ///
		absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
		vce(cluster i.std_adm_region_code)
		
		outreg2 using "$d_output/family_comp.tex", ///
		label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, YES)
	
*--------------------------------------------------------------------*
* (3.1)	Ideal number of boys - all boys 
*--------------------------------------------------------------------*	

// Ideal number of children if two children are girls
	reghdfe w_ideal_boys_trunc recent_secondborn_daughter recentbirth ///
	[aweight=wght_avg_pop] ///
	if firstborn_daughter == 1, ///
	absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)
	
	outreg2 using "$d_output/family_comp.tex", ///
	label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, NO)
	
// Ideal number of children if two children are girls - controls added
	reghdfe w_ideal_boys_trunc recent_secondborn_daughter recentbirth ///
	age age_firstbirth_trunc edu_yrs_trunc rural total_children poor ///
	[aweight=wght_avg_pop] ///
	if firstborn_daughter == 1, ///
	absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
	vce(cluster i.std_adm_region_code)

	outreg2 using "$d_output/family_comp.tex", ///
	label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, YES)
	
*--------------------------------------------------------------------*
* (3.2)	Ideal number of boys - all boys
*--------------------------------------------------------------------*	

// Ideal number of children if two children are boys 
	reghdfe w_ideal_boys_trunc recent_secondborn_son recentbirth ///
		[aweight=wght_avg_pop] ///
		if firstborn_son == 1, ///
		absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
		vce(cluster i.std_adm_region_code)
	
		outreg2 using "$d_output/family_comp.tex", ///
		label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, NO)
		
// Ideal number of children if two children are boys - controls added
	reghdfe w_ideal_boys_trunc recent_secondborn_son recentbirth ///
		age age_firstbirth_trunc edu_yrs_trunc rural total_children poor ///
		[aweight=wght_avg_pop] ///
		if firstborn_son == 1, ///
		absorb(i.std_adm_region_code##i.interview_month i.interview_year) ///
		vce(cluster i.std_adm_region_code)
		
		outreg2 using "$d_output/family_comp.tex", ///
	label excel dec(3) append addtext(Recent birth controls, YES, Demographic controls, YES)
	
	
