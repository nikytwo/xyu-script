
# 文件说明

* backupLv*.bat 为备份脚本，其中*代表备份的级别（0：全备份，1：差异备份），即运行 backupLv0.bat 则执行全备份。

* bacupWithRmanLv*.rman 为 RMAN 备份脚本，其中*代表备份的级别（0：全备份，1：差异备份）。

* [rman_usage.md](http://192.168.1.122/docs/doc/blob/master/rman_usage.md) 为 RMAN 操作说明。


# 备份时间

备份时间由系统执行计划进行设置。（注意全局与差异备份应有时间差，否则同时执行会影响数据库性能）

当前的备份计划为：一个星期1次全备份，然后每4小时1次差异备份。


# 其他

备份内容为：控制文件，表空间 ELBONLINE_DATA 以及其归档日志。

备份文件保留 14 天，过期自动删除（除归档日志）。

备份路径为：F:/OracleBackup/rman/，文件后缀为 *.bak。

详见备份脚本。
