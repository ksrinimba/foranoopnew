#!/bin/bash -x
set -x
MOUNTDIR=$1  # Where files are mounted
BASEDIR=$2   # Where files are copied, edited and used, should be emptyDir
#MOUNTDIR=/tmp/config  # Where files are mounted
#BASEDIR=/tmp/config2   # Where files are copied, edited and used, should be emptyDir
echo cp -r $1/* $2
cp -r $MOUNTDIR $BASEDIR
if [ $? != 0 ];
then
  echo copy failed
  exit 1
fi
echo "##########Replacing Secret#########"
grep -ir encrypted: $BASEDIR | sort -t: -u -k1,1 |cut -d : -f1 > tmp.list
cat tmp.list | grep -v "oes\|install\|upgrade\|MISC\|SAMPLES\|values.yaml\|values-openldap.yaml" > tmp1.list
echo "##### Following files have the encrypted secrets ########"
cat tmp1.list
while IFS= read -r file; do
grep encrypted: $file > tmp2.list
while read line ; do
echo ${line#*encrypted:} ;
done < tmp2.list > secret-strings.list
while read secret ; do
secretName=${secret%%:*}
echo "---------$secretName---"
keyName=${secret#*:}
keyName=${keyName%%\"*}
keyName=${keyName%% *}
echo "----------$keyName--"
#echo "secret Name= $secretName and key is = $keyName"
#kubectl get secret -o jis
#echo kubectl --kubeconfig /home/srini/ibm-cloud/staging/ibmstaging.config -n ninja-srini get secret $secretName -o json  jq -r ".data.$keyName"
jqParam=".data.\"$keyName\""
value=$(kubectl get secret $secretName -o json | jq -r $jqParam | base64 -d)
value=$(echo $value | sed -e 's`[][\\/.*^$]`\\&`g')
#echo "-----------$value---"
#echo "secret Name= $secretName and key is = $keyName and value is $value"
sed -i s/encrypted:$secretName:$keyName/$value/g $file
done < secret-strings.list
done < tmp1.list
