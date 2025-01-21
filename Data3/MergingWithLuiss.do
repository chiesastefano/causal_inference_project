// To change to yours
global base_dir "PATH"
cd "$base_dir"

use "$base_dir\Data3\Luiss\national_accounts.dta", clear

merge 1:1 year geo_name geo_code nace_r2_name nace_r2_code using "$base_dir\Data3\Luiss\capital_accounts.dta"
drop _merge
merge 1:1 year geo_name geo_code nace_r2_name nace_r2_code using "$base_dir\Data3\Luiss\intangibles_analytical.dta"
drop _merge

// leaving only main industry categories
drop if strlen(nace_r2_code) > 1
keep nace_r2_name geo_name year H_EMPE VA_PI Ip_Brand Ip_Train Ip_Tang

label var H_EMPE "Total hours worked by employees, th."
label var VA_PI "GVA, price indexes (2020)"
label var Ip_Brand "Brand, price index 2020 = 100"
label var Ip_Train "Training, price index 2020 = 100"
label var Ip_Tang "Total tangible assets, price index 2020 = 100"

rename year Year
rename geo_name Country
rename nace_r2_name nace_r2

merge m:m Year Country nace_r2 using "$base_dir\Data3\combined_data.dta"
rename _merge merge_eurostat_luiss

save "$base_dir\Data3\combined_luiss_eurostat.dta", replace
