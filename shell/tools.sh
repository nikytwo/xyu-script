#!/bin/bash

echo "=============================她她头条==================================="
echo "0.全部部署"
echo "1.部署web"
echo "2.部署api"
echo "3.部署admin"
echo "00.全部重启"
echo "4.重启web"
echo "5.重启api"
echo "6.重启admin"
echo "7.部署smart-cloud"
echo "8.重启smart-cloud"
echo "e.退出"
echo "========================================================================"

echo -n "请输入命令执行序号："
read com
case "$com" in
0)
ps -ef|grep tomcat-tta|awk '{print $2}'| xargs sudo kill -9
sudo rm -rf /web2/tta*
unzip -q /web2/headline-web.war -d /web2/ttapp/
\cp -r -f conf-app/app-web.properties ttapp/WEB-INF/classes/conf/
\cp -r -f conf-app/base-db.properties ttapp/WEB-INF/classes/conf/
\cp -r -f conf-app/log4j.xml ttapp/WEB-INF/classes/conf/
\cp -r -f conf-app/weixin.properties ttapp/WEB-INF/classes/conf/payment_gateway/weixin/weixin.properties

unzip -q /web2/headline-api.war -d /web2/ttapi/
\cp -r -f conf-api/app-web.properties ttapi/WEB-INF/classes/conf/
\cp -r -f conf-api/base-db.properties ttapi/WEB-INF/classes/conf/
\cp -r -f conf-api/log4j.xml ttapi/WEB-INF/classes/conf/

unzip -q /web2/headline-admin.war -d /web2/ttadmin/
\cp -r -f conf-admin/app-web.properties ttadmin/WEB-INF/classes/conf/
\cp -r -f conf-admin/base-db.properties ttadmin/WEB-INF/classes/conf/
\cp -r -f conf-admin/log4j.xml ttadmin/WEB-INF/classes/conf/

sudo service tomcat-ttadmin start
sudo service tomcat-ttapi start
sudo service tomcat-ttapp start
chmod -R 707 /web2/ttapp/
chmod -R 707 /web2/ttapi/
chmod -R 707 /web2/ttadmin/
;;
1)
ps -ef|grep tomcat-ttapp|awk '{print $2}'|xargs sudo kill -9
sudo rm -rf /web2/ttapp/*
unzip -q /web2/headline-web.war -d /web2/ttapp/
\cp -r -f conf-app/app-web.properties ttapp/WEB-INF/classes/conf/
\cp -r -f conf-app/base-db.properties ttapp/WEB-INF/classes/conf/
\cp -r -f conf-app/log4j.xml ttapp/WEB-INF/classes/conf/
\cp -r -f conf-app/weixin.properties ttapp/WEB-INF/classes/conf/payment_gateway/weixin/weixin.properties
sudo service tomcat-ttapp start
chmod -R 707 /web2/ttapp
./tools.sh
;;
2)
ps -ef|grep tomcat-ttapi|awk '{print $2}'|xargs sudo kill -9
sudo rm -rf /web2/ttapi/*
unzip -q /web2/headline-api.war -d /web2/ttapi/
\cp -r -f conf-api/app-web.properties ttapi/WEB-INF/classes/conf/
\cp -r -f conf-api/base-db.properties ttapi/WEB-INF/classes/conf/
\cp -r -f conf-api/log4j.xml ttapi/WEB-INF/classes/conf/
sudo service tomcat-ttapi start
chmod -R 707 /web2/ttapi/
./tools.sh
;;
3)
ps -ef|grep tomcat-ttadmin|awk '{print $2}'|xargs sudo kill -9
sudo rm -rf /web2/ttadmin/*
unzip -q /web2/headline-admin.war -d /web2/ttadmin/
\cp -r -f conf-admin/app-web.properties ttadmin/WEB-INF/classes/conf/
\cp -r -f conf-admin/base-db.properties ttadmin/WEB-INF/classes/conf/
\cp -r -f conf-admin/log4j.xml ttadmin/WEB-INF/classes/conf/
sudo service tomcat-ttadmin start
chmod -R 707 /web2/ttadmin
./tools.sh
;;
00)
ps -ef|grep tomcat-tta|awk '{print $2}'|xargs sudo kill -9
sudo service tomcat-ttadmin start
sudo service tomcat-ttapi start
sudo service tomcat-ttapp start
;;
4)
ps -ef|grep tomcat-ttapp|awk '{print $2}'|xargs sudo kill -9
sudo service tomcat-ttapp start
./tools.sh
;;
5)
ps -ef|grep tomcat-ttapi|awk '{print $2}'|xargs sudo kill -9
sudo service tomcat-ttapi start
./tools.sh
;;
6)
ps -ef|grep tomcat-ttadmin|awk '{print $2}'|xargs sudo kill -9
sudo service tomcat-ttadmin start
./tools.sh
;;
000)
;;
7)
ps -ef|grep tomcat-smart-cloud|awk '{print $2}'|xargs sudo kill -9
sudo rm -rf /web2/smart-cloud/*
unzip -q /web2/smart-cloud.war -d /web2/smart-cloud/
\cp -r -f conf-smart-cloud/jdbc.properties smart-cloud/WEB-INF/classes/
sudo service tomcat-smart-cloud start
chmod -R 707 /web2/smart-cloud
./tools.sh
;;
8)
ps -ef|grep tomcat-smart-cloud|awk '{print $2}'|xargs sudo kill -9
sudo service tomcat-smart-cloud start
./tools.sh
;;
9)
;;
e)
exit 1
;;
*)
echo "输入命令错误"
./tools.sh
esac
