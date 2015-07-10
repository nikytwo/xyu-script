
-- =============================================
-- Create PROCEDURE
-- 增加新科目
-- 只能增加4类，5类科目
-- 对应新镇街系统的存储过程
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'K_AddAccount')
	DROP PROCEDURE K_AddAccount
GO

-- TODO 出错时 事务未提交？
--本存储过程可处理多个核算项目（见@items参数）
CREATE  PROCEDURE K_AddAccount(
	@accountnum varchar(80),  	--科目编码(如：501.01)
	@accountname varchar(255),  	--科目名称（如：基本支出）
	@dc int,      			--借贷方向(1=借方，-1=贷方)
	@level int,      		--级别（501.01 为 2级）
	@detail int,      		--是否最明细（0=否，1=是）

	--多个核算项目，没有请留空，
	--格式：ItemClassID1@@ItemID1__&&ItemClassID2@@ItemID2__&&ItemClassIDn@@ItemIDn__,
	--如:3001@@-1__&&3002@@-1__&&3003@@-1__（-1是会计科目挂载时用的，核算项目挂载到凭证时，ItemID应大于0）
	@items varchar(100),	
	@rst varchar(80) OUTPUT		--返回信息
)
AS
declare @rootid int,
	@accountid int,      	--科目id
	@detailidt int,
	@parentid int,
	@cha int,
	@tnum varchar(80)
  
--BEGIN TRANSACTION TRAN_AddAccount
	print convert(varchar, @@TRANCOUNT)
	print 'BEGIN TRANSACTION TRAN_AddAccount'
 	
	if exists (select 1 from t_account where fnumber = @accountnum)
	begin
		set @rst = '科目[' + @accountnum + ']已存在。'
		select @accountid = faccountid from t_account where fnumber = @accountnum
	end
	else
	begin		
		set @rst = '';
		select @accountid = fnext from t_identity where fname='t_account'
		
		if @level<>1
		begin
			-- 非一级科目
			-- 根据"."来获取上级科目
			set @cha = len(@accountnum) - charindex('.', reverse(@accountnum))
			set @tnum = substring(@accountnum,1,@cha) --上级科目
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

		if isnull(@rootid, -1) >= 0 
		begin
			-- 存在上级科目的
			declare 
				@recCount int,	--
				@index int,	--
				@itemCount int,	--新科目有多少辅助核算项目
				@tmpItemClassID varchar(20),	--辅助核算项目ID（临时变量）
				@sqlString nvarchar(1000),
				@sqlStr2 nvarchar(1000)
		
			exec @detailidt = K_GetSetItemDetailID @items, @rst out

			if (isnull(@dc,0) <> 1 or isnull(@dc,0) <> -1)
			begin
				if (charindex('5',@accountnum) = 1 or charindex('1',@accountnum) = 1)
				begin
					set @dc = 1
				end
				else
				begin
					set @dc = -1
				end
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
			if (@@error<>0) 
			begin
				set @rst = '向表t_Account插入新科目失败。' + @accountnum + ',' + @accountname + ',' + @level + ',' + @detail
				goto fail			
			end
		end 
		else
		begin
			set @rst = '科目[' + @accountnum + ']的上级科目不存在。'
			set @accountid = 0;
		end
	end
  
	print 'COMMIT TRANSACTION TRAN_AddAccount'
--COMMIT TRANSACTION TRAN_AddAccount
	print convert(varchar, @@TRANCOUNT)
return @accountid 

fail:
	print 'ROLLBACK TRANSACTION TRAN_AddAccount'
--ROLLBACK TRANSACTION 
	print convert(varchar, @@TRANCOUNT)
return -1
