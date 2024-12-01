# The script takes two optional arguments:
# The folder X where to search the files, default: current folder
# A number of lines N, default: 0

#TODO: Fix indentation

# We first check the number of arguments is correct. If it is, try to accommodate them in the correct variable
if [[ $# -gt 2 ]] # If more than two arguments are given, exit the program
then
  echo "The number of arguments passed is greater than expected"
  exit 1
fi

if [[ $# -eq 0 ]] # If no arguments are given, use the default values
then
    N=0
    FOLDER=.
fi

if [[ $# -eq 1 ]] # If one argument is given, check first whether it is numeric
then
  if [[ $1 =~ ^-?[0-9]+$ ]] # If argument is numeric, use it as N and set FOLDER to current folder
  then
    N=$1
    FOLDER=.
  else # If the argument is not numeric, use it as FOLDER and set N to 0
    FOLDER=$1
    N=0
  fi
fi

if [[ $# -eq 2 ]] # If two arguments are given, check whether one is numeric and assign it to N
then
  if [[ $1 =~ ^-?[0-9]+$ ]] # Check whether the first argument is a number
  then
    N=$1
    FOLDER=$2
  else
    N=$2
    FOLDER=$1
  fi
fi

echo "FOLDER: $FOLDER"
echo "N: $N"

# Now, check if all arguments are correct
if [[ -d $FOLDER ]] # With the option -d, we check if the given path exists AND is a directory
then
  if [[ -r $FOLDER ]] # Check if we have permission to read the directory
  then
    if [[ ! -w $FOLDER ]] # Check if we have permission to write in the directory, since this is necessary to compute
    # the number of unique fastaIDs
    then
    	echo "The folder does not have write permission, and this is necessary for further steps"
    	exit 1
    fi
  else
    echo "The folder specified does not have read permission"
    exit 1
  fi
else
  echo "The given path is not a directory or the directory does not exist"
  exit 1
fi

if [[ $N =~ ^[-] ]]
then
  echo "The number of lines provided is not valid"
  exit 1
fi

# Now that all arguments are valid, we proceed to generate the report
# We first compute the number of fa/fasta files in the given folder
FASTA_FILES=$(find $FOLDER -type f -name "*.fa" -or -name "*.fasta")
N_FILES=$(echo "$FASTA_FILES" | wc -l)
echo "##################### REPORT #####################"
echo "There are $N_FILES fa/fasta files in the provided folder"

if [[ $N_FILES -eq 0 ]]
then
  echo "There is nothing to process"
  exit 0
fi

# Determine how many unique fastaIDs the fa/files of the given folder contain in total
# Step 1: create fasta_ids file in the given folder (using the touch command). We will store
# all fasta IDs here for further processing
# Step 2: sort the fasta IDs
# Step 3: get the unique ones
echo "FOLDER: $FOLDER"
touch $FOLDER/fasta_ids
find $FOLDER -type f -name "*.fa" -or -name "*.fasta" | while read i
  do
    grep ">" $i | sed 's/>//' | awk '{print $1}' >> $FOLDER/fasta_ids
  done

# Print the number of unique fastaIDs
N_UNIQUE_IDS=$(sort $FOLDER/fasta_ids | uniq | wc -l)
echo "There are $N_UNIQUE_IDS unique fasta IDs in the given folder"
echo "-------------- REPORT PER FILE --------------"

# Process each file to:
# 1. Print a header with the file name and
#    indicate whether the file is a symlink, the number of sequences the file contains,
#    and the total sequence length
# 2. Show the full content if the file has 2N lines or less, otherwise show the first N lines
#    then ... and the last N lines
find $FOLDER -type f -name "*.fa" -or -name "*.fasta" | while read i
  do
    # To only show the file name instead of the path, remove everything up to and including the last '/'
    FILENAME=$(echo $i | sed "s/.*\///g")

    echo "######## The file name is $FILENAME ########"

    # Indicate whether the file is a symlink
    if [[ -h $i ]]
      then
    	echo "The file is a symbolic link."
    else
    	echo "Not a symbolic link"
    fi

    # Use the exit code of grep to decide whether to process the file further.
    # For example, grep cannot process files starting with '._'
    # If FILENAME does not start with a letter, print the message:
    # 'File cannot be processed because its filename is not as expected'
    # and go to the next iteration.
    # Use -q to not print the matches
    if echo $FILENAME | grep -q -v "^[a-zA-Z]"
    then
      echo "File cannot be processed because its filename is not as expected"
      continue
    fi

    #TODO: How to print the header including the file name and whether the file contains nucleotides or amino acids?
    #TODO: remove the sed repetition in lines 73 and 111
    SEQUENCES=$(sed '/>/! s/-//g; s/ //g' $i | grep -v '>' | tr -d '\n')
    if echo $SEQUENCES | grep -q "[defhiklmpqrsvwxyDEFHIKLMPQRSVWXY]"
    then
      echo "Amino acid ########"
    else
        echo "Nucleotide ########"
    fi

		# Compute total number of sequences per file
		# Recall: use ^ to grep ">" at the beginning of a string
		NSEQ=$(grep "^>" $i | wc -l)
		echo "The number of sequences is:  $NSEQ"

		# Compute the total number of amino acids or nucleotides of ALL sequences in the file

		# We first get rid of '-, and then we get rid of white spaces in lines that are not the header.
		# Then we pass all lines except the headers to tr to get rid of new line characters
		# tr -d '\n' removes new lines, wc -m counts characters in a file
		SEQ_LENGTH=$(sed '/>/! s/-//g; s/ //g' $i | grep -v '>' | tr -d '\n' | wc -m)
		echo "The total sequence length of the file is: $SEQ_LENGTH"

    # If file $i contains less than or equal to N*2 lines, show it completely
    # Otherwise, show the first N lines, then "...", and then the last N lines
    NLINES_FILE=$(grep -c "" $i)
    echo "The number of lines in the file is: $NLINES_FILE" #TODO: remove this line when submitting

    if [[ $N -gt 0 ]]
    then
      if [[ $NLINES_FILE -le $(( $N * 2 )) ]]
      then
        echo "Showing entire file:"
        cat $i
      else
        echo "Peek of the file: "
        head -n $N $i
        echo "..."
        tail -n $N $i
      fi
    fi
  done


