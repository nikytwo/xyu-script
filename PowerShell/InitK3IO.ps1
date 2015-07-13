########################################################
## 向 sqlserver实例的指定数据库导入 K3 存储过程（在$fileList 参数指定） 
## 可接受参数 sqlserver实例 和 K3帐套数据库名 以及 用户名、密码
## Example: 
## InitK3IO 10.0.0.1 "" sa ""
## InitK3IO -servername 10.0.0.1 -user sa 
## InitK3IO 10.0.0.1 -password 123
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

$fileList = ".\K3_yhrjz.sql",
".\K_GetSetItemDetailID.sql",
".\K_CheckItemDetailID.sql",
".\K_GetAddItemClass.sql",
".\K_AddAccount.sql",
".\K_AddUser.sql",
".\K_AddVoucherEntry.sql"

Add-PSSnapin sqlserverCmdletSnapin100

foreach($file in $fileList)
{
	"执行 sql 文件(存错过程):" + $file
	$content = get-content $file
	$SqlString = ""
	foreach($obj in $content)
	{
		$SqlString += "`n" + $obj.ToString() ## 换行
	}
	## execute $SqlString
	if ($password)
	{
		Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $SqlString
	}
	else
	{
		Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -Query $SqlString
	}
}

Remove-PSSnapin sqlserverCmdletSnapin100

