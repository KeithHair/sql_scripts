/*===============================================================
Finds all tables with columns that have similar names
to the output columns of a given stored procedure.

Indicates "YES" if the datatypes of the compared columns match and "NO" if they don't.
================================================================*/
declare @SP_To_Check nvarchar(70) = '<yourStoreProcedureName>'

-- Gather records for stored procedure output columns
DECLARE @SP_OutputColumns TABLE
(
   [stored_procedure_name] nvarchar(100)
  ,[column_name] nvarchar(100)
  ,[name_and_type] nvarchar(100)
)
-- Gather records for table columns
DECLARE @Table_Columns TABLE
(
   [table_name] nvarchar(100)
  ,[column_name] nvarchar(100)
  ,[name_and_type] nvarchar(100)
)

-- The display table
DECLARE @Info TABLE
(
   [stored_procedure_name] nvarchar(100)
  ,[sp_column_name] nvarchar(100)
  ,[sp_column_type] nvarchar(20)
  
  ,[table_name] nvarchar(100)
  ,[table_column_name] nvarchar(100)
  ,[table_column_type] nvarchar(20)
)


-- Populate store procedure table
insert into @SP_OutputColumns
select
@SP_To_Check as 'stored_procedure_name',
name as 'column_name',
concat(name,' ',system_type_name) as 'name_and_type'
from sys.dm_exec_describe_first_result_set_for_object
(
  OBJECT_ID(@SP_To_Check), 
  NULL
);

-- Populate column table
insert into @Table_Columns
select
   'table' =  concat(TABLE_SCHEMA,'.',TABLE_NAME,'.',COLUMN_NAME),
   'column_name' = COLUMN_NAME,
   'name_and_type' =
   case
		when DATA_TYPE = 'datetime' or DATA_TYPE = 'money' then
   			concat(COLUMN_NAME,' ',DATA_TYPE)
		when NUMERIC_PRECISION is not null and NUMERIC_SCALE > 0 then
			concat(COLUMN_NAME,' ',DATA_TYPE,'(',NUMERIC_PRECISION,',',NUMERIC_SCALE,')')       
		when DATA_TYPE like '%char%' then
   			concat(COLUMN_NAME,' ',DATA_TYPE,'(',CHARACTER_MAXIMUM_LENGTH,')')
		else   
			concat(COLUMN_NAME,' ',DATA_TYPE)
   end
from INFORMATION_SCHEMA.COLUMNS


-- Display the information
select

	sc.stored_procedure_name as 'Stored Procedure',
	sc.name_and_type as 'SP Column and Type',

	tc.table_name as 'Table',
	tc.name_and_type as 'Table Column and Type',

	case
		when tc.name_and_type = sc.name_and_type then 'YES'
		else 'NO'
	end as 'DataTypes Match?'

from @SP_OutputColumns sc
join @Table_Columns tc on tc.column_name like '%'+sc.column_name+'%'


