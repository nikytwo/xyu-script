
# checkout svn
cd skg-smart/
svn sw --username life_package --password !Life714. http://10.10.99.114:8081/svn/skg-smart/trunk .

# package
mvn clean package -Dmaven.test.skip=true
chmod -R o+w /project/skg-smart

# upload war
rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-smart/smart-cloud/target/smart-cloud.war  com@120.76.152.185::com
rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-smart/smart-admin/target/smart-admin.war  com@120.76.152.185::com
