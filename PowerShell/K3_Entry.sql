/*exec k3_entry 1,'2009-12-31','2009-12-31','501.02.02.02.01.01','����֧��--������ȫ--����--һ��������������--ֱ��--Ԥ����֧��',6,
  '0007','�й���������ɽ��˳����ίԱ������ίԱ��','10029501','������Ա�ͳ����ݹ�����Ա���ý�������',7440.0,0,25,'��������Ա�ͳ����ݹ�����Ա���ý�������',7,'����','-1',0,'good'*/


--���洢����ֻ�ܴ������2��������Ŀ
CREATE  PROCEDURE K3_Entry(
	@entryid int,--��¼id����0��ʼ����ˮ�ţ���Ϊ0ʱ���ô洢���̲���ƾ֤������������Ϣ
	@transDate datetime,--ҵ������
	@date datetime,--��������
	@accountnum varchar(80),  --��Ŀ���룬�����á�.������������
	@accountname varchar(255),  --��Ŀ���ƣ�ȫ�ƣ�������һ����Ŀ���������á�--���������������Ƶļ�������磺������ȫ--����--һ��������������--ֱ��--Ԥ����֧��
	@accountlevel int,    --��Ŀ���𣬱���������Ŀ�Ŀ������һ��

	--û�к�����Ŀ����4����������
	@cusnum varchar(80),    --������λ������ĺ�����Ŀ����
	@cusname varchar(255),    --������λ������ĺ�����Ŀ����

	--ֻ��һ��������Ŀ������������������
	@pronum varchar(80),    --������Ŀ������ĺ�����Ŀ����
	@proname varchar(255),    --������Ŀ������ĺ�����Ŀ����

	@amout money,--���
	@dc int,--������� 1.�� 0.��
	@attachments int,--������
	@Explanation varchar(200),--ժҪ
	@entrycount int,--��¼����

	@preparername varchar(80),--�Ƶ�������

	@vouchergroup varchar(1000),--�����ġ�ƾ֤�֡��ֶ�
	@FNum int out,--ƾ֤��
	@voucherid int out,--ƾ֤ID(fvoucherid)
	@ret int out,--����ֵ
	@ret_value varchar(80) out--������Ϣ
)
AS

declare  
	@debitTotal money,
	@creditTotal money,
	@accountid int,
	@CurrentYear int,
	@CurrentPeriod int,
	--@voucherid int,
	@serialNum int,
	@itemid2 int,
	@itemid3 int,
	@detailid int,--������Ŀid
	@accountIDE1 int,--�Է���Ŀ��
	@accountIDE0 int,--�Է���Ŀ��
	@preparerid int,--�Ƶ���id

	@detail int,--�Ƿ���ϸ��Ŀ
	@lv int,--����
	@unum varchar(20),
	@detailcount int,--������Ŀ�ĸ���
	@vouchergroupid int--����ƾ֤������

declare 
	@tmpNumber varchar(100),
	@num varchar(100),
	@name varchar(100),
	@subname varchar(100),
	@num_index int,
	@name_index int

-------------------------------------------------------------------------------------------------------------
-- ȫ�ֶ���
declare  
	@ItemClassID2 int,	--������λ������ĺ�����Ŀ���ID
	@ItemClassID3 int,	--������Ŀ������ĺ�����Ŀ���ID
	@ItemClassName2 varchar(255),	--������Ŀ���2������
	@ItemClassName3 varchar(255)	--������Ŀ���3������

--Set @ItemClassID2 = 3002
--Set @ItemClassID3 = 3003
set @ItemClassName2 = '��λ'	--ָ����һ���������Ϊ����λ��
set @ItemClassName3 = '��Ŀ'	--ָ���ڶ����������Ϊ����Ŀ��
-------------------------------------------------------------------------------------------------------------

begin transaction--����鿪ʼ

-------------------------------------------------------------------------------------------------------------
-- ��ȡ/�����Ƶ���id
if exists (select 1 from t_user where fname = @preparername)
begin
	select @preparerid = FUserID from t_user where fname = @preparername
