#!/bin/bash

#Script adapted for Precision dell

#launch script with this command to redirect log messages and print them on terminal in the same time 
# . /WGS_11102023_Precision.sh 2>&1 | tee -a "/media/ramzi/One\ Touch/Share_Ubuntu_WGS/WGS_Sequencing_41_Precision/logfile_$(date +%D | sed 's/\///g').txt" <-------------- Real samples 



#################################################################################

##########################  GENERAL PATH ################################

#output_00="WGS_Sequencing_41_Precision"    #      <--------------------------------------------------------- path for the general results
#output_00="/media/ramzi/One Touch/Share_Ubuntu_WGS/WGS_Precision"                  #     <--------------------------------------------------------- path to TEST output of the script
output_00="/home/ramzi/Desktop/JOB"

mkdir -p "$output_00"
#################################################################################

####################    STEP SEPARATION FUNCTION   ##############################
function step(){
	local step=$1
	local line_length=80  # Adjust the total line length as needed
	local line=$(echo "############################################################################################")
	local padding=$(( (line_length - ${#step}) / 2 ))
	local padding_line=$(printf "%${padding}s" "")
	
	echo "$line"
    	echo -e "$padding_line$step$padding_line"
    	echo "$line"
	echo -e "\n\n\n"	
}
function wall(){
	local sep="-------------------------------------------------------------------------------------------"
	echo
	echo "$sep"
	echo -e "\n\n"
	}
###########################################################################

#######################	   HEADER	 ##################################
date
echo -e "your current location is \"$(pwd)\""
echo -e "your output folder is $output_00"

Raw_input="/media/ramzi/One Touch/Share_Ubuntu_WGS/Raw_mixed"
echo  -e "Raw sequencing data are located in \"$Raw_input\""
################################################################################################

##########################    PROGRESS BAR CONFIGURATION   #####################################

# Function to draw a progress bar
drawProgressBar() {
    local progress=$1
    local length=100  # Length of the progress bar
    local fillChar='#'
    local emptyChar='-'

    # Calculate the number of filled and empty spaces
    local filled=$(($progress * $length / 100))
    local empty=$(($length - $filled))

    # Print the progress bar
    printf "\r[%-${filled}s%-${empty}s] %d%%" $(printf "%-${filled}s" | tr ' ' "$fillChar") $(printf "%-${empty}s" | tr ' ' "$emptyChar") $progress
}

## Simulate a task with a loop
#for i in {1..100}; do
#    # Perform your task here
#    sleep 0.1  # Simulating some work being done
#
#    # Update the progress bar
#    drawProgressBar $i
#done

# Print a new line after the progress bar
#echo

##############################################################################################

##################### 		CHECK USER CHOICE	  ####################################


#function check_user_choice() {
#    local iteration=$1

#    if [ "$iteration" = 1 ]; then
#        paplay /home/ramzi/Downloads/Notif_Sound_Question.wav &

        # Prompt user for input with a timeout of 10 seconds
#        if ! read -t 10 -n 1 -p  "Do you want to continue? (y/n): " choice || [ -z "$choice" ]; then
            # Timeout occurred
#            echo "Timeout reached. Continuing with the default action..."
#            return
#        fi

#        printf "\n"  # Move to the next line after the user's input

#        if [ "${choice}" != "y" ]; then
#            echo "Script stopped by user"
#            exit 0
#        else
#            echo "Continuing Run...."
#        fi
#    fi
#}

# Example usage
#check_user_choice 1


##############################################################################################

######################## 	SOUND NOTIFICATION	######################################
: '
function notify_user(){
paplay /home/ramzi/Downloads/Notif_Sound_2.wav
}
#usage  notify_user

function notify_end(){
paplay /home/ramzi/Downloads/Notif_Sound_Finished.wav
}
#usage   motify_end
'

function notify_job(){
paplay /home/ramzi/Downloads/Notif_Sound_CR7.wav
}


#usage   notify_job


##############################################################################################

############################# TIME DURATION CONVERTER ########################################


 start_time=$(date +%s)
	#sleep 10 
# end_time=$(date +%s) #paste it at the end of the file
   

function converter(){
    duration=$((end_time - start_time))
    local hours=$((duration / 3600))
    local minutes=$(( (duration % 3600) / 60))
    local seconds=$((duration % 60))
    echo "Script completed in ${hours} hours, ${minutes} minutes, and ${seconds}"
    paplay /home/ramzi/Downloads/NBA.wav
}
#usage
#converter


###############################################################################################

#####################            EXTRACTING SAMPLE NAMES        ###############################
step "EXTRACTING SAMPLE NAMES"
ls "$Raw_input" > "$output_00/names.txt"
file="$output_00/names.txt"
sample_names=$(awk -F '_' '{print $1}' $file | sort -u )
echo "Sorting input..."
rm -f "$output_00/full_sample_names.txt"
sample_names=($sample_names) # because the sample names need to be in the same line ;)
total_samples=${#sample_names[@]} # get the number of samples
for ((i=0 ; i<$total_samples ; i++ ))  ;
	do
		
		
		number=$(grep  $(echo "$(echo ${sample_names[$i]})_") $file | head -n+1 |  awk -F '_' '{print $2}' )
		echo "${sample_names[$i]}_${number}"  >> "$output_00/full_sample_names.txt" 
		sleep 0.1  		# ProgressBar is optionnal


		# Calculate progress percentage
    		progress=$(( ($i + 1) * 100 / $total_samples ))

    		# Draw the progress bar
    		drawProgressBar $progress
		echo
	done 
notify_job

cat  "$output_00/full_sample_names.txt" |  sort -t 'S' -k2,2n > "$output_00/samples.txt" 		# Kepp this file

rm "$output_00/full_sample_names.txt" "$output_00/names.txt" 		# remove temp files

# -t 'S': Specifies 'S' as the field delimiter \
# -k2,2n: Sorts based on the second field (the number following 'S') using numerical (integer) comparison.
echo 'number of samples to treat : $(cat "$output_00/samples.txt" | wc -l)' 
echo "full sample names are the following :"
sample_names=$(cat "$output_00/samples.txt")
echo $sample_names
wall
echo "total = $total_samples"

#############################################################################################

################          CONCATENATING READS OF EACH SAMPLE       	#####################

step "CONCATENATING READS OF EACH SAMPLE"

mkdir -p "$output_00/concat_raw/"
echo "This folder contains concatenated reads of the samples, they will be trimmed after that" > "$output_00/concat_raw/info.txt"

# Read sample names into an array
mapfile -t sample_names < "$output_00/samples.txt"

total_samples=${#sample_names[@]}

# Loop through each sample
	for ((i=0; i<$total_samples; i++)); do			#	<------------------------- THIS Loop for the real samples
#	for ((i=0; i<1; i++)); do     				#	<------------------------- This loop to TEST  4 firts samples

		check_user_choice $i				#	<-------------------------  Ask user if we should continue
		notify_user
    		output_dir="${output_00}/concat_raw/${sample_names[$i]}"
    	
	
		function concatenation(){
		echo "Concatenating files..."
		mkdir -p "$output_dir"
		zcat "$Raw_input/${sample_names[$i]}_L001_R1_001.fastq.gz" "$Raw_input/${sample_names[$i]}_L002_R1_001.fastq.gz" | gzip  > "$output_dir/${sample_names[$i]}_R1.fastq.gz"
		zcat "$Raw_input/${sample_names[$i]}_L001_R2_001.fastq.gz" "$Raw_input/${sample_names[$i]}_L002_R2_001.fastq.gz" | gzip > "$output_dir/${sample_names[$i]}_R2.fastq.gz"
		}


		function concatenation_status(){
  		echo "concatenation status for sample ${sample_names[$i]}"
		r1b1=$(zcat "$Raw_input/${sample_names[$i]}_L001_R1_001.fastq.gz"  | echo $((`wc -l`/4)))
		r1b2=$(zcat "$Raw_input/${sample_names[$i]}_L002_R1_001.fastq.gz"  | echo $((`wc -l`/4)))
		r1=$(zcat "$output_dir/${sample_names[$i]}_R1.fastq.gz"  | echo $((`wc -l`/4)))


		r2b1=$(zcat "$Raw_input/${sample_names[$i]}_L001_R2_001.fastq.gz"  | echo $((`wc -l`/4)))
		r2b2=$(zcat "$Raw_input/${sample_names[$i]}_L002_R2_001.fastq.gz"  | echo $((`wc -l`/4)))
		r2=$(zcat "$output_dir/${sample_names[$i]}_R2.fastq.gz"  | echo $((`wc -l`/4)))
	
		echo " number of forward reads in batch 1 : $r1b1 reads"
		echo " number of forward reads in batch 2 : $r1b2 reads"
		echo "number of total forward reads in the concatenated file : $r1 reads"

		if [ "$((r1b1 + r1b2))" -eq "$r1" ]; 
		then
		echo "All good"
		else
		echo "There is a mistake somewhere, double check"
		fi

		echo " number of reverse reads in batch 1 : $r2b1 reads"
		echo " number of reverse reads in batch 2 : $r2b2 reads"
		echo "number of total reverse reads in the concatenated file : $r2 reads"

		if [ "$((r2b1 + r2b2))" -eq "$r2" ];
		then
		echo "All good"
		else
		echo "There is a mistake somewhere, double check"
		fi
		}
	
		if [ ! -e "$output_dir/${sample_names[$i]}_R1.fastq.gz" ] || [ ! -e "$output_dir/${sample_names[$i]}_R2.fastq.gz" ]; then
			concatenation
			concatenation_status	
		 else
         		echo "Concatenation already done for ${sample_names[$i]}. Skipping..."
			concatenation_status 
		fi


    		# Calculate progress percentage
    		progress=$(( ($i + 1) * 100 / $total_samples ))

    		# Draw the progress bar
    		drawProgressBar $progress

		notify_end

		done
notify_job
wall
#############################################################################################

########################            TRIMMING READS           ################################

step "TRIMMING READS"

mkdir -p "$output_00/trimmed_fastp/"
echo "This folder contains fastp output" > "$output_00/trimmed_fastp/info.txt"

# Read sample names into an array
mapfile -t sample_names < "$output_00/samples.txt"

total_samples=${#sample_names[@]}

# Loop through each sample
for ((i=0; i<$total_samples; i++)); do			#  <----------------------------------   This loop for the real samples
# for ((i=0; i<1; i++)); do                             #  <-----------------------------------  This loop is for tesing 4  first samples  

 input_dir="${output_00}/concat_raw/${sample_names[$i]}"
         output_dir_fastp="${output_00}/trimmed_fastp/${sample_names[$i]}" 
	check_user_choice $i				#	<--------------------------- Ask if we should continue


	if [ ! -e "$output_dir_fastp/${sample_names[$i]}.fastp.html" ] ; then
 	 	
    	mkdir -p "$output_dir_fastp"

	echo  "trimming reads..."
	/home/ramzi/fastp/fastp -v 		#print version 
	/home/ramzi/fastp/fastp -q 20 -r -i "$input_dir/${sample_names[$i]}_R1.fastq.gz" ­­\
        -I "$input_dir/${sample_names[$i]}_R2.fastq.gz" ­­\
        -o "$output_dir_fastp/${sample_names[$i]}_R1.fq.gz" \
        -O "$output_dir_fastp/${sample_names[$i]}_R2.fq.gz" \
        -w 2 -j "$output_dir_fastp/${sample_names[$i]}.fastp.json" -h "$output_dir_fastp/${sample_names[$i]}.fastp.html"
	else
	echo "reads already trimmed for sample ${sample_names[$i]}"
	fi
	notify_end
done
notify_job
wall

##############################################################################################

####################### ASSEMBLING READS INTO CONTIGS ########################################

step "ASSEMBLING READS INTO CONTIGS"

mkdir -p "$output_00/assembly_spades/"
echo "This folder contains Spades output" > "$output_00/assembly_spades/info.txt"		#CB

mkdir -p ~/assembly_spades/									#CB
echo "This folder contains Spades output" > ~/assembly_spades/info.txt		#	<---------------------- testing if putting the output here solves the problem



 # Read sample names into an array
mapfile -t sample_names < "$output_00/samples.txt"

total_samples=${#sample_names[@]}

# Loop through each sample
for ((i=0; i<$total_samples; i++)); do			#	<--------------------------- This loop for real samples
#for ((i=0; i<1; i++)); do 				#	<--------------------------- This loop for TESTING 4 first samples
	
	check_user_choice $i                            #       <--------------------------- Ask if we should continue 
	
	input_dir_spades="${output_00}/trimmed_fastp/${sample_names[$i]}"
	output_dir_spades=~/assembly_spades/"${sample_names[$i]}"
	 if [ ! -e "$output_dir_spades" ] || [ ! -e "$output_00/assembly_spades/${sample_names[$i]}" ] ; then
	
        	mkdir -p "$output_dir_spades"

	
		echo "assembling into contigs..."

		python3 "/home/ramzi/SPAdes-3.15.5/SPAdes-3.15.5/spades.py" --isolate -o "$output_dir_spades" -t 8 -m 20 -1 "$input_dir_spades/${sample_names[$i]}_R1.fq.gz" -2 "$input_dir_spades/${sample_names[$i]}_R2.fq.gz"
 
 		# Calculate progress percentage
     		progress=$(( ($i + 1) * 100 / $total_samples ))

     		# Draw the progress bar
     		drawProgressBar $progress

		echo "moving files to $output_00" && mv "$output_dir_spades" "$output_00/assembly_spades/"
		output_dir_spades="$output_00/assembly_spades/${sample_names[$i]}"
		notify_end
		echo "cooling processor"
		sleep 60 &&  echo "cooling finished"

		else
		echo "Assembly already done for sample ${sample_names[$i]}"
		output_dir_spades="$output_00/assembly_spades/${sample_names[$i]}"
		fi

done
echo "Assemblies finished"
notify_job
wall

#############################################################################################

###################### 	       CHECKING ASSEMBLY QUALITY 	#############################

step "CHECKING ASSEMBLY QUALITY"

mkdir -p "$output_00/assembly_QC/"
 echo "This folder contains QUAST output" > "$output_00/assembly_QC/info.txt"

  # Read sample names into an array
 mapfile -t sample_names < "$output_00/samples.txt"

 total_samples=${#sample_names[@]}

 # Loop through each sample
 for ((i=0; i<$total_samples; i++)); do                 #       <--------------------------- This loop for real samples
 #for ((i=0; i<1; i++)); do                               #       <--------------------------- This loop for TESTING 4 first samples
        
	check_user_choice $i                            #       <--------------------------- Ask if we should continue 
	
	input_dir_QC="$output_00/assembly_spades/${sample_names[$i]}"
        output_dir_QC="${output_00}/assembly_QC/${sample_names[$i]}"
	
	if [ ! -e "$output_dir_QC" ] ; then
	
		mkdir -p "$output_dir_QC"
		echo "evaluating assembly QC..."
		python3  "/home/ramzi/quast/quast-5.2.0/quast.py" -o "$output_dir_QC" "$input_dir_QC/contigs.fasta" --labels ${sample_names[$i]} #-R /home/ramzi/Desktop/SG_clos/Reference/GCF_020138775.1_ASM2013877v1_genomic.fna.gz -G  /home/ramzi/Desktop/SG_clos/Reference/GCF_020138775.1_ASM2013877v1_genomic.gff.gz

		# Calculate progress percentage
		progress=$(( ($i + 1) * 100 / $total_samples ))
		# Draw the progress bar
		drawProgressBar $progress

		notify_end

	else
		echo "QC already checked for sample ${sample_names[$i]}"
	fi
done
echo "evaluating assemblies QC finished"
notify_job
wall

#############################################################################################

######################    ANNOTATION USING PROKKA SOFTWARE       ############################

step "ANNOTATION USING PROKKA"
echo "activating prokka conda environment"
conda activate prokka	# for this to work you need to launch the script as following : source script.sh
#conda update prokka	# Last updated 11122023 
prokka --version
mkdir -p "$output_00/Prokka_annotation/"
echo "This folder contains prokka output" > "$output_00/Prokka_annotation/info.txt"

mkdir  -p ~/Prokka_annotation

# Read sample names into an array
  mapfile -t sample_names < "$output_00/samples.txt"

  total_samples=${#sample_names[@]}

  # Loop through each sample
  for ((i=0; i<$total_samples; i++)); do                 #       <--------------------------- This loop for real samples
 # for ((i=0; i<1; i++)); do               		  #       <--------------------------- This loop for TESTING 4 first samples
	
	check_user_choice $i                            #       <--------------------------- Ask if we should continue
	input_dir="$output_00/assembly_spades/${sample_names[$i]}"
	output_dir_prokka=~/Prokka_annotation/"${sample_names[$i]}"

	if [ ! -e "$output_dir_prokka" ] || [ ! -e "$output_00/Prokka_annotation/${sample_names[$i]}"] ;	then
		notify_user
		echo "starting annotation ${sample_names[$i]}"
		mkdir output_dir_prokka
		prokka --gcode 11 "${input_dir}/contigs.fasta" --outdir "${output_dir_prokka}" --cpus 8 --usegenus --kingdom Bacteria --addgenes --prefix "${sample_names[$i]}" --mincontiglen 200 # --prodigaltf /home/ramzi/WGS_41_isolates/prodigal_41/prodigal_training_25922.trn  --mincontiglen 200
		#it might crash during tbl2asn step so ill run it on my own
		echo "Annotation $i finished"
		echo "moving  files to $output_00" && mv "$output_dir_prokka" "$output_00/Prokka_annotation"
		echo "cooling started" && sleep 90
		echo "cooling finished"

		# Calculate progress percentage
        	progress=$(( ($i + 1) * 100 / $total_samples ))

       		 # Draw the progress bar
		drawProgressBar $progress

		notify_end
	else
		echo " annotation already done for sample ${sample_names[$i]}"
	fi  
done
echo "all annotations finished"
notify_job
conda deactivate
wall



#############################################################################################
end_time=$(date +%s)		# calculating time
converter
#############################################################################################
