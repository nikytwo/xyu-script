-- =============================================
-- Create procedure with OUTPUT Parameters
-- =============================================
-- creating the store procedure
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'K_AddUser' 
	   AND 	  type = 'P')
    DROP PROCEDURE K_AddUser
GO

CREATE PROCEDURE K_AddUser 
	@preparername varchar(80),	--用户名称
	@rst varchar(80)  OUTPUT	--返回信息
AS	
	Declare 
		@sqlStr varchar(1000),
		@preparerid int		--用户id
	set @preparerid = 0

	-- 获取/插入用户id
	if exists (select 1 from t_user where fname = @preparername)
	begin
		select @preparerid = FUserID from t_user where fname = @preparername
		set @rst = '已存在用户：' + @preparername + ',其ID为' + convert(varchar, @preparerid)
	end
	else
	begin
		select @preparerid = (Max(FUserID) + 1) from t_User

		if EXISTS (Select 1 from syscolumns c,sysobjects o where c.Id=o.Id and c.name = 'ID' and o.name = 't_user')	
		begin
			-- 13.0版，增加了 ID 列
			set @sqlStr = 'INSERT INTO t_User ('
				+ 'FAuthRight, FDescription, FEmpID, FForbidden, FHRUser, FName, FPrimaryGroup, FPwValidDay, FSafeMode,'
				+ 'FSID, FSSOUsername, FUInValidDate, FUserID, FPwCreateDate,ID) VALUES ('
				+ '4, NULL, 0, 0, 0, ''' + @preparername + ''', 0, 0, 0,'
				+ ''')  F ", ,P T #8 *P!D &D 80!N &@ <0 C ''''< : !M &4 )0 Q #( ,P '',' --默认密码123
				+ ''''',''01-1-1900'',' + convert(varchar,@preparerid) + ',''' 
				+ convert(varchar,getdate()) + ''',''' + CAST(newid() as nvarchar(36)) + ''')'		
			print @sqlStr
			exec (@sqlStr)
		end
		else
		begin
			-- 10.3版
			set @sqlStr = 'INSERT INTO t_User ('
				+ 'FAuthRight, FDescription, FEmpID, FForbidden, FHRUser, FName, FPrimaryGroup, FPwValidDay, FSafeMode,'
				+ 'FSID, FSSOUsername, FUInValidDate, FUserID, FPwCreateDate) VALUES ('
				+ '4, NULL, 0, 0, 0, ''' + @preparername + ''', 0, 0, 0,'
				+ ''')  F ", ,P T #8 *P!D &D 80!N &@ <0 C ''''< : !M &4 )0 Q #( ,P '',' --默认密码123
				+ ''''',''01-1-1900'',' + convert(varchar,@preparerid) + ',''' 
				+ convert(varchar,getdate()) + ''')'		
			print @sqlStr
			exec (@sqlStr)
			/*
			INSERT INTO t_User (
				FAuthRight, FDescription, FEmpID, FForbidden, FHRUser, FName, FPrimaryGroup, FPwValidDay, FSafeMode,
				FSID, FSSOUsername, FUInValidDate, FUserID, FPwCreateDate) VALUES (
				4, NULL, 0, 0, 0, @preparername, 0, 0, 0, 
				')  F ", ,P T #8 *P!D &D 80!N &@ <0 C ''< : !M &4 )0 Q #( ,P ', --默认密码123
				'','01-1-1900', @preparerid, getdate())	
			*/		
		end		
		if (@@error <> 0)
		begin
			set @rst = '无法增加用户[' + @preparername + ']' 
			return -1
		end
		Insert into t_Group (FUserID, FGroupID) Values (@preparerid, 0)
		Insert into t_Group (FUserID, FGroupID) Values (@preparerid, 1)
		set @rst = '已增加用户：' + @preparername + ',其ID为' + convert(varchar, @preparerid)
	end
	print '增加用户[' + @preparername + ']id=' + convert(varchar, @preparerid)

	return @preparerid
GO

