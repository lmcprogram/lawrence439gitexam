#!/usr/bin/env bash

# The shell script processes a list of CSV files containing bird observation data, filtering out 
# species that were observed exactly once, either overall or within a particular year, and outputs 
# the results into two separate CSV files with clear headers and formatted data. The script is 
# designed to be user-friendly, allowing colleagues at the Fish and Wildlife Service to simply input 
# the desired files on the command line and receive easily readable output for further analysis.


# usage: bash find_rare_birds filename1.csv filename2.csv ...

# Validation Techniques:
# I used 2 test files.  (test.csv and test2.csv)
# In test.csv there are all unique birds codes except for purfin.
# purfin appears 3 times in this file, with each line having a different year.
# So, in rare_birds_per_datasets.csv, purfin should not appear. (it does not appear)
# However in rare_birds_per_year.csv, purfin should appear 3 times, or once per year. (it does appear 3 times)
# amegfi appears once with the same year in test.csv and test2.csv, so it should not print in either rare_birds_per_datasets or rare_birds_per_year (it does not appear)
# normoc appears multiple times, with different (sometimes the same) years, so it only should print in rare_birds_per_year (it does.)
# As well as that, normoc only appears when the years are unique. (which is should.)
# For any future users, if you would to confirm this validation run the following command:
# usage: bash find_rare_birds.sh test.csv test2.csv


# Indices of needed columns used for testing and future use.
#_____________________
# how_many_index=13
species_name_index=12
year_index=10
# loc_id_index=1
# lat_index=2
# long_index=3
# state_index=4


# This part of the script answers part 1 of the guideline, getting all the species observed once among all observation files input,
# getting the species code's equivalent common and scientific name along with year observed and location info and outputing it to a file
# known as "rare_birds_per_datasets.csv" that can be used for future graphing and data manpulation in Excel or R.

output_file="rare_birds_per_datasets.csv"

> "$output_file"  # Clear the output file before writing

# Extract and write the desired columns from the header to print in the rare_species.csv
# While not instructed to, I included the "How_Many" column as it helps quantify each rare species's viewing.
awk -F',' 'NR==1 {print $12 "," $13 "," $10 "," $1 "," $2 "," $3 "," $4 ",Scientific_Name,Common_Name"}' "$1" > "$output_file"

# Process each file using a wildcard for multiple file inputs
for file in "$@"; do
  # Get all unique species codes from all the files
  all_species_codes=$(cut -d',' -f"$species_name_index" "$@" | tail -n +2 | sort -u)

  # Count occurrences of each species code from all unique codes
  for species_code in $all_species_codes; do
    # Check if there is only 1 appearance of that species in the csv files
    if [[ $(grep -i -o "$species_code" "$@" | wc -l) -eq 1 ]]; then
        # Gets the scientific name and the common name based on the species code from the bird-info shared document and stores it in the "bird_names" varible
        # we are getting column 4 and 5, only printing the first set of info for the same code in edge cases (head -n 1), 
        # sorting them, removing duplicates with 'uniq'
        bird_names=$(grep -i "$species_code" /mnt/homes4celsrs/shared/439539/birds/bird-info | cut -d',' -f4,5 | sort | uniq | head -n 1)        
        # Send the bird species with only 1 appearance and all its requested data to output file (rare_birds_per_datasets.csv)
        grep -i "$species_code" "$file" | awk -F',' -v bird_names="$bird_names" '{print $12","$13","$10","$1","$2","$3","$4","bird_names}' >> $output_file
        fi
  done
done


# This part of the script answers part 2 of the guideline, getting all the species observed once among each year of the observation files input,
# getting the species code's equivalent common and scientific name along with year observed and location info and outputing it to a file
# known as "rare_birds_per_year.csv" that can be used for future graphing and data manpulation in Excel or R.



output_file="rare_birds_per_year.csv"

> "$output_file"  # Clear the output file before writing

# Extract and write the desired columns from the header to print in the rare_species.csv
# Including "How_Many" column for quantifying occurrences
awk -F',' 'NR==1 {print $12 "," $13 "," $10 "," $1 "," $2 "," $3 "," $4 ",Scientific_Name,Common_Name"}' "$1" > "$output_file"

# Process each file using a wildcard for multiple file inputs
for file in "$@"; do
  # Get all unique species codes from the current file
  all_species_codes=$(cut -d',' -f"$species_name_index" "$file" | tail -n +2 | sort -u)
  
  # Get all unique years from the current file
  all_years=$(cut -d',' -f"$year_index" "$file" | tail -n +2 | sort -u)

  # Loop through all the years in the current file
  for year in $all_years; do
  
    # Process each species code for the current year
    for species_code in $all_species_codes; do
    
      # Filter the data for the current year and species code in all the file
      occurrences=$(grep -i "$species_code" "$@" | grep -w "$year" | wc -l)
      
      # Check if this species appears exactly once in the current year
      if [[ $occurrences -eq 1 ]]; then
      
        # Get the scientific name and the common name based on the species code
        bird_names=$(grep -i "$species_code" /mnt/homes4celsrs/shared/439539/birds/bird-info | cut -d',' -f4,5 | sort | uniq | head -n 1)
        
        # Send the bird species with only 1 appearance in the current year to the output file
        grep -i "$species_code" "$file" | grep -w "$year" | awk -F',' -v bird_names="$bird_names" '{print $12","$13","$10","$1","$2","$3","$4","bird_names}' >> "$output_file"
      fi
    done
  done
done

