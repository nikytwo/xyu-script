
-- =============================================
--对应新镇街系统的存储过程
--本存储过程可处理多个核算项目
-- =============================================

IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'K_AddVoucherEntry' 
	   AND 	  type = 'P')
    DROP PROCEDURE K_AddVoucherEntry
GO

-- TODO 出错时 事务未提交。
CREATE  PROCEDURE K_AddVoucherEntry(
	@entryid int,--分录id，以0开始的流水号；当为0时，该存储过程才向凭证主表插入相关信息
	@transDate datetime,--业务日期
	@date datetime,--记账日期
	@accountnum varchar(80),  --科目编码，必须用“.”做级别间隔符
	@accountname varchar(255),  --科目名称（全称），必须用“--”做各个级别名称的间隔符。如：公共安全--公安--一般行政管理事务--直接--预算内支出
	@accountlevel int,    --科目级别，必须与上面的科目编码相一致

	--辅助核算项目信息，没有留空，
	--格式：“核算项目类别名1@@核算项目编码1__核算项目名称1&&核算项目类别名2@@核算项目编码2__核算项目名称2&&核算项目类别名n@@核算项目编码n__核算项目名称n”,
	--如：单位@@20011001__大良某某单位&&项目@@200130601__大良某某工程&&支付方式@@01__直接支付&&资金来源@@000__预算内资金
	@items varchar(1000),	
	@amout money,--金额
	@dc int,--借贷方向 1.借 0.贷
	@attachments int,--附件数
	@Explanation varchar(200),--摘要
	@entrycount int,--分录条数

	@preparername varchar(80),--制单人名字

	@vouchergroup varchar(1000),--新增的“凭证字”字段
	@FNum int out,--凭证号，不指定凭证号请赋值-1
	@voucherid int out,--凭证ID(fvoucherid)
	@ret int out,--返回值
	@ret_value varchar(80) out--返回信息
)
AS

declare  
	@debitTotal money,
	@creditTotal money,
	@accountid int,
	@CurrentYear int,
	@CurrentPeriod int,
	@serialNum int,
	@accountIDE1 int,--对方科目借
	@accountIDE0 int,--对方科目贷
	@preparerid int,--制单人id

	@detail int,--是否明细科目
	@lv int,--级别
	@unum varchar(80),
	@vouchergroupid int--新增凭证字内码

declare 
	@tmpNumber varchar(100),
	@num varchar(100),
	@name varchar(100),
	@subname varchar(100),
	@num_index int,
	@name_index int,

	@index int,
	@isUse int,
	@detailid int,--核算项目id
	@detailcount int,--核算项目的个数
	@tmpDetailcount int,--核算项目的个数
	@tmpRstStr varchar(80),
	@tmpItem varchar(255),		--核算项目类别的名称+核算项目ID+核算项目名称
	@tmpItemID varchar(255),	--核算项目ID（内码）
	@tmpItemNumber varchar(255),	--核算项目编码
	@tmpItemName varchar(255),	--核算项目名称
	@tmpItemClassID varchar(255),		--核算项目类别ID
	@tmpItemClassName varchar(255),	--核算项目类别的名称
	@itemClassID_itemIDs varchar(100),	--所有核算项目类别ID+核算项目ID（内码）的串联字符
	@tmpItemClassIDs varchar(100)	--所有核算项目类别ID的串联字符

begin transaction--事务块开始

-- 获取/插入制单人id
exec @preparerid = K_AddUser @preparername, @tmpRstStr out
print @tmpRstStr

-- 获取当前年和当前期间
set @CurrentYear = YEAR(@date)
set @CurrentPeriod = month(@date)
print '当前年、月=' + convert(varchar, @CurrentYear) + '.' + convert(varchar, @CurrentPeriod)

