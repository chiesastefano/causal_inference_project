// Change to root 
global base_dir "C:\Users\LENOVO\CausalInference\MainProject\causal_inference_project"
cd "$base_dir"

local year_start 2014
local year_end 2021

// Working with Luiss data here

// choosing only Italy and suitable years from the big dataset
use "$base_dir/RawDataAmendmends/LuissData/national_accounts.dta", clear
keep if geo_code == "IT"
keep if year >= `year_start' & year <= `year_end'
// Total is removed here
drop if strlen(nace_r2_code) > 1
save "$base_dir/RawDataAmendmends/LuissData/national_accounts_amended.dta", replace


use "$base_dir/RawDataAmendmends/LuissData/capital_accounts.dta", clear
keep if geo_code == "IT"
keep if year >= `year_start' & year <= `year_end'
// Total is removed here
drop if strlen(nace_r2_code) > 1
save "$base_dir/RawDataAmendmends/LuissData/capital_accounts_amended.dta", replace


use "$base_dir/RawDataAmendmends/LuissData/intangibles_analytical.dta", clear
keep if geo_code == "IT"
keep if year >= `year_start' & year <= `year_end'
// Total is removed here
drop if strlen(nace_r2_code) > 1
save "$base_dir/RawDataAmendmends/LuissData/intangibles_analytical_amended.dta", replace


use "$base_dir/RawDataAmendmends/LuissData/national_accounts_amended.dta", clear
merge 1:1 nace_r2_code year using "$base_dir/RawDataAmendmends/LuissData/capital_accounts_amended.dta"
drop _merge
merge 1:1 nace_r2_code year using "$base_dir/RawDataAmendmends/LuissData/intangibles_analytical_amended.dta"
drop _merge

keep nace_r2_code nace_r2_name year H_EMPE VA_PI Ip_Brand Ip_Train Ip_Tang

rename year Year
rename nace_r2_code code
rename nace_r2_name EconomicActivities

label var H_EMPE "Total hours worked by employees, th."
label var VA_PI "GVA, price indexes (2020)"
label var Ip_Brand "Brand, price index 2020 = 100"
label var Ip_Train "Training, price index 2020 = 100"
label var Ip_Tang "Total tangible assets, price index 2020 = 100"

save "$base_dir/RawDataAmendmends/LuissData/merged_capital_national_intangibles_amended.dta", replace




// Working with other data here (ISTAT in particular)


// reading wages data
import excel "$base_dir/RawDataAmendmends/OtherData/hourly_wages_by_employees_class.xlsx", sheet("A 1 IT HOUWAG_ENTEMP_MED_MI TO") firstrow clear
reshape long y, i(code TypeofWorker) j(Year)
rename y Wages
label var Wages "Hourly wage"
save "$base_dir/RawDataAmendmends/OtherData/wages_by_class.dta", replace


// reading taxes data
import excel "$base_dir/RawDataAmendmends/OtherData/taxes_on_production_by_industry.xlsx", sheet("A IT D29_D_W2_S1 V N 2024M9") firstrow clear
reshape long y, i(EconomicActivities) j(Year)
rename y Taxes
label var Taxes "Taxes per industry"
save "$base_dir/RawDataAmendmends/OtherData/taxes.dta", replace


// reading subsidies data
import excel "$base_dir/RawDataAmendmends/OtherData/subsidies_on_production_by_industry.xlsx", sheet("A IT D39_C_W2_S1 V N 2024M9") firstrow clear
reshape long y, i(EconomicActivities) j(Year)
rename y Subsidies
label var Subsidies "Subsidies per industry"
save "$base_dir/RawDataAmendmends/OtherData/subsidies.dta", replace


// Total factor productivity
import excel "$base_dir/RawDataAmendmends/OtherData/TFP.xlsx", sheet("A IT TFPVA_I_B2020 S1_X_S13 20") firstrow clear
reshape long y, i(EconomicActivities) j(Year)
rename y Productivity
label var Productivity "Total factor productivity"
save "$base_dir/RawDataAmendmends/OtherData/productivity.dta", replace

// Consumer Prices Index
import excel "$base_dir/RawDataAmendmends/OtherData/italy_cpi_2020.xlsx", sheet("Annual") firstrow clear
label var CPI "Consumer Price Index"
save "$base_dir/RawDataAmendmends/OtherData/cpi.dta", replace


// merging data, due to worker type there will duplicates in columns, so need to be careful

use "$base_dir/RawDataAmendmends/OtherData/wages_by_class.dta", clear
//keep if TypeofWorker == "Total  "

merge m:1 code Year using "$base_dir/RawDataAmendmends/OtherData/taxes.dta"
rename _merge merge_taxes_1

merge m:1 code Year using "$base_dir/RawDataAmendmends/OtherData/subsidies.dta"
rename _merge merge_subsidies_2

merge m:1 code Year using "$base_dir/RawDataAmendmends/OtherData/productivity.dta"
rename _merge merge_productivity_3

merge m:1 code Year using "$base_dir/RawDataAmendmends/LuissData/merged_capital_national_intangibles_amended.dta"
rename _merge merge_capital_n_co_4

merge m:1 Year using "$base_dir/RawDataAmendmends/OtherData/cpi.dta"
rename _merge merge_cpi_5

save "$base_dir/all_data.dta", replace