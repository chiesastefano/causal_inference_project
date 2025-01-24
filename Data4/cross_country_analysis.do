cd "`c(do_dir)'"

use merged_NA, clear

summarize //, detail

// some plots, TODO decide which we need and save 
histogram hourly_wages, bin(50)
graph box hourly_wages
scatter hourly_wages productivity_1

// correlation with of some variables and their significance, TODO add more
pwcorr hourly_wages productivity_1 tradeunion_density, sig

// some preliminary regression
reghdfe hourly_wages tradeunion_density productivity_1, absorb(geo)