-- 获取/设置核算项目相关信息
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
	-- 不存在该核算项目类别时，增加核算项目类别
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

	-- 获取/新增核算项目类别名称为@tmpItemClassName,核算编码为@tmpItemNumber的核算项目内码（ItemID）
	if exists (select 1 from t_item where fitemclassid = @tmpItemClassID and fnumber = @tmpItemNumber)
	begin
		-- t_item表中有该核算项目，则取其内码
		select @tmpItemID = fitemid from t_item where fitemclassid = @tmpItemClassID and fnumber = @tmpItemNumber
		-- 更新“项目”核算项目基础资料中的名称
		print '更新t_item.Name=' + @tmpItemName
		update t_item set fname = @tmpItemName 
		where fitemclassid = @tmpItemClassID and fnumber = @tmpItemNumber AND fname <> @tmpItemName
	end
	else
	begin
		-- t_item表中没有该核算项目，则增加
		-- TODO 自动增加上级核算项目。
		select @tmpItemID = fnext from t_identity where fname = 't_item'--获取表t_item的下一个主键ID
		print '插入 t_item 表:' + @tmpItemClassID + ', ' + @tmpItemNumber + ', ' + @tmpItemName
		insert into t_item(fitemid, fitemclassid, fexternid, fnumber, fparentid, flevel, fdetail, fname,
			 funused, fbrno, ffullnumber, fdiff, fdeleted, fshortnumber, ffullname, fgrcommonid,
			 fsystemtype, fusesign, fchkuserid, faccessory, fgrcontrol) 
			 values (
			 @tmpItemID, @tmpItemClassID, -1, @tmpItemNumber, 0, 1, 1, @tmpItemName,
			 0, 0, @tmpItemNumber, 0, 0, @tmpItemNumber, @tmpItemName, -1,
			 1, 0, null, 0, -1)
		if (@@error <> 0) 
		begin
		  set @ret_value = '插入基础资料失败(t_item)：' + @tmpItemClassID + ',' + @tmpItemNumber + ',' + @tmpItemName
		  goto fail
		end
	end

	--构造串联参数，以备新增科目和获取凭证分录的DetailID使用
	set @tmpItemClassIDs = @tmpItemClassIDs + @tmpItemClassID + '@@-1__'
	set @itemClassID_itemIDs = @itemClassID_itemIDs + @tmpItemClassID + '@@' + @tmpItemID + '__'
	if (@index < @detailcount)
	begin
		set @tmpItemClassIDs = @tmpItemClassIDs + '&&'
		set @itemClassID_itemIDs = @itemClassID_itemIDs + '&&'
	end
end

-- 检查科目是否存在，不存在则将新科目插入科目表
if exists (select 1 from t_account where fnumber = @accountnum)
begin
	-- 获取科目ID 以及 科目下设的核算id
	select @accountid = faccountid, @detailID = fdetailid from t_account where fnumber = @accountnum
	exec @isUse = sp_ObjectInUsed 0, @accountid
	if (@isUse = 0)
	begin
		-- 科目未使用过，向科目挂载新核算项目(先比较新辅助核算与原辅助核算)
		exec K_CheckItemDetailID @tmpItemClassIDs,@detailID,@tmpItemClassIDs OUTPUT
		exec @detailid = K_GetSetItemDetailID @tmpItemClassIDs, @ret_value out
		update t_account set fdetailid = @detailid where FAccountID = @accountid
	end
	else
	begin
		-- 科目已使用过，不能向科目挂载或删除新的核算项目类别
		select @detailid = fdetailid from t_account where fnumber = @accountnum
		print '获取科目ID=' + convert(varchar, @accountid) + '; 科目下设的核算id=' + convert(varchar, @detailid)

		-- 根据科目下设的核算id，获取 detailcount 
		select @tmpDetailcount = Count(1) from t_itemdetailv where fdetailid = @detailid and fitemclassid > 0
		-- 科目挂载的核算项目与传入的核算项目不同
		-- TODO 科目挂载的核算项目多于传入的？
		--if (@tmpDetailcount > @detailcount)
		--begin
		--end
		--if (@tmpDetailcount < @detailcount)
		--begin
			--科目挂载的核算项目少于传入的		
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
					-- 科目挂载了该核算项目类（@tmpItemClassID），才构造串联参数，以备获取凭证分录的DetailID使用
					set @tmpItemClassIDs = @tmpItemClassIDs + @tmpItemClassID + '@@-1__&&'
					-- 从t_item表取其内码
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
	-- 循环插入新科目
	set @lv=1
	set @subname = @accountname + '--'
	set @num_index = 0
	set @name = ''
	set @tmpNumber = @accountnum + '.'
	while (@lv <= @accountlevel)
	begin
		-- 获取该级别的科目名称
		set @name_index = charindex('--', @subname,1)
		set @name = substring(@subname, 1, @name_index - 1)
		-- 获取除去当前级别的剩余科目名称，为增加下一级科目做准备
		if (len(@subname) - len(@name) - 2 > 0)
		begin
			set @subname = substring(@subname, @name_index + 2, len(@subname) - len(@name) - 2)
		end

		-- 获取该级别的科目编码
		set @num_index = charindex('.', @tmpNumber, @num_index + 1)
		-- TODO 增加自动判断科目级别（level）
		if (@num_index - 1 > 0)
		begin
			set @unum = substring(@tmpNumber, 1, @num_index - 1)
		end
		else
		begin
			set @ret_value='科目编码:' + @accountnum+ '与科目级别:' + convert(varchar(10), @accountlevel) + '不一致'
			goto fail
		end

		-- 非一级科目且科目表中不存在该科目，则增加该科目
		-- TODO 处理一级科目？？
		if (@lv > 1) and (not exists (select 1 from t_account where fnumber=@unum))
		begin
			-- 获取是否最明细科目
			if (@lv = @accountlevel)
			begin
				set @detail = 1
			end
			else
			begin
				set @detail = 0
			end

			print '科目挂载的核算项目数 = ' + convert(varchar, @detailcount) + ':' + @tmpItemClassIDs
			exec @accountid = K_AddAccount @unum, @name, @dc, @lv, @detail, @tmpItemClassIDs, @tmpRstStr out
			
			print '插入科目：' + convert(varchar, @accountid) + ', ' + convert(varchar, @unum) + ', ' + @name 
				+ ', ' + convert(varchar, @dc) + ', ' + convert(varchar, @lv) + ', ' 
				+ convert(varchar, @detail) + ', ' + convert(varchar, @detailcount)
		end

		set @lv = @lv + 1
	end
