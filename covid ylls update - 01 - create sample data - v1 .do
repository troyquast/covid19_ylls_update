clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;

log using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\covid ylls update - 01 - create sample data - v1 .smcl", replace ;

* read in & revise covid data ;
	* read in data ;
		import excel using "C:\Users\Troy\Box Sync\_ troy's files\research\_data\us\cdc\covid\cdc - covid-19 deaths by sex, age, & state .xlsx", sheet("data as of 2021-02-03") first allstring ;			
	* change US state name so it always sorts to top ;
		replace State = "1 United States" if State == "United States" ;
	* drop states that do not report deaths by gender ;
		gsort State ;
		list State COVID19Deaths if Agegroup == "All ages" & Sex == "Female" ;
		list State COVID19Deaths if Agegroup == "All ages" & Sex == "Male" ;
/*
		drop if 
			State == "Alaska"      | State == "Alaska Total" | 
			State == "Hawaii"      | State == "Hawaii Total" | 
			State == "Puerto Rico" | State == "Puerto Rico Total" | 
			State == "Wyoming"     | State == "Wyoming Total" ;
*/
	* drop totals across genders ;
		drop if Sex == "All Sexes" ; 
	* limit to relevant vars ;
		keep State Sex Agegroup COVID19Deaths ;
	* destring covid deaths var ;
		destring COVID19Deaths, force gen(num_deaths_report) ;
		drop COVID19Deaths ;
	* sex var ;
		* revise sex var values for easier variable creation below ;
				replace Sex = "female" if Sex == "Female";
				replace Sex = "male"   if Sex == "Male";
		* account for deaths of unknown sex ;
			* show national total of covid deaths w/ unknown sex ;
				list State num_deaths_report if State == "United States" & Sex == "Unknown" ;
			* show states that have blank # deaths for Unknown sex ;
			* (indicates that the count is suppressed & is thus between 1 & 9) ;
				table num_deaths_report if Sex == "Unknown" ;
				gsort State Sex Agegroup ;
				list State Sex Agegroup num_deaths_report if Sex == "Unknown" & num_deaths_report ~= 0 ;
			* drop all observations for unknown sex ;
				drop if Sex == "Unknown" ;
		* check for deaths for which gender was suppressed ;
			gsort State Sex ;
			list State Sex if num_deaths_report == . & Agegroup == "All Ages" ;
	* drop age groups that were added on 2020-09-02 ;
		drop if Agegroup == "0-17 years" | Agegroup == "18-29 years" | Agegroup == "30-49 years" | Agegroup == "50-64 years" ;
	* create new age group var ;
		gen     age_group = "00_00" if Agegroup == "Under 1 year" ;
		replace age_group = "01_04" if Agegroup == "1-4 years" ;
		replace age_group = "05_14" if Agegroup == "5-14 years" ;
		replace age_group = "15_24" if Agegroup == "15-24 years" ;
		replace age_group = "25_34" if Agegroup == "25-34 years" ;
		replace age_group = "35_44" if Agegroup == "35-44 years" ;
		replace age_group = "45_54" if Agegroup == "45-54 years" ;
		replace age_group = "55_64" if Agegroup == "55-64 years" ;
		replace age_group = "65_74" if Agegroup == "65-74 years" ;
		replace age_group = "75_84" if Agegroup == "75-84 years" ;
		replace age_group = "85_99" if Agegroup == "85 years and over" ;
		replace age_group = "00_99" if Agegroup == "All Ages" ;
		drop Agegroup ;
	* order vars ;
		order State Sex age_group ;
	* determine # deaths where data were suppressed ;
		* calc # deaths for which age group was suppressed by state & gender ;
			* create var that is the # reported deaths for that state & gender ; 
				gsort State Sex ;
				by State Sex: egen num_deaths_rep_st_sex_temp = mean(num_deaths_report) if age_group == "00_99" ;
				by State Sex: egen num_deaths_rep_st_sex = mean(num_deaths_rep_st_sex_temp) ;
				drop num_deaths_rep_st_sex_temp ;
			* create var that is the # reported deaths summed across age groups for that state & gender ; 
				gsort State Sex ;
				by State Sex: egen num_deaths_sum_st_sex = sum(num_deaths_report) if age_group ~= "00_99" ;
			* create var that is the calculated number of suppressed deaths by state & gender (& not by age group) ;
				gen num_deaths_sup_st_sex = num_deaths_rep_st_sex - num_deaths_sum_st_sex ;
			* show # deaths suppressed for which age group was suppressed by state & gender ;
				gsort State Sex ;
				list State Sex num_deaths_sup_st_sex if age_group == "00_00" ;
		* show total # deaths vs unsuppressed # at national level;
			list State Sex num_deaths_report if State == "1 United States" & age_group == "00_99" ;
			gsort Sex ;
			by Sex: egen num_deaths_report_sex_us = sum(num_deaths_report)     if State ~= "1 United States" & age_group ~= "00_99" ;
			by Sex: egen num_deaths_sup_sex_us    = sum(num_deaths_sup_st_sex) if State ~= "1 United States" & age_group == "00_00" ;
			by Sex: sum  num_deaths_report_sex_us num_deaths_sup_sex_us ;