end
else
begin
	select @preparerid = (Max(FUserID) + 1) from t_User

	INSERT INTO t_User (
		FAuthRight, FDescription, FEmpID, FForbidden, FHRUser, FName, FPrimaryGroup, FPwValidDay, FSafeMode,
        FSID, FSSOUsername, FUInValidDate, FUserID, FPwCreateDate, ID) VALUES (
        4, NULL, 0, 0, 0, @preparername, 0, 0, 0, 
        ')  F ", ,P T #8 *P!D &D 80!N &@ <0 C ''< : !M &4 )0 Q #( ,P ', 
        '','01-1-1900', @preparerid, getdate(), CAST(newid() as nvarchar(36)))
	Insert into t_Group (FUserID, FGroupID) Values (@preparerid, 0)
end
print '�Ƶ���[' + @preparername + ']id=' + convert(varchar, @preparerid)
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
--��ȡ��ǰ��͵�ǰ�ڼ�
set @CurrentYear = YEAR(@date)
set @CurrentPeriod = month(@date)
print '��ǰ�ꡢ��=' + convert(varchar, @CurrentYear) + '.' + convert(varchar, @CurrentPeriod)
-------------------------------------------------------------------------------------------------------------

Select @ItemClassID2 = fitemclassid from t_ItemClass Where FName = @ItemClassName2
Select @ItemClassID3 = fitemclassid from t_ItemClass Where FName = @ItemClassName3

-------------------------------------------------------------------------------------------------------------
-- ����Ŀ�Ƿ���ڣ����������¿�Ŀ�����Ŀ��
if exists (select 1 from t_account where fnumber = @accountnum)
begin
	-- ��ȡ��ĿID �Լ� ��Ŀ����ĺ���id
	select @accountid = faccountid from t_account where fnumber = @accountnum
	select @detailid = fdetailid from t_account where fnumber = @accountnum
	print '��ȡ��ĿID=' + convert(varchar, @accountid) + '; ��Ŀ����ĺ���id=' + convert(varchar, @detailid)

	----------------------------------------------------------------------------------------------------
	-- TODO ���ݿ�Ŀ����ĺ���id����ȡ detailcount 
	select @detailcount = Count(1) from t_itemdetailv where fdetailid = @detailid and fitemclassid > 0

	----------------------------------------------------------------------------------------------------

