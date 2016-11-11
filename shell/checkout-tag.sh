# !/bin/bash

tags=`svn list http://10.10.99.114:8081/svn/skg-headline/tags | sort -t '.' -k1,1n -k2,2n -k3,3n`
echo "$tags"

for tag in $tags
do
	:
done

echo newest tag is "$tag"
echo svn sw --username life_package --password '!Life714.' http://10.10.99.114:8081/svn/skg-headline/tags/"$tag" .
cd skg-headline-root/
mvn clean
svn sw --username life_package --password !Life714. http://10.10.99.114:8081/svn/skg-headline/tags/"$tag" .

svn info
