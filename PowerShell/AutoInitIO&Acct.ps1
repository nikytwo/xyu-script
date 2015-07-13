########################################################
## 批量导入向 sqlserver实例的所有新增数据库导入 K3 API 以及 基本的会计科目
## 可接受参数 sqlserver实例名，K3帐套信息数据库，数据库用户id，数据库密码和查询的where子句
## 参数说明：
## -servername : sql server 数据库实例名，如：153.0.0.87\SQL2005
## -db ：K3帐套信息数据库 ,一般模式为：KDAcctDB
## -user ：登录数据库的用户名
## -password ：登录数据库的用户密码
## -wheresql : 自定义查询的where语句，如：-wheresql "facctnumber like '15.%'" 为查询帐套编码为”15.“开头的帐套。
## 如：
## & '.\AutoInitIO&Acct' 151.0.0.190 
## & '.\AutoInitIO&Acct' 151.0.0.190 -wheresql "facctnumber like '15.%'"
########################################################

## 初始化参数
param($servername,$db,$user,$password,$wheresql)

if (-not $servername)
{
	$servername = "152.0.0.187"
}
if (-not $user)
{
	$user = "sa"
}
if (-not $wheresql)
{
	$wheresql = ""
}
elseif($wheresql.StartsWith('and '))
{
	$wheresql = " " + $wheresql
}
elseif(-not $wheresql.TrimStart().StartsWith('and '))
{
	$wheresql = " and " + $wheresql
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
	$tmpSQLStr = "select FDBName from t_ad_kdaccount_gl where 1 = 1" + $wheresql
}
else
{
	## K3 10.3 版
	if (-not $db)
	{
		$db = "master"
	}
	"K3帐套信息数据库：" + $db
	$tmpSQLStr = "select name from dbo.sysdatabases where dbid > 6" + $wheresql
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
	.\InitK3IO $servername $dbname[0] $user $password
	## 初始化函数
	.\InitK3Fun $servername $dbname[0] $user $password
	## 初始化万能报表存储过程
	.\InitK3Report $servername $dbname[0] $user $password
	## 导入K3万能报表
	.\ImportK3Report $servername $dbname[0] $user $password
}