end
else
begin
	----------------------------------------------------------------------------------------------------
	-- ��ȡ detailcount
	-- ���� detailcount = 0 �����
	-- TODO δ���� @cusnum is null and @pronum is not null
	-- TODO bug:������ @detailcount <> 2 �����
	if (@pronum is null or @pronum = '') and (@cusnum is null or @cusname = '')
	begin
		set @detailcount = 0  
	end
	else if (@pronum is null or @pronum = '') 
	begin
		set @detailcount = 1
	end
	else
	begin
		set @detailcount = 2   
	end
	----------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------
	-- ѭ�������¿�Ŀ
	set @lv=1
	set @subname = 'һ����Ŀ--' + @accountname + '--'
	set @num_index = 0
	set @name = ''
	set @tmpNumber = @accountnum + '.'
	while(@lv <= @accountlevel)
	begin
		-- ��ȡ�ü���Ŀ�Ŀ����
		set @name_index = charindex('--', @subname,1)
		set @name = substring(@subname, 1, @name_index - 1)
		-- ��ȡ��ȥ��ǰ�����ʣ���Ŀ����
		if (len(@subname) - len(@name) - 2 > 0)
		begin
			set @subname = substring(@subname, @name_index + 2, len(@subname) - len(@name) - 2)
		end

		-- ��ȡ�ü���Ŀ�Ŀ����
		set @num_index = charindex('.', @tmpNumber, @num_index + 1)
		if (@num_index - 1 > 0)
		begin
			set @unum = substring(@tmpNumber, 1, @num_index - 1)
		end
		else
		begin
			set @ret_value='��Ŀ����:' + @accountnum+ '���Ŀ����:' + convert(varchar(10), @accountlevel) + '��һ��'
			goto fail
		end

		-- ��һ����Ŀ�ҿ�Ŀ���в����ڸÿ�Ŀ�������Ӹÿ�Ŀ
		if (@lv > 1) and (not exists (select 1 from t_account where fnumber=@unum))
		begin
			-- ��ȡ�Ƿ�����ϸ��Ŀ
			if (@lv = @accountlevel)
			begin
				set @detail = 1
			end
			else
			begin
				set @detail = 0
			end

			select @accountid = fnext from t_identity where fname='t_account'
			if (@detailcount = 0)
			begin
				print 'Count = 0' + convert(varchar, isnull(@ItemClassID2, 0)) + ';' + convert(varchar, isnull(@ItemClassID3, 0))
				exec K_account @accountid, @unum, @name, @dc, @lv, @detail, null, null
			end
			else if (@detailcount = 1)
			begin
				print 'Count = 1' + convert(varchar, isnull(@ItemClassID2, 0)) + ';' + convert(varchar, isnull(@ItemClassID3, 0))
				exec K_account @accountid, @unum, @name, @dc, @lv, @detail, @ItemClassID2, null
			end
			else
			begin
				print 'Count = 2' + convert(varchar, isnull(@ItemClassID2, 0)) + ';' + convert(varchar, isnull(@ItemClassID3, 0))
				exec K_account @accountid, @unum, @name, @dc, @lv, @detail, @ItemClassID2, @ItemClassID3
			end
			print '�����Ŀ��' + convert(varchar, @accountid) + ', ' + convert(varchar, @unum) + ', ' + @name 
				+ ', ' + convert(varchar, @dc) + ', ' + convert(varchar, @lv) + ', ' 
				+ convert(varchar, @detail) + ', ' + convert(varchar, @detailcount)
		end

		set @lv = @lv + 1
	end
	----------------------------------------------------------------------------------------------------
end
----------------------------------------------------------------------------------------------------

----------------------------------------add by Devin at 2010-05-13----------------------------------
---------------------�����Ŀ���ڣ������Ƿ�һ������ϸ�Ļ����������й����Ŀ�Ŀ����-------------------
----------------------------------------------------------------------------------------------------
if ( @accountlevel <>1  and isnull(@accountname,'')<>'')
begin
	set @tmpNumber = @accountnum
	set @lv = 1
	set @subname = 'һ����Ŀ--' + @accountname
	set @num_index = 1
	while (@lv < @accountlevel)
	begin 
		-- ��ȡ��ǰ����(accountlevel)�Ŀ�Ŀ����
		set @num_index = charindex('.', @tmpNumber, @num_index + 1)
		if (@num_index - 1 >= 0)
		begin
		  set @num = substring(@tmpNumber, 1, @num_index - 1)	--��ȡ��Ŀ
		end

		-- ��ȡ��ǰ����Ŀ�Ŀ����
		set @name_index = charindex('--', @subname, 1)
		set @name = substring(@subname, 0, @name_index)
		-- ��ȡ��ȥ��ǰ�����ʣ���Ŀ����
		if (len(@subname)-len(@name)-2 >= 0)
		begin
			set @subname = substring(@subname, @name_index + 2, len(@subname) - len(@name) - 2)
		end
		-- �޸Ŀ�Ŀ����(����ͬʱ)
		IF @lv <> 1  and (@num like '5%' OR @num LIKE '4%')
		begin
			--���޸�һ����Ŀ���������Ŀ�Ŀ������������ˣ�
			update t_account set fname = @name where fnumber = @num and fname <> @name and isnull(@name, '') <> ''
			print '���¿�Ŀ����,fname=' + @name
		end

		set @lv = @lv + 1
	end
	-- �޸Ŀ�Ŀ����(����ͬʱ)
	if (@tmpNumber like '5%' OR @tmpNumber LIKE '4%')
	begin
		update t_account set fname = @subname where fnumber = @tmpNumber and fname <> @subname
		print '���¿�Ŀ����,fname=' + @subname
	end
	update t_account set fname = fname --���ڴ�������t_account�е�"t_Account_FullName"�������Ը���"ffullname"�ֶ�
