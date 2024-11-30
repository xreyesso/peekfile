# The script takes two optional arguments:
# The folder X where to search the files, default: current folder
# A number of lines N, default: 0

#TODO: Fix indentation

FOLDER=$1
N=$2

if [[ $# -gt 2 ]]
then
  echo "The number of arguments passed is greater than expected"
  exit 1
fi

# If the folder is not given, use current folder as default
# However, if the file does exist, check whether it is a directory, and give a message if not
if [[ -z $1 ]]
then
	FOLDER=.
else
  #TODO: improve this condition, what if the given dir does not exist?
  if [[ ! -d $1 ]]
  then
  	echo "The argument given is not a directory"
  	exit 1
  fi
fi

# If the number of lines N is not given, use 0 as default
if [[ -z $2 ]]
then
  N=0
fi

#TODO: how to check $2 is a positive number?
#TODO: how to set the default of $1 to current dir

fasta_files=$(find $FOLDER -type f -name "*.fa" -or -name "*.fasta")
n_files=$(find $FOLDER -type f -name "*.fa" -or -name "*.fasta" | wc -l)
echo "##################### REPORT #####################"
echo "There are $n_files fa/fasta files in the provided folder"

# Determine how many unique fastaIDs the fa/files of the given folder contain in total
# Step 1: create fasta_ids file in the given folder (using the touch command). We will store
# all fasta IDs here for further processing
# Step 2: sort the fastaIDs
# Step 3: get the unique ones
touch $FOLDER/fasta_ids
find $FOLDER -type f -name "*.fa" -or -name "*.fasta" | while read i
  do
    grep ">" $i | sed 's/>//' | awk '{print $1}' >> $FOLDER/fasta_ids
  done

# Print the number of unique fastaIDs
N_UNIQUE_IDS=$(sort $FOLDER/fasta_ids | uniq | wc -l)
echo "There are $N_UNIQUE_IDS unique fasta IDs in the given folder"
echo "------------ REPORT PER FILE ------------"

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

    # Print the header including the file name
    echo "########## The file name is $FILENAME ##########"

    # Indicate whether the file is a symlink
    if [[ -h $i ]]
      then
    	echo "The file is a symbolic link."
    else
    	echo "Not a symbolic link" #TODO: Are these conditions exclusive??
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

		# Compute total number of sequences per file
		# Recall: use ^ to grep ">" at the beginning of a string
		NSEQ=$(grep "^>" $i | wc -l)
		echo "The number of sequences is:  $NSEQ"

		# Compute the total number of amino acids or nucleotides of ALL sequences in the file

		# We first get rid of '-, and then we get rid of white spaces in lines that are not the header.
		# Then we pass all lines except the headers to tr to get rid of new line characters
		# wc -m counts words in a file
		SEQ_LENGTH=$(sed '/>/! s/-//g; s/ //g' $i | grep -v '>' | tr -d '\n' | wc -m)
		echo "The total sequence length of the file is: " $SEQ_LENGTH

    # tr -d '\n' removes new lines

    # If file $i contains less than or equal to N*2 lines, show it completely
    # Otherwise, show the first N lines, then "...", and then the last N lines
    NLINES_FILE=$(grep -c "" $i)
    echo "The number of lines in the file is: " $NLINES_FILE

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


