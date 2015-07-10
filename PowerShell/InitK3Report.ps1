########################################################
## 向 sqlserver实例的制定数据库导入 K3 万能报表的存储过程
## 可接受参数 sqlserver实例 和 K3帐套数据库名 以及 用户名、密码
########################################################


param($servername,$dbname,$user,$password)

if (-not $servername)
{
	$servername = "152.0.0.187"
}
if (-not $dbname)
{
	$dbname = "sdcsljys2011"
}
if (-not $user)
{
	$user = "sa"
}
"数据库实例：" + $servername
"K3帐套信息数据库：" + $dbname
"用户：" + $user
"密码：" + $password

$fileList = ".\公共预算财政拨款收入支出决算表07.sql",
".\收入支出决算表02.sql",
".\收入决算表03.sql",
".\支出决算表04.sql",
".\基本支出决算明细表05-1.sql",
".\项目支出决算明细表05-2.sql",
".\行政事业类项目收入支出决算表06.sql",
".\公共预算财政拨款基本支出决算表08-1.sql",
".\公共预算财政拨款项目支出决算表08-2.sql",
".\财政专户管理资金收入支出决算表11.sql"

Add-PSSnapin sqlserverCmdletSnapin100

foreach($file in $fileList)
{
	"执行 sql 文件(存储过程)" + $file
	$content = get-content $file
	$SqlString = ""
	foreach($obj in $content)
	{
		$SqlString += "`n" + $obj.ToString() ## 换行
	}
	## execute $SqlString
	if($password)
	{
		Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $SqlString
	}
	else
	{
		Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -Query $SqlString
	}
}

Remove-PSSnapin sqlserverCmdletSnapin100

