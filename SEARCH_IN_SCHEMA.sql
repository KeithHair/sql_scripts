-- Each given variable will narrow the results.
DECLARE @FindColumnNameLike varchar(70)=''					
DECLARE @FindTableNameLike varchar(70)=''
DECLARE @FindDataType varchar(70)=''
DECLARE @FindSchemaName varchar(70)=''
DECLARE @MinCharLen int=0
DECLARE @MaxCharLen int=0
DECLARE @IsNullable varchar(3)='' -- yes or no
DECLARE @ShowConstraints varchar(3)='yes' -- yes or no
DECLARE @FindConstraintLike varchar(70)='' -- @ShowContraint must be 'yes'

IF OBJECT_ID('tempdb.dbo.#tmp1','U') IS NOT NULL
	DROP TABLE #tmp1;

SELECT 
	(c.TABLE_CATALOG+'.'+c.TABLE_SCHEMA+'.'+c.TABLE_NAME)		AS 'TableName',
	c.COLUMN_NAME												AS 'ColumnName',
	c.DATA_TYPE													AS 'DataType',
	c.CHARACTER_MAXIMUM_LENGTH									AS 'MaxCharLength',
	c.IS_NULLABLE												AS 'IsNullable',
	CASE WHEN @ShowConstraints = 'yes' THEN
		(select top 1 u.CONSTRAINT_NAME from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE u
		where (u.TABLE_CATALOG+'.'+u.TABLE_SCHEMA+'.'+u.TABLE_NAME+'.'+c.COLUMN_NAME) = (c.TABLE_CATALOG+'.'+c.TABLE_SCHEMA+'.'+c.TABLE_NAME+'.'+u.COLUMN_NAME)
		and	(u.CONSTRAINT_NAME LIKE '%'+@FindConstraintLike+'%'))
	ELSE '----'
	END															AS 'ConstraintName'

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


