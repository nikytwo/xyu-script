########################################################
## 向 sqlserver实例的指定数据库导入 K3 基本科目
## 可接受参数 sqlserver实例 和 K3帐套数据库名 以及 用户名、密码
########################################################

## 初始化参数
param($servername,$dbname,$user,$password)

if (-not $servername)
{
	$servername = "152.0.0.187"
}
if (-not $dbname)
{
	$dbname = "sdcsljys"
}
if (-not $user)
{
	$user = "sa"
}
"数据库实例：" + $servername
"K3帐套数据库：" + $dbname
"用户：" + $user
"密码：" + $password

Add-PSSnapin sqlserverCmdletSnapin100

## 导入基本科目
if ($password)
{	$sqlStr = "exec K_AddAccount '4001','财政补助收入',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '5001','事业支出',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '4005','事业收入',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '5005','事业支出',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	
	$sqlStr = "exec K_AddAccount '401','拨入经费',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '501','经费支出',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '405','基金收入',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '505','基金支出',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '102','银行存款',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '107','零余额账户用款额度',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '111','暂付款',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '101','现金',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
}
else
{
	$sqlStr = "exec K_AddAccount '4001','财政补助收入',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '5001','事业支出',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '4005','事业收入',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '5005','事业支出',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	
	$sqlStr = "exec K_AddAccount '401','拨入经费',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '501','经费支出',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '405','基金收入',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '505','基金支出',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '102','银行存款',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '107','零余额账户用款额度',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '111','暂付款',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '101','现金',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
}

Remove-PSSnapin sqlserverCmdletSnapin100