end

-- 获取辅助核算id(detailid)，为插入凭证做准备
exec @detailid = K_GetSetItemDetailID @itemClassID_itemIDs, @ret_value out

-- 插入凭证
select @serialNum = isnull(MAX(FSerialNum), 1) 
FROM (select * from t_Voucher union all select * from t_VoucherBlankout) v 
Where FYear = @CurrentYear
-----------------alter by devin at 2010-08-17
if (@entryid = 0)
begin
	-- 第一条分录时，插入分录头（凭证主表）
	select @voucherid = fnext from t_identity where fname = 't_voucher'
	-- 获取/添加凭证字
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
			print '插入凭证字=' + convert(varchar, @vouchergroup)
			insert into t_vouchergroup(FbrNo, Fgroupid, fname, fsystemtype, fdeleted, fstandard, flimitmulti, uuid)
			values('0', @vouchergroupid, @vouchergroup, 1, 0, 0, 0, newid())
		end
	end
	print '获取凭证字id=' + convert(varchar, @vouchergroupid)
	-- 获取凭证号
	if (@FNum < 0)
	begin
		select @FNum = isnull(max(fnumber), 0) + 1 from t_voucher 
		where fyear = @CurrentYear and fperiod = @CurrentPeriod
	end
	print '获取凭证号=' + convert(varchar, @FNum)
	-- 插入分录头(凭证主表)
	print '插入分录头:' + convert(varchar, @voucherid)
	INSERT INTO t_Voucher (
		FDate, FTransDate, FYear, FPeriod,
		FGroupID, FNumber, FReference, FExplanation, FAttachments,
		FEntryCount, FDebitTotal, FCreditTotal, FInternalInd, FChecked,
		FPosted, FPreparerID, FCheckerID, FPosterID, FCashierID, FHandler,
		FObjectName, FParameter, FSerialNum, FTranType, FOwnerGroupID) 
	VALUES (
		@date, @transDate, @CurrentYear, @CurrentPeriod,
		@vouchergroupid, @FNum, null, isnull(@Explanation, '无摘要'), @attachments,
		@entrycount, @amout, @amout, null, 0, 0,
		@preparerid, -1, -1, -1, null,
		null, null, @serialNum, 0, 0)

	if (@@error <> 0) 
	begin
		set @ret_value = '插入凭证表头失败'
		goto fail
	end
end
-- 插入分录
-- TODO 未考虑并发情况，是否返回 @voucherid ？
if (isnull(@voucherid, -1) <= 0) 
begin
	select @voucherid = fnext - 1 from t_identity where fname='t_voucher'
end
print '插入分录：voucherid=' + convert(varchar, @voucherid) + '--' + convert(varchar, @entryid)
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
		set @ret_value='插入分录失败'
		goto fail
    end
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
if @entryid = (@entrycount - 1)
begin
	-- 修正凭证主表的合计金额
	select @debitTotal = sum(d.famount * d.fdc), @creditTotal = sum(d.famount * (1 - d.fdc)) from t_voucher m
	inner join t_voucherentry d
	on m.fvoucherid = d.fvoucherid
	where m.fvoucherid = @voucherid
	update t_Voucher set FDebitTotal = @debitTotal, FCreditTotal = @creditTotal
	where fvoucherid = @voucherid

	-- 设置对方科目
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

commit transaction--提交事务项
set @ret = 0
set @ret_value = '操作成功'
return 

fail:
set @ret = 1
rollback tran--回滚事务块
return 
GO

