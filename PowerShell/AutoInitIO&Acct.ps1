########################################################
## 批量导入向 sqlserver实例的所有新增数据库导入 K3 API 以及 基本的会计科目
## 可接受参数 sqlserver实例 和 K3帐套信息数据库
########################################################

## 初始化参数
param($servername,$db,$user,$password)

if (-not $servername)
{
	$servername = "152.0.0.187"
}
if (-not $user)
{
	$user = "sa"
}
"数据库实例：" + $servername
"用户：" + $user
"密码：" + $password


## 判断 K3 版本，并根据版本查询帐套信息
Add-PSSnapin sqlserverCmdletSnapin100

if ($password)
{
	$Exists = Invoke-SqlCmd -ServerInstance $servername -Database "master" -U sa -P $password -Query "select 1 from sysdatabases where name = 'kdacctdb'"
}
else
{
	$Exists = Invoke-SqlCmd -ServerInstance $servername -Database "master" -U sa -Query "select 1 from sysdatabases where name = 'kdacctdb'"
}
if ($Exists)
{
	## K3 13.0 版
	if (-not $db)
	{
		$db = "KDAcctDB"
	}
	"K3帐套信息数据库：" + $db
	$tmpSQLStr = "select FDBName from t_ad_kdaccount_gl"
}
else
{
	## K3 10.3 版
	if (-not $db)
	{
		$db = "master"
	}
	"K3帐套信息数据库：" + $db
	$tmpSQLStr = "select name from dbo.sysdatabases where dbid > 6"
}

## 获取所有帐套对应的数据库名称列表
if ($password)
{
	$dbnames = Invoke-SqlCmd -ServerInstance $servername -Database $db -U $user -P $password -Query $tmpSQLStr 
}
else
{
	$dbnames = Invoke-SqlCmd -ServerInstance $servername -Database $db -U $user -Query $tmpSQLStr 
}

Remove-PSSnapin sqlserverCmdletSnapin100

## 对每个帐套执行如下操作
foreach ($dbname in $dbnames)
{
	$dbname
	## 初始化基础科目
	#.\InitK3BasicAccount $servername $dbname[0] $user $password
	## 初始化存储过程
	#.\InitK3IO $servername $dbname[0] $user $password
	## 初始化函数
	#.\InitK3Fun $servername $dbname[0] $user $password
	## 初始化万能报表
	.\InitK3Report $servername $dbname[0] $user $password
}
