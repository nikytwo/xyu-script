########################################################
## �� sqlserverʵ�����ƶ����ݿ⵼�� K3 ���ݿ⺯������$fileList ����ָ���� 
## InitK3IO.ps1 �޷���SQLSERVER2000���� ���� ������ʹ�� ADO.NET ���е���
## �ɽ��ܲ��� sqlserverʵ�� �� K3�������ݿ��� �Լ� �û���������
## Example: 
## InitK3Fun 10.0.0.1 "" sa ""
## InitK3Fun -servername 10.0.0.1 -user sa 
## InitK3Fun 10.0.0.1 -password 123
########################################################

## ��ʼ������
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
"���ݿ�ʵ����" + $servername
"K3�������ݿ⣺" + $dbname
"�û���" + $user
"���룺" + $password


$fileList = ".\getItemClass.sql",
".\getItemFrom.sql",
".\getItemName.sql",
".\getItemNumber.sql",
".\getItemsCount.sql"

## ʹ�� sql ADO.NET �����������ݿ�
$sqlCon = New-Object System.Data.SqlClient.SqlConnection
$sqlCom = New-Object System.Data.SqlClient.SqlCommand
$sqlCom.Connection = $sqlCon

foreach($file in $fileList)
{
	"ִ�� sql �ļ�(����):" + $file
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