end
----------------------------------------------------------------------------------------------------

/* 
TODO Ԥ�㵥λ�Ƿ��а�����λ������ĺ�����Ŀ��
 */

-------------------------------------------------------------------------------------------------------------
-- ��ȡ/��Ӹá���Ŀ���� t_item.itemid
-- �Ƿ��а�����Ŀ������
-- TODO ��������ڸø������㣿
-- TODO �������� @detailcount �Ḳ�Ǵӿ�Ŀ�в�ѯ���Ľ�����Ӷ�����ƾ֤���Ŀ�Ĳ�һ�¡�
if @proname is null or @pronum is null or @pronum = '' or @proname = '' or @ItemClassID3 is null
begin
    set @itemid3 = 0
	if (@detailcount = 2)
	begin
		set @detailcount = 1
	end
end
else
begin
	-- ��ȡ������Ŀ�������Ϊ����Ŀ����������
	-- ���¡���Ŀ��������Ŀ���������е�����
	print '����t_item.Name=' + @proname
	update t_item set fname = @proname where fitemclassid = @ItemClassID3 and fnumber = @pronum AND fname <> @proname
	-- �����а�����Ŀ����������
	if not exists (select 1 from t_item where fitemclassid = @ItemClassID3 and fnumber = @pronum)
	begin
		-- t_item����û�иá���Ŀ����������
		select @itemid3 = fnext from t_identity where fname = 't_item'--��ȡ��t_item����һ������ID
		print '���� t_item ��:' + convert(varchar, @ItemClassID3) + ', ' + convert(varchar, @pronum) + ', ' + @proname
		insert into t_item(fitemid, fitemclassid, fexternid, fnumber, fparentid, flevel, fdetail, fname,
			 funused, fbrno, ffullnumber, fdiff, fdeleted, fshortnumber, ffullname, fgrcommonid,
			 fsystemtype, fusesign, fchkuserid, faccessory, fgrcontrol) 
			 values (
			 @itemid3, @ItemClassID3, -1, @pronum, 0, 1, 1, @proname,
			 0, 0, @pronum, 0, 0, @pronum, @proname, -1,
			 1, 0, null, 0, -1)

		if (@@error <> 0) 
		begin
		  set @ret_value = '�����������ʧ��(t_item)'
		  goto fail
		end
	end
	else
	begin
		-- t_item�����иá���Ŀ������ȡ������
		select @itemid3 = fitemid from t_item where fitemclassid = @ItemClassID3 and fnumber = @pronum
	end
end
-------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------
-- ��ȡ/��Ӹá���λ���� t_item.itemid 
-- �Ƿ��а�����λ������ 
-- TODO ��������ڸø������㣿
if @cusnum is null or @cusname is null or @cusnum = '' or @cusname = '' or @ItemClassID2 is null
begin
    set @itemid2 = 0
	set @detailcount = 0
