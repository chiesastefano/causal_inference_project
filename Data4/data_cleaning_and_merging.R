setwd("C:\\Users\\maidi\\OneDrive\\Desktop\\OneDrive - Università degli Studi di Milano\\causal_inference_project\\Data4")

library(readxl)
  library(data.table) # or library(readr)
  
  # Get the list of all files in the directory
  files <- list.files(pattern = "\\.(csv|xlsx)$")
  
  # Loop through each file and create separate data frames
  for (file in files) {
    # Generate a valid variable name for the data frame
    df_name <- gsub("\\.|-|\\s", "_", tools::file_path_sans_ext(file))
    
    if (grepl("\\.csv$", file)) {
      # Read CSV files
      assign(df_name, fread(file)) # Use read_csv(file) if using `readr`
    } else if (grepl("\\.xlsx$", file)) {
      # Read XLSX files
      assign(df_name, read_excel(file))
    }
  }
  
  # Check the created data frames
  ls()
  
  library(dplyr)
  
  # Rename specific columns
  tradeunion_density <- tradeunion_density %>%
    rename(
      geo = `Reference area`,
    )
  
  hh_index <- hh_index %>%
    rename(
      TIME_PERIOD = Year,
      geo = "Country Name"
    )
  
  
  # List all data frames in the environment
  dfs <- ls()
  
  # Loop through each object and keep only the specified columns, and rename 'OBS_VALUE' column
  for (df_name in dfs) {
    # Check if the object is a data frame
    if (is.data.frame(get(df_name))) {
      # Use tryCatch to handle potential errors
      tryCatch({
        # Get the data frame
        df <- get(df_name)
        
        # Keep only the specified columns: 'geo', 'OBS_VALUE', and 'TIME_PERIOD'
        df <- df[, c("geo", "OBS_VALUE", "TIME_PERIOD"), drop = FALSE]
        
        # Rename 'OBS_VALUE' column to the name of the data frame
        colnames(df)[colnames(df) == "OBS_VALUE"] <- df_name
        
        # Assign the modified data frame back to the original name
        assign(df_name, df)
        
      }, error = function(e) {
        # Print the name of the data frame that caused the error
        cat("Error in data frame:", df_name, "\n")
        cat("Error message:", conditionMessage(e), "\n")
      })
    }
  }
  
  # Get the list of data frame names in the environment
  dfs <- ls()
  
  # Initialize an empty list to store the NA counts for each data frame
  na_counts <- list()
  
  # Loop through each object in the environment
  for (df_name in dfs) {
    # Check if the object is a data frame
    if (is.data.frame(get(df_name))) {
      # Get the data frame
      df <- get(df_name)
      
      # Count the number of NA values in each column of the data frame
      na_count <- colSums(is.na(df))
      
      # Store the result in the list with the data frame's name as the key
      na_counts[[df_name]] <- na_count
    }
  }
  
  
  productivity_pp <- productivity_pp %>%
    arrange(geo, TIME_PERIOD) %>%
    group_by(geo) %>%
    mutate(
      productivity_1 = lag(productivity_pp, n = 1),
      productivity_2 = lag(productivity_pp, n = 2)
    ) %>%
    ungroup()
  
  
  # Function to merge and adjust wages
  adjust_wages_with_hicp <- function(wages_df, hicp_df) {
    # Merge dataframes on geo and TIME_PERIOD
    merged_df <- wages_df %>%
      left_join(hicp_df, by = c("geo", "TIME_PERIOD"))
    
    # Calculate reference HICP (2015 base)
    ref_hicp <- merged_df %>%
      filter(TIME_PERIOD == "2015") %>%
      pull(hicp) %>%
      first()
    
    # Adjust wages
    adjusted_df <- merged_df %>%
      mutate(
        adjusted_wages = wages_per_h_worked * (ref_hicp / hicp),
        real_wage_change_pct = ((adjusted_wages - wages_per_h_worked) / wages_per_h_worked) * 100
      )
    
    return(adjusted_df)
  }
  
  # Usage example
  wages_per_h_worked <- adjust_wages_with_hicp(wages_per_h_worked, hicp)
  
  wages_per_h_worked <- wages_per_h_worked %>% select(-c(hicp, wages_per_h_worked, real_wage_change_pct))
  
  # List of dataframes to join
  df_list <- list(wages_per_h_worked, hicp, business_investment, low_education, middle_education, high_education,
                  hh_index,partime_contracts, productivity_pp, realgdp_pc, 
                  tradeunion_density, training_education_l4w, unemployment)
  
  # Perform the left join
  result_df <- wages_per_h_worked
  
  # Iteratively join each dataframe
  for (df in df_list) {
    result_df <- merge(result_df, df, by = c("geo", "TIME_PERIOD"), all.x = TRUE)
  }
  
  
  # Count NA values for each column in the resulting dataframe
  na_count <- sapply(result_df, function(x) sum(is.na(x)))

  # Print the NA count
  print(na_count)
  
  result_df_clean <- na.omit(result_df)
  unique_geo_count <- n_distinct(result_df_clean$geo)
  unique_geo_count
  
  result_df_clean <- result_df_clean %>% select(-adjusted_wages.x)
  result_df_clean <- result_df_clean %>%
    rename(
      hourly_wages = adjusted_wages.y,
      year = TIME_PERIOD
    )
  
  
  
  
  write.csv(result_df_clean, "merged1.csv", row.names = FALSE)
  
  # Save as Stata format (requires haven package)
  library(haven)
  write_dta(result_df_clean, "merged1.dta")