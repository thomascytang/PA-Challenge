#!/bin/bash

#using bash because it lets me call command line functions easily

if [ $# -ne 3 ]
then
	echo "usage: grab_data base_id start end"
	exit 1
fi

#create temporary directory
tmp=$(mktemp -d)
#save current directory
curr=`pwd`
#location of files
loc="ftp://www.ngs.noaa.gov/cors/rinex/"
#move to temporary directory
cd $tmp

#extract key numbers from dates

start_year=${2:0:4}
start_month=${2:5:2}
start_day=${2:8:2}
start_hour=${2:11:2}
#use date to get day number (epoch)
start_epoch=`date -j +%j $start_month$start_day"0000"$start_year`


end_year=${3:0:4}
end_month=${3:5:2}
end_day=${3:8:2}
end_hour=${3:11:2}
end_epoch=`date -j +%j $end_month$end_day"0000"$end_year`

tyear=$start_year
tepoch=$start_epoch
thour=$start_hour
#ftp://www.ngs.noaa.gov/cors/rinex/2017/257/nybp/nybp257x.17o.gz
#loop through each hour until we're done
count=0
while [ $tyear -ne $end_year ] || [ $tepoch -ne $end_epoch ] || [ $thour -ne $end_hour ]
do
	#convert hour to ascii value
	hasc=$(expr 97 + $thour)
	#convert ascii value to character
	hchar=$(printf "\\$(printf '%03o' "$hasc")")
	y=${tyear:2:2}
	fname=$1$tepoch$hchar"."$y"o"
	curl -sSL $loc"/"$tyear"/"$tepoch"/"$1"/"$fname".gz" > $fname".gz"
	gunzip $fname".gz"
	#move to numbered file
	mv $fname $count
	
	#increment count and hour
	count=$(expr $count + 1)
	thour=$(expr $thour + 1)
	if [ $thour -ge 24 ]
	then
		thour=0
		#increment day and reset hour if required
		tepoch=$(expr $tepoch + 1)
		#put the zeroes back at the start of day numbers
		if [ $tepoch -lt 100 ]
		then
			$tepoch="0"$tepoch
		fi
		if [ $tepoch -lt 10 ]
		then
			$tepoch="0"$tepoch
		fi
		#increment year if necessary
		#with leap year protection
		if [ $tepoch -gt 365 ]
		then
			if [ $(expr $tyear % 400) -eq 0 ]; then
				if [ $tepoch > 366 ]
				then
					tepoch=001
					tyear=$(expr $tyear + 1)
				fi
			elif [ $(expr $tyear % 100) -eq 0 ]; then
					tepoch=001
					tyear=$(expr $tyear + 1)
			elif [ $(expr $tyear % 4) -eq 0 ]; then
				if [ $tepoch > 366 ]
				then
					tepoch=001
					tyear=$(expr $tyear + 1)
				fi
			else
				tepoch=001
				tyear=$(expr $tyear + 1)
			fi
		fi
	fi
done

#execute loop body one more time
hasc=$(expr 97 + $thour)
hchar=$(printf "\\$(printf '%03o' "$hasc")")
y=${tyear:2:2}
fname=$1$tepoch$hchar"."$y"o"
curl -sSL $loc"/"$tyear"/"$tepoch"/"$1"/"$fname".gz" > $fname".gz"
gunzip $fname".gz"
mv $fname $count
i=0
files=""
while [ $i -le $count ]
do
	files=$files" $i"
	i=$(expr $i + 1)
done
teqc $files > $curr"/"$1".obs"

#remove temporary file
rm -r $tmp

exit 0