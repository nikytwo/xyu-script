
-- =============================================
--��Ӧ�����ϵͳ�Ĵ洢����
--���洢���̿ɴ�����������Ŀ
-- =============================================

IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'K_AddVoucherEntry' 
	   AND 	  type = 'P')
    DROP PROCEDURE K_AddVoucherEntry
GO

-- TODO ����ʱ ����δ�ύ��
CREATE  PROCEDURE K_AddVoucherEntry(
	@entryid int,--��¼id����0��ʼ����ˮ�ţ���Ϊ0ʱ���ô洢���̲���ƾ֤������������Ϣ
	@transDate datetime,--ҵ������
	@date datetime,--��������
	@accountnum varchar(80),  --��Ŀ���룬�����á�.������������
	@accountname varchar(255),  --��Ŀ���ƣ�ȫ�ƣ��������á�--���������������Ƶļ�������磺������ȫ--����--һ��������������--ֱ��--Ԥ����֧��
	@accountlevel int,    --��Ŀ���𣬱���������Ŀ�Ŀ������һ��

	--����������Ŀ��Ϣ��û�����գ�
	--��ʽ����������Ŀ�����1@@������Ŀ����1__������Ŀ����1&&������Ŀ�����2@@������Ŀ����2__������Ŀ����2&&������Ŀ�����n@@������Ŀ����n__������Ŀ����n��,
	--�磺��λ@@20011001__����ĳĳ��λ&&��Ŀ@@200130601__����ĳĳ����&&֧����ʽ@@01__ֱ��֧��&&�ʽ���Դ@@000__Ԥ�����ʽ�
	@items varchar(1000),	
	@amout money,--���
	@dc int,--������� 1.�� 0.��
	@attachments int,--������
	@Explanation varchar(200),--ժҪ
	@entrycount int,--��¼����

	@preparername varchar(80),--�Ƶ�������

	@vouchergroup varchar(1000),--�����ġ�ƾ֤�֡��ֶ�
	@FNum int out,--ƾ֤�ţ���ָ��ƾ֤���븳ֵ-1
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
	@serialNum int,
	@accountIDE1 int,--�Է���Ŀ��
	@accountIDE0 int,--�Է���Ŀ��
	@preparerid int,--�Ƶ���id

	@detail int,--�Ƿ���ϸ��Ŀ
	@lv int,--����
	@unum varchar(80),
	@vouchergroupid int--����ƾ֤������

declare 
	@tmpNumber varchar(100),
	@num varchar(100),
	@name varchar(100),
	@subname varchar(100),
	@num_index int,
	@name_index int,

	@index int,
	@isUse int,
	@detailid int,--������Ŀid
	@detailcount int,--������Ŀ�ĸ���
	@tmpDetailcount int,--������Ŀ�ĸ���
	@tmpRstStr varchar(80),
	@tmpItem varchar(255),		--������Ŀ��������+������ĿID+������Ŀ����
	@tmpItemID varchar(255),	--������ĿID�����룩
	@tmpItemNumber varchar(255),	--������Ŀ����
	@tmpItemName varchar(255),	--������Ŀ����
	@tmpItemClassID varchar(255),		--������Ŀ���ID
	@tmpItemClassName varchar(255),	--������Ŀ��������
	@itemClassID_itemIDs varchar(100),	--���к�����Ŀ���ID+������ĿID�����룩�Ĵ����ַ�
	@tmpItemClassIDs varchar(100)	--���к�����Ŀ���ID�Ĵ����ַ�

begin transaction--����鿪ʼ

-- ��ȡ/�����Ƶ���id
exec @preparerid = K_AddUser @preparername, @tmpRstStr out
print @tmpRstStr

-- ��ȡ��ǰ��͵�ǰ�ڼ�
set @CurrentYear = YEAR(@date)
set @CurrentPeriod = month(@date)
print '��ǰ�ꡢ��=' + convert(varchar, @CurrentYear) + '.' + convert(varchar, @CurrentPeriod)

-- ��ȡ/���ú�����Ŀ�����Ϣ
select @detailcount = dbo.getItemsCount(@items)
set @index = 0
set @tmpItemClassIDs = ''
set @itemClassID_itemIDs = ''
while (@index < @detailcount)
begin
	set @index = @index + 1
	select @tmpItem = dbo.getItemFrom(@items, @index)
	select @tmpItemClassName = dbo.getItemClass(@tmpItem)
	select @tmpItemNumber = dbo.getItemNumber(@tmpItem)
	select @tmpItemName = dbo.getItemName(@tmpItem)
	-- �����ڸú�����Ŀ���ʱ�����Ӻ�����Ŀ���
	if not exists (Select 1 from t_ItemClass Where FName = @tmpItemClassName)
	begin
		exec @tmpItemClassID = K_GetAddItemClass @tmpItemClassName
		if (@tmpItemClassID = '0')
		begin
			CONTINUE
		end
	end
	else
	begin
		Select @tmpItemClassID = fitemclassid from t_ItemClass Where FName = @tmpItemClassName
	end

	-- ��ȡ/����������Ŀ�������Ϊ@tmpItemClassName,�������Ϊ@tmpItemNumber�ĺ�����Ŀ���루ItemID��
	if exists (select 1 from t_item where fitemclassid = @tmpItemClassID and fnumber = @tmpItemNumber)
	begin
		-- t_item�����иú�����Ŀ����ȡ������
		select @tmpItemID = fitemid from t_item where fitemclassid = @tmpItemClassID and fnumber = @tmpItemNumber
		-- ���¡���Ŀ��������Ŀ���������е�����
		print '����t_item.Name=' + @tmpItemName
		update t_item set fname = @tmpItemName 
		where fitemclassid = @tmpItemClassID and fnumber = @tmpItemNumber AND fname <> @tmpItemName
	end
	else
	begin
		-- t_item����û�иú�����Ŀ��������
		-- TODO �Զ������ϼ�������Ŀ��
		select @tmpItemID = fnext from t_identity where fname = 't_item'--��ȡ��t_item����һ������ID
		print '���� t_item ��:' + @tmpItemClassID + ', ' + @tmpItemNumber + ', ' + @tmpItemName
		insert into t_item(fitemid, fitemclassid, fexternid, fnumber, fparentid, flevel, fdetail, fname,
			 funused, fbrno, ffullnumber, fdiff, fdeleted, fshortnumber, ffullname, fgrcommonid,
			 fsystemtype, fusesign, fchkuserid, faccessory, fgrcontrol) 
			 values (
			 @tmpItemID, @tmpItemClassID, -1, @tmpItemNumber, 0, 1, 1, @tmpItemName,
			 0, 0, @tmpItemNumber, 0, 0, @tmpItemNumber, @tmpItemName, -1,
			 1, 0, null, 0, -1)
		if (@@error <> 0) 
		begin
		  set @ret_value = '�����������ʧ��(t_item)��' + @tmpItemClassID + ',' + @tmpItemNumber + ',' + @tmpItemName
		  goto fail
		end
	end

	--���촮���������Ա�������Ŀ�ͻ�ȡƾ֤��¼��DetailIDʹ��
	set @tmpItemClassIDs = @tmpItemClassIDs + @tmpItemClassID + '@@-1__'
	set @itemClassID_itemIDs = @itemClassID_itemIDs + @tmpItemClassID + '@@' + @tmpItemID + '__'
	if (@index < @detailcount)
	begin
		set @tmpItemClassIDs = @tmpItemClassIDs + '&&'
		set @itemClassID_itemIDs = @itemClassID_itemIDs + '&&'
	end
end

-- ����Ŀ�Ƿ���ڣ����������¿�Ŀ�����Ŀ��
if exists (select 1 from t_account where fnumber = @accountnum)
begin
	-- ��ȡ��ĿID �Լ� ��Ŀ����ĺ���id
	select @accountid = faccountid, @detailID = fdetailid from t_account where fnumber = @accountnum
	exec @isUse = sp_ObjectInUsed 0, @accountid
	if (@isUse = 0)
	begin
		-- ��Ŀδʹ�ù������Ŀ�����º�����Ŀ(�ȱȽ��¸���������ԭ��������)
		exec K_CheckItemDetailID @tmpItemClassIDs,@detailID,@tmpItemClassIDs OUTPUT
		exec @detailid = K_GetSetItemDetailID @tmpItemClassIDs, @ret_value out
		update t_account set fdetailid = @detailid where FAccountID = @accountid
	end
	else
	begin
		-- ��Ŀ��ʹ�ù����������Ŀ���ػ�ɾ���µĺ�����Ŀ���
		select @detailid = fdetailid from t_account where fnumber = @accountnum
		print '��ȡ��ĿID=' + convert(varchar, @accountid) + '; ��Ŀ����ĺ���id=' + convert(varchar, @detailid)

		-- ���ݿ�Ŀ����ĺ���id����ȡ detailcount 
		select @tmpDetailcount = Count(1) from t_itemdetailv where fdetailid = @detailid and fitemclassid > 0
		-- ��Ŀ���صĺ�����Ŀ�봫��ĺ�����Ŀ��ͬ
		-- TODO ��Ŀ���صĺ�����Ŀ���ڴ���ģ�
		--if (@tmpDetailcount > @detailcount)
		--begin
		--end
		--if (@tmpDetailcount < @detailcount)
		--begin
			--��Ŀ���صĺ�����Ŀ���ڴ����		
			set @index = 0
			set @tmpItemClassIDs = ''
			set @itemClassID_itemIDs = ''
			while (@index < @detailcount)
			begin
				set @index = @index + 1
				select @tmpItem = dbo.getItemFrom(@items, @index)
				select @tmpItemClassName = dbo.getItemClass(@tmpItem)
				select @tmpItemNumber = dbo.getItemNumber(@tmpItem)
				Select @tmpItemClassID = ''
				Select @tmpItemClassID = fitemclassid from t_ItemClass Where FName = @tmpItemClassName
			
				if exists (select 1 from t_itemdetailv where fdetailid = @detailid and fitemclassid = @tmpItemClassID)
				begin
					-- ��Ŀ�����˸ú�����Ŀ�ࣨ@tmpItemClassID�����Ź��촮���������Ա���ȡƾ֤��¼��DetailIDʹ��
					set @tmpItemClassIDs = @tmpItemClassIDs + @tmpItemClassID + '@@-1__&&'
					-- ��t_item��ȡ������
					select @tmpItemID = fitemid from t_item where fitemclassid = @tmpItemClassID and fnumber = @tmpItemNumber
					set @itemClassID_itemIDs = @itemClassID_itemIDs + @tmpItemClassID + '@@' + @tmpItemID + '__&&'
				end
			end
			if (len(@tmpItemClassIDs) >= 2)
			begin
				set @tmpItemClassIDs = substring(@tmpItemClassIDs, 1, len(@tmpItemClassIDs) - 2)
			end
			if (len(@itemClassID_itemIDs) >= 2)
			begin
				set @itemClassID_itemIDs = substring(@itemClassID_itemIDs, 1, len(@itemClassID_itemIDs) - 2)
			end
			print @tmpItemClassIDs
			print @itemClassID_itemIDs
		--end
		set @detailcount = @tmpDetailcount
	end
end
else
begin
	-- ѭ�������¿�Ŀ
	set @lv=1
	set @subname = @accountname + '--'
	set @num_index = 0
	set @name = ''
	set @tmpNumber = @accountnum + '.'
	while (@lv <= @accountlevel)
	begin
		-- ��ȡ�ü���Ŀ�Ŀ����
		set @name_index = charindex('--', @subname,1)
		set @name = substring(@subname, 1, @name_index - 1)
		-- ��ȡ��ȥ��ǰ�����ʣ���Ŀ���ƣ�Ϊ������һ����Ŀ��׼��
		if (len(@subname) - len(@name) - 2 > 0)
		begin
			set @subname = substring(@subname, @name_index + 2, len(@subname) - len(@name) - 2)
		end

		-- ��ȡ�ü���Ŀ�Ŀ����
		set @num_index = charindex('.', @tmpNumber, @num_index + 1)
		-- TODO �����Զ��жϿ�Ŀ����level��
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
		-- TODO ����һ����Ŀ����
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

			print '��Ŀ���صĺ�����Ŀ�� = ' + convert(varchar, @detailcount) + ':' + @tmpItemClassIDs
			exec @accountid = K_AddAccount @unum, @name, @dc, @lv, @detail, @tmpItemClassIDs, @tmpRstStr out
			
			print '�����Ŀ��' + convert(varchar, @accountid) + ', ' + convert(varchar, @unum) + ', ' + @name 
				+ ', ' + convert(varchar, @dc) + ', ' + convert(varchar, @lv) + ', ' 
				+ convert(varchar, @detail) + ', ' + convert(varchar, @detailcount)
		end

		set @lv = @lv + 1
	end
end

-- ��ȡ��������id(detailid)��Ϊ����ƾ֤��׼��
exec @detailid = K_GetSetItemDetailID @itemClassID_itemIDs, @ret_value out

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
	print '�����¼ͷ:' + convert(varchar, @voucherid)
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
print '�����¼��voucherid=' + convert(varchar, @voucherid) + '--' + convert(varchar, @entryid)
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

