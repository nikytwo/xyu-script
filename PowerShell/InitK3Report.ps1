########################################################
## �� sqlserverʵ�����ƶ����ݿ⵼�� K3 ���ܱ���Ĵ洢����
## �ɽ��ܲ��� sqlserverʵ�� �� K3�������ݿ��� �Լ� �û���������
## Example: 
## InitK3Report 10.0.0.1 "" sa ""
## InitK3Report -servername 10.0.0.1 -user sa 
## InitK3Report 10.0.0.1 -password 123
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
"���ݿ�ʵ����" + $servername
"K3������Ϣ���ݿ⣺" + $dbname
"�û���" + $user
"���룺" + $password

$fileList = ".\����Ԥ�������������֧�������07.sql",
".\��������03.sql",
".\֧�������04.sql",
".\����֧��������ϸ��05-1.sql",
".\��Ŀ֧��������ϸ��05-2.sql",
".\����Ԥ������������֧�������08-1.sql",
".\����Ԥ�����������Ŀ֧�������08-2.sql"

Add-PSSnapin sqlserverCmdletSnapin100

foreach($file in $fileList)
{
	"ִ�� sql �ļ�(�洢����):" + $file
	$content = get-content $file
	$SqlString = ""
	foreach($obj in $content)
	{
		$SqlString += "`n" + $obj.ToString() ## ����
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