end
else
begin
	-- ��ȡ������Ŀ�������Ϊ����λ����������(itemid2)
	-- ���¡���λ��������Ŀ���������е�����
	print '����t_item.Name=' + @cusname
	update t_item set fname = @cusname where fitemclassid = @ItemClassID2 and fnumber = @cusnum AND fname <> @cusname
	-- �����а�����λ����������
	if exists (select 1 from t_item where fitemclassid = @ItemClassID2 and fnumber = @cusnum)
	begin
		-- ��� t_item ����ڸá���λ���ģ���ȡ������
		select @itemid2 = fitemid from t_item where fitemclassid = @ItemClassID2 and fnumber = @cusnum 
	end
	else--��� t_item �����ڸá���λ���ģ�������
	begin
		select @itemid2 = fnext from t_identity where fname = 't_item'
		print '���� t_item ��' + convert(varchar, @ItemClassID2) + ', ' + convert(varchar, @cusnum) + ', ' + @cusname
		insert into t_item(fitemid, fitemclassid, fexternid, fnumber, fparentid, flevel, fdetail, fname,
			 funused, fbrno, ffullnumber, fdiff, fdeleted, fshortnumber, ffullname, fgrcommonid,
			 fsystemtype, fusesign, fchkuserid, faccessory, fgrcontrol) 
			 values(
			 @itemid2, @ItemClassID2, -1, @cusnum, 0, 1, 1, @cusname,
			 0, 0, @cusnum, 0, 0, @cusnum, @cusname, -1,
			 1, 0, null, 0, -1)
		if (@@error <> 0) 
		begin
		  set @ret_value = '�����������ʧ��(t_item)'
		  goto fail
		end
	end
end
-------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- ��ȡ��������id(detailid)��Ϊ����ƾ֤��׼��
declare 
	@recCount int,	--
	@sqlString nvarchar(1000)
if (@detailcount = 0)
begin
	-- ��Ŀû�и�������
	set @detailid = 0
end
else if (@detailcount = 1)
begin
	-- ֻ�а�����λ����������
	set @sqlString = N'select @recCount = Count(1) from t_itemdetail where fdetailcount = 1 and f' 
		+ convert(varchar, @ItemClassID2) + ' = @itemid'
	execute sp_executesql @sqlString
		, N'@recCount int output, @itemid int'
		, @recCount output, @itemid2
	if (@recCount > 0)
	begin
		-- t_itemdetail ���е� ItemClass �е�ֵ = itemid
		set @sqlString = N'select @detailid = fdetailid from t_itemdetail where fdetailcount = 1 and f' 
			+ convert(varchar, @ItemClassID2) + ' = @itemid'
		execute sp_executesql @sqlString
			, N'@detailid int output, @itemid int'
			, @detailid output, @itemid2
		print '��ȡ detailid=' + convert(varchar, @detailid)
	end
	else
	begin
		-- t_itemdetail ���е� ItemClass �е�ֵ <> itemid
		select @detailid=(select fnext from t_identity where fname='t_itemdetail')
		print '�� t_itemdetail ���� detailid=' + convert(varchar, @detailid) + ', f' 
			+ convert(varchar, @ItemClassID2) + '=' + convert(varchar, @itemid2)
		set @sqlString = 'insert into t_itemdetail(fdetailid, fdetailcount, f' 
			+ convert(varchar, @ItemClassID2) + ') values (@detailid,1,@itemid)'
		execute sp_executesql @sqlString
			, N'@detailid int, @itemid int'
			, @detailid, @itemid2
		if @@error<>0 
		begin
			set @ret_value='������ʧ��(t_itemdetail)'
			goto fail
		end
		print '�� t_itemdetailv ���� detailid=' + convert(varchar, @detailid) + ', f' 
			+ convert(varchar, @ItemClassID2) + '=' + convert(varchar, @itemid2)
		insert into t_itemdetailv values (@detailid,@ItemClassID2,@itemid2)
		if @@error<>0 
		begin
			set @ret_value='�����ݱ�ʧ��(t_itemdetailv)'
			goto fail
		end
	end
