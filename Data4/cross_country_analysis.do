cd "`c(do_dir)'"

use merged_NA, clear

encode geo, gen(geo_num)
xtset geo_num year

// generating percentage changes
gen pct_change_wages = (D.hourly_wages / L.hourly_wages) * 100
label var pct_change_wages "Percentage change in hourly wages compared to previous year"
gen pct_change_productivity = (D.productivity_pp / L.productivity_pp) * 100
label var pct_change_productivity "Percentage change in productivity compared to previous year"
gen pct_change_productivity_1 = (D.productivity_1 / L.productivity_1) * 100
label var pct_change_productivity_1 "Lagged percentage change in productivity compared to previous year"
gen pct_change_gdp = (D.realgdp_pc / L.realgdp_pc) * 100
label var pct_change_gdp "Percentage change in GDP compared to previous year"

// Checking within-unit variation of variables, which should not be zero for
// fixed effect to work well. Excluding hh_index (=0.015)
xtsum hourly_wages hicp business_investment low_education middle_education ///
      high_education hh_index partime_contracts productivity_pp ///
	  productivity_1 productivity_2 realgdp_pc tradeunion_density ///
	  training_education_l4w unemployment pct_change_wages ///
	  pct_change_productivity pct_change_gdp

summarize //, detail
	  
// correlations with of some variables and their significance
pwcorr hourly_wages pct_change_wages hicp business_investment ///
       low_education middle_education high_education ///
	   productivity_pp productivity_1 pct_change_productivity ///
	   pct_change_productivity_1 realgdp_pc pct_change_gdp ///
	   tradeunion_density partime_contracts ///
	   unemployment training_education_l4w, sig
matrix corrmatrix = r(C)
heatplot corrmatrix, lower values(format(%9.1f)) legend(off)  ///
         title("Correlation Heatmap") xlabel(, angle(45))
// from the above, we can't include in the same model:
// - productivity and its lag, due to perfect multicollinearity 
// - low_education and middle_education, due to multicollinearity 
// - percentage change in productivity and percentage change in gdp, due to multicollinearity




// Percentage change models

// Just productivity and FE
reghdfe pct_change_wages pct_change_productivity_1, absorb(geo year) resid(residuals)
// Check for exogenouity, passed (correlation not significant under 0.05)
pwcorr pct_change_productivity_1 residuals, sig
drop residuals
// full data, robust standart errors to deal with heteroscedasticity (as in all below) - THE MAIN REGRESSION WE WERE TALKING 
reghdfe pct_change_wages pct_change_productivity_1 pct_change_gdp tradeunion_density hicp business_investment middle_education high_education partime_contracts realgdp_pc training_education_l4w unemployment, absorb(geo year) vce (robust)

// full data without hicp, unemployment and tradeunion_density to get more data
reghdfe pct_change_wages pct_change_productivity_1 business_investment middle_education high_education partime_contracts realgdp_pc training_education_l4w, absorb(geo year) vce (robust)
// removing some non significant variables and keeping significant
reghdfe pct_change_wages pct_change_productivity_1 tradeunion_density business_investment unemployment, absorb(geo year) vce (robust)

// Conclusion from above - coefficient for productivity change is quite stable (between 0.35 and 0.42), almost always significant, the same for unemployment. Other variables not so good




// Models with real values and productivity lag

// Just productivity and FE
reghdfe hourly_wages productivity_1, absorb(geo year) resid(residuals)
// Check for exogenouity, passed
pwcorr productivity_1 residuals, sig
// graph, but I am not sure it's a good idea to put it inside of report
twoway scatter residuals productivity_1, ///
xlabel(, grid) ylabel(, grid) ///
title("Correlation between Productivity_1 and Residuals") ///
xtitle("Productivity_1") ytitle("Residuals")

// full data, robust standart errors to deal with heteroscedasticity (as in all below)
reghdfe hourly_wages productivity_1 tradeunion_density hicp business_investment middle_education high_education partime_contracts realgdp_pc training_education_l4w unemployment, absorb(geo year) vce (robust)
// full data without hicp, unemployment and tradeunion_density to get more data
reghdfe hourly_wages productivity_1 business_investment middle_education high_education partime_contracts realgdp_pc training_education_l4w, absorb(geo year) vce (robust)
// removing some non significant variables and keeping significant
reghdfe hourly_wages productivity_1 unemployment tradeunion_density middle_education, absorb(geo year) vce (robust)
vif, uncentered

// Summary of above: estimate for productivity varies from 0.028 to 0.041, which is quite good; quite significant
// vif is a bit worse than in percentage change model, but not too much





// distribution of wages among countries

graph box hourly_wages, over(geo, label(angle(45)))
// from the graph above, it is quite visible division between countries with threshold of 20, so wanted to check their difference

// checking what if divide wages by threshold of 20
egen mean_wages = mean(hourly_wages), by(geo)
tabulate geo if mean_wages <= 20
tabulate geo if mean_wages > 20

// full data for <= 20
reghdfe pct_change_wages pct_change_productivity_1 pct_change_gdp tradeunion_density hicp business_investment middle_education high_education partime_contracts realgdp_pc training_education_l4w unemployment if mean_wages <= 20, absorb(geo year) vce (robust)

// full data for > 20
reghdfe pct_change_wages pct_change_productivity_1 pct_change_gdp tradeunion_density hicp business_investment middle_education high_education partime_contracts realgdp_pc training_education_l4w unemployment if mean_wages > 20, absorb(geo year) vce (robust)

// TODO discuss difference in coefficients and significance of the above...




// Random stuff

// some plots, TODO decide which we need and save 
scatter hourly_wages productivity_1
scatter pct_change_wages pct_change_productivity


twoway (scatter hourly_wages productivity_1 if tradeunion_density < 40, mcolor(blue)) ///
        (scatter hourly_wages productivity_1 if tradeunion_density >= 40, mcolor(red)), ///
        legend(label(1 "Trade Union Density < 40") label(2 "Trade Union Density ≥ 40")) ///
        title("Hourly Wages vs. Productivity", color(black)) ///
        xtitle("Productivity") ytitle("Hourly Wages")

// Charts of some countries over time
xtline hourly_wages if geo == "Italy" | geo == "France" | geo == "Germany" | geo == "Poland" | geo == "Netherlands", overlay
xtline productivity_1 if geo == "Italy" | geo == "France" | geo == "Germany" | geo == "Poland" | geo == "Netherlands", overlay


// Just an experiment trying to cluster countries based on productivity and wages
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

