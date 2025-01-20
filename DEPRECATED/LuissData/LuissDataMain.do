cd "C:\Users\LENOVO\CausalInference\MainProject\causal_inference_project\LuissData"

//theoretically can use more
local year_start 2014
local year_end 2021

use national_accounts, clear
keep if geo_code == "IT"
keep if year >= `year_start' & year <= `year_end'
// Total is removed here, but we may need it
drop if strlen(nace_r2_code) > 1
save "national_accounts_amended.dta", replace


use capital_accounts, clear
keep if geo_code == "IT"
keep if year >= `year_start' & year <= `year_end'
// Total is removed here, but we may need it
drop if strlen(nace_r2_code) > 1
save "capital_accounts_amended.dta", replace


use intangibles_analytical, clear
keep if geo_code == "IT"
keep if year >= `year_start' & year <= `year_end'
// Total is removed here, but we may need it
drop if strlen(nace_r2_code) > 1
save "intangibles_analytical_amended.dta", replace


use "national_accounts_amended.dta", clear
merge 1:1 nace_r2_code year using "capital_accounts_amended.dta"
drop _merge
merge 1:1 nace_r2_code year using "intangibles_analytical_amended.dta"
drop _merge

keep nace_r2_code nace_r2_name year H_EMPE VA_PI Ip_Brand Ip_Train Ip_Tang

save "merged_capital_national_intangibles_amended.dta", replace

correlate H_EMPE VA_PI Ip_Brand Ip_Train Ip_Tang
matrix corrmatrix = r(C)
heatplot corrmatrix