end
else -- detailcount >=2 �����
begin
	-- ͬʱ������λ���͡���Ŀ�����к���ʱ
	set @sqlString = N'select @recCount = Count(1) from t_itemdetail where fdetailcount=2 and f' 
		+ convert(varchar, @ItemClassID2) + ' = @itemid2 and f' 
		+ convert(varchar, @ItemClassID3) + ' = @itemid3'
	execute sp_executesql @sqlString
		, N'@recCount int output, @itemid2 int, @itemid3 int'
		, @recCount output, @itemid2, @itemid3
	if (@recCount > 0)
	begin
		-- t_itemdetail ���е� ItemClassI �е�ֵ = itemid
		set @sqlString = N'select @detailid = fdetailid from t_itemdetail where fdetailcount = 2 and f' 
			+ convert(varchar, @ItemClassID2) + ' = @itemid2 and f' 
			+ convert(varchar, @ItemClassID3) + ' = @itemid3'
		execute sp_executesql @sqlString
			, N'@detailid int output, @itemid2 int, @itemid3 int'
			, @detailid output, @itemid2, @itemid3
		print '��ȡ detailid=' + convert(varchar, @detailid)
	end
	else
	begin
		-- t_itemdetail ���е� ItemClass �е�ֵ <> itemid
		select @detailid=(select fnext from t_identity where fname='t_itemdetail')
		print '�� t_itemdetail ���� detailid=' + convert(varchar, @detailid) 
			+ ', f' + convert(varchar, @ItemClassID2) + '=' + convert(varchar, @itemid2) 
			+ ', f' + convert(varchar, @ItemClassID3) + '=' + convert(varchar, @itemid3)
		set @sqlString = 'insert into t_itemdetail(fdetailid, fdetailcount, f' 
			+ convert(varchar, @ItemClassID2) + ', f' + convert(varchar, @ItemClassID3) 
			+ ') values (@detailid, @detailcount, @itemid2, @itemid3)'
		execute sp_executesql @sqlString
			, N'@detailid int, @detailcount int, @itemid2 int, @itemid3 int'
			, @detailid, @detailcount, @itemid2, @itemid3
		if @@error<>0 
		begin
			set @ret_value='������ʧ��(t_itemdetail)'
			goto fail
		end
		print '�� t_itemdetailv ���� detailid=' + convert(varchar, @detailid) 
			+ ', ItemClassID=' + convert(varchar, @ItemClassID2) + ', itemid=' + convert(varchar, @itemid2) 
		print '�� t_itemdetailv ���� detailid=' + convert(varchar, @detailid) 
			+ ', ItemClassID=' + convert(varchar, @ItemClassID3) + ', itemid=' + convert(varchar, @itemid3)
		INSERT into t_itemdetailv Values (@detailid, @ItemClassID2, @itemid2)
		INSERT into t_itemdetailv VALUES (@detailid, @ItemClassID3, @itemid3)
		if @@error<>0 
		begin
			set @ret_value='�����ݱ�ʧ��(t_itemdetailv)'
			goto fail
		end
	end
end
----------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------
-- ����ƾ֤
select @serialNum = isnull(MAX(FSerialNum), 1) 
FROM (select * from t_Voucher union all select * from t_VoucherBlankout) v 
Where FYear = @CurrentYear
-----------------alter by devin at 2010-08-17
if (@entryid = 0)
begin
	-- ��һ����¼ʱ�������¼ͷ��ƾ֤����
	select @voucherid = fnext from t_identity where fname = 't_voucher'
	-- ��ȡ/���ƾ֤��
	if (isnull(@vouchergroup, '') = '')
	begin
		select @vouchergroupid = 1
	end
	else
	begin
		select @vouchergroupid = fgroupid from t_vouchergroup where fname = @vouchergroup
		if (isnull(@vouchergroupid, 0) = 0)
		begin
			select @vouchergroupid = isnull(max(fgroupid), 0) + 1 from t_vouchergroup
			print '����ƾ֤��=' + convert(varchar, @vouchergroup)
			insert into t_vouchergroup(FbrNo, Fgroupid, fname, fsystemtype, fdeleted, fstandard, flimitmulti, uuid)
			values('0', @vouchergroupid, @vouchergroup, 1, 0, 0, 0, newid())
		end
	end
	print '��ȡƾ֤��id=' + convert(varchar, @vouchergroupid)
	-- ��ȡƾ֤��
	if (@FNum < 0)
	begin
		select @FNum = isnull(max(fnumber), 0) + 1 from t_voucher 
		where fyear = @CurrentYear and fperiod = @CurrentPeriod
	end
	print '��ȡƾ֤��=' + convert(varchar, @FNum)
	-- �����¼ͷ(ƾ֤����)
	print '�����¼ͷ:' 
	INSERT INTO t_Voucher (
		FDate, FTransDate, FYear, FPeriod,
		FGroupID, FNumber, FReference, FExplanation, FAttachments,
		FEntryCount, FDebitTotal, FCreditTotal, FInternalInd, FChecked,
		FPosted, FPreparerID, FCheckerID, FPosterID, FCashierID, FHandler,
		FObjectName, FParameter, FSerialNum, FTranType, FOwnerGroupID) 
	VALUES (
		@date, @transDate, @CurrentYear, @CurrentPeriod,
		@vouchergroupid, @FNum, null, isnull(@Explanation, '��ժҪ'), @attachments,
		@entrycount, @amout, @amout, null, 0, 0,
		@preparerid, -1, -1, -1, null,
		null, null, @serialNum, 0, 0)

	if (@@error <> 0) 
	begin
		set @ret_value = '����ƾ֤��ͷʧ��'
		goto fail
	end
