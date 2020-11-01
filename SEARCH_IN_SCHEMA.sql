-- Each given variable will narrow the results.
DECLARE @FindColumnNameLike varchar(70)='name'					
DECLARE @FindTableNameLike varchar(70)=''
DECLARE @FindDataType varchar(70)=''
DECLARE @FindSchemaName varchar(70)=''
DECLARE @MinCharLen int=0
DECLARE @MaxCharLen int=0
DECLARE @IsNullable varchar(3)=''					-- yes or no
DECLARE @ShowConstraints varchar(3)='yes'			-- yes or no
DECLARE @FindConstraintLike varchar(70)=''			-- @ShowContraint must be 'yes'
DECLARE @FindColumnValue sysname = 'summer'		--If blank ColumnValue column is exclude in results.



IF OBJECT_ID('tempdb.dbo.#tmp1','U') IS NOT NULL
	DROP TABLE #tmp1;
IF OBJECT_ID('tempdb.dbo.#tmp2','U') IS NOT NULL
	DROP TABLE #tmp2;

SELECT 
	('['+c.TABLE_CATALOG+'].['+c.TABLE_SCHEMA+'].['+c.TABLE_NAME+']')		AS 'TableName',
	c.COLUMN_NAME												AS 'ColumnName',
	c.DATA_TYPE													AS 'DataType',
	c.CHARACTER_MAXIMUM_LENGTH									AS 'MaxCharLength',
	c.IS_NULLABLE												AS 'IsNullable',
	CASE WHEN @ShowConstraints = 'yes' THEN
		(select top 1 u.CONSTRAINT_NAME from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE u
		where ('['+u.TABLE_CATALOG+'].['+u.TABLE_SCHEMA+'].['+u.TABLE_NAME+'].['+c.COLUMN_NAME+']') = ('['+c.TABLE_CATALOG+'].['+c.TABLE_SCHEMA+'].['+c.TABLE_NAME+'].['+u.COLUMN_NAME+']')
		and	(u.CONSTRAINT_NAME LIKE '%'+@FindConstraintLike+'%'))
	ELSE '----'
	END															AS 'ConstraintName'
INTO #tmp1
FROM INFORMATION_SCHEMA.COLUMNS c


WHERE
	(c.COLUMN_NAME LIKE '%'+@FindColumnNameLike+'%')
	AND
	(c.TABLE_NAME LIKE '%'+@FindTableNameLike+'%')
	AND
	(c.DATA_TYPE = @FindDataType OR @FindDataType='')
	AND
	(c.TABLE_SCHEMA = @FindSchemaName OR @FindSchemaName='')
	AND
	((c.CHARACTER_MAXIMUM_LENGTH BETWEEN @MinCharLen AND @MaxCharLen)
	  OR (@MinCharLen=0 AND @MaxCharLen=0))
	AND
	(c.IS_NULLABLE = @IsNullable OR @IsNullable='')

--SELECT * FROM #tmp1
--===================================

CREATE TABLE #tmp2
(
	TableName varchar(100),
	ColumnName varchar(100),
	DataType varchar(100),
	MaxCharLength int,
	IsNullable varchar(3),
	ConstraintName varchar(100),
	ColumnValue nvarchar(1000)
)
DECLARE
@TableName varchar(100),
@ColumnName varchar(100),
@DataType varchar(100),
@MaxCharLength int,
@Nullable varchar(3),
@ConstraintName varchar(100),
@ColumnValue nvarchar(1000)

DECLARE @sQry nvarchar(200)
IF CURSOR_STATUS('global','cursor1')>=-1
BEGIN
	CLOSE cursor1
	DEALLOCATE cursor1
END
DECLARE cursor1 CURSOR FOR
	SELECT TableName, ColumnName, DataType, MaxCharLength, IsNullable, ConstraintName FROM #tmp1
OPEN cursor1
FETCH NEXT FROM cursor1 INTO @TableName, @ColumnName, @DataType, @MaxCharLength, @Nullable, @ConstraintName
WHILE (@@FETCH_STATUS = 0)
BEGIN
	SET @ColumnValue = NULL
	IF @FindColumnValue <> ''
	BEGIN
		IF @DataType IN ('varchar', 'char', 'text','nvarchar', 'nchar', 'ntext')
		BEGIN
			SET @sQry = N'(SELECT TOP 1 @ColumnValue=['+@ColumnName+'] FROM '+@TableName+' WHERE ['+@ColumnName+'] LIKE ''%'+@FindColumnValue+'%'')'	
			EXEC sp_executesql @sQry, N'@ColumnValue nvarchar(1000) OUTPUT', @ColumnValue OUTPUT;
			IF @ColumnValue IS NOT NULL
			BEGIN
				INSERT INTO #tmp2
				(TableName, ColumnName, DataType, MaxCharLength, IsNullable, ConstraintName, ColumnValue)
				VALUES
				(@TableName, @ColumnName, @DataType, @MaxCharLength, @Nullable, @ConstraintName, @ColumnValue)
			END
		END
		IF CAST(SQL_VARIANT_PROPERTY(@FindColumnValue,'BaseType') AS varchar(20))  = 'int'
		BEGIN
			SET @sQry = N'(SELECT TOP 1 @ColumnValue=['+@ColumnName+'] FROM '+@TableName+' WHERE ['+@ColumnName+'] = '+@FindColumnValue+')'	
			EXEC sp_executesql @sQry, N'@ColumnValue nvarchar(1000) OUTPUT', @ColumnValue OUTPUT;
			IF @ColumnValue IS NOT NULL
			BEGIN
				INSERT INTO #tmp2
				(TableName, ColumnName, DataType, MaxCharLength, IsNullable, ConstraintName, ColumnValue)
				VALUES
				(@TableName, @ColumnName, @DataType, @MaxCharLength, @Nullable, @ConstraintName, @ColumnValue)
			END
		END
	END
	ELSE
		
		INSERT INTO #tmp2
		(TableName, ColumnName, DataType, MaxCharLength, IsNullable, ConstraintName, ColumnValue)
		VALUES
		(@TableName, @ColumnName, @DataType, @MaxCharLength, @Nullable, @ConstraintName, @ColumnValue);
				
FETCH NEXT FROM cursor1 INTO @TableName, @ColumnName, @DataType, @MaxCharLength, @Nullable, @ConstraintName
END
CLOSE cursor1
DEALLOCATE cursor1

IF @FindColumnValue = ''
BEGIN
	SELECT TableName, ColumnName, DataType, MaxCharLength, IsNullable, ConstraintName FROM #tmp2
END
ELSE
	SELECT * FROM #tmp2
