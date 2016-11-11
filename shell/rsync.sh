rsync -avzP --delete --password-file=/etc/rsyncd.secrets /project/skg-headline-root/modules/headline-admin/target/headline-admin-1.0.0-SNAPSHOT.war  tata@120.24.14.143::rsyncd
rsync -avzP --delete --password-file=/etc/rsyncd.secrets /project/skg-headline-root/modules/headline-api/target/headline-api-1.0.0-SNAPSHOT.war  tata@120.24.14.143::rsyncd
rsync -avzP --delete --password-file=/etc/rsyncd.secrets /project/skg-headline-root/modules/headline-web/target/headline-web-1.0.0-SNAPSHOT.war  tata@120.24.14.143::rsyncd
#rsync -avzP --delete root@10.44.74.179:/web/conf-a* /web
