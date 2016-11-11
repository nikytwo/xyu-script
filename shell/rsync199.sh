rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-headline-root/modules/headline-admin/target/headline-admin.war  com@120.76.152.185::com
rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-headline-root/modules/headline-api/target/headline-api.war  com@120.76.152.185::com
rsync -avzP --delete --password-file=/etc/rsyncd199.secrets /project/skg-headline-root/modules/headline-web/target/headline-web.war  com@120.76.152.185::com
#rsync -avzP --delete root@10.44.74.179:/web/conf-a* /web
