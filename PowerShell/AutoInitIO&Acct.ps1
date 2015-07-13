########################################################
## ���������� sqlserverʵ���������������ݿ⵼�� K3 API �Լ� �����Ļ�ƿ�Ŀ
## �ɽ��ܲ��� sqlserverʵ������K3������Ϣ���ݿ⣬���ݿ��û�id�����ݿ�����Ͳ�ѯ��where�Ӿ�
## ����˵����
## -servername : sql server ���ݿ�ʵ�������磺153.0.0.87\SQL2005
## -db ��K3������Ϣ���ݿ� ,һ��ģʽΪ��KDAcctDB
## -user ����¼���ݿ���û���
## -password ����¼���ݿ���û�����
## -wheresql : �Զ����ѯ��where��䣬�磺-wheresql "facctnumber like '15.%'" Ϊ��ѯ���ױ���Ϊ��15.����ͷ�����ס�
## �磺
## & '.\AutoInitIO&Acct' 151.0.0.190 
## & '.\AutoInitIO&Acct' 151.0.0.190 -wheresql "facctnumber like '15.%'"
########################################################

## ��ʼ������
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
"���ݿ�ʵ����" + $servername
"�û���" + $user
"���룺" + $password


## �ж� K3 �汾�������ݰ汾��ѯ������Ϣ
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
	## K3 13.0 ��
	if (-not $db)
	{
		$db = "KDAcctDB"
	}
	"K3������Ϣ���ݿ⣺" + $db
	$tmpSQLStr = "select FDBName from t_ad_kdaccount_gl where 1 = 1" + $wheresql
}
else
{
	## K3 10.3 ��
	if (-not $db)
	{
		$db = "master"
	}
	"K3������Ϣ���ݿ⣺" + $db
	$tmpSQLStr = "select name from dbo.sysdatabases where dbid > 6" + $wheresql
}

## ��ȡ�������׶�Ӧ�����ݿ������б�
if ($password)
{
	$dbnames = Invoke-SqlCmd -ServerInstance $servername -Database $db -U $user -P $password -Query $tmpSQLStr 
}
else
{
	$dbnames = Invoke-SqlCmd -ServerInstance $servername -Database $db -U $user -Query $tmpSQLStr 
}

Remove-PSSnapin sqlserverCmdletSnapin100

## ��ÿ������ִ�����²���
foreach ($dbname in $dbnames)
{
	$dbname
	## ��ʼ��������Ŀ
	#.\InitK3BasicAccount $servername $dbname[0] $user $password
	## ��ʼ���洢����
	.\InitK3IO $servername $dbname[0] $user $password
	## ��ʼ������
	.\InitK3Fun $servername $dbname[0] $user $password
	## ��ʼ�����ܱ���洢����
	.\InitK3Report $servername $dbname[0] $user $password
	## ����K3���ܱ���
	.\ImportK3Report $servername $dbname[0] $user $password
}
