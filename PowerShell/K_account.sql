
-- =============================================
-- Create PROCEDURE
-- �����¿�Ŀ
-- ֻ������4�࣬5���Ŀ
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'K_account')
	DROP PROCEDURE K_account
GO


--���洢����ֻ�ܴ������2��������Ŀ
CREATE  PROCEDURE K_account(
	@accountid int,      --��Ŀid
	@accountnum varchar(80),  --��Ŀ����
	@accountname varchar(255),  --��Ŀ����
	@dc int,      --�������
	@level int,      --����
	@detail int,      --�Ƿ�����ϸ
	@ItemClassID2 int,	--�������2��ID��û��������
	@ItemClassID3 int	--�������3��ID��û��������
)
AS
declare @rootid int,
	  @detailidt int,
	  @parentid int,
	  @cha int,
	  @tnum varchar(80)
  
BEGIN TRANSACTION
 
-- ����"."����ȡ�ϼ���Ŀ
set @cha = len(@accountnum) - charindex('.', reverse(@accountnum))

if @level<>1
begin
	-- ��һ����Ŀ
	set @tnum = substring(@accountnum,1,@cha)
	select @parentid=faccountid from t_account where fnumber=@tnum
	update t_account set FDetail=0 where faccountid=@parentid	--�����ϼ���ĿΪ����ϸ��Ŀ
	select @rootid=frootid from t_account where FAccountID = @parentid
end
else
begin
	-- һ����Ŀ
	set @parentid = 0
	set @rootid = @accountid
end

declare 
	@recCount int,	--
	@sqlString nvarchar(1000)

-- TODO Ԥ�㵥λ�Ƿ��а�����λ������ĺ�����Ŀ
if (@ItemClassID2 is not NULL and @ItemClassID2 <> '' and (@ItemClassID3 is NULL or @ItemClassID3 = ''))
begin
	-- ��ȡ��Ŀ������λ������ĺ�����ĿID��û�е�������
	print 'Count = 1'
	set @sqlString = N'select @recCount = Count(1) from t_itemdetail where fdetailcount = 1 and f' 
		+ convert(varchar, @ItemClassID2) + ' = -1 and f'
		+ convert(varchar, @ItemClassID3) + ' = 0 '
	execute sp_executesql @sqlString
		, N'@recCount int output'
		, @recCount output
	if (@recCount > 0)
	begin
		-- ��ȡ
		set @sqlString = N'select @detailidt = fdetailid from t_itemdetail where fdetailcount = 1 and f' 
			+ convert(varchar, @ItemClassID2) + ' = -1 and f'
			+ convert(varchar, @ItemClassID3) + ' = 0 '
		execute sp_executesql @sqlString
			, N'@detailidt int output'
			, @detailidt output
    end
	else
    begin
		-- ����
		select @detailidt=fnext from t_identity where fname='t_ItemDetail'
		set @sqlString = 'insert into t_itemdetail(fdetailid, fdetailcount, f' 
			+ convert(varchar, @ItemClassID2) + ') values (@detailidt, 1, -1)'
		execute sp_executesql @sqlString
			, N'@detailidt int'
			, @detailidt
		insert into t_itemdetailv values (@detailidt, @ItemClassID2, -1)
    end
end
else if (@ItemClassID2 is not NULL and @ItemClassID2 <> '' and @ItemClassID3 is not NULL or @ItemClassID3 <> '')
begin
	-- ��ȡ��Ŀ������λ���͡���Ŀ������ĺ�����ĿID��û�е�������
	print 'Count = 2'
	set @sqlString = N'select @recCount = Count(1) from t_itemdetail where fdetailcount = 2 and f' 
		+ convert(varchar, @ItemClassID2) + ' = -1 and f'
		+ convert(varchar, @ItemClassID3) + ' = -1 '
	execute sp_executesql @sqlString
		, N'@recCount int output'
		, @recCount output
	if (@recCount > 0)
    begin
		-- ��ȡ
		set @sqlString = N'select @detailidt = fdetailid from t_itemdetail where fdetailcount = 2 and f' 
			+ convert(varchar, @ItemClassID2) + ' = -1 and f'
			+ convert(varchar, @ItemClassID3) + ' = -1 '
		execute sp_executesql @sqlString
			, N'@detailidt int output'
			, @detailidt output
    end
	else
    begin
		-- ����
		select @detailidt=fnext from t_identity where fname='t_ItemDetail'
		set @sqlString = 'insert into t_itemdetail(fdetailid, fdetailcount, f' 
			+ convert(varchar, @ItemClassID2) + ', f' + convert(varchar, @ItemClassID3) 
			+ ') values (@detailidt, 2, -1, -1)'
		execute sp_executesql @sqlString
			, N'@detailidt int'
			, @detailidt
		insert into t_itemdetailv values (@detailidt, @ItemClassID2, -1)
		insert into t_itemdetailv values (@detailidt, @ItemClassID3, -1)
	end
end
else
begin
	print 'Count = 0' + convert(varchar, isnull(@ItemClassID2, 0)) + ';' + convert(varchar, isnull(@ItemClassID3, 0))
	set @detailidt = 0
end
  
if charindex('5',@accountnum)=1
begin
	-- ����֧��
    INSERT INTO t_Account (FAccountID,FNumber,FName,FGroupID,FDC,FHelperCode,FCurrencyID,FAdjustRate,
               FIsCash,FIsBank,FJournal,FContact,FQuantities,FUnitGroupID,FMeasureUnitID,
               FDetailID,FIsCashFlow,FAcnt,FInterest,FIsAcnt,FAcctint,FLevel,FDetail,
               FParentID,FIsBudget,FRootID) VALUES (
               @accountid,@accountnum,@accountname,503,@dc,NULL, 1, 0,
               0, 0, 0, 0, 0, 0, 0, 
               @detailidt, 0, 0, 0, 0, 0, @level, @detail,
               @parentid, 0,@rootid)

    if @@error<>0 goto fail
end
else if charindex('4',@accountnum)=1
begin
	--��������
    INSERT INTO t_Account (FAccountID,FNumber,FName,FGroupID,FDC,FHelperCode,FCurrencyID,FAdjustRate,
               FIsCash,FIsBank,FJournal,FContact,FQuantities,FUnitGroupID,FMeasureUnitID,
               FDetailID,FIsCashFlow,FAcnt,FInterest,FIsAcnt,FAcctint,FLevel,FDetail,
               FParentID,FIsBudget,FRootID) VALUES (
               @accountid,@accountnum,@accountname,401,@dc,NULL, 1, 0,
               0, 0, 0, 0, 0, 0, 0, 
               @detailidt, 0, 0, 0, 0, 0, @level, @detail,
               @parentid, 0,@rootid)

    if @@error<>0 goto fail
end
else 
begin
	--����
		INSERT INTO t_Account (FAccountID,FNumber,FName,FGroupID,FDC,FHelperCode,FCurrencyID,FAdjustRate,
			   FIsCash,FIsBank,FJournal,FContact,FQuantities,FUnitGroupID,FMeasureUnitID,
			   FDetailID,FIsCashFlow,FAcnt,FInterest,FIsAcnt,FAcctint,FLevel,FDetail,
			   FParentID,FIsBudget,FRootID) VALUES (
			   @accountid,@accountnum,@accountname,CONVERT(int, left(@accountnum,1) + '01'),@dc,NULL, 1, 0,
			   0, 0, 0, 0, 0, 0, 0, 
			   @detailidt, 0, 0, 0, 0, 0, @level, @detail,
			   @parentid, 0,@rootid)	
end
  
commit transaction
return

fail:
rollback tran
GO



