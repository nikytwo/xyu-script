
# 检出最新的 trunk 分支代码
cd skg-headline-root/
svn sw --username life_package --password !Life714. http://10.10.99.114:8081/svn/skg-headline/branches/v2.x_stage .

# 打包
mvn clean package -Dmaven.test.skip=true
chmod -R o+w /project/skg-headline-root

# 上传测试服务器
rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-headline-root/modules/headline-admin/target/headline-admin.war  com@120.76.152.185::com
rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-headline-root/modules/headline-api/target/headline-api.war  com@120.76.152.185::com
rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-headline-root/modules/headline-web/target/headline-web.war  com@120.76.152.185::com


