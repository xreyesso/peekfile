# The script takes two optional arguments:
# The folder X where to search the files, default: current folder
# A number of lines N, default: 0

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
echo "####### REPORT ###############"
echo There are $n_files fa/fasta files in the provided folder


#TODO: determine how many unique fasta IDs there are in the fa/files of our folder
#Step 1: print all/create a file with all the fasta IDs
#Step 2: keep the unique ones -> how??

#TODO: for each file print a header with the file name
#Create fasta_ids file in the given folder, we will store all fasta IDs here for further processing
touch $FOLDER/fasta_ids
#chmod +w $1/fasta_ids
find $FOLDER -type f -name "*.fa" -or -name "*.fasta" | while read i
  do
    filename=$i

    #TODO: how to delete the path and only keep the name??
    echo "######" The file name is $filename "#########"
      if [[ -h $i ]]
        then
			  echo "The file is a symbolic link."
		  else
			  echo "Not a symbolic link" #TODO: Are these conditions exclusive??
	    fi

	  #Get the fastaIDs from file $i and append them to a list containing all fastaIDs from the given folder
		grep ">" $i | sed 's/>//' | awk '{print $1}' >> $FOLDER/fasta_ids

		#Compute total number of sequences per file
		# Recall: use ^ to grep ">" at the beginning of a string
		nseq=$(grep "^>" $i | wc -l)
		echo "The number of sequences is: " $nseq

		#Compute the total number of amino acids or nucleotides of ALL sequences in the file
		#First, remove all gaps in the non-title lines and then remove all the titles

		#TODO: how to deal with files like ._sequences.fasta?? Or hidden files???
		#Maybe I should filter this at the beginning, when I'm selecting the files to iterate over
		#wc -m counts words in a file
		SEQ_LENGTH=$(sed '/>/! s/-//g; s/ //g' $i | grep -v '>' | tr -d '\n' | wc -m)
		echo "The total sequence length of the file is: " $SEQ_LENGTH
    #sed '/>/! s/-//g; s/ //g' $i | grep -v '>' | tr -d '\n' | wc -m
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
        head -n $N $i
      fi
    fi

  done
#Once the fasta_ids file is created, sort it, get unique fastaIDs and count them
echo "######" End of information per file "#########"
N_UNIQUE_IDS=$(sort $FOLDER/fasta_ids | uniq | wc -l)
echo "There are: " $N_UNIQUE_IDS "unique fasta IDs in the given folder"

# remove all gaps in non-title lines, example:
#sed '/>/! s/-//g' fesor.dbteu.aligned.fa
#Can you print all sequences (omitting titles) in fesor.dbteu.aligned.fa with gaps removed?
#remove all gaps in non-title lines and then then remove all the titles, example:
#sed '/>/! s/-//g' fesor.dbteu.aligned.fa | grep -v '>'
