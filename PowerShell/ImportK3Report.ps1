########################################################
## �� sqlserverʵ�����ƶ����ݿ⵼�� K3 ���ܱ�����$fileList ����ָ���� 
## ʹ�� ADO.NET ���е���
## �ɽ��ܲ��� sqlserverʵ�� �� K3�������ݿ��� �Լ� �û���������
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


$fileList = 
".\����Ԥ������������֧�������08-1.KDR",
".\����Ԥ�������������֧�������07.KDR",
".\����Ԥ�����������Ŀ֧�������08-2.KDR",
".\����֧��������ϸ��05-1.KDR",
".\֧�������04.KDR",
".\��������03.KDR",
".\����֧�������02.KDR",
".\������ҵ����Ŀ����֧�������06.KDR",
".\����ר�������ʽ�����֧�������11.KDR",
".\��Ŀ֧��������ϸ��05-2.KDR"


## ʹ�� sql ADO.NET �����������ݿ�
$sqlCon = New-Object System.Data.SqlClient.SqlConnection
$sqlCom = New-Object System.Data.SqlClient.SqlCommand
$sqlCom.Connection = $sqlCon
$Image = New-Object System.Data.SqlDbType

foreach($file in $fileList)
{
	"����K3���ܱ��� " + $file
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


