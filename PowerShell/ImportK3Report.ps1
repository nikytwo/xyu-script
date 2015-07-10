########################################################
## 向 sqlserver实例的制定数据库导入 K3 万能报表（在$fileList 参数指定） 
## 使用 ADO.NET 进行导入
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


$fileList = 
".\公共预算财政拨款基本支出决算表08-1.KDR",
".\公共预算财政拨款收入支出决算表07.KDR",
".\公共预算财政拨款项目支出决算表08-2.KDR",
".\基本支出决算明细表05-1.KDR",
".\支出决算表04.KDR",
".\收入决算表03.KDR",
".\收入支出决算表02.KDR",
".\行政事业类项目收入支出决算表06.KDR",
".\财政专户管理资金收入支出决算表11.KDR",
".\项目支出决算明细表05-2.KDR"


## 使用 sql ADO.NET 对象链接数据库
$sqlCon = New-Object System.Data.SqlClient.SqlConnection
$sqlCom = New-Object System.Data.SqlClient.SqlCommand
$sqlCom.Connection = $sqlCon
$Image = New-Object System.Data.SqlDbType

foreach($file in $fileList)
{
	"导入K3万能报表： " + $file
	$content = get-content $file -Encoding byte
	$byte = New-Object Byte[] $content.Count
	for($i = 0; $i -lt $content.Count; $i++)
	{
		$byte[$i] = $content[$i]
	}
	$file = $file.Replace(".KDR", "").Replace(".\", "")
	$delSql = "delete from t_userdefinerpt where FSubSystemID = 1 and FRptName like '%" + $file + "%';"
	$insertSql = "Insert into t_userdefinerpt values(1, '" + $file + "', @rptDetail, 1);"

	$sqlCon.ConnectionString = "server=$servername;initial catalog=$dbname;user id=$user;password=$password"
	$sqlCom.Parameters.Clear()
	$sqlCom.Connection.Open()
	$delSql
	$sqlCom.CommandText = $delSql
	$sqlCom.ExecuteNonQuery()
	$insertSql
	$sqlCom.CommandText = $insertSql
	$sqlCom.Parameters.Add("@rptDetail", $Image.Image).Value = $byte
	$sqlCom.ExecuteNonQuery()
	$sqlcom.Connection.Close()
}


