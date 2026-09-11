#!/bin/bash

# Define the directory containing the files
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost"

# Loop through all files ending with .fastq.gz in the directory
for FILE in "$INPUT_DIR"/*R1.fastq; do
  # Extract the base name without the .gz extension
    NEW_NAME="${FILE}.gz"

  # Rename the file
  mv "$FILE" "$NEW_NAME"

  # Print the change
  echo "Renamed: $FILE -> $NEW_NAME"
done

# Loop through all files ending with .fastq.gz in the directory
for FILE in "$INPUT_DIR"/*R2.fastq; do
  # Extract the base name without the .gz extension
    NEW_NAME="${FILE}.gz"

  # Rename the file
  mv "$FILE" "$NEW_NAME"

  # Print the change
  echo "Renamed: $FILE -> $NEW_NAME"
done

echo "All files renamed successfully!"

