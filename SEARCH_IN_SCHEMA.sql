-- Each given variable will narrow the results.
DECLARE @FindColumnNameLike varchar(70)=''					
DECLARE @FindTableNameLike varchar(70)=''
DECLARE @FindDataType varchar(70)=''
DECLARE @FindSchemaName varchar(70)=''
DECLARE @MinCharLen int=0
DECLARE @MaxCharLen int=0
DECLARE @IsNullable varchar(3)='' -- yes or no

SELECT
	TABLE_CATALOG+'.'+TABLE_SCHEMA+'.'+	TABLE_NAME			AS 'TableName',
	COLUMN_NAME												AS 'ColumnName',
	DATA_TYPE												AS 'DataType',
	CHARACTER_MAXIMUM_LENGTH								AS 'MaxCharLength',
	IS_NULLABLE												AS 'IsNullable'
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
