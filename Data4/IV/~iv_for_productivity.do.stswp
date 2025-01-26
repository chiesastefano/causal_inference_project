cd "`c(do_dir)'"

import excel "RD_percent_of_GDP.xlsx", sheet("Sheet 1") firstrow clear
reshape long y, i(geo) j(year)
rename y RnD
label var RnD "RnD expendituure as percentage of GDP"
save "RD_percent_of_GDP.dta", replace


import excel "patent_application_per_million_inhabitants.xlsx", sheet("Sheet 1") firstrow clear
reshape long y, i(geo) j(year)
rename y patents
label var patents "patent_application_per_million_inhabitants"
save "patent_application_per_million_inhabitants.dta", replace



use "merged_NA.dta", clear

merge 1:1 geo year using "RD_percent_of_GDP.dta"
//drop if _merge == 2
drop _merge

merge 1:1 geo year using "patent_application_per_million_inhabitants.dta"
//drop if _merge == 2
drop _merge

merge 1:1 geo year using "globalization_index.dta"
// TODO rename chechia and slovakia in globalization_index
drop if _merge == 2
rename KOFGI globalization
//drop _merge


encode geo, generate(geo_num)
xtset geo_num year

generate globalization_1 = L.globalization
generate globalization_2 = L.globalization
generate globalization_3 = L2.globalization
generate Rnd_1 = L.RnD
generate Rnd_2 = L2.RnD
generate Rnd_3 = L3.RnD
generate patents_1 = L.patents
generate patents_2 = L2.patents
generate patents_3 = L3.patents


// variables are more correlated with wages than with productivity
pwcorr hourly_wages productivity_pp ///
	   RnD Rnd_1 Rnd_2 Rnd_3 ///
	   patents patents_1 patents_2 patents_3 ///
	   globalization globalization_1 globalization_2 globalization_3, sig
matrix corrmatrix = r(C)
heatplot corrmatrix, lower values(format(%9.2f)) legend(off)  ///
         title("Correlation Heatmap") xlabel(, angle(45))