/*

I DON'T THINK I'M GOING TO TRY TO ALLOCATE SUPPRESSED DEATHS 
INSTEAD, I'LL NOTE THAT THE YLL'S BY AGE GROUP ARE MISSING THE SPECIFIED NUMBER OF DEATHS


		* for entire country, calc proportion of deaths by age group for each gender ;
			* create vars that are the reported total # deaths in country by gender ;
				gsort Sex ;
				by Sex: gen  num_deaths_us_sex_00_99_temp = num_deaths_report if State == "United States" & age_group == "00_99" ;
				by Sex: egen num_deaths_us_sex_00_99_rep  = mean(num_deaths_us_sex_00_99_temp) ;
				drop num_deaths_us_sex_00_99_temp ;
			* create var that is the # of deaths nationally by age group for each gender ;
				gsort Sex age_group ;
				by Sex age_group: gen num_deaths_us_sex_age_temp = num_deaths_report if State == "United States" ;
				by Sex age_group : egen num_deaths_us_sex_age_rep  = mean(num_deaths_us_sex_age_temp) ;
				drop num_deaths_us_sex_age_temp ;
			* create var that is the proportion of US deaths by age group for each gender when death count is suppressed for that age group & gender ;
				gen pro_deaths_us_sex_age_temp = num_deaths_us_sex_age_rep / num_deaths_us_sex_00_99_rep ;
				gen pro_deaths_us_sex_age = pro_deaths_us_sex_age_temp if num_deaths_report == . ;
				drop pro_deaths_us_sex_age_temp ;
		* apply national proportions to # suppressed deaths by state & gender ;
			* calc the sum of proportions where no deaths were reported by age group & gender ;
				gsort State Sex ;
				by State Sex: egen sum_pro_sup_deaths_st_sex = sum(pro_deaths_us_sex_age) if age_group ~= "00_99" ;
			* calc the proportion of the proportion where no deaths were reported ;
				gen pro_sup_deaths_st_sex = pro_deaths_us_sex_age / sum_pro_sup_deaths_st_sex ;
			* estimate # suppressed deaths for that age group ;
				gen     num_deaths_extrap = . ;
				replace num_deaths_extrap = num_deaths_report if num_deaths_report ~= . ;
				replace num_deaths_extrap = trunc( pro_sup_deaths_st_sex * num_deaths_sup_st_sex) if num_deaths_report == . ;
*/



		* drop unneeded vars ;
			drop num_deaths_sup_st_sex num_deaths_report_sex_us /* num_deaths_us_sex_00_99_rep num_deaths_us_sex_age_rep pro_deaths_us_sex_age sum_pro_sup_deaths_st_sex pro_sup_deaths_st_sex */ ;
	* drop totals across age groups ;
		drop if age_group == "00_99" ;
	* limit to relevant variables ;
		keep  State Sex age_group num_deaths_report /* num_deaths_extrap */ ;
		order State Sex age_group num_deaths_report /* num_deaths_extrap */ ;
	* add life expect by age group & gender ;
	* (using 2017 actuarial table & using ages 0, 2, 10, 20, ...) ;
		gen     life_expect_100pct = . ;
		replace life_expect_100pct = 75.97 if Sex == "male"   & age_group == "00_00" ;
		replace life_expect_100pct = 74.48 if Sex == "male"   & age_group == "01_04" ;
		replace life_expect_100pct = 66.57 if Sex == "male"   & age_group == "05_14" ;
		replace life_expect_100pct = 56.85 if Sex == "male"   & age_group == "15_24" ;
		replace life_expect_100pct = 47.65 if Sex == "male"   & age_group == "25_34" ;
		replace life_expect_100pct = 38.56 if Sex == "male"   & age_group == "35_44" ;
		replace life_expect_100pct = 29.67 if Sex == "male"   & age_group == "45_54" ;
		replace life_expect_100pct = 21.58 if Sex == "male"   & age_group == "55_64" ;
		replace life_expect_100pct = 14.39 if Sex == "male"   & age_group == "65_74" ;
		replace life_expect_100pct =  8.28 if Sex == "male"   & age_group == "75_84" ;
		replace life_expect_100pct =  4.05 if Sex == "male"   & age_group == "85_99" ;
		replace life_expect_100pct = 80.96 if Sex == "female" & age_group == "00_00" ;
		replace life_expect_100pct = 79.42 if Sex == "female" & age_group == "01_04" ;
		replace life_expect_100pct = 71.50 if Sex == "female" & age_group == "05_14" ;
		replace life_expect_100pct = 61.63 if Sex == "female" & age_group == "15_24" ;
		replace life_expect_100pct = 51.97 if Sex == "female" & age_group == "25_34" ;
		replace life_expect_100pct = 42.47 if Sex == "female" & age_group == "35_44" ;
		replace life_expect_100pct = 33.23 if Sex == "female" & age_group == "45_54" ;
		replace life_expect_100pct = 24.56 if Sex == "female" & age_group == "55_64" ;
		replace life_expect_100pct = 16.54 if Sex == "female" & age_group == "65_74" ;
		replace life_expect_100pct =  9.68 if Sex == "female" & age_group == "75_84" ;
		replace life_expect_100pct =  4.78 if Sex == "female" & age_group == "85_99" ;
		table life_expect_100pct, missing ;
	* create discounted life expectances (to adjust for sicker population) ;
		gen life_expect_75pct = life_expect_100pct * .75 ;
		gen life_expect_50pct = life_expect_100pct * .50 ;
		gen life_expect_25pct = life_expect_100pct * .25 ;
	* calc life expectancies discounted at 3%/year ;
		foreach X in 100 75 50 25 
			{ ;
			gen life_expect_disc_`X'pct = (1/.03) * ( 1 - [1/((1+.03)^life_expect_`X'pct)]) ;
			} ;
	* rename new york state name to clarify it doesn't include nyc ;
		replace State = "New York (excl NYC)" if State == "New York" ;
	* rename state var for merge w/ pop data ;
		rename State state ;
	* sort & save ;
		gsort state ;
		tempfile death_counts ;
		save "`death_counts'" ;
		clear ;
