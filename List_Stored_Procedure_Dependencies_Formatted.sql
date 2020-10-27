DECLARE @ProcName varchar(70) = 'YourProcName'
DECLARE @SearchDatabase varchar(70) = 'YourDatabaseName'	-- Current database will be searched if not given.
DECLARE @SearchSchema varchar(70) = 'dbo'	-- Default schema will be searched if not given.

SET @SearchDatabase = IIF(LEN(@SearchDatabase) = 0, DB_NAME(),@SearchDatabase)
SET @SearchSchema = IIF(LEN(@SearchSchema) = 0, SCHEMA_NAME(),@SearchSchema)
DECLARE @sql nvarchar(4000) = ''
SET @sql = '
USE '+@SearchDatabase+'

SET NOCOUNT ON

DECLARE @str nvarchar(4000) = ''''
DROP TABLE IF EXISTS #strTable
CREATE TABLE #strTable(
	[Result] [varchar](2000) NULL
)

IF CURSOR_STATUS(''global'',''cursor1'') >= -1
BEGIN
	CLOSE cursor1
	DEALLOCATE cursor1
END

DECLARE cursor1 CURSOR FOR	

	SELECT
	SCHEMA_NAME(o.SCHEMA_ID)								AS ''ProcSchemaName'',
	o.name													AS ''AnalyzedProcName'',
	COALESCE(referenced_database_name,DB_NAME())			AS ''RefedDatabaseName'',
	COALESCE(referenced_schema_name,SCHEMA_NAME())			AS ''RefedSchemaName'',
	referenced_entity_name									AS ''RefedObjectName''
	FROM
	sys.sql_expression_dependencies sed
	INNER JOIN
	sys.objects o ON sed.referencing_id = o.[object_id]
	LEFT OUTER JOIN
	sys.objects o1 ON sed.referenced_id = o1.[object_id]
	WHERE
	o.name = '''+@ProcName+'''
	AND SCHEMA_NAME(o.SCHEMA_ID) = '''+@SearchSchema+'''

DECLARE @ProcSchemaName varchar(70)
DECLARE @AnalyzedProcName varchar(70)
DECLARE @RefedDatabaseName varchar(70)
DECLARE @RefedSchemaName varchar(70)
DECLARE @RefedObjectName varchar(70)

SET @str = @str + ''"'+ @ProcName + '" Dependencies:''
SET @str = @str + CHAR(13)
SET @str = @str + ''===================================================================================''
SET @str = @str + CHAR(13)

OPEN cursor1
FETCH NEXT FROM cursor1 INTO @ProcSchemaName, @AnalyzedProcName, @RefedDatabaseName, @RefedSchemaName, @RefedObjectName
WHILE (@@FETCH_STATUS = 0)
BEGIN
	SET @str = @str + '''' + @RefedDatabaseName + ''.'' + @RefedSchemaName + ''.'' + @RefedObjectName
	SET @str = @str + CHAR(13)

	FETCH NEXT FROM cursor1 INTO @ProcSchemaName, @AnalyzedProcName, @RefedDatabaseName, @RefedSchemaName, @RefedObjectName
END

INSERT INTO #strTable
(Result)
VALUES(@str)

--SELECT * FROM #strTable
PRINT @str
'

-- PRINT @sql
EXEC(@sql)