# Corrected file paths using double backslashes (\\)
t_wages <- read.csv("C:\\Users\\maidi\\OneDrive\\Desktop\\OneDrive - Università degli Studi di Milano\\causal_inference_project\\Data3\\wages_pps.csv")
t_productivity <- read.csv("C:\\Users\\maidi\\OneDrive\\Desktop\\OneDrive - Università degli Studi di Milano\\causal_inference_project\\Data3\\productivity_per_person.csv")
t_economic_values <- read.csv("C:\\Users\\maidi\\OneDrive\\Desktop\\OneDrive - Università degli Studi di Milano\\causal_inference_project\\Data3\\economic_values_per_industry.csv")
t_bankrupcy_and_registration_index <- read.csv("C:\\Users\\maidi\\OneDrive\\Desktop\\OneDrive - Università degli Studi di Milano\\causal_inference_project\\Data3\\bankrupcy_and_registration_index_percentage_change.csv")

# Display the first few rows of t_wages
head(t_wages)
t_wages_2 <- subset(t_wages, select = -c(DATAFLOW, LAST.UPDATE, freq, currency, unit, sizeclas, OBS_FLAG))

names(t_wages_2)[names(t_wages_2) == "OBS_VALUE"] <- "Wages and salaries"
names(t_wages_2)[names(t_wages_2) == "TIME_PERIOD"] <- "Year"
names(t_wages_2)[names(t_wages_2) == "geo"] <- "Country"
t_wages_2 <- subset(t_wages_2, select = -c(lcstruct))



t_productivity_2 <- subset(t_productivity, select = c(nace_r2, geo, TIME_PERIOD, OBS_VALUE)) 
names(t_productivity_2)[names(t_productivity_2) == "OBS_VALUE"] <- "Real labour productivity per person"
names(t_productivity_2)[names(t_productivity_2) == "TIME_PERIOD"] <- "Year"
names(t_productivity_2)[names(t_productivity_2) == "geo"] <- "Country"


names(t_bankrupcy_and_registration_index)
t_bankrupcy_and_registration_index_2 <- subset(t_bankrupcy_and_registration_index, select = c(nace_r2, geo, TIME_PERIOD, OBS_VALUE, indic_bt))

names(t_bankrupcy_and_registration_index_2)[names(t_bankrupcy_and_registration_index_2) == "TIME_PERIOD"] <- "Year"
names(t_bankrupcy_and_registration_index_2)[names(t_bankrupcy_and_registration_index_2) == "geo"] <- "Country"


# Filter rows with "Bankruptcy declarations"
t_bankruptcy <- subset(t_bankrupcy_and_registration_index_2, indic_bt == "Bankruptcy declarations")

# Filter rows with "Registrations"
t_registrations <- subset(t_bankrupcy_and_registration_index_2, indic_bt == "Registrations")


names(t_bankruptcy)[names(t_bankruptcy) == "OBS_VALUE"] <- "Bankruptcy declarations Index"
t_bankruptcy <- subset(t_bankruptcy, select = -c(indic_bt))


names(t_registrations)[names(t_registrations) == "OBS_VALUE"] <- "Registrations"
t_registrations <- subset(t_registrations, select = -c(indic_bt))




# Subset the relevant columns
t_economic_values <- subset(t_economic_values, select = c(nace_r2, na_item, geo, TIME_PERIOD, OBS_VALUE))
names(t_economic_values)[names(t_economic_values) == "geo"] <- "Country"
names(t_economic_values)[names(t_economic_values) == "TIME_PERIOD"] <- "Year"
# Get unique values in the 'na_item' column
unique_values <- unique(t_economic_values$na_item)

# Create separate tables for each unique 'na_item' value
for (value in unique_values) {
  # Filter the rows where 'na_item' equals the current value
  table <- subset(t_economic_values, na_item == value)
  
  # Rename the 'OBS_VALUE' column to the current 'na_item' value
  colnames(table)[colnames(table) == "OBS_VALUE"] <- value
  
  # Drop the 'na_item' column
  table$na_item <- NULL
  
  # Assign the table to a new variable dynamically
  assign(paste("t_", value, sep = ""), table)
}

# Now you have separate tables like t_GDP, t_Unemployment, etc.
list_of_tables[["value1"]]



library(dplyr)
# Perform the full join across all tables
combined_data <- `t_Consumption of fixed capital` %>%
  full_join(t_Output, by = c("Country", "Year", "nace_r2")) %>%
  full_join(`t_Intermediate consumption`, by = c("Country", "Year", "nace_r2")) %>%
  full_join(t_wages_2, by = c("Country", "Year", "nace_r2")) %>%
  full_join(t_productivity_2, by = c("Country", "Year", "nace_r2")) %>%
  full_join(t_bankruptcy, by = c("Country", "Year", "nace_r2")) %>%
  full_join(t_registrations, by = c("Country", "Year", "nace_r2"))

# View the combined data
head(combined_data)


install.packages("haven")  # Run this if you haven't installed the package yet
library(haven)  # Load the package
# Rename the problematic column
names(combined_data)[colnames(combined_data) == "Real labour productivity per person"] <- "real_labour_productivity"
names(combined_data)[colnames(combined_data) == "Consumption of fixed capital"] <- "consumption_of_capital"
names(combined_data)[colnames(combined_data) == "Intermediate consumption"] <- "intermediate_consumption"
names(combined_data)[colnames(combined_data) == "Wages and salaries"] <- "wages_and_salaries"
names(combined_data)[colnames(combined_data) == "Bankruptcy declarations Index"] <- "bankruptcy_declarations_index"
write.csv(combined_data, "C:\\Users\\maidi\\OneDrive\\Desktop\\OneDrive - Università degli Studi di Milano\\causal_inference_project\\Data3\\combined_data.csv", row.names = FALSE)
write_dta(combined_data, "C:\\Users\\maidi\\OneDrive\\Desktop\\OneDrive - Università degli Studi di Milano\\causal_inference_project\\Data3\\combined_data.dta")

