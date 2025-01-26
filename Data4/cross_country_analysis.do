cd "`c(do_dir)'"

use merged_NA, clear

encode geo, gen(geo_num)
xtset geo_num year

summarize //, detail

// some plots, TODO decide which we need and save 
histogram hourly_wages, bin(50)
// distributions among countries. What if divide our analysis by two sets of countries with 20 as threshold?
graph box hourly_wages, over(geo, label(angle(45)))

scatter hourly_wages productivity_1

// checking what if divide by threshold
egen mean_wages = mean(hourly_wages), by(geo)
twoway scatter hourly_wages productivity_1 if mean_wages > 20
// correlation changes from 0.30 if take all data to 0.44 if take this:
correlate hourly_wages productivity_1 if mean_wages <= 20


twoway (scatter hourly_wages productivity_1 if tradeunion_density < 40, mcolor(blue)) ///
        (scatter hourly_wages productivity_1 if tradeunion_density >= 40, mcolor(red)), ///
        legend(label(1 "Trade Union Density < 40") label(2 "Trade Union Density ≥ 40")) ///
        title("Hourly Wages vs. Productivity", color(black)) ///
        xtitle("Productivity") ytitle("Hourly Wages")



// correlation with of some variables and their significance
pwcorr hourly_wages hicp business_investment low_education middle_education ///
       high_education hh_index partime_contracts productivity_pp ///
	   productivity_1 productivity_2 realgdp_pc tradeunion_density ///
	   training_education_l4w unemployment, sig
matrix corrmatrix = r(C)
heatplot corrmatrix, lower values(format(%9.2f)) legend(off)  ///
         title("Correlation Heatmap") xlabel(, angle(45))
// from the above, we can't include al 3 productivities because of issue of 
// multicollinearity; as well we can't include all 3 levels of education

// some preliminary regression, excluded tradeunion_density and unemployment
reghdfe hourly_wages hicp business_investment  ///
        hh_index partime_contracts ///
	    productivity_1 realgdp_pc, absorb(geo year)
		// training_education_l4w middle_education high_education
vif, uncentered


// let's try with -1 productivity and complete regression
reghdfe hourly_wages tradeunion_density productivity_1 hicp business_investment low_education middle_education high_education hh_index partime_contracts realgdp_pc training_education_l4w unemployment, absorb(geo year)
	
 // let's try with -2 productivity
reghdfe hourly_wages tradeunion_density productivity_2 hicp business_investment low_education middle_education high_education hh_index partime_contracts realgdp_pc training_education_l4w unemployment, absorb(geo year)


// let's try with more years of productivity
reghdfe hourly_wages tradeunion_density productivity_pp productivity_1 productivity_2 hicp business_investment low_education middle_education high_education low_education hh_index partime_contracts realgdp_pc training_education_l4w unemployment, absorb(geo year)


// is productivity_1 exogenous? Yes
// drop residuals
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





// SOME experiments for data compliance with assumptions

// for reverse causality between productivity and wages
drop if missing(hourly_wages) | missing(productivity_pp)
xtgcause hourly_wages productivity_pp, lags(2)
xtgcause productivity_pp hourly_wages, lags(2)

drop if missing(diff_hourly_wages) | missing(diff_productivity)
xtgcause diff_hourly_wages diff_productivity
xtgcause diff_productivity diff_hourly_wages


// for first order difference)
generate diff_hourly_wages = D.hourly_wages
generate diff_productivity = D.productivity_pp
reghdfe diff_hourly_wages diff_productivity tradeunion_density unemployment hh_index, absorb(geo year)

reghdfe hourly_wages productivity_1 tradeunion_density unemployment hh_index, absorb(geo year)

// Checking within-unit variation of variables, which should not be zero. hh_index causes conserns (=0.015)
xtsum hourly_wages hicp business_investment low_education middle_education ///
      high_education hh_index partime_contracts productivity_pp ///
	  productivity_1 productivity_2 realgdp_pc tradeunion_density ///
	  training_education_l4w unemployment

	  
// check for serial correlation (if p<0.05, there is serial correlation). And it is present for normal data, but absent for first order differenced
xtserial diff_hourly_wages diff_productivity
xtserial hourly_wages productivity_1

// heteroscedasticity??
xtreg diff_hourly_wages diff_productivity, fe vce(robust)
xttest3

// Cross-Sectional Dependence???
xtcsd, pesaran abs



// robust standart errors to deal with issues
xtreg hourly_wages productivity_1 tradeunion_density unemployment hh_index, fe vce(cluster geo_num)


// Charts of some countries over time
xtline hourly_wages if geo == "Italy" | geo == "France" | geo == "Germany" | geo == "Poland" | geo == "Netherlands", overlay
xtline productivity_pp if geo == "Italy" | geo == "France" | geo == "Germany" | geo == "Poland" | geo == "Netherlands", overlay


// Just an experiment trying to cluster countries based on productivity and wages
egen mean_wages = mean(hourly_wages), by(geo)
egen mean_productivity = mean(productivity_pp), by(geo)
collapse (mean) mean_wages mean_productivity, by(geo)
cluster kmeans mean_wages mean_productivity, k(3) name(Clusters)
cluster list
generate cluster_id = Clusters
sort cluster_id
list geo cluster_id mean_wages mean_productivity
twoway (scatter mean_wages mean_productivity if cluster_id == 1, mcolor(blue)) ///
        (scatter mean_wages mean_productivity if cluster_id == 2, mcolor(red)) ///
		(scatter mean_wages mean_productivity if cluster_id == 3, mcolor(green)), ///
		legend(label(1 "cluster_id == 1") label(2 "cluster_id == 2") label(3 "cluster_id == 3"))


