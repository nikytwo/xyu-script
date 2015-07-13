/*exec k3_entry 1,'2009-12-31','2009-12-31','501.02.02.02.01.01','经费支出--公共安全--公安--一般行政管理事务--直接--预算内支出',6,
  '0007','中国共产党佛山市顺德区委员会政法委员会','10029501','流动人员和出租屋管理人员表彰奖励经费',7440.0,0,25,'区流动人员和出租屋管理人员表彰奖励经费',7,'方芳','-1',0,'good'*/


--本存储过程只能处理最多2个核算项目
CREATE  PROCEDURE K3_Entry(
	@entryid int,--分录id，以0开始的流水号；当为0时，该存储过程才向凭证主表插入相关信息
	@transDate datetime,--业务日期
	@date datetime,--记账日期
	@accountnum varchar(80),  --科目编码，必须用“.”做级别间隔符
	@accountname varchar(255),  --科目名称（全称，但不含一级科目），必须用“--”做各个级别名称的间隔符。如：公共安全--公安--一般行政管理事务--直接--预算内支出
	@accountlevel int,    --科目级别，必须与上面的科目编码相一致

	--没有核算项目以下4个参数留空
	@cusnum varchar(80),    --按“单位”核算的核算项目编码
	@cusname varchar(255),    --按“单位”核算的核算项目名称

	--只有一个核算项目的以下两个参数留空
	@pronum varchar(80),    --按“项目”核算的核算项目编码
	@proname varchar(255),    --按“项目”核算的核算项目名称

	@amout money,--金额
	@dc int,--借贷方向 1.借 0.贷
	@attachments int,--附件数
	@Explanation varchar(200),--摘要
	@entrycount int,--分录条数

	@preparername varchar(80),--制单人名字

	@vouchergroup varchar(1000),--新增的“凭证字”字段
	@FNum int out,--凭证号
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
	--@voucherid int,
	@serialNum int,
	@itemid2 int,
	@itemid3 int,
	@detailid int,--核算项目id
	@accountIDE1 int,--对方科目借
	@accountIDE0 int,--对方科目贷
	@preparerid int,--制单人id

	@detail int,--是否明细科目
	@lv int,--级别
	@unum varchar(20),
	@detailcount int,--核算项目的个数
	@vouchergroupid int--新增凭证字内码

declare 
	@tmpNumber varchar(100),
	@num varchar(100),
	@name varchar(100),
	@subname varchar(100),
	@num_index int,
	@name_index int

-------------------------------------------------------------------------------------------------------------
-- 全局定义
declare  
	@ItemClassID2 int,	--按“单位”核算的核算项目类别ID
	@ItemClassID3 int,	--按“项目”核算的核算项目类别ID
	@ItemClassName2 varchar(255),	--核算项目类别2的名称
	@ItemClassName3 varchar(255)	--核算项目类别3的名称

--Set @ItemClassID2 = 3002
--Set @ItemClassID3 = 3003
set @ItemClassName2 = '单位'	--指定第一个核算类别为“单位”
set @ItemClassName3 = '项目'	--指定第二个核算类别为“项目”
-------------------------------------------------------------------------------------------------------------

begin transaction--事务块开始

-------------------------------------------------------------------------------------------------------------
-- 获取/插入制单人id
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
print '制单人[' + @preparername + ']id=' + convert(varchar, @preparerid)
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
--获取当前年和当前期间
set @CurrentYear = YEAR(@date)
set @CurrentPeriod = month(@date)
print '当前年、月=' + convert(varchar, @CurrentYear) + '.' + convert(varchar, @CurrentPeriod)
-------------------------------------------------------------------------------------------------------------

Select @ItemClassID2 = fitemclassid from t_ItemClass Where FName = @ItemClassName2
Select @ItemClassID3 = fitemclassid from t_ItemClass Where FName = @ItemClassName3

-------------------------------------------------------------------------------------------------------------
-- 检查科目是否存在，不存在则将新科目插入科目表
if exists (select 1 from t_account where fnumber = @accountnum)
begin
	-- 获取科目ID 以及 科目下设的核算id
	select @accountid = faccountid from t_account where fnumber = @accountnum
	select @detailid = fdetailid from t_account where fnumber = @accountnum
	print '获取科目ID=' + convert(varchar, @accountid) + '; 科目下设的核算id=' + convert(varchar, @detailid)

	----------------------------------------------------------------------------------------------------
	-- TODO 根据科目下设的核算id，获取 detailcount 
	select @detailcount = Count(1) from t_itemdetailv where fdetailid = @detailid and fitemclassid > 0

	----------------------------------------------------------------------------------------------------

end
else
begin
	----------------------------------------------------------------------------------------------------
	-- 获取 detailcount
	-- 考虑 detailcount = 0 的情况
	-- TODO 未考虑 @cusnum is null and @pronum is not null
	-- TODO bug:不会有 @detailcount <> 2 的情况
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
	-- 循环插入新科目
	set @lv=1
	set @subname = '一级科目--' + @accountname + '--'
	set @num_index = 0
	set @name = ''
	set @tmpNumber = @accountnum + '.'
	while(@lv <= @accountlevel)
	begin
		-- 获取该级别的科目名称
		set @name_index = charindex('--', @subname,1)
		set @name = substring(@subname, 1, @name_index - 1)
		-- 获取除去当前级别的剩余科目名称
		if (len(@subname) - len(@name) - 2 > 0)
		begin
			set @subname = substring(@subname, @name_index + 2, len(@subname) - len(@name) - 2)
		end

		-- 获取该级别的科目编码
		set @num_index = charindex('.', @tmpNumber, @num_index + 1)
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
			print '插入科目：' + convert(varchar, @accountid) + ', ' + convert(varchar, @unum) + ', ' + @name 
				+ ', ' + convert(varchar, @dc) + ', ' + convert(varchar, @lv) + ', ' 
				+ convert(varchar, @detail) + ', ' + convert(varchar, @detailcount)
		end

		set @lv = @lv + 1
	end
	----------------------------------------------------------------------------------------------------
end
----------------------------------------------------------------------------------------------------

----------------------------------------add by Devin at 2010-05-13----------------------------------
---------------------如果科目存在，并且是非一级的明细的话，更新所有关联的科目名称-------------------
----------------------------------------------------------------------------------------------------
if ( @accountlevel <>1  and isnull(@accountname,'')<>'')
begin
	set @tmpNumber = @accountnum
	set @lv = 1
	set @subname = '一级科目--' + @accountname
	set @num_index = 1
	while (@lv < @accountlevel)
	begin 
		-- 获取当前级别(accountlevel)的科目长度
		set @num_index = charindex('.', @tmpNumber, @num_index + 1)
		if (@num_index - 1 >= 0)
		begin
		  set @num = substring(@tmpNumber, 1, @num_index - 1)	--获取科目
		end

		-- 获取当前级别的科目名称
		set @name_index = charindex('--', @subname, 1)
		set @name = substring(@subname, 0, @name_index)
		-- 获取除去当前级别的剩余科目名称
		if (len(@subname)-len(@name)-2 >= 0)
		begin
			set @subname = substring(@subname, @name_index + 2, len(@subname) - len(@name) - 2)
		end
		-- 修改科目名称(不相同时)
		IF @lv <> 1  and (@num like '5%' OR @num LIKE '4%')
		begin
			--不修改一级科目（还其他的科目可以在这里过滤）
			update t_account set fname = @name where fnumber = @num and fname <> @name and isnull(@name, '') <> ''
			print '更新科目名称,fname=' + @name
		end

		set @lv = @lv + 1
	end
	-- 修改科目名称(不相同时)
	if (@tmpNumber like '5%' OR @tmpNumber LIKE '4%')
	begin
		update t_account set fname = @subname where fnumber = @tmpNumber and fname <> @subname
		print '更新科目名称,fname=' + @subname
	end
	update t_account set fname = fname --用于触发发表t_account中的"t_Account_FullName"触发器以更新"ffullname"字段
end
----------------------------------------------------------------------------------------------------

/* 
TODO 预算单位是否有按“单位”核算的核算项目？
 */

-------------------------------------------------------------------------------------------------------------
-- 获取/添加该“项目”的 t_item.itemid
-- 是否有按“项目”核算
-- TODO 如果不存在该辅助核算？
-- TODO 这里设置 @detailcount 会覆盖从科目中查询到的结果，从而导致凭证与科目的不一致。
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
	-- 获取核算项目类别名称为“项目”的类别编码
	-- 更新“项目”核算项目基础资料中的名称
	print '更新t_item.Name=' + @proname
	update t_item set fname = @proname where fitemclassid = @ItemClassID3 and fnumber = @pronum AND fname <> @proname
	-- 处理有按“项目”核算的情况
	if not exists (select 1 from t_item where fitemclassid = @ItemClassID3 and fnumber = @pronum)
	begin
		-- t_item表中没有该“项目”，则增加
		select @itemid3 = fnext from t_identity where fname = 't_item'--获取表t_item的下一个主键ID
		print '插入 t_item 表:' + convert(varchar, @ItemClassID3) + ', ' + convert(varchar, @pronum) + ', ' + @proname
		insert into t_item(fitemid, fitemclassid, fexternid, fnumber, fparentid, flevel, fdetail, fname,
			 funused, fbrno, ffullnumber, fdiff, fdeleted, fshortnumber, ffullname, fgrcommonid,
			 fsystemtype, fusesign, fchkuserid, faccessory, fgrcontrol) 
			 values (
			 @itemid3, @ItemClassID3, -1, @pronum, 0, 1, 1, @proname,
			 0, 0, @pronum, 0, 0, @pronum, @proname, -1,
			 1, 0, null, 0, -1)

		if (@@error <> 0) 
		begin
		  set @ret_value = '插入基础资料失败(t_item)'
		  goto fail
		end
	end
	else
	begin
		-- t_item表中有该“项目”，则取其内码
		select @itemid3 = fitemid from t_item where fitemclassid = @ItemClassID3 and fnumber = @pronum
	end
end
-------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------
-- 获取/添加该“单位”的 t_item.itemid 
-- 是否有按“单位”核算 
-- TODO 如果不存在该辅助核算？
if @cusnum is null or @cusname is null or @cusnum = '' or @cusname = '' or @ItemClassID2 is null
begin
    set @itemid2 = 0
	set @detailcount = 0
end
else
begin
	-- 获取核算项目类别名称为“单位”的类别编码(itemid2)
	-- 更新“单位”核算项目基础资料中的名称
	print '更新t_item.Name=' + @cusname
	update t_item set fname = @cusname where fitemclassid = @ItemClassID2 and fnumber = @cusnum AND fname <> @cusname
	-- 处理有按“单位”核算的情况
	if exists (select 1 from t_item where fitemclassid = @ItemClassID2 and fnumber = @cusnum)
	begin
		-- 如果 t_item 表存在该“单位”的，则取其内码
		select @itemid2 = fitemid from t_item where fitemclassid = @ItemClassID2 and fnumber = @cusnum 
	end
	else--如果 t_item 表不存在该“单位”的，则增加
	begin
		select @itemid2 = fnext from t_identity where fname = 't_item'
		print '插入 t_item 表：' + convert(varchar, @ItemClassID2) + ', ' + convert(varchar, @cusnum) + ', ' + @cusname
		insert into t_item(fitemid, fitemclassid, fexternid, fnumber, fparentid, flevel, fdetail, fname,
			 funused, fbrno, ffullnumber, fdiff, fdeleted, fshortnumber, ffullname, fgrcommonid,
			 fsystemtype, fusesign, fchkuserid, faccessory, fgrcontrol) 
			 values(
			 @itemid2, @ItemClassID2, -1, @cusnum, 0, 1, 1, @cusname,
			 0, 0, @cusnum, 0, 0, @cusnum, @cusname, -1,
			 1, 0, null, 0, -1)
		if (@@error <> 0) 
		begin
		  set @ret_value = '插入基础资料失败(t_item)'
		  goto fail
		end
	end
end
-------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- 获取辅助核算id(detailid)，为插入凭证做准备
declare 
	@recCount int,	--
	@sqlString nvarchar(1000)
if (@detailcount = 0)
begin
	-- 科目没有辅助核算
	set @detailid = 0
end
else if (@detailcount = 1)
begin
	-- 只有按“单位”核算的情况
	set @sqlString = N'select @recCount = Count(1) from t_itemdetail where fdetailcount = 1 and f' 
		+ convert(varchar, @ItemClassID2) + ' = @itemid'
	execute sp_executesql @sqlString
		, N'@recCount int output, @itemid int'
		, @recCount output, @itemid2
	if (@recCount > 0)
	begin
		-- t_itemdetail 表中的 ItemClass 列的值 = itemid
		set @sqlString = N'select @detailid = fdetailid from t_itemdetail where fdetailcount = 1 and f' 
			+ convert(varchar, @ItemClassID2) + ' = @itemid'
		execute sp_executesql @sqlString
			, N'@detailid int output, @itemid int'
			, @detailid output, @itemid2
		print '获取 detailid=' + convert(varchar, @detailid)
	end
	else
	begin
		-- t_itemdetail 表中的 ItemClass 列的值 <> itemid
		select @detailid=(select fnext from t_identity where fname='t_itemdetail')
		print '向 t_itemdetail 插入 detailid=' + convert(varchar, @detailid) + ', f' 
			+ convert(varchar, @ItemClassID2) + '=' + convert(varchar, @itemid2)
		set @sqlString = 'insert into t_itemdetail(fdetailid, fdetailcount, f' 
			+ convert(varchar, @ItemClassID2) + ') values (@detailid,1,@itemid)'
		execute sp_executesql @sqlString
			, N'@detailid int, @itemid int'
			, @detailid, @itemid2
		if @@error<>0 
		begin
			set @ret_value='插入横表失败(t_itemdetail)'
			goto fail
		end
		print '向 t_itemdetailv 插入 detailid=' + convert(varchar, @detailid) + ', f' 
			+ convert(varchar, @ItemClassID2) + '=' + convert(varchar, @itemid2)
		insert into t_itemdetailv values (@detailid,@ItemClassID2,@itemid2)
		if @@error<>0 
		begin
			set @ret_value='插入纵表失败(t_itemdetailv)'
			goto fail
		end
	end
end
else -- detailcount >=2 的情况
begin
	-- 同时按“单位”和“项目”进行核算时
	set @sqlString = N'select @recCount = Count(1) from t_itemdetail where fdetailcount=2 and f' 
		+ convert(varchar, @ItemClassID2) + ' = @itemid2 and f' 
		+ convert(varchar, @ItemClassID3) + ' = @itemid3'
	execute sp_executesql @sqlString
		, N'@recCount int output, @itemid2 int, @itemid3 int'
		, @recCount output, @itemid2, @itemid3
	if (@recCount > 0)
	begin
		-- t_itemdetail 表中的 ItemClassI 列的值 = itemid
		set @sqlString = N'select @detailid = fdetailid from t_itemdetail where fdetailcount = 2 and f' 
			+ convert(varchar, @ItemClassID2) + ' = @itemid2 and f' 
			+ convert(varchar, @ItemClassID3) + ' = @itemid3'
		execute sp_executesql @sqlString
			, N'@detailid int output, @itemid2 int, @itemid3 int'
			, @detailid output, @itemid2, @itemid3
		print '获取 detailid=' + convert(varchar, @detailid)
	end
	else
	begin
		-- t_itemdetail 表中的 ItemClass 列的值 <> itemid
		select @detailid=(select fnext from t_identity where fname='t_itemdetail')
		print '向 t_itemdetail 插入 detailid=' + convert(varchar, @detailid) 
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
			set @ret_value='插入横表失败(t_itemdetail)'
			goto fail
		end
		print '向 t_itemdetailv 插入 detailid=' + convert(varchar, @detailid) 
			+ ', ItemClassID=' + convert(varchar, @ItemClassID2) + ', itemid=' + convert(varchar, @itemid2) 
		print '向 t_itemdetailv 插入 detailid=' + convert(varchar, @detailid) 
			+ ', ItemClassID=' + convert(varchar, @ItemClassID3) + ', itemid=' + convert(varchar, @itemid3)
		INSERT into t_itemdetailv Values (@detailid, @ItemClassID2, @itemid2)
		INSERT into t_itemdetailv VALUES (@detailid, @ItemClassID3, @itemid3)
		if @@error<>0 
		begin
			set @ret_value='插入纵表失败(t_itemdetailv)'
			goto fail
		end
	end
end
----------------------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------------------
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
	print '插入分录头:' 
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
print '插入分录：voucherid=' + convert(varchar, @voucherid)
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
-- 设置对方科目
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

