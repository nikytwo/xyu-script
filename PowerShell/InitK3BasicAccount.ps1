########################################################
## �� sqlserverʵ����ָ�����ݿ⵼�� K3 ������Ŀ
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

Add-PSSnapin sqlserverCmdletSnapin100

## ���������Ŀ
if ($password)
{	$sqlStr = "exec K_AddAccount '4001','������������',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '5001','��ҵ֧��',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '4005','��ҵ����',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '5005','��ҵ֧��',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	
	$sqlStr = "exec K_AddAccount '401','���뾭��',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '501','����֧��',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '405','��������',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '505','����֧��',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '102','���д��',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '107','������˻��ÿ���',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '111','�ݸ���',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
	$sqlStr = "exec K_AddAccount '101','�ֽ�',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user -P $password -Query $sqlStr
}
else
{
	$sqlStr = "exec K_AddAccount '4001','������������',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '5001','��ҵ֧��',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '4005','��ҵ����',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '5005','��ҵ֧��',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	
	$sqlStr = "exec K_AddAccount '401','���뾭��',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '501','����֧��',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '405','��������',-1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '505','����֧��',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '102','���д��',1,1,0,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '107','������˻��ÿ���',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '111','�ݸ���',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
	$sqlStr = "exec K_AddAccount '101','�ֽ�',1,1,1,'',''"
	Invoke-SqlCmd -ServerInstance $servername -Database $dbname -U $user  -Query $sqlStr
}

Remove-PSSnapin sqlserverCmdletSnapin100

