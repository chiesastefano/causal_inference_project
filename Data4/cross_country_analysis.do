cd "`c(do_dir)'"

use merged_NA, clear

summarize //, detail

// some plots, TODO decide which we need and save 
histogram hourly_wages, bin(50)
graph box hourly_wages
scatter hourly_wages productivity_1


twoway (scatter hourly_wages productivity_1 if tradeunion_density < 40, mcolor(blue)) ///
        (scatter hourly_wages productivity_1 if tradeunion_density >= 40, mcolor(red)), ///
        legend(label(1 "Trade Union Density < 40") label(2 "Trade Union Density ≥ 40")) ///
        title("Hourly Wages vs. Productivity", color(black)) ///
        xtitle("Productivity") ytitle("Hourly Wages")



// correlation with of some variables and their significance, TODO add more
pwcorr hourly_wages productivity_1 tradeunion_density, sig

// some preliminary regression
reghdfe hourly_wages tradeunion_density productivity_1, absorb(geo)


// let's try with -1 productivity and complete regression
reghdfe hourly_wages tradeunion_density productivity_1 hicp business_investment low_education middle_education high_education hh_index partime_contracts realgdp_pc training_education_l4w unemployment, absorb(geo year)
	
 // let's try with -2 productivity
reghdfe hourly_wages tradeunion_density productivity_2 hicp business_investment low_education middle_education high_education hh_index partime_contracts realgdp_pc training_education_l4w unemployment, absorb(geo year)


// let's try with more years of productivity
reghdfe hourly_wages tradeunion_density productivity_pp productivity_1 productivity_2 hicp business_investment low_education middle_education high_education low_education hh_index partime_contracts realgdp_pc training_education_l4w unemployment, absorb(geo year)


// is productivity_1 exogenous? Yes
drop residuals
reghdfe hourly_wages productivity_1, absorb(geo year) resid(residuals)
corr productivity_pp residuals

twoway scatter residuals productivity_1, ///
xlabel(, grid) ylabel(, grid) ///
title("Correlation between Productivity_1 and Residuals") ///
xtitle("Productivity_pp") ytitle("Residuals")



// same for productivity_2
drop residuals
reghdfe hourly_wages productivity_2, absorb(geo year) resid(residuals)
corr productivity_pp residuals

twoway scatter residuals productivity_2, ///
xlabel(, grid) ylabel(, grid) ///
title("Correlation between Productivity_2 and Residuals") ///
xtitle("Productivity_pp") ytitle("Residuals")




// add control variables
drop residuals
reghdfe hourly_wages productivity_1 tradeunion_density unemployment hh_index, absorb(geo year) resid(residuals)
corr productivity_pp residuals
vif, uncentered