* open & save pop data ;
	* read in data ;
		import excel using "C:\Users\Troy\Box Sync\_ troy's files\research\_data\us\population\pop by gender-age-race (but not hispanic)\pop by st-gender-age-race (2010-2019).xlsx", sheet("data") first allstring ;	
	* keep relevant vars ;
		keep NAME SEX ORIGIN RACE AGE POPESTIMATE2019 ;
	* drop observations for total across genders ;
		drop if SEX == "0" | ORIGIN == "0" | RACE == "0" | AGE == "0" ; 
	* drop states excluded from analysis ;
		/* drop if NAME == "Alaska" | NAME == "Hawaii" | NAME == "Wyoming" */ ;
	* destring pop var ;
		destring POPESTIMATE2019, gen(pop_st_gend) ;
	* revise sex values ;
		replace SEX = "male"   if SEX == "1" ;
		replace SEX = "female" if SEX == "2" ;
	* rename vars ;
		rename (NAME SEX) (state Sex) ;
	* sum pop by state & gender ;
		collapse (sum) pop_st_gend, by(state Sex) ;
	* adjust new york values ;
		replace state = "New York (excl NYC)" if state == "New York" ;
		replace pop_st_gend = pop_st_gend - trunc(.523 * 8336817) if state == "New York (excl NYC)" & Sex == "female" ;
		replace pop_st_gend = pop_st_gend - trunc(.477 * 8336817) if state == "New York (excl NYC)" & Sex == "male" ;
		* add observation ;
			set obs 104 ;
		* create observation for new york city ;
			replace state = "New York City" if state == "" ;
			replace Sex = "female" if state == "New York City" & state[_n-1] ~= "New York City" ;
			replace Sex = "male"   if state == "New York City" & state[_n-1] == "New York City" ;
			replace pop_st_gend   = trunc(.523 * 8336817) if state == "New York City" & Sex == "female" ;
			replace pop_st_gend   = trunc(.477 * 8336817) if state == "New York City" & Sex == "male" ;
	* sort & save ;
		gsort state ;
		tempfile pop ;
		save "`pop'" ;
		clear ;
