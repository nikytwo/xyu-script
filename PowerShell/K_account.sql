
-- =============================================
-- Create PROCEDURE
-- 增加新科目
-- 只能增加4类，5类科目
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'K_account')
	DROP PROCEDURE K_account
GO


--本存储过程只能处理最多2个核算项目
CREATE  PROCEDURE K_account(
	@accountid int,      --科目id
	@accountnum varchar(80),  --科目编码
	@accountname varchar(255),  --科目名称
	@dc int,      --借贷方向
	@level int,      --级别
	@detail int,      --是否最明细
	@ItemClassID2 int,	--核算类别2的ID，没有请留空
	@ItemClassID3 int	--核算类别3的ID，没有请留空
)
AS
declare @rootid int,
	  @detailidt int,
	  @parentid int,
	  @cha int,
	  @tnum varchar(80)
  
BEGIN TRANSACTION
 
-- 根据"."来获取上级科目
set @cha = len(@accountnum) - charindex('.', reverse(@accountnum))

if @level<>1
begin
	-- 非一级科目
	set @tnum = substring(@accountnum,1,@cha)
	select @parentid=faccountid from t_account where fnumber=@tnum
	update t_account set FDetail=0 where faccountid=@parentid	--设置上级科目为非明细科目
	select @rootid=frootid from t_account where FAccountID = @parentid
end
else
begin
	-- 一级科目
	set @parentid = 0
	set @rootid = @accountid
end

declare 
	@recCount int,	--
	@sqlString nvarchar(1000)

-- TODO 预算单位是否有按“单位”核算的核算项目
if (@ItemClassID2 is not NULL and @ItemClassID2 <> '' and (@ItemClassID3 is NULL or @ItemClassID3 = ''))
begin
	-- 获取科目按“单位”核算的核算项目ID，没有的则增加
	print 'Count = 1'
	set @sqlString = N'select @recCount = Count(1) from t_itemdetail where fdetailcount = 1 and f' 
		+ convert(varchar, @ItemClassID2) + ' = -1 and f'
		+ convert(varchar, @ItemClassID3) + ' = 0 '
	execute sp_executesql @sqlString
		, N'@recCount int output'
		, @recCount output
	if (@recCount > 0)
	begin
		-- 获取
		set @sqlString = N'select @detailidt = fdetailid from t_itemdetail where fdetailcount = 1 and f' 
			+ convert(varchar, @ItemClassID2) + ' = -1 and f'
			+ convert(varchar, @ItemClassID3) + ' = 0 '
		execute sp_executesql @sqlString
			, N'@detailidt int output'
			, @detailidt output
    end
	else
    begin
		-- 插入
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
	-- 获取科目按“单位”和“项目”核算的核算项目ID，没有的则增加
	print 'Count = 2'
	set @sqlString = N'select @recCount = Count(1) from t_itemdetail where fdetailcount = 2 and f' 
		+ convert(varchar, @ItemClassID2) + ' = -1 and f'
		+ convert(varchar, @ItemClassID3) + ' = -1 '
	execute sp_executesql @sqlString
		, N'@recCount int output'
		, @recCount output
	if (@recCount > 0)
    begin
		-- 获取
		set @sqlString = N'select @detailidt = fdetailid from t_itemdetail where fdetailcount = 2 and f' 
			+ convert(varchar, @ItemClassID2) + ' = -1 and f'
			+ convert(varchar, @ItemClassID3) + ' = -1 '
		execute sp_executesql @sqlString
			, N'@detailidt int output'
			, @detailidt output
    end
	else
    begin
		-- 插入
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
	-- 其他支出
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
	--经费收入
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
	--其他
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