end
-- �����¼
-- TODO δ���ǲ���������Ƿ񷵻� @voucherid ��
if (isnull(@voucherid, -1) <= 0) 
begin
	select @voucherid = fnext - 1 from t_identity where fname='t_voucher'
end
print '�����¼��voucherid=' + convert(varchar, @voucherid)
INSERT INTO t_VoucherEntry (
	FVoucherID, FEntryID, FExplanation, FAccountID, FCurrencyID, FExchangeRate, FDC,
	FAmountFor, FAmount, FQuantity, FMeasureUnitID, FUnitPrice, FInternalInd, FAccountID2,
	FSettleTypeID, FSettleNo, FCashFlowItem, FTaskID, FResourceID, FTransNo, FDetailID) 
VALUES (
	@voucherid, @entryid, @Explanation, @accountid, 1, 1.0, @dc,
	@amout, @amout, 0.0, 0, 0.0, null, 0,
	0, null, 0, 0, 0, null, @detailid)

	if @@error<>0 
    begin
		set @ret_value='�����¼ʧ��'
		goto fail
    end
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- ���öԷ���Ŀ
if @entryid = (@entrycount - 1)
begin
	-- ����ƾ֤����ĺϼƽ��
	select @debitTotal = sum(d.famount * d.fdc), @creditTotal = sum(d.famount * (1 - d.fdc)) from t_voucher m
	inner join t_voucherentry d
	on m.fvoucherid = d.fvoucherid
	where m.fvoucherid = @voucherid
	update t_Voucher set FDebitTotal = @debitTotal, FCreditTotal = @creditTotal
	where fvoucherid = @voucherid

	-- ���öԷ���Ŀ
	select @accountIDE1 = faccountid from t_voucherentry 
	where fentryid in (select max(fentryid) from t_voucherentry where fdc = 0 and fvoucherid = @voucherid) 
	and fdc = 0 and fvoucherid = @voucherid

	select @accountIDE0 = faccountid from t_voucherentry 
	where fentryid = (select max(fentryid) from t_voucherentry where fdc = 1 and fvoucherid = @voucherid) 
	and fdc = 1 and fvoucherid = @voucherid

	update t_voucherentry set faccountid2 = isnull(@accountIDE1, '') where fdc = 1 and fvoucherid = @voucherid
	if (@@error <> 0) goto fail
	update t_voucherentry set faccountid2 = isnull(@accountIDE0, '') where fdc = 0 and fvoucherid = @voucherid
	if (@@error <> 0) goto fail
end
----------------------------------------------------------------------------------------------------

commit transaction--�ύ������
set @ret = 0
set @ret_value = '�����ɹ�'
return

fail:
set @ret = 1
rollback tran--�ع������
return
GO