* merge datasets ;
	use "`death_counts'" ;
	merge m:1 state Sex using "`pop'" ;
	table state if _merge == 1 ;
	drop if _merge == 1 ;
	drop _merge ;
* create state abbreviation var ;
	gen state_abbrev = "" ;
	replace state_abbrev = "AL" if state == "Alabama" ;
	replace state_abbrev = "AK" if state == "Alaska" ;
	replace state_abbrev = "AZ" if state == "Arizona" ;
	replace state_abbrev = "AR" if state == "Arkansas" ;
	replace state_abbrev = "CA" if state == "California" ;
	replace state_abbrev = "CO" if state == "Colorado" ;
	replace state_abbrev = "CT" if state == "Connecticut" ;
	replace state_abbrev = "DE" if state == "Delaware" ;
	replace state_abbrev = "DC" if state == "District of Columbia" ;
	replace state_abbrev = "FL" if state == "Florida" ;
	replace state_abbrev = "GA" if state == "Georgia" ;
	replace state_abbrev = "HI" if state == "Hawaii" ;
	replace state_abbrev = "ID" if state == "Idaho" ;
	replace state_abbrev = "IL" if state == "Illinois" ;
	replace state_abbrev = "IN" if state == "Indiana" ;
	replace state_abbrev = "IA" if state == "Iowa" ;
	replace state_abbrev = "KS" if state == "Kansas" ;
	replace state_abbrev = "KY" if state == "Kentucky" ;
	replace state_abbrev = "LA" if state == "Louisiana" ;
	replace state_abbrev = "ME" if state == "Maine" ;
	replace state_abbrev = "MD" if state == "Maryland" ;
	replace state_abbrev = "MA" if state == "Massachusetts" ;
	replace state_abbrev = "MI" if state == "Michigan" ;
	replace state_abbrev = "MN" if state == "Minnesota" ;
	replace state_abbrev = "MS" if state == "Mississippi" ;
	replace state_abbrev = "MO" if state == "Missouri" ;
	replace state_abbrev = "MT" if state == "Montana" ;
	replace state_abbrev = "NE" if state == "Nebraska" ;
	replace state_abbrev = "NV" if state == "Nevada" ;
	replace state_abbrev = "NH" if state == "New Hampshire" ;
	replace state_abbrev = "NJ" if state == "New Jersey" ;
	replace state_abbrev = "NM" if state == "New Mexico" ;
	replace state_abbrev = "NY" if state == "New York (excl NYC)" ;
	replace state_abbrev = "NYC" if state == "New York City" ;
	replace state_abbrev = "NC" if state == "North Carolina" ;
	replace state_abbrev = "ND" if state == "North Dakota" ;
	replace state_abbrev = "OH" if state == "Ohio" ;
	replace state_abbrev = "OK" if state == "Oklahoma" ;
	replace state_abbrev = "OR" if state == "Oregon" ;
	replace state_abbrev = "PA" if state == "Pennsylvania" ;
	replace state_abbrev = "RI" if state == "Rhode Island" ;
	replace state_abbrev = "SC" if state == "South Carolina" ;
	replace state_abbrev = "SD" if state == "South Dakota" ;
	replace state_abbrev = "TN" if state == "Tennessee" ;
	replace state_abbrev = "TX" if state == "Texas" ;
	replace state_abbrev = "US" if state == "United States" ;
	replace state_abbrev = "UT" if state == "Utah" ;
	replace state_abbrev = "VT" if state == "Vermont" ;
	replace state_abbrev = "VA" if state == "Virginia" ;
	replace state_abbrev = "WA" if state == "Washington" ;
	replace state_abbrev = "WV" if state == "West Virginia" ;
	replace state_abbrev = "WI" if state == "Wisconsin" ;
	replace state_abbrev = "WY" if state == "Wyoming" ;
