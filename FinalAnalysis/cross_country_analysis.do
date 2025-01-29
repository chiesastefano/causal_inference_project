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
gen pct_change_hicp = (D.hicp/L.hicp)*100
label var pct_change_hicp "Percentage change in HICP"
egen mean_wages = mean(hourly_wages), by(geo)

// Checking within-unit variation of variables, which should not be zero for
// fixed effect to work well. Excluding hh_index (=0.015)
xtsum hourly_wages hicp business_investment low_education middle_education ///
      high_education hh_index partime_contracts productivity_pp ///
	  productivity_1 productivity_2 realgdp_pc tradeunion_density ///
	  training_education_l4w unemployment pct_change_wages ///
	  pct_change_productivity pct_change_gdp

summarize
	  
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
graph export "Charts\Correlations.jpg", as(jpg) name("Graph") quality(100)
// from the above, we can't include in the same model:
// - productivity and its lag, due to perfect multicollinearity 
// - low_education and middle_education, due to multicollinearity 
// - percentage change in productivity and percentage change in gdp, due to multicollinearity

// distribution of wages among countries
graph box hourly_wages, over(geo, label(angle(45))) yline(20, lcolor(red) lwidth(medium))
graph export "Charts\Wages_distribuiton.jpg", as(jpg) name("Graph") quality(100)


// Percentage change model

// Just productivity and FE
reghdfe pct_change_wages pct_change_productivity_1, absorb(geo year) resid(residuals)
// Check for exogenouity, passed
pwcorr pct_change_productivity_1 residuals, sig
// plotting
twoway scatter residuals pct_change_productivity_1, ///
xlabel(, grid) ylabel(, grid) ytitle("Residuals")
drop residuals


// Regression with all uncorellated control variables and past percentage change of productivity
reghdfe pct_change_wages pct_change_productivity_1 pct_change_gdp tradeunion_density pct_change_hicp business_investment middle_education high_education partime_contracts training_education_l4w unemployment, absorb(geo year) vce (robust)	
vif, uncentered		


// Standardise data for PCA
foreach var in pct_change_gdp tradeunion_density pct_change_hicp business_investment middle_education high_education partime_contracts training_education_l4w unemployment {
    egen z_`var' = std(`var')
}
// Verify 
summarize z_*

// Run PCA on standardized variables
pca z_pct_change_gdp z_tradeunion_density z_pct_change_hicp z_business_investment z_middle_education z_high_education z_partime_contracts z_training_education_l4w z_unemployment

// Display scree plot to help decide number of components
screeplot

// Show eigenvalues
estat smc // 7 components

// Allow choosing number of components
pca z_pct_change_gdp z_tradeunion_density z_pct_change_hicp z_business_investment z_middle_education z_high_education z_partime_contracts z_training_education_l4w z_unemployment, components(7)

// Get component loadings
estat loadings

// Predict component scores
predict pc1 pc2 pc3 pc4 pc5 pc6 pc7

// Rotate factors for easier interpretation
rotate, varimax

// regression with PCA
reghdfe pct_change_wages pct_change_productivity_1 pc1 pc2 pc3 pc4 pc5 pc6 pc7, absorb(geo year) vce (robust)
outreg2 using regression_pca_results.tex, replace tex label	
vif, uncentered		


// Robustness checks
reghdfe pct_change_wages pct_change_productivity_1 pc1 pc2 pc3 pc4 pc5 pc6 pc7 if mean_wages <= 20, absorb(geo year) vce (robust)
outreg2 using regression_grp1.tex, replace tex label	
vif, uncentered

reghdfe pct_change_wages pct_change_productivity_1 pc1 pc2 pc3 pc4 pc5 pc6 pc7 if mean_wages > 20, absorb(geo year) vce (robust)
outreg2 using regression_grp2.tex, replace tex label	
vif, uncentered



