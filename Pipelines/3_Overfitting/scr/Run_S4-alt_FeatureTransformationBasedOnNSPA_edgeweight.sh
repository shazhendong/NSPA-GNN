# This sh file generate subject networks.

#### Parameters ####
cutoff=0.0272 # information gain cutoff
cutoff_comp=20 # the minimun size of network components
num_folds=5 # number of folds for cross validation
seed=25 # random seed

add_input=../res/igCutoff_"$cutoff"_minCompSize_"$cutoff_comp"/datasets
add_input_net=../res/igCutoff_"$cutoff"_minCompSize_"$cutoff_comp"/network
add_output=../res/igCutoff_"$cutoff"_minCompSize_"$cutoff_comp"/datasets_subjNet
add_output_ori=../res/igCutoff_"$cutoff"_minCompSize_"$cutoff_comp"/datasets_ori_subjNet
mkdir $add_output
mkdir $add_output_ori

#### Split the dataset ####

echo "Split the dataset"

cp $add_input/Allnodes* .
python crossvalidation_split.py Allnodes.training.csv $num_folds $seed

#### Feature transformation ####

# translate edge list of names to edge list of indices
echo "Translate edge list of names to edge list of indices"
cp $add_input_net/Alledges.edgelist .
python translate_edge_list.py Alledges.edgelist Allnodes.training.csv

# compute the delta degree of each dataset
echo "Compute the delta degrees of traning dataset"
head -n 1 Allnodes.training.csv > header.csv # prepare the header
tail -n +2 Allnodes.testing.csv > Allnodes.testing.csv.noheader.csv # remove the header
python csv2tsv.py Allnodes.testing.csv.noheader.csv Allnodes.testing.csv.noheader.tsv
rm Allnodes.testing.csv.noheader.csv
for i in $(seq 1 $num_folds)
do
    echo "Fold $i"
    # process test dataset
    python SubjectNetwork_Network.py train_fold_$i.tsv edge_list_index.csv test_fold_$i.tsv
    cp FeatrueTrans.csv Allnodes_test_fold_"$i"_SubjectNet.csv
    # process train dataset
    python SubjectNetwork_Network.py train_fold_$i.tsv edge_list_index.csv train_fold_$i.tsv
    cp FeatrueTrans.csv Allnodes_train_fold_"$i"_SubjectNet.csv
    # process validation dataset
    python SubjectNetwork_Network.py train_fold_$i.tsv edge_list_index.csv Allnodes.testing.csv.noheader.tsv
    cp FeatrueTrans.csv Allnodes_validation_fold_"$i"_SubjectNet.csv
done
rm FeatrueTrans.csv


#### Cleaning ####
rm Allnodes.training.csv
rm Allnodes.testing.csv
mv Allnodes*_SubjectNet.csv $add_output # move the transformed datasets to the output folder
#mv LC*_SubjectNet.csv $add_output # move the LC specific transformed datasets to the output folder
#mv Allnodes*.csv $add_output_ori # move the datasets to the output folder
#mv LC*.csv $add_output_ori # move the LC specific datasets to the output folder
rm header.csv
rm edge_list_index.csv
#rm LC*.nodelist
rm Allnodes.testing.csv.noheader.tsv