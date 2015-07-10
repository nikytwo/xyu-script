########################################################
## 向 sqlserver实例的制定数据库导入 K3 数据库函数（在$fileList 参数指定） 
## InitK3IO.ps1 无法向SQLSERVER2000导入 函数 ，所以使用 ADO.NET 进行导入
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


$fileList = ".\getItemClass.sql",
".\getItemFrom.sql",
".\getItemName.sql",
".\getItemNumber.sql",
".\getItemsCount.sql"

## 使用 sql ADO.NET 对象链接数据库
$sqlCon = New-Object System.Data.SqlClient.SqlConnection
$sqlCom = New-Object System.Data.SqlClient.SqlCommand
$sqlCom.Connection = $sqlCon

foreach($file in $fileList)
{
	"执行 sql 文件(函数)" + $file
	$content = get-content $file
	$SqlString = ""
	foreach($obj in $content)
	{
		$SqlString += "`n" + $obj.ToString()
	}
	$SqlString = $SqlString.Replace("GO",";")
	$sqlList = $SqlString.Split(";")

	foreach($sql in $sqlList)
	{
		$sqlCon.ConnectionString = "server=$servername;initial catalog=$dbname;user id=$user;password=$password"
		$sqlCom.CommandText = $sql
		$sqlCom.Connection.Open()
		$sqlCom.ExecuteNonQuery()
		$sqlcom.Connection.Close()
	}
}


