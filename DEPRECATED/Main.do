// TODO change to valid path
local productivity_path = "Data\productivity_indicators_by_sector.xlsx"
local subsidies_path = "Data\subsidies_on_production_by_industry_seasonaly_and_inflaction_adjusted.xlsx"


import excel "`productivity_path'", sheet("A") firstrow clear
// code for renaming variables from a, b, c into year2014, year2015, etc.
foreach var of varlist _all {
    local lbl : variable label `var' // Extract the variable's label
    if "`lbl'" != "" & "`lbl'" != "Economic Activities" { // Check if the variable has a label
		destring `var', replace
		recast double `var'
        local newname = "year" + substr(strtoname("`lbl'"), 2, 4) // Ensure the label is a valid variable name
        rename `var' `newname' // Rename the variable
    }
}
// making a dataset with only 3 columns and saving it
reshape long year, i(EconomicActivities) j(Year)
rename year Productivity
save "productivity_indicators_by_sector.dta", replace



import excel "`subsidies_path'", sheet("A") firstrow clear
// code for naming a, b, c into year2014, year2015, etc.
foreach var of varlist _all {
    local lbl : variable label `var' // Extract the variable's label
    if "`lbl'" != "" & "`lbl'" != "Economic Activities" { // Check if the variable has a label
		destring `var', replace
		recast double `var'
        local newname = "year" + substr(strtoname("`lbl'"), 2, 4) // Ensure the label is a valid variable name
        rename `var' `newname' // Rename the variable
    }
}
// making a dataset with only 3 columns and saving it
reshape long year, i(EconomicActivities) j(Year)
rename year Subsidies
save "subsidies_on_production_by_industry_seasonaly_and_inflaction_adjusted.dta", replace




// merging productivity and subsidies into one dataset
use "productivity_indicators_by_sector.dta", clear
merge 1:1 EconomicActivities Year using "subsidies_on_production_by_industry_seasonaly_and_inflaction_adjusted.dta"
save "merged_subsidies_productivity.dta", replace

// just simple regression with Productivity as dependent variable
reg Productivity Subsidies if EconomicActivities == "Construction  "



// reading wages data (in progress)
/*
import excel "C:\Users\LENOVO\CausalInference\MainProject\causal_inference_project\Data\hourly_wages_by_employees_class_inflation_adjusted.xlsx", sheet("A") firstrow clear
* Convert string variables to numeric if needed
// TODO change sex to 1/2
foreach var of varlist _all {
    local lbl : variable label `var' // Extract the variable's label
    if "`lbl'" != "Sex" & "`lbl'" != "Time" { // Check if the variable has a label
		destring `var', replace
		recast double `var'
    }
}
*/
// TODO reshape long



//labour cost
import excel "Data\labour_cost_per_full_time_equivalent_unit_(base 2015)_inflation_adjusted.xlsx", sheet("A") firstrow clear
// code for renaming variables from a, b, c into year2014, year2015, etc.
foreach var of varlist _all {
    local lbl : variable label `var' // Extract the variable's label
    if "`lbl'" != "" & "`lbl'" != "Economic Activities" { // Check if the variable has a label
		destring `var', replace
		recast double `var'
        local newname = "year" + substr(strtoname("`lbl'"), 2, 4) // Ensure the label is a valid variable name
        rename `var' `newname' // Rename the variable
    }
}
// making a dataset with only 3 columns and saving it
reshape long year, i(EconomicActivities) j(Year)
rename year Labour_Cost
save "labour_cost.dta", replace


// merging productivity and labour_cost into one dataset
use "productivity_indicators_by_sector.dta", clear
merge 1:1 EconomicActivities Year using "labour_cost.dta"
save "merged_labour_cost_productivity.dta", replace

// just simple regression with Productivity as dependent variable
reg Productivity Labour_Cost 
