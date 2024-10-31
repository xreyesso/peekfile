#1. If user does not provide $2, it must default to 3
if [[ $# -eq 1 ]]
then
	head -n 3 $1
	echo ...
	tail -n 3 $1
elif [[ $# -eq 2 ]]
then
	head -n $2 $1
	echo ...
	tail -n $2 $1
else
	echo The number of arguments passed is not allowed
fi
