########################################################
## �� sqlserverʵ����ָ�����ݿ⵼�� K3 �洢���̣���$fileList ����ָ���� 
## �ɽ��ܲ��� sqlserverʵ�� �� K3�������ݿ��� �Լ� �û���������
## Example: 
## InitK3IO 10.0.0.1 "" sa ""
## InitK3IO -servername 10.0.0.1 -user sa 
## InitK3IO 10.0.0.1 -password 123
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
	"ִ�� sql �ļ�(������):" + $file
	$content = get-content $file
	$SqlString = ""
	foreach($obj in $content)
	{
		$SqlString += "`n" + $obj.ToString() ## ����
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