* calculate # of deaths, lost life years, & econ loss ;
	* pop ;
		* by state & gender ;
			gsort state ;
			by state: egen pop_st = total(pop_st_gend) if age_group == "00_00" ;
	* deaths ;
		* by state ;
			gsort state ;
			by state: egen num_deaths_report_st = total(num_deaths_report);
		* by state & gender ;
			gsort state Sex ;
			by state Sex: egen num_deaths_report_st_gend = total(num_deaths_report);
	* lost life years ;
		* for each gender-age group ;
			foreach Y in report  
				{ ;
				foreach Z in 100pct 75pct 50pct 25pct 
					{ ;
					gen lly_`Y'_`Z'      = num_deaths_`Y' * life_expect_`Z'      ;
					gen lly_`Y'_disc_`Z' = num_deaths_`Y' * life_expect_disc_`Z' ;
					} ;
				} ;
		* by state ;
			gsort state ;
			foreach Y in /* report */ report 
				{ ;
				foreach Z in 100pct 75pct 50pct 25pct 
					{ ;
					by state: egen lly_`Y'_`Z'_st      = total(lly_`Y'_`Z') ;
					by state: egen lly_`Y'_disc_`Z'_st = total(lly_`Y'_disc_`Z') ;
					} ;
				} ;
		* by state & gender ;
			gsort state Sex ;
			foreach Y in /* report */ report 
				{ ;
				foreach Z in 100pct 75pct 50pct 25pct 
					{ ;
					by state Sex: egen lly_`Y'_`Z'_st_gend      = total(lly_`Y'_`Z') ;
					by state Sex: egen lly_`Y'_disc_`Z'_st_gend = total(lly_`Y'_disc_`Z') ;
					} ;
				} ;
	* econ loss (based on voly of $66,759) ;
		* by state ;
			foreach Z in 100pct 75pct 50pct 25pct 
				{ ;
				gen econ_report_disc_`Z'_st      = 66759 * lly_report_disc_`Z'_st ;
				gen econ_report_disc_`Z'_st_gend = 66759 * lly_report_disc_`Z'_st_gend ;
				} ;
* calculate # deaths & lost life years per 10,000 capita ;
	* # deaths ;
		* both genders ;
			gen num_deaths_report_cap_st      = 10000 * num_deaths_report_st      / pop_st ;
		* by gender ;
			gen num_deaths_report_cap_st_gend = 10000 * num_deaths_report_st_gend / pop_st_gend ;
	* lost life years ;
		foreach Y in /* report */ report 
			{ ;
			foreach Z in 100pct 75pct 50pct 25pct 
				{ ;
				* both genders ;
					gen lly_cap_`Y'_`Z'_st      = 10000 * lly_`Y'_`Z'_st      / pop_st ;
					gen lly_cap_`Y'_disc_`Z'_st = 10000 * lly_`Y'_disc_`Z'_st / pop_st ;
				* by gender ;
					gen lly_cap_`Y'_`Z'_st_g      = 10000 * lly_`Y'_`Z'_st_gend      / pop_st_gend ;
					gen lly_cap_`Y'_disc_`Z'_st_g = 10000 * lly_`Y'_disc_`Z'_st_gend / pop_st_gend ;
				} ;
			} ;
* calculate econ loss per 10,000 capita (based on voly of $66,759) ;
	foreach Y in /* report */ report 
		{ ;
		foreach Z in 100pct 75pct 50pct 25pct 
			{ ;
			* both genders ;
				gen econ_cap_`Y'_disc_`Z'_st   = 66759 * lly_`Y'_disc_`Z'_st      / pop_st ;
			* by gender ;
				gen econ_cap_`Y'_disc_`Z'_st_g = 66759 * lly_`Y'_disc_`Z'_st_gend / pop_st_gend ;
			} ;
		} ;
* format vars ;
	format lly_report_100pct_st*        lly_report_75pct_st*        lly_report_50pct_st*        lly_report_25pct_st*       %9.0fc ;
	format lly_report_disc_100pct_st*   lly_report_disc_75pct_st*   lly_report_disc_50pct_st*   lly_report_disc_25pct_st*   %9.0fc ;
	format lly_cap_report_100pct*       lly_cap_report_75pct*       lly_cap_report_50pct*       lly_cap_report_25pct*       %9.2fc ;
	format lly_cap_report_disc_100pct*  lly_cap_report_disc_75pct*  lly_cap_report_disc_50pct*  lly_cap_report_disc_25pct*  %9.2fc ;
	format econ_cap_report_disc_100pct* econ_cap_report_disc_75pct* econ_cap_report_disc_50pct* econ_cap_report_disc_25pct* %9.2fc ;
*summarize ;
	* by state ;
		* 100% life expectancy ;
			gsort -num_deaths_report_st state ;
			list 
				state 
				num_deaths_report_st pop_st num_deaths_report_cap_st lly_report_100pct_st lly_cap_report_100pct_st /* lly_report_disc_100pct_st econ_cap_report_disc_100pct_st */
				if age_group == "00_00" & Sex == "female" ,
				/* compress */ ;
		* 75% life expectancy ;
			gsort -num_deaths_report_st state ;
			list 
				state 
				num_deaths_report_st pop_st num_deaths_report_cap_st lly_report_75pct_st lly_cap_report_75pct_st /* lly_report_disc_75pct_st econ_cap_report_disc_75pct_st */
				if age_group == "00_00" & Sex == "female" ,
				compress ;
		* 50% life expectancy ;
			gsort -num_deaths_report_st state ;
			list 
				state 
				num_deaths_report_st pop_st num_deaths_report_cap_st lly_report_50pct_st lly_cap_report_50pct_st /* lly_report_disc_50pct_st econ_cap_report_disc_50pct_st */
				if age_group == "00_00" & Sex == "female" ,
				compress ;
	* by gender ;
		* 75% life expectancy ;
			* females ;
				gsort -num_deaths_report_st state ;
				list 
					state 
					num_deaths_report_st_gend pop_st_gend num_deaths_report_cap_st_gend lly_report_75pct_st_gend lly_cap_report_75pct_st_g /* lly_report_disc_75pct_st_gend econ_cap_report_disc_75pct_st_g */
					if age_group == "00_00" & Sex == "female" ,
					compress ;
#delimit ;
			* males ;
				gsort -num_deaths_report_st state ;
				list 
					state 
					num_deaths_report_st_gend pop_st_gend num_deaths_report_cap_st_gend lly_report_75pct_st_gend lly_cap_report_75pct_st_g /* lly_report_disc_75pct_st_gend econ_cap_report_disc_75pct_st_g */
					if age_group == "00_00" & Sex == "male" ,
					compress ;
* graphical analysis ;
	* graphing set-up ;
		pause on ;
		graph set window fontface "Times New Roman" ;
		set scheme s1color ;
	* scatter of state-level deaths per cap & yll's per cap ;
/*
		* 100% life expectancy ;
			twoway
				( scatter lly_cap_extrap_100pct_st num_deaths_extrap_cap_st , mlabcolor(black) mlabsize(small) mlabel(state_abbrev) mlabposition(0) m(i) )
				( lfit    lly_cap_extrap_100pct_st num_deaths_extrap_cap_st , lcolor(red) lwidth(medthick) )
				if age_group == "00_00" , 
				xlabel( , format(%9.0fc) )
				xtitle( "Deaths per 10,000 capita", /*size(small)*/  axis(1) orientation(horizonta) yoffset(-2) )
				ylabel( , format(%9.0fc) )
				ytitle( "YLLs per 10,000 capita", /*size(small)*/  axis(1) orientation(vertical) xoffset(-2) )
				legend(off) ;
			graph save   "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ylls analysis\stata work\graphs - deaths vs llys per cap (100% life expect) "    , replace ;
			graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ylls analysis\stata work\graphs - deaths vs llys per cap (100% life expect) .tif", replace ;
			pause ;
*/
		* 75% life expectancy ;
			twoway
				( scatter lly_cap_report_75pct_st num_deaths_report_cap_st , mlabcolor(black) mlabsize(small) mlabel(state_abbrev) mlabposition(0) m(i) )
				( lfit    lly_cap_report_75pct_st num_deaths_report_cap_st , lcolor(red) lwidth(medthick) )
				if age_group == "00_00" , 
				xlabel( , format(%9.0fc) )
				xtitle( "Deaths per 10,000 capita", /*size(small)*/  axis(1) orientation(horizonta) yoffset(-2) )
				ylabel( , format(%9.0fc) )
				ytitle( "YLLs per 10,000 capita", /*size(small)*/  axis(1) orientation(vertical) xoffset(-2) )
				legend(off) ;
			graph save   "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\graphs - deaths vs llys per cap (75% life expect) "    , replace ;
			graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\graphs - deaths vs llys per cap (75% life expect) .tif", replace ;
			pause ;
	* state-level choropleth maps ;
		* combine NY (excl NYC) & NYC in analytic data to allow for state-level maps ;
			* limit to necessary vars ;
				keep if age_group == "00_00" ;
				keep state Sex num_deaths_report_st_gend lly_report_100pct_st_gend lly_report_75pct_st_gend lly_report_disc_75pct_st lly_report_disc_75pct_st_gend pop_st pop_st_gend ;
			* need to combine NYC & NY state since maps are at state level ;
				replace state = "New York" if state == "New York (excl NYC)" | state == "New York City" ;
				collapse (sum) num_deaths_report_st_gend lly_report_100pct_st_gend lly_report_75pct_st_gend lly_report_disc_75pct_st lly_report_disc_75pct_st_gend pop_st pop_st_gend, by(state Sex) ;
			* calculate per 10000 cap yll's & econ loss (based on voly of $66,759) ;
				gen lly_cap_report_100pct_st_g = 10000 * lly_report_100pct_st_gend / pop_st_gend ;
				gen lly_cap_report_75pct_st_g  = 10000 * lly_report_75pct_st_gend  / pop_st_gend ;
				gen econ_cap_report_disc_75pct_st   = 66759 * lly_report_disc_75pct_st      / pop_st ;
				gen econ_cap_report_disc_75pct_st_g = 66759 * lly_report_disc_75pct_st_gend / pop_st_gend ;
			* create temp file of analytic data ;
				gsort state ;
				tempfile analytic_data ;
				save "`analytic_data'" ;
				clear ;
		* open & save state boundaries data ;
			* spshapte2dta requires use of local path ;
				cd "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work" ;
			* create dta file; 
				spshape2dta "C:\Users\Troy\Box Sync\_ troy's files\research\_data\us\census bureau\geographic data\cb_2018_us_state_500k.shp", saving(geodata_us_states) replace ;
		* merge state boundries data to analytic dataset ;
			use geodata_us_states.dta, clear ;
			rename NAME state ;
			gsort state ;
			merge 1:m state using "`analytic_data'"	 ;
		* save temp data file ;
			tempfile graph_data ;
			save "`graph_data'" ;
			clear ;
		* create graphs ;
			* yyl's per cap by gender ;
/*
				* 100% life expectancy ;
					* females ;
						use "`graph_data'", clear ;
						keep if Sex == "female" | state == "Wyoming" ;
						grmap lly_cap_report_100pct_st_g , 
							clnumber(8) clmethod(custom) clbreaks(0 5 10 20 35 60 90 250) 
							fcolor(Heat) ndfcolor(black)
							title("Females", size(huge)) 
							legend(size(medium)) ;
						graph save   "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\graphs - map - llys per cap by state - females (100% life expect) "    , replace ;
						graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\graphs - map - llys per cap by state - females (100% life expect) .tif", replace ;
						pause ;	
					* male ;
						use "`graph_data'", clear ;
						keep if Sex == "male" | state == "Wyoming" ;
						grmap lly_cap_report_100pct_st_g , 
							clnumber(8) clmethod(custom) clbreaks(0 5 10 20 35 60 90 250) 
							fcolor(Heat) ndfcolor(black)
							title("Males", size(huge)) 
							legenda(off) ;
						graph save   "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\graphs - map - llys per cap by state - males (100% life expect) "    , replace ;
						graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\graphs - map - llys per cap by state - males (100% life expect) .tif", replace ;
						pause ;	
*/
				* 75% life expectancy ;
					* females ;
						use "`graph_data'", clear ;
						keep if Sex == "female" /* | state == "Wyoming" */ ;
						grmap lly_cap_report_75pct_st_g , 
							clnumber(8) clmethod(custom) clbreaks(0 50 100 150 200 400) 
							fcolor(Heat) ndfcolor(black)
							title("Females", size(huge)) 
							legend(size(medium)) ;
						graph save   "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\graphs - map - llys per cap by state - females (75% life expect) "    , replace ;
						graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\graphs - map - llys per cap by state - females (75% life expect) .tif", replace ;
						pause ;	
					* male ;
						use "`graph_data'", clear ;
						keep if Sex == "male" /* | state == "Wyoming" */ ;
						grmap lly_cap_report_75pct_st_g , 
							clnumber(8) clmethod(custom) clbreaks(0 50 100 150 200 400) 
							fcolor(Heat) ndfcolor(black)
							title("Males", size(huge)) 
							legenda(off) ;
						graph save   "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\graphs - map - llys per cap by state - males (75% life expect) "    , replace ;
						graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2021-02 - ylls update\stata work\graphs - map - llys per cap by state - males (75% life expect) .tif", replace ;
						pause ;	
stop ;
*/
		* econ loss per cap ;
				* 75% life expectancy ;
					* both genders ;
						use "`graph_data'", clear ;
						keep if Sex == "female" | state == "Wyoming" ;
						grmap econ_cap_report_disc_75pct_st , 
							clnumber(8) clmethod(custom) clbreaks(0 100 200 300 400 1000) 
							fcolor(Greens) ndfcolor(black)
							/* title("Females", size(huge)) */
							legend(size(medium)) ;
						graph save   "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-08 - ylls dollar loss\graphs - map - econ loss per cap by state (75% life expect) "    , replace ;
						graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-08 - ylls dollar loss\graphs - map - econ loss per cap by state (75% life expect) .tif", replace ;
						pause ;	


log close ;
end ;
