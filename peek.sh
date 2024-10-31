#2. If the input file contains more than $2*2 lines, show it completely.
#Otherwise, show a warning and the first $2 and the last $2 lines
NLINES=$(grep -c "" $1)
if [[ $NLINES -le $(( $2 * 2 )) ]]
then
	cat $1
else
	echo The file has more than 2*$2 = $(( $2 * 2 )) lines
	head -n $2 $1
	echo ...
	tail -n $2 $1
fi


