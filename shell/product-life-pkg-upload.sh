# !/bin/bash

# 检出最新的 tag 分支下最新版本的代码
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

# 打包
mvn clean package -Dmaven.test.skip=true
chmod -R o+w /project/skg-headline-root

# 上传测试服务器
rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-headline-root/modules/headline-admin/target/headline-admin.war  com@120.76.152.185::com
rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-headline-root/modules/headline-api/target/headline-api.war  com@120.76.152.185::com
rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-headline-root/modules/headline-web/target/headline-web.war  com@120.76.152.185::com

