#!/bin/bash
# description:backup database skg_crm 
# written by liping in 20160202

mysqldump -uroot -pStore+SKG88 skg_headline >/datamysql/mysqlback/skg-`date +%F`.sql
tar czvf /datamysql/mysqlback/skg-`date +%F`.tar.gz  /datamysql/mysqlback/skg-`date +%F`.sql
rm -f  /datamysql/mysqlback/skg-`date +%F`.sql
rm -f  /datamysqlback/mysqlback/skg-`date +%F -d "-30 day"`.tar.gz
rsync -avz -e 'ssh -p 2132' /datamysql/mysqlback/skg-`date +%F`.tar.gz  root@10.170.118.205:/datamysql/mysqlback
ssh  -p 2132 root@10.170.118.205 rm -f  /datamysql/mysqlback/skg-`date +%F -d "-30 day"`.tar.gz
