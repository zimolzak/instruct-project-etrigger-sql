
-----------------------------
----                     ----
---   Trigger - FOBT   ---
----                     ----
-----------------------------


-- Set study parameters.
-----------------------
use master

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_0_1_inputP]') is not null)	    --altered (ORD_...Dflt)
	begin
		--Only one row (current running parameter) in this table
		delete from [MyDB].[MySchema].FOBT_0_1_inputP    --altered (ORD_...Dflt)
	end
	else
	begin	
		CREATE TABLE [MyDB].[MySchema].FOBT_0_1_inputP(    --altered (ORD_...Dflt)
		[trigger] [varchar](20) NULL,
		[VISN] [smallint] NULL,		 
		Sta3n smallint null,
		[round] [varchar](8) NULL,
		[run_dt] [datetime] NULL,
		[sp_start] [datetime] NULL,
		[sp_end] [datetime] NULL,
		[fu_period] [smallint] NULL,
		[age_Lower] [smallint] NULL,
		[age_upper] [smallint] NULL,
		[op_grp] [varchar](4) NULL)
	end

go

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_0_1_run_count]') is null)  -- never delete, alwasys append    --altered (ORD_...Dflt)
	begin
		CREATE TABLE [MyDB].[MySchema].FOBT_0_1_run_count(    --altered (ORD_...Dflt)
		[trigger] [varchar](20) NULL,
		[round] [smallint] Not NULL default 0,
		[VISN] [smallint] NULL,
		Sta3n smallint null,
		[run_dt] [datetime] NULL,
		[sp_start] [datetime] NULL,
		[sp_end] [datetime] NULL,
		[fu_period] [smallint] NULL,
		[age_lower] [smallint] NULL,
		[age_upper] [smallint] NULL,
		[op_grp] [varchar](4) NULL,
		[init_ins] [int] NULL,
		[prev_lc_excl] [int] NULL,
		[term_excl] [int] NULL,
		hospi_excl int null,
		[tuber_excl] [int] NULL,
		[pulm_ref_excl] [int] NULL,  
		[pulm_ref_OutCome] [int] NULL,       
		[lung_proc] [int] NULL,
		[rep_img] [int] NULL,
		[trig_pos_pts] [int] NULL)		
	end

go



declare @trigger varchar(20)
declare @VISN smallint
declare @Sta3n smallint
DECLARE @round smallint
declare @run_date datetime
declare @sp_start datetime
declare @sp_end datetime
declare @fu_period as smallint
declare @age_lower as smallint
declare @age_upper as smallint
DECLARE @op_grp varchar(4)


set @trigger='FOBT'
set @VISN=12
--set @Sta3n=580 -- -1 all sta3n
set @run_date=getdate()
set @sp_start='2012-01-01 00:00:00'
set @sp_end='2012-12-31 23:59:59'
--  Follow-up period
set @fu_period=60
set @age_lower=40
set @age_upper=75


set @op_grp='C'
set @round= ( case when (select count(*) from [MyDB].[MySchema].[FOBT_0_1_run_count])>0    --altered (ORD_...Dflt)
				then (select max(round)+1 from [MyDB].[MySchema].[FOBT_0_1_run_count])    --altered (ORD_...Dflt)
			else 1
			end)


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_0_1_inputPVISN]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].[FOBT_0_1_inputPVISN]    --altered (ORD_...Dflt)

select distinct sta3n into [MyDB].[MySchema].[FOBT_0_1_inputPVISN]    --altered (ORD_...Dflt)
from cdwwork.dim.vistasite where VISN=@VISN 
--and sta3n<>556

INSERT INTO [MyDB].[MySchema].[FOBT_0_1_inputP]    --altered (ORD_...Dflt)
           ([trigger]
		   ,[VISN]
		   ,Sta3n
           ,[round]
           ,[run_dt]
           ,[sp_start]
           ,[sp_end]
           ,[fu_period]
           ,[age_lower]
		   ,[age_upper]
           ,[op_grp])
     VALUES
           (
           @trigger
		   ,@VISN
		   ,@Sta3n
           ,@round
		   ,@run_date
           ,@sp_start
           ,@sp_end
           ,@fu_period
           ,@age_lower
		   ,@age_upper
           ,@op_grp)


go

select * from [MyDB].[MySchema].[FOBT_0_1_inputP]    --altered (ORD_...Dflt)

INSERT INTO [MyDB].[MySchema].[FOBT_0_1_run_count]    --altered (ORD_...Dflt)
           ([trigger]
		   ,[VISN]
		   ,Sta3n
           ,[round]
           ,[run_dt]
           ,[sp_start]
           ,[sp_end]
           ,[fu_period]
           ,[age_lower]
		   ,[age_upper]
           ,[op_grp]
           ,[init_ins]
           ,[prev_lc_excl]
           ,[term_excl]
		   ,hospi_excl
           ,[tuber_excl]
           ,[pulm_ref_excl]
           ,[pulm_ref_OutCome]
           ,[lung_proc]
           ,[rep_img]
           ,[trig_pos_pts])
		   select 
		   [trigger]
		   ,[VISN]
		   ,Sta3n
           ,[round]
           ,[run_dt]
           ,[sp_start]
           ,[sp_end]
           ,[fu_period]
           ,[age_lower]
		   ,[age_upper]
           ,[op_grp] 
				  ,null
				  ,null
				  ,null
				  ,null
				  ,null
				  ,null
				  ,null
				  ,null
				  ,null
				  ,null
		 from [MyDB].[MySchema].[FOBT_0_1_inputP] as Input    --altered (ORD_...Dflt)

go



if (OBJECT_ID('[MyDB].[MySchema].FOBT_0_2_DxICD10CodeExc') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_0_2_DxICD10CodeExc    --altered (ORD_...Dflt)
go


	CREATE TABLE [MyDB].[MySchema].FOBT_0_2_DxICD10CodeExc (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go




insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.6'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.7'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.5'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.9'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C19.'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C20.'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C21.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C21.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C21.8'



insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.00'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.40'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.50'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.01'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.41'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.51'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.02'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.42'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.52'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C93.00'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C93.01'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C93.02'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.00'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.01'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.02'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.20'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.21'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.22'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C95.00'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C95.01'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C95.02'



insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.3'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.7'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.9'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C78.7'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C23.'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.9'


insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.3'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.5'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.9'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.3'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.5'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.6'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.9'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.3'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.5'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.6'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.7'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.9'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C79.31'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C79.32'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C79.49'
--insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Brain Cancer', 'C79.40'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Ovarian Cancer','C56.9'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Ovarian Cancer','C56.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Ovarian Cancer','C56.2'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.3'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.7'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.9'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C33.'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.00'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.01'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.02'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.10'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.11'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.12'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.30'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.31'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.32'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.80'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.81'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.82'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.90'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.91'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.92'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C78.00'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C78.01'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C78.02'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pleural Cancer & Mesothelioma','C38.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pleural Cancer & Mesothelioma','C45.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pleural Cancer & Mesothelioma','C78.2'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Uterine Cancer','C55.'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C45.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C78.6'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','C90.00'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','C90.01'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','C90.02'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','D47.Z9'

--insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Tracheal Cancer','C33'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Tracheal Cancer','C33.'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Tracheal Cancer','C78.39'
--insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Tracheal Cancer','C78.30'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Hospice','','Z51.5'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K92.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K22.11'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K25.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K25.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K25.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K25.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K25.6'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K26.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K26.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K26.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K26.6'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K27.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K27.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K27.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K27.6'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K28.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K28.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K28.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K28.6'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'I85.01'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'I85.11'


insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N92.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N92.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N92.4'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N95.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R31.9'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R31.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R31.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R31.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R04.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N89.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N92.5'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N93.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R04.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R04.9'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R04.89'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','T79.2XXA'

insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','Z34.00'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','Z34.80'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','Z34.90'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','Z33.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.00'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.10'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.291'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.40'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.211'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.291'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.291'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.30'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.511'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.521'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.611'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.621'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.891'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.892'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.893'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.899'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.90'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.91'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.92'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.93'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.8'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.9'


insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemic','','D56.9'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemic','','D57.40'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemic','','D57.419'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemic','','D56.0'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemic','','D56.1'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemic','','D56.2'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemic','','D56.3'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemic','','D56.5'
insert into [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemic','','D56.8'




if (OBJECT_ID('[MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc]    --altered (ORD_...Dflt)
go

	CREATE TABLE [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[ICD10Proc_code_type] [varchar](50) NULL,
	[ICD10Proc_code_Name] [varchar](50) NULL,
	[ICD10ProcCode] [varchar](10) NULL
	) 
go


insert into [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','0DTE4ZZ'
insert into [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','0DTE0ZZ'
insert into [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','0DTE7ZZ'
insert into [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','0DTE8ZZ'

insert into [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 'Colonoscopy','','0DJD8ZZ'



if (OBJECT_ID('[MyDB].[MySchema].FOBT_0_4_DxICD9CodeExc') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_0_4_DxICD9CodeExc    --altered (ORD_...Dflt)
go


	CREATE TABLE [MyDB].[MySchema].FOBT_0_4_DxICD9CodeExc (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go

insert into  [MyDB].[MySchema].FOBT_0_4_DxICD9CodeExc (    --altered (ORD_...Dflt)
	[ICD9Code]
	) 
select distinct ICD9Code from CDWWork.dim.ICD9 as dimICD9
where	
			-------------------------------------------------------- Previous Colorectal Cancer
			-- Move to ProblemList
			---- Colon Cancer Codes
			--	'154.0','154.1','154.8',
			-------------------------------------------------------- Terminal
			dimICD9.ICD9Code in (

			-- Leukemia (Acute Only)
				'205.0','206.0','207.0','208.0',
				--	'204.1','204.2','204.8','204.9','205.1','205.2','205.3','205.8','205.9','206.1',
				--	'206.2','206.8','206.9','207.1','207.2','207.8','208.1','208.2','208.8','208.9',
				
			-- Hepatocelllular Cancer
				'155.0','155.1','155.2','197.7',
			-- Biliary Cancer
			-- Esophageal Cancer
			-- Gastric Cancer
			-- Brain Cancer
				'191.0','191.1','191.2','191.3','191.4','191.5','191.6','191.7','191.8','191.9','198.3','198.4',
			-- Ovarian Cancer
				'183.0',
			-- Pancreatic Cancer
			-- Lung Cancer
				'162.1','162.2','162.3','162.4','162.5','162.6','162.7','162.8','162.9','197.0',
			-- Pleural Cancer & Mesothelioma
				 '197.2',
			-- Uterine Cancer
			--Peritonel, Omental & Mesenteric Cancer
				'158.8','158.9','197.6',
			--Myeloma
				'238.6',
			--Tracheal Cancer
				'162.0','197.3',		
			-------------------------------------------------------- Hospice / Palliative Care
			-- Hospice / Palliative Care
				'V66.7',
			-------------------------------------------------------- Evidence of Upper Bleeding
			-- Hematamesis
				'578.0',
			-- Ulcer of Esophagus,stomach or duodenum with Bleeding		
				'530.21',
			-- Esophageal Varices with Bleeding
				'456.0','456.20',
			----------------------------------------------------------- Only IDA only--------------------------
			-------------------------------------------------------- Other bleeding 
			-- Hematuria		
			-- Menorrhagia
				'626.2','626.6','627.0','627.1',
			-- Epistaxis
				'784.7',
			-- Uterine, cervical or Vaginal Bleeding
				'623.8','626.8',
			-- Hemoptysis
				'786.3' ,
			--Second Hemorrhage
				'958.2',
			----------------------------------------------------------- Thalessemia
			-- Thalessemia	    
			----------------------------------------------------------- Pregnancy
			-- Pregnancy
				'V22.0','V22.1','V22.2','V23.0','V23.1','V23.2',
				'V23.3','V23.41','V23.49','V23.5','V23.7','V23.81',
				'V23.82','V23.83','V23.84','V23.89','V23.9'
		)
			-------------------------------------------------------- Previous Colorectal Cancer
		--or ICD9.ICD9Code like
		---- Colon Cancer Codes
		--	'153.%'			
			-------------------------------------------------------- Terminal				
		or dimICD9.ICD9Code like
		-- Leukemia (Acute Only)
			'207.2%'
		-- Hepatocelllular Cancer

		or dimICD9.ICD9Code like
		-- Biliary Cancer
			'156.%'
		or dimICD9.ICD9Code like
		-- Esophageal Cancer
			'150.%'
		or dimICD9.ICD9Code like
		-- Gastric Cancer
			'151.%'
		-- Brain Cancer
		-- Ovarian Cancer
		or dimICD9.ICD9Code like
		-- Pancreatic Cancer
			'157.%'
		-- Lung Cancer			
		or dimICD9.ICD9Code like
		-- Pleural Cancer & Mesothelioma
				'163.%'
		or dimICD9.ICD9Code like
		--Uterine Cancer
				'179.%'
		--Peritonel, Omental & Mesenteric Cancer
		or dimICD9.ICD9Code like
		--Myeloma
				'203.0%'
		--Tracheal Cancer
			-------------------------------------------------------- Hospice / Palliative Care
		-- Hospice / Palliative Care
			-------------------------------------------------------- Evidence of Upper Bleeding
		-- Hematamesis		
		-- Ulcer of Esophagus,stomach or duodenum with Bleeding		
		or dimICD9.ICD9Code like '531.0%' or dimICD9.ICD9Code like '531.2%' or dimICD9.ICD9Code like '531.4%' or dimICD9.ICD9Code like '531.6%'
		or dimICD9.ICD9Code like '532.0%' or dimICD9.ICD9Code like '532.2%' or dimICD9.ICD9Code like '532.4%' or dimICD9.ICD9Code like '532.6%'
		or dimICD9.ICD9Code like '533.0%' or dimICD9.ICD9Code like '533.2%' or dimICD9.ICD9Code like '533.4%' or dimICD9.ICD9Code like '533.6%'
		or dimICD9.ICD9Code like '534.0%' or dimICD9.ICD9Code like '534.2%' or dimICD9.ICD9Code like '534.4%' or dimICD9.ICD9Code like '534.6%'
		-- Esophageal Varices with Bleeding		
			----------------------------------------------------------- Only IDA only--------------------------
			-------------------------------------------------------- Other bleeding source			
		or dimICD9.ICD9Code like
		-- Hematuria
			'599.7%'
		-- Menorrhagia
		-- Epistaxis	
		-- Uterine, cervical or Vaginal Bleeding	
		or dimICD9.ICD9Code like
		-- Hemoptysis
			'786.3%' 
		--Second Hemorrhage
			----------------------------------------------------------- Thalessemia
    	or dimICD9.ICD9Code like
		-- Thalessemia
			'282.4%'
			----------------------------------------------------------- Pregnancy
		-- Pregnancy


update [MyDB].[MySchema].FOBT_0_4_DxICD9CodeExc    --altered (ORD_...Dflt)
set   dx_code_type = case
		--when 
		--	ICD9Code in (
		--		-- Colon Cancer Codes
		--			'154.0','154.1','154.8') or ICD9Code like '153.%'			
		--	then 'Colon/Rectal Cancer'
		when ICD9Code in (
			-- Leukemia (Acute Only)
				'205.0','206.0','207.0','208.0',
				--	'204.1','204.2','204.8','204.9','205.1','205.2','205.3','205.8','205.9','206.1',
				--	'206.2','206.8','206.9','207.1','207.2','207.8','208.1','208.2','208.8','208.9',
			-- Hepatocelllular Cancer
				'155.0','155.1','155.2','197.7',
			-- Biliary Cancer
			-- Esophageal Cancer
			-- Gastric Cancer
			-- Brain Cancer
				'191.0','191.1','191.2','191.3','191.4','191.5','191.6','191.7','191.8','191.9','198.3','198.4',
			-- Ovarian Cancer
				'183.0',
			-- Pancreatic Cancer
			-- Lung Cancer
				'162.1','162.2','162.3','162.4','162.5','162.6','162.7','162.8','162.9','197.0',
			-- Pleural Cancer & Mesothelioma
				 '197.2',
			-- Uterine Cancer
			--Peritonel, Omental & Mesenteric Cancer
				'158.8','158.9','197.6',
			--Myeloma
				'238.6',
			--Tracheal Cancer
				'162.0','197.3') 
							or ICD9Code like
							-- Leukemia (Acute Only)
								'207.2%'
							-- Hepatocelllular Cancer

							or ICD9Code like
							-- Biliary Cancer
								'156.%'
							or ICD9Code like
							-- Esophageal Cancer
								'150.%'
							or ICD9Code like
							-- Gastric Cancer
								'151.%'
							-- Brain Cancer
							-- Ovarian Cancer
							or ICD9Code like
							-- Pancreatic Cancer
								'157.%'
							-- Lung Cancer			
							or ICD9Code like
							-- Pleural Cancer & Mesothelioma
									'163.%'
							or ICD9Code like
							--Uterine Cancer
									'179.%'
							--Peritonel, Omental & Mesenteric Cancer
							or ICD9Code like
							--Myeloma
									'203.0%'
							--Tracheal Cancer
			 then 'Terminal'
		when ICD9Code in (
				-- Hospice / Palliative Care
					'V66.7'
			) then 'Hospice'
		when ICD9Code in (
			-- Hematamesis
				'578.0',
			-- Ulcer of Esophagus,stomach or duodenum with Bleeding		
				'530.21',
			-- Esophageal Varices with Bleeding
				'456.0','456.20')
						-- Hematamesis		
						-- Ulcer of Esophagus,stomach or duodenum with Bleeding		
						or ICD9Code like '531.0%' or ICD9Code like '531.2%' or ICD9Code like '531.4%' or ICD9Code like '531.6%'
						or ICD9Code like '532.0%' or ICD9Code like '532.2%' or ICD9Code like '532.4%' or ICD9Code like '532.6%'
						or ICD9Code like '533.0%' or ICD9Code like '533.2%' or ICD9Code like '533.4%' or ICD9Code like '533.6%'
						or ICD9Code like '534.0%' or ICD9Code like '534.2%' or ICD9Code like '534.4%' or ICD9Code like '534.6%'
			 then 'Upper GI Bleed'
		when ICD9Code in (
			-- Hematuria		
			-- Menorrhagia
				'626.2','626.6','627.0','627.1',
			-- Epistaxis
				'784.7',
			-- Uterine, cervical or Vaginal Bleeding
				'623.8','626.8',
			-- Hemoptysis
				'786.3' ,
			--Second Hemorrhage
				'958.2')
						or ICD9Code like
						-- Hematuria
							'599.7%'
						-- Menorrhagia
						-- Epistaxis	
						-- Uterine, cervical or Vaginal Bleeding	
						or ICD9Code like
						-- Hemoptysis
							'786.3%' 
						--Second Hemorrhage
			 then 'Other Bleeding'
		when ICD9Code in (
			-- Pregnancy
				'V22.0','V22.1','V22.2','V23.0','V23.1','V23.2',
				'V23.3','V23.41','V23.49','V23.5','V23.7','V23.81',
				'V23.82','V23.83','V23.84','V23.89','V23.9'
			) then 'Pregnancy'
		when ICD9Code like 
				-- Thalasemia
				'282.4%'
			 then 'Thalassemia'
		else NULL
	end
go


-- Extract of all FOBT values
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_1_Inc_1_AllFOBT]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[FOBT_1_Inc_1_AllFOBT]    --altered (ORD_...Dflt)

	SELECT [LabChemSID]
      ,labChem.[Sta3n]
      ,labChem.[LabChemTestSID]
      ,[PatientSID]
      ,[LabChemSpecimenDateTime] 
      ,[LabChemCompleteDateTime] as FOBT_dt
      ,[LabChemResultValue]
	  ,( case when (ltrim(rtrim([LabChemResultValue])) like '%pos%' 
					or ltrim(rtrim([LabChemResultValue])) like 'p' 
					--or ltrim(rtrim([LabChemResultValue])) like '1' 
					--or ltrim(rtrim([LabChemResultValue])) like '2' 
					--or ltrim(rtrim([LabChemResultValue])) like 'A' 
					--or ltrim(rtrim([LabChemResultValue])) like 'H%' 
					--or ltrim(rtrim(Abnormal)) like 'H%'
					--or ltrim(rtrim(Abnormal)) like 'A%'
					--or ltrim(rtrim(Abnormal)) like '*%'  --from FOBT_CRC_VHADirection_2007-004, * is for cancelled due to incompleted stoll cards
					)then 1
			else 0
			end) as IsPositive     
		,[LabChemResultNumericValue]
      ,[Abnormal]
      ,[RefHigh]
      ,[RefLow]
	  ,[RequestingStaffSID]
	  ,dimTest.[LabChemTestIEN]
	  ,dimTest.[LabChemTestName]
	  ,dimTest.[LabChemPrintTestName]
	  ,labChem.[LOINCSID]
	  ,LOINC.LOINC
	  ,LOINC.LOINCIEN
      ,labChem.[Units]
 into [MyDB].[MySchema].[FOBT_1_Inc_1_AllFOBT]    --altered (ORD_...Dflt)
  FROM [CDWWork].[Chem].[PatientLabChem] as labChem    --altered (VINCI1)
  inner join cdwwork.dim.labchemtest as dimTest
  on labChem.[LabChemTestSID]=dimTest.LabChemTestSID
  inner join cdwwork.dim.LOINC as LOINC
  on labChem.LOINCSID=LOINC.LOINCSID
  --inner join cdwwork.dim.VistaSite as VistaSite
		--on labChem.sta3n=VistaSite.Sta3n
  where 
    labChem.[LabChemCompleteDateTime] between DATEADD(mm,-13,(select sp_start from [MyDB].[MySchema].FOBT_0_1_inputP)) --12 month before Clue Date for Ferritin    --altered (ORD_...Dflt)
											and DATEADD(dd,61,(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP)) --Clue Date Range+followup    --altered (ORD_...Dflt)
	and VistaSite.VISN=(select VISN from [MyDB].[MySchema].FOBT_0_1_inputP) 	    --altered (ORD_...Dflt)
	--and labChem.sta3n in (select sta3n from [MyDB].[MySchema].[FOBT_0_1_inputPVISN])    --altered (ORD_...Dflt)
	and (
			LOINC.LOINCIEN in ( '50196','14563','14564','14565','38527','38526'
							,'57803','7905','56490','56491','59841','57804'
							,'2335','57803','59841'  --FOBT
							,'27396' --mass
							--,'42909','42910','42911','42912','42913'  -- not in stool
							--,'48047'-- not in stool
							--,'50017'-- not in stool
							,'50191','50196' --PRESENCE OR THRESHOLD
							,'77353' --NONINVASIVE COLORECTAL CANCER DNA+OCCULT BLOOD SCREENING
							,'77354' --NONINVASIVE COLORECTAL CANCER DNA+OCCULT BLOOD SCREENING

							,'12503','12504','27401','27925','27926'  --4th-8th specimen
							,'29771'							
							,'57905'  --FIT	Presence
							,'58453' -- FIT Mass/Volume						
							,'80372' --FIT ia.rapid
							)
			or (
					 (dimTest.[LabChemTestName] like '%FOB%' or dimTest.[LabChemTestName] like '%Occult%' -- or dimTest.[LabChemTestName] like '%stool%' 
						or dimTest.[LabChemTestName] like '%FIT%' )-- or dimTest.[LabChemPrintTestName] like '%stool%' 
 				 	 and labchemtestname not like 'z%'	
					and labchemtestname not like '%Study%'
					and labchemtestname not like '%urine%'
					and labchemtestname not like '%Gastr%'
			)
		)

	--and labchem.sta3n<>556 -- Exclude NorthChicago	
go



-- Only rows of patients with result = "positive", not combined
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_1_Inc_8_IncIns]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_1_Inc_8_IncIns    --altered (ORD_...Dflt)

go

select distinct [LabChemSID]
      ,a.[Sta3n]
      ,[LabChemTestSID]
      ,a.[PatientSID]
      ,[LabChemSpecimenDateTime]
      ,[FOBT_dt] as CBC_dt
      ,[LabChemResultValue]
      ,[IsPositive]
      ,[LabChemResultNumericValue]
      ,[Abnormal]
      ,[RefHigh]
      ,[RefLow]
      ,[RequestingStaffSID]
      ,[LabChemTestIEN]
      ,[LabChemTestName]
      ,[LabChemPrintTestName]
      ,[LOINCSID]
      ,[LOINC]
      ,[LOINCIEN]
      ,[Units]
	    ,VStatus.DateofBirth as DOB
		,VStatus.dateofDeath as DOD
		,VStatus.gender as Sex
		,VStatus.PatientSSN
		,VStatus.ScrSSN
		,VStatus.PatientICN
into [MyDB].[MySchema].FOBT_1_Inc_8_IncIns    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[FOBT_1_Inc_1_AllFOBT] as a    --altered (ORD_...Dflt)
left join [CDWWork].[SPatient].[SPatient] as VStatus    --altered (ORD_...Src)
on a.PatientSID=VStatus.PatientSID and a.sta3n=VStatus.sta3n
where isPositive=1
and [FOBT_dt] between (select sp_start from [MyDB].[MySchema].FOBT_0_1_inputP)     --altered (ORD_...Dflt)
											and (select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP)    --altered (ORD_...Dflt)

go


-- diag_clue: distinct patients meeting all criteria for diagnostic clue 
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_1_Inc_9_IncPat    --altered (ORD_...Dflt)
go

	select distinct VStatus.Sta3n,VStatus.PatientSID,VStatus.patientSSN, VStatus.ScrSSN,VStatus.PatientICN
	into [MyDB].[MySchema].FOBT_1_Inc_9_IncPat    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].FOBT_1_Inc_8_IncIns as a    --altered (ORD_...Dflt)
    left join  [CDWWork].[SPatient].[SPatient] as VStatus    --altered (ORD_...Src)
    on a.patientSSN=VStatus.PatientSSN	
go



---------------------------------------Exclusion Dx----------------------------------------
-------------------------------------------------------------------------------------------
--  Extract of previous colon cancer

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_0_PrevCLCFromProblemList_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_0_PrevCLCFromProblemList_ICD9    --altered (ORD_...Dflt)
go

SELECT 
	 	p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	  ,Plist.*	  
into [MyDB].[MySchema].FOBT_2_ExcDx_0_PrevCLCFromProblemList_ICD9    --altered (ORD_...Dflt)
  FROM [CDWWork].[Outpat].[ProblemList] as Plist    --altered (VINCI1)
  inner join CDWWork.Dim.ICD as ICD
  on Plist.ICD9SID=ICD.ICDSID
inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Plist.sta3n=p.sta3n and Plist.patientsid=p.patientsid
where 
plist.[EnteredDate] <= DATEADD(dd,(select fu_period from [MyDB].[MySchema].[FOBT_0_1_inputP]),(select sp_end from [MyDB].[MySchema].[FOBT_0_1_inputP]))    --altered (ORD_...Dflt)
and
(
  ICD.ICDCode in (
			-------------------------------------------------------- Previous Colorectal Cancer
			-- Colon Cancer Codes
				'154.0','154.1','154.8')
			-------------------------------------------------------- Previous Colorectal Cancer
		or ICD.ICDCode like
		-- Colon Cancer Codes
			'153.%'			
)
go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_0_PrevCLCFromProblemList_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_0_PrevCLCFromProblemList_ICD10    --altered (ORD_...Dflt)
go


SELECT 
	 	p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	  ,Plist.*	  
into [MyDB].[MySchema].FOBT_2_ExcDx_0_PrevCLCFromProblemList_ICD10    --altered (ORD_...Dflt)
  FROM [CDWWork].[Outpat].[ProblemList] as Plist    --altered (VINCI1)
  inner join CDWWork.Dim.ICD10 as ICD10
  on Plist.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Plist.ICD10SID=ICD10Diag.ICD10SID
  inner join [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] as  ICD10CodeList    --altered (ORD_...Dflt)
on ICD10.ICD10Code=ICD10CodeList.ICD10Code
inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Plist.sta3n=p.sta3n and Plist.patientsid=p.patientsid
where 
plist.[EnteredDate] <= DATEADD(dd,(select fu_period from [MyDB].[MySchema].[FOBT_0_1_inputP]),(select sp_end from [MyDB].[MySchema].[FOBT_0_1_inputP]))    --altered (ORD_...Dflt)
and
( 
 ICD10CodeList.dx_code_type='PrevColonCancer'	
)

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_0_PrevCLCFromProblemList]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_0_PrevCLCFromProblemList    --altered (ORD_...Dflt)
go

select * into [MyDB].[MySchema].FOBT_2_ExcDx_0_PrevCLCFromProblemList    --altered (ORD_...Dflt)
	from (
		select * from [MyDB].[MySchema].FOBT_2_ExcDx_0_PrevCLCFromProblemList_ICD9    --altered (ORD_...Dflt)
		union
		select * from [MyDB].[MySchema].FOBT_2_ExcDx_0_PrevCLCFromProblemList_ICD10    --altered (ORD_...Dflt)
	) sub
	go

--  Extract of all DX codes from outpatient
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_1_OutPatDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_1_OutPatDx_ICD9    --altered (ORD_...Dflt)

SELECT 
	 [VDiagnosisSID]
      ,Diag.[Sta3n]
  --    ,Diag.[ICDSID]
      ,Diag.[PatientSID]
	  ,ICD9.ICD9Code as ICDCode
	  ,targetCode.dx_code_type
	  ,ICD9Diag.ICD9Diagnosis as ICDDiagnosis
      ,[VisitSID]
      ,[VisitDateTime]
      ,[VDiagnosisDateTime] as dx_dt
      ,[ProblemListSID]   	
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN  
into [MyDB].[MySchema].FOBT_2_ExcDx_1_OutPatDx_ICD9    --altered (ORD_...Dflt)
  FROM [CDWWork].[Outpat].[VDiagnosis] as Diag    --altered (VINCI1)
  inner join CDWWork.Dim.ICD9 as ICD9
  on Diag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DiagnosisVersion as ICD9Diag
  on Diag.ICD9SID=ICD9Diag.ICD9SID
inner join [MyDB].[MySchema].FOBT_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=ICD9.ICD9Code
inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
[VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))     --altered (ORD_...Dflt)

go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_1_OutPatDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_1_OutPatDx_ICD10    --altered (ORD_...Dflt)

go

SELECT 
	 [VDiagnosisSID]
      ,Diag.[Sta3n]
  --    ,Diag.[ICDSID]
      ,Diag.[PatientSID]
      ,Diag.[ICD9SID]
	  ,Diag.[ICD10SID]

	  ,ICD10.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type
	  ,ICD10Diag.ICD10Diagnosis as ICDDiagnosis
	  ,[VisitSID]
      ,[VisitDateTime]
      ,[VDiagnosisDateTime] as dx_dt
      ,[ProblemListSID] 	  	
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN  
into [MyDB].[MySchema].FOBT_2_ExcDx_1_OutPatDx_ICD10    --altered (ORD_...Dflt)
  FROM [CDWWork].[Outpat].[VDiagnosis] as Diag    --altered (VINCI1)
  inner join CDWWork.Dim.ICD10 as ICD10
  on Diag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Diag.ICD10SID=ICD10Diag.ICD10SID
inner join [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] as ICD10CodeList    --altered (ORD_...Dflt)
on ICD10.ICD10Code=ICD10CodeList.ICD10Code
inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
[VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))     --altered (ORD_...Dflt)

go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_2_SurgDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_2_SurgDx_ICD9    --altered (ORD_...Dflt)

SELECT 
	  -- surg.[SurgerySID]
      surg.[Sta3n]
      ,[SurgeryIEN]
      --,[PatientIEN]
      --,[VisitIEN]
      ,Surg.[PatientSID]
      ,[VisitSID]
      ,[DateOfOperationNumeric]  as dx_dt
      ,[PrincipalDiagnosis]
      ,[PrincipalPostOpDiag]
      ,[PrincipalPreOpDiagnosis]
      ,[PrincipalProcedure]
      ,[ProcedureCompleted]	  
	  ,SurgDx.[PrinPostopDiagnosisCode] as ICDCode
	  ,dx_code_type
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
  into [MyDB].[MySchema].FOBT_2_ExcDx_2_SurgDx_ICD9    --altered (ORD_...Dflt)
    FROM [CDWWork].[Surgery].[Surgery_130] as surg    --altered (ORD_...Src)
	inner join [CDWWork].[Surgery].[surgeryprcdrdgnsscodes_136] as SurgDx      --altered (ORD_...Src)
  --on surg.[SurgerySID]=SurgDx.[SurgerySID]
  on surg.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  and surg.Sta3n=SurgDx.Sta3n
  inner join [MyDB].[MySchema].FOBT_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=SurgDx.PrinPostopDiagnosisCode
    inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Surg.sta3n=p.sta3n and surg.patientsid=p.patientsid
   where 
  [DateOfOperationNumeric]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))     --altered (ORD_...Dflt)

	go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_2_SurgDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_2_SurgDx_ICD10    --altered (ORD_...Dflt)

SELECT 
	  -- surg.[SurgerySID]
      surg.[Sta3n]
      ,[SurgeryIEN]
      --,[PatientIEN]
      --,[VisitIEN]
      ,Surg.[PatientSID]
      ,[VisitSID]
      ,[DateOfOperationNumeric]  as dx_dt
      ,[PrincipalDiagnosis]
      ,[PrincipalPostOpDiag] as ICDDiagnosis
      ,[PrincipalPreOpDiagnosis]
      ,[PrincipalProcedure]
      ,[ProcedureCompleted]	  
	  ,SurgDx.[PrinPostopDiagnosisCode] as ICDCode
	  ,ICD10CodeList.dx_code_type
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
  into [MyDB].[MySchema].FOBT_2_ExcDx_2_SurgDx_ICD10    --altered (ORD_...Dflt)
  --FROM [CDWWork].[Surgery].[Surgery_130] as surg    --altered (ORD_...Src)
  --inner join [CDWWork].[Surgery].[surgeryprcdrdgnsscodes_136] as SurgDx    --altered (ORD_...Src)
    FROM [CDWWork].[Surgery].[Surgery_130] as surg    --altered (ORD_...Src)
	inner join [CDWWork].[Surgery].[surgeryprcdrdgnsscodes_136] as SurgDx      --altered (ORD_...Src)
  --on surg.[SurgerySID]=SurgDx.[SurgerySID]
  on surg.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  and surg.Sta3n=SurgDx.Sta3n
inner join [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] as ICD10CodeList    --altered (ORD_...Dflt)
on SurgDx.PrinPostopDiagnosisCode=ICD10CodeList.ICD10Code
    inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Surg.sta3n=p.sta3n and surg.patientsid=p.patientsid
   where  
  [DateOfOperationNumeric]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))     --altered (ORD_...Dflt)

	go



--  Extract of all DX codes from inpatient
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_3_A_InPatDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_3_A_InPatDx_ICD9    --altered (ORD_...Dflt)

SELECT 
	  [InpatientDiagnosisSID] --Primary Key
      ,InPatDiag.[Sta3n]
      --,[OrdinalNumber]
      ,[InpatientSID]  --foreign key to Inpatient table
      ,InPatDiag.[PatientSID]
      ,[AdmitDateTime]
      ,[DischargeDateTime] as dx_dt
      ,InPatDiag.[ICD9SID]
	  ,ICD9.ICD9Code as ICDCode
	  ,dx_code_type
	  ,ICD9Diag.ICD9Diagnosis as ICDDiagnosis	    
	  ,InPatDiag.[ICD10SID]
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	into  [MyDB].[MySchema].FOBT_2_ExcDx_3_A_InPatDx_ICD9    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[InpatientDiagnosis] as InPatDiag    --altered (VINCI1)
  inner join CDWWork.Dim.ICD9 as ICD9
  on InPatDiag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DiagnosisVersion as ICD9Diag
  on InPatDiag.ICD9SID=ICD9Diag.ICD9SID
    inner join [MyDB].[MySchema].FOBT_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=ICD9.ICD9Code
  inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
  where 
  
[DischargeDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP)) --Clue Date Range+followup    --altered (ORD_...Dflt)

	go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_3_A_InPatDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_3_A_InPatDx_ICD10    --altered (ORD_...Dflt)

SELECT 
	  [InpatientDiagnosisSID] --Primary Key
      ,InPatDiag.[Sta3n]
      --,[OrdinalNumber]
      ,[InpatientSID]  --foreign key to Inpatient table
      ,InPatDiag.[PatientSID]
      ,[AdmitDateTime]
      ,[DischargeDateTime] as dx_dt
      ,InPatDiag.[ICD9SID]
	  ,InPatDiag.[ICD10SID]
	  ,ICD10.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type
	  ,ICD10Diag.ICD10Diagnosis as ICDDiagnosis
	  ,p.patientSSN
	  ,p.ScrSSN 
	  ,p.patientICN
	into  [MyDB].[MySchema].FOBT_2_ExcDx_3_A_InPatDx_ICD10    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[InpatientDiagnosis] as InPatDiag    --altered (VINCI1)
  inner join CDWWork.Dim.ICD10 as ICD10
  on InPatDiag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on InPatDiag.ICD10SID=ICD10Diag.ICD10SID
inner join [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] as ICD10CodeList    --altered (ORD_...Dflt)
on ICD10.ICD10Code=ICD10CodeList.ICD10Code
  inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
  where 
  
[DischargeDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP)) --Clue Date Range+followup    --altered (ORD_...Dflt)

	go



if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9    --altered (ORD_...Dflt)

SELECT 
       Diag.[Sta3n]
      ,Diag.[PatientSID]
	  ,ICD9.ICD9Code as ICD9
	  ,dx_code_type
	  ,v.[ICD9Description]
	  --,ICD.[DiagnosisText]
	  ,[InpatientFeeDiagnosisSID]
      ,[OrdinalNumber]
      ,[InpatientFeeBasisSID]      
      ,[AdmitDateTime] as dx_dt
      ,[AdmitDateTimeTransformSID]
      ,[AdmitDateSID]
      ,[DischargeDateTime]
      ,[DischargeDateTimeTransformSID]
      ,[DischargeDateSID]
      ,Diag.[ICD9SID]
      ,[ICD10SID]	  	
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN  
into [MyDB].[MySchema].FOBT_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].InpatientFeeDiagnosis as Diag    --altered (VINCI1)
  inner join CDWWork.Dim.ICD9 as ICD9
  on Diag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DescriptionVersion AS V
  on icd9.ICD9SID=v.ICD9SID
  inner join [MyDB].[MySchema].FOBT_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=ICD9.ICD9Code
inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
 
[AdmitDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))     --altered (ORD_...Dflt)
go



	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10    --altered (ORD_...Dflt)

SELECT 
       Diag.[Sta3n]
      ,Diag.[PatientSID]
	  ,ICD10.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type
	  ,ICD10Diag.ICD10Diagnosis as ICDDiagnosis
	  ,[InpatientFeeDiagnosisSID]
      ,[OrdinalNumber]
      ,[InpatientFeeBasisSID]      
      ,[AdmitDateTime] as dx_dt
      ,[AdmitDateTimeTransformSID]
      ,[AdmitDateSID]
      ,[DischargeDateTime]
      ,[DischargeDateTimeTransformSID]
      ,[DischargeDateSID]
      ,Diag.[ICD9SID]
      ,Diag.[ICD10SID]	  	
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN  
into [MyDB].[MySchema].FOBT_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].InpatientFeeDiagnosis as Diag    --altered (VINCI1)
  inner join CDWWork.Dim.ICD10 as ICD10
  on Diag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Diag.ICD10SID=ICD10Diag.ICD10SID
inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
  inner join [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] as ICD10CodeList    --altered (ORD_...Dflt)
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
where  
[AdmitDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))     --altered (ORD_...Dflt)

go




--Fee ICD Dx 
  		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9    --altered (ORD_...Dflt)


SELECT  
	  c.patientssn
	,d.InitialTreatmentDateTime as dx_dt
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,[ServiceProvidedCPTSID]
      ,a.[ICD9SID]
      ,[ICD10SID]
	  ,ICD9.ICD9Code as ICD9
	  ,dx_code_type
	  ,v.[ICD9Description]
      ,[AmountClaimed]
      ,[AmountPaid]
	  ,patientICN
	  ,ScrSSN
into [MyDB].[MySchema].FOBT_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9    --altered (ORD_...Dflt)
  FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
  inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join CDWWork.Dim.ICD9 as ICD9
  on a.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DescriptionVersion AS V
  on icd9.ICD9SID=v.ICD9SID
  inner join [MyDB].[MySchema].FOBT_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=ICD9.ICD9Code
  inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as c    --altered (ORD_...Dflt)
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)

go



--Fee ICD Dx
  		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10    --altered (ORD_...Dflt)


SELECT  
	  c.patientssn
	,d.InitialTreatmentDateTime
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,[ServiceProvidedCPTSID]
	  ,a.[ICD9SID]
	  ,a.ICD10SID
	  ,ICD10.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type
	  ,ICD10Diag.ICD10Diagnosis as ICDDiagnosis
      ,[AmountClaimed]
      ,[AmountPaid]
	  ,patientICN
	  ,ScrSSN
into [MyDB].[MySchema].FOBT_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10    --altered (ORD_...Dflt)
  FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
  inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join CDWWork.Dim.ICD10 as ICD10
  on a.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on a.ICD10SID=ICD10Diag.ICD10SID
  inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as c    --altered (ORD_...Dflt)
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
inner join [MyDB].[MySchema].[FOBT_0_2_DxICD10CodeExc] as ICD10CodeList    --altered (ORD_...Dflt)
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
  where d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)

go


	--  Extract of all exclusion diagnoses from surgical, inpatient, and outpatient tables
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_4_ALLDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_4_ALLDx_ICD9    --altered (ORD_...Dflt)
go

select patientSSN,sta3n, PatientSID,dx_dt,ICDCode as ICD9,dx_code_type,'Dx-Surg' as dataSource,patientICN,ScrSSN
into [MyDB].[MySchema].FOBT_2_ExcDx_4_ALLDx_ICD9    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[FOBT_2_ExcDx_2_SurgDx_ICD9]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICDCode as ICD9,dx_code_type,'DX-OutPat' as dataSource,patientICN,ScrSSN from [MyDB].[MySchema].[FOBT_2_ExcDx_1_OutPatDx_ICD9]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICDCode as ICD9,dx_code_type,'Dx-InPat' as dataSource,patientICN,ScrSSN from [MyDB].[MySchema].[FOBT_2_ExcDx_3_A_InPatDx_ICD9]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD9,dx_code_type,'Dx-InPatFee' as dataSource,patientICN,ScrSSN from [MyDB].[MySchema].[FOBT_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD9,dx_code_type,'Dx-InPatFeeService' as dataSource,patientICN,ScrSSN from [MyDB].[MySchema].[FOBT_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9]    --altered (ORD_...Dflt)



alter table [MyDB].[MySchema].FOBT_2_ExcDx_4_ALLDx_ICD9    --altered (ORD_...Dflt)
	add crc_dx_dt datetime, 
	term_dx_dt datetime,
	hospice_dt datetime,
	ugi_bleed_dx_dt datetime,
--	menorr_dx_dt datetime,
	other_bleed_dx_dt datetime,
	preg_dx_dt datetime,
	thal_dx_dt datetime,
	colonoscopy_dt datetime,
	colectomy_dt datetime
	--admit_dt datetime,
	--dischg_dt datetime
	--surg_dt datetime
go

update [MyDB].[MySchema].FOBT_2_ExcDx_4_ALLDx_ICD9    --altered (ORD_...Dflt)
set 
	--crc_dx_dt = case
	--	when 
	--		ICD9 in (
	--			-- Colon Cancer Codes
	--				'154.0','154.1','154.8') or ICD9 like '153.%'			
	--		then dx_dt
	--	else NULL
	--end,
	term_dx_dt = case
		when dx_code_type='Terminal'
			 then dx_dt
		else NULL
	end,
	hospice_dt = case
		when dx_code_type='Hospice'
		 then dx_dt
		else NULL
	end,
	ugi_bleed_dx_dt = case
		when dx_code_type='Upper GI Bleed'
			 then dx_dt
		else NULL
	end,
	other_bleed_dx_dt = case
		when dx_code_type='Other Bleeding'
			 then dx_dt
		else NULL
	end,
	preg_dx_dt = case
		when dx_code_type='Pregnancy'
		then dx_dt
		else NULL
	end,
	thal_dx_dt = case
		when dx_code_type='Thalassemia'
			 then dx_dt
		else NULL
	end,
	colonoscopy_dt = NULL,
	colectomy_dt = NULL
	--admit_dt = NULL,
	--surg_dt = NULL
go


	--  Extract of all exclusion diagnoses from surgical, inpatient, and outpatient tables
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_4_ALLDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_4_ALLDx_ICD10    --altered (ORD_...Dflt)
go

select patientSSN,sta3n, PatientSID,dx_dt,ICDCode as ICDCode,dx_code_type,'Dx-Surg' as dataSource
into [MyDB].[MySchema].FOBT_2_ExcDx_4_ALLDx_ICD10    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[FOBT_2_ExcDx_2_SurgDx_ICD10]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'DX-OutPat' as dataSource from [MyDB].[MySchema].[FOBT_2_ExcDx_1_OutPatDx_ICD10]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10Code,dx_code_type,'Dx-InPat' as dataSource from [MyDB].[MySchema].[FOBT_2_ExcDx_3_A_InPatDx_ICD10]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'Dx-InPatFee' as dataSource from [MyDB].[MySchema].[FOBT_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,[InitialTreatmentDateTime] as [dx_dt],[ICD10code],dx_code_type,'Dx-InPatFeeService' as dataSource from [MyDB].[MySchema].FOBT_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10    --altered (ORD_...Dflt)

Alter table [MyDB].[MySchema].FOBT_2_ExcDx_4_ALLDx_ICD10    --altered (ORD_...Dflt)
	add 
--	crc_dx_dt datetime, 
	term_dx_dt datetime,
	hospice_dt datetime,
	ugi_bleed_dx_dt datetime,
--	menorr_dx_dt datetime,
	other_bleed_dx_dt datetime,
	preg_dx_dt datetime,
	thal_dx_dt datetime
	--colonoscopy_dt datetime,
	--colectomy_dt datetime
	--admit_dt datetime,
	--dischg_dt datetime
	--surg_dt datetime
go

update [MyDB].[MySchema].FOBT_2_ExcDx_4_ALLDx_ICD10    --altered (ORD_...Dflt)
set term_dx_dt= case when dx_code_type='Terminal' then dx_dt else null end,
	hospice_dt= case when dx_code_type='hospice' then dx_dt else null end,
--	crc_dx_dt= case when dx_code_type='PrevColonCancer' then dx_dt else null end,
	preg_dx_dt=case when dx_code_type='Pregnancy' then dx_dt else null end,
	ugi_bleed_dx_dt= case when dx_code_type='UpperGIBleeding' then dx_dt else null end,
	other_bleed_dx_dt=case when dx_code_type='OtherBleeding' then dx_dt else null end,
	thal_dx_dt=case when dx_code_type='Thalassemic' then dx_dt else null end
	--colonoscopy_dt=case when dx_code_type='bladderRenalBleeding' then dx_dt else null end,
	--colectomy_dt=case when dx_code_type='bladderRenalBleeding' then dx_dt else null end
go
	

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_2_ExcDx_4_Union_ALLDx_ICD]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_2_ExcDx_4_Union_ALLDx_ICD    --altered (ORD_...Dflt)
go

select 
	  [patientSSN]
      ,[sta3n]
      ,[PatientSID]
      ,[dx_dt]
      ,[ICD9] as ICDCode
      ,[dataSource]
      ,[dx_code_type]
      ,[term_dx_dt]
      ,[hospice_dt]
      ,[preg_dx_dt]
	--,crc_dx_dt
	,ugi_bleed_dx_dt
	,other_bleed_dx_dt
	--,colonoscopy_dt
	--,colectomy_dt
into [MyDB].[MySchema].FOBT_2_ExcDx_4_Union_ALLDx_ICD    --altered (ORD_...Dflt)
from [MyDB].[MySchema].FOBT_2_ExcDx_4_ALLDx_ICD9    --altered (ORD_...Dflt)
union
select 
	  [patientSSN]
      ,[sta3n]
      ,[PatientSID]
      ,[dx_dt]
      ,[ICDCode]
      ,[dataSource]
      ,[dx_code_type]
      ,[term_dx_dt]
      ,[hospice_dt]
      ,[preg_dx_dt]
	--,crc_dx_dt
	,ugi_bleed_dx_dt
	,other_bleed_dx_dt
	--,colonoscopy_dt
	--,colectomy_dt
from [MyDB].[MySchema].FOBT_2_ExcDx_4_ALLDx_ICD10    --altered (ORD_...Dflt)
go


	------------------------------------------------------------------------------------------------------------
	-------------------------------- trigger Non-Dx exclusions
	------------------------------------------------------------------------------------------------------------
--Previous ICD procedures from inpatient 

				if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)

			  select pat.patientssn,pat.scrssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime]
	      ,DimICD9Proc.[ICDProcedureCode],DimICD9Proc.ProcedureName,DimICD9Proc.ICDProcedureDescription,pat.patientICN
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
  FROM CDWWork.[Inpat].[InpatientICDProcedure] as ICDProc    --altered (VINCI1)
  inner join cdwwork.dim.ICDProcedure as DimICD9Proc
  on ICDProc.[ICD9ProcedureSID]=DimICD9Proc.[ICDProcedureSID]  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where DimICD9Proc.[ICDProcedureCode] in (  
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
							)
 and [ICDProcedureDateTime] < DateAdd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
 go


				if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)

			  select pat.patientssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime]
		      ,ICDProc.ICD9ProcedureSID	  
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
  FROM CDWWork.[Inpat].[InpatientICDProcedure] as ICDProc    --altered (VINCI1)
  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
inner join   [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist    --altered (ORD_...Dflt)
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
 where 

  [ICDProcedureDateTime] < DateAdd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
  go


			if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[ICDProcedureDateTime]
	      ,DimICD9Proc.[ICDProcedureCode],DimICD9Proc.ProcedureName,DimICD9Proc.ICDProcedureDescription,pat.patientICN
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
  FROM CDWWork.[Inpat].[CensusICDProcedure] as a    --altered (VINCI1)
  inner join cdwwork.dim.ICDProcedure as DimICD9Proc
  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICDProcedureSID]  
   inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where DimICD9Proc.[ICDProcedureCode] in (   
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
							)

 and [ICDProcedureDateTime] < DateAdd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
go


			if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)

 select pat.patientssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime]
	      		      ,ICDProc.ICD9ProcedureSID	  
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
  FROM CDWWork.[Inpat].[CensusICDProcedure] as ICDProc    --altered (VINCI1)
    inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
inner join   [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist    --altered (ORD_...Dflt)
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
   inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where [ICDProcedureDateTime] < DateAdd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
	      ,DimICD9Proc.[ICDProcedureCode],DimICD9Proc.ProcedureName,DimICD9Proc.ICDProcedureDescription,pat.patientICN
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc    --altered (ORD_...Dflt)
  FROM CDWWork.[Inpat].[InpatientSurgicalProcedure] as a    --altered (VINCI1)
  inner join cdwwork.dim.ICDProcedure as DimICD9Proc
  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICDProcedureSID]  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where DimICD9Proc.[ICDProcedureCode] in (   
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
								)

 and [SurgicalProcedureDateTime] <dateadd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)

go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc    --altered (ORD_...Dflt)

select pat.patientssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[SurgicalProcedureDateTime]
		      ,ICDProc.ICD9ProcedureSID	  
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc    --altered (ORD_...Dflt)
  FROM CDWWork.[Inpat].[InpatientSurgicalProcedure] as ICDProc    --altered (VINCI1)
  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
inner join   [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist    --altered (ORD_...Dflt)
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where [SurgicalProcedureDateTime] <dateadd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)

go



if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc    --altered (ORD_...Dflt)

 select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
	      ,DimICD9Proc.[ICDProcedureCode],DimICD9Proc.ProcedureName,DimICD9Proc.ICDProcedureDescription,pat.patientICN
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc    --altered (ORD_...Dflt)
  FROM CDWWork.[Inpat].[CensusSurgicalProcedure] as a    --altered (VINCI1)
  inner join cdwwork.dim.ICDProcedure as DimICD9Proc
  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICDProcedureSID] 
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where DimICD9Proc.[ICDProcedureCode] in (   
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
						)

 and [SurgicalProcedureDateTime] <DateAdd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc    --altered (ORD_...Dflt)

 select pat.patientssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
		      ,a.ICD9ProcedureSID	  
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc    --altered (ORD_...Dflt)
  FROM CDWWork.[Inpat].[CensusSurgicalProcedure] as a    --altered (VINCI1)
  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
inner join   [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist    --altered (ORD_...Dflt)
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where 
 [SurgicalProcedureDateTime] <DateAdd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
go


	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc	    --altered (ORD_...Dflt)

	select pat.patientssn,pat.scrssn,a.sta3n,b.patientsid,b.[TreatmentFromDateTime]
	      ,DimICD9Proc.[ICDProcedureCode],DimICD9Proc.ProcedureName,DimICD9Proc.ICDProcedureDescription,pat.patientICN
	into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
	--from CDWWork.[Fee].[FeeInpatInvoiceICDProcedure] as a    --altered (VINCI1)
	from [CDWWork].[Fee].[FeeInpatInvoiceICDProcedure] as a    --altered (ORD_...Src)
	inner join[CDWWork].[Fee].[FeeInpatInvoice] as b    --altered (ORD_...Src)
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
	 inner join cdwwork.dim.ICDProcedure as DimICD9Proc
	  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICDProcedureSID] 
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where DimICD9Proc.[ICDProcedureCode] in (
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
							)

 and [TreatmentFromDateTime] < DateAdd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
 go


 if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc	    --altered (ORD_...Dflt)

	select pat.patientssn,a.sta3n,b.patientsid,b.[TreatmentFromDateTime]
	      		      ,a.ICD9ProcedureSID	  
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
	into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
	--from CDWWork.[Fee].[FeeInpatInvoiceICDProcedure] as a    --altered (VINCI1)
	from [CDWWork].[Fee].[FeeInpatInvoiceICDProcedure] as a    --altered (ORD_...Src)
	inner join[CDWWork].[Fee].[FeeInpatInvoice] as b    --altered (ORD_...Src)
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
inner join   [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist    --altered (ORD_...Dflt)
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where [TreatmentFromDateTime] < DateAdd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
 go



  		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD9Proc    --altered (ORD_...Dflt)
										 


SELECT  
	  c.patientssn
	,d.InitialTreatmentDateTime
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,[ServiceProvidedCPTSID]
	  ,b.ICDcode
	  ,ICDdescription
      ,[AmountClaimed]
      ,[AmountPaid]
	  ,patientICN
	  ,ScrSSN
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD9Proc    --altered (ORD_...Dflt)
  FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
  inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join cdwwork.dim.icd as b
  on a.[ICD9SID]=b.icdsid
  inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as c    --altered (ORD_...Dflt)
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where  b.ICDcode in 		(	
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
					)
and	d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from [MyDB].[MySchema].[FOBT_0_1_inputP]))    --altered (ORD_...Dflt)
go	
											


  		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD10Proc    --altered (ORD_...Dflt)


SELECT  
	  c.patientssn
	,d.InitialTreatmentDateTime
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,[ServiceProvidedCPTSID]
	  ,a.ICD9SID
	  ,a.ICD10SID
,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
      ,[AmountClaimed]
      ,[AmountPaid]
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD10Proc    --altered (ORD_...Dflt)
FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
  inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
    inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on a.[ICD10SID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
inner join   [MyDB].[MySchema].[FOBT_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist    --altered (ORD_...Dflt)
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
  inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as c    --altered (ORD_...Dflt)
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where  d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from [MyDB].[MySchema].[FOBT_0_1_inputP]))    --altered (ORD_...Dflt)
go	




if (OBJECT_ID('[MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc    --altered (ORD_...Dflt)
	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICDProcedureCode]
      ,[ICDProcedureDescription]
	  ,'Inp-InpICD'	  as datasource
    into  [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICDProcedureCode]
      ,[ICDProcedureDescription]
	  ,'Inp-CensusICD'	  as datasource
	from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICDProcedureCode]
      ,[ICDProcedureDescription]
	 ,'Inp-InpSurg'	  as datasource	 
	from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICDProcedureCode]
      ,[ICDProcedureDescription]
	 ,'Inp-CensusSurg'	  as datasource
	from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICDProcedureCode]      
      ,[ICDProcedureDescription]
	 ,'Inp-FeeICDProc'	  as datasource
	 from [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,InitialTreatmentDateTime as Proc_dt
	  ,ICDcode
	  ,[ICDDescription]
	 ,'FeeICDProc'	  as datasource
	 from [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD9Proc    --altered (ORD_...Dflt)

	
go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc    --altered (ORD_...Dflt)
	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	  ,'Inp-InpICD'	  as datasource
    into  [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	  ,'Inp-CensusICD'	  as datasource
	from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	 ,'Inp-InpSurg'	  as datasource	 
	from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	 ,'Inp-CensusSurg'	  as datasource
	from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	 ,'Inp-FeeICDProc'	  as datasource
	 from [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,InitialTreatmentDateTime as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	 ,'Inp-FeeICDProc'	  as datasource
	 from [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD10Proc    --altered (ORD_...Dflt)

	
go


			-- Previous procedures from outpatient tables

		if (OBJECT_ID('[MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_6_Outpat') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_6_Outpat    --altered (ORD_...Dflt)
		go
		
		SELECT 
		p.patientSSN,
      VProc.[Sta3n]
      ,VProc.[CPTSID]
	  ,dimCPT.[CPTCode]
	  ,DimCPT.[CPTName]
      ,VProc.[PatientSID]
      ,VProc.[VisitSID]
      ,VProc.[VisitDateTime]
      ,VProc.[VProcedureDateTime] 
      ,VProc.[CPRSOrderSID]
		,p.ScrSSN,p.patientICN
  into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_6_Outpat    --altered (ORD_...Dflt)
  FROM [CDWWork].[Outpat].[VProcedure] as VProc    --altered (VINCI1)
  inner join CDWWork.[Dim].[CPT] as DimCPT 
  on  VProc.[CPTSID]=DimCPT.CPTSID
  inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on VProc.sta3n=p.sta3n and VProc.patientsid=p.patientsid
  where  
  [VProcedureDateTime] is not null and
  dimCPT.[CPTCode] in  (
			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392',
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212'
			)	

go

  
  		-- previous procedures from surgical tables

		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_7_surg]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_7_surg    --altered (ORD_...Dflt)
		SELECT 
	   --[SurgerySID]
	   p.patientSSN
      ,surg.[Sta3n]
      --,[SurgeryIEN]
      --,[PatientIEN]
      --,[VisitIEN]
      ,surg.[PatientSID]
      ,[VisitSID]
      ,[DateOfOperationNumeric]
      ,[PrincipalDiagnosis]
      ,[PrincipalPostOpDiag]
      ,[PrincipalPreOpDiagnosis]
      ,[PrincipalProcedure]
	  ,SurgDx.[PrincipalProcedureCode]
      ,[ProcedureCompleted]
		,p.ScrSSN,p.patientICN
  into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_7_surg    --altered (ORD_...Dflt)
    FROM [CDWWork].[Surgery].[Surgery_130] as surg    --altered (ORD_...Src)
  inner join [CDWWork].[Surgery].[surgeryprcdrdgnsscodes_136] as SurgDx    --altered (ORD_...Src)
    on surg.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  and surg.Sta3n=SurgDx.Sta3n
    inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Surg.sta3n=p.sta3n and surg.patientsid=p.patientsid
  where  
  [DateOfOperationNumeric] is not null and 
  SurgDx.[PrincipalProcedureCode] in (
  
			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392',
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212'
			)	

  go


  -- Previous CPT from inpatient

	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,CPTProc.sta3n,CPTProc.patientsid,CPTProc.[CPTProcedureDateTime]
	      ,DimCPT.[CPTCode],DimCPT.CPTName,DimCPT.CPTDescription ,patientICN
into  [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[InpatientCPTProcedure] as CPTProc    --altered (ORD_...Src)
  inner join cdwwork.dim.CPT as DimCPT
  on CPTProc.[CPTSID]=DimCPT.CPTSID  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on CPTProc.patientsid=pat.patientsid and CPTProc.sta3n=pat.sta3n
 where DimCPT.[CPTCode] in (   
 			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392',
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212')							
and CPTProc.[CPTProcedureDateTime] <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
go


----- Fee: Surg, proc, img
  --Fee CPT
  		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_9_FeeCPT]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_9_FeeCPT    --altered (ORD_...Dflt)

SELECT  
	  c.patientssn
	  ,d.InitialTreatmentDateTime
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,[ServiceProvidedCPTSID]
	  ,b.cptcode
	  ,cptdescription
      ,[AmountClaimed]
      ,[AmountPaid]
	  ,patientICN
	  ,ScrSSN
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_9_FeeCPT    --altered (ORD_...Dflt)
  FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
  inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join cdwwork.dim.cpt as b
  on a.[ServiceProvidedCPTSID]=b.cptsid
  inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as c    --altered (ORD_...Dflt)
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where 
		b.cptcode in (   
 			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392',
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212')									
  and	d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from [MyDB].[MySchema].[FOBT_0_1_inputP]))    --altered (ORD_...Dflt)

  go



-- All colonoscopy procedures from surgical, inpatient and outpatient tables
	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy    --altered (ORD_...Dflt)

--select [PatientSID],[VProcedureDateTime] as colonoscopy_dt,'PrevColonScpy-OutPat' as Datasource
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as colonoscopy_dt ,'PrevColonScpy-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy    --altered (ORD_...Dflt)
from [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_6_Outpat     --altered (ORD_...Dflt)
		where [VProcedureDateTime] is not null
		and [CPTCode] in (  
			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392')
	UNION ALL
--select [patientsid],[ProcDay] as colonoscopy_dt,'PrevColonScpy-InPat' as Datasource 
select patientSSN,sta3n,patientSID,[Proc_dt] as colonoscopy_dt,'PrevColonScpy-InPatICD' as datasource,ICDProcedureCode as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
		where [Proc_dt] is not null
		and ICDProcedureCode in (   --Colonoscopy
								'45.23' )
	UNION ALL
--select [patientsid],[ProcDay] as colonoscopy_dt,'PrevColonScpy-InPat' as Datasource 
select patientSSN,sta3n,patientSID,[Proc_dt] as colonoscopy_dt,'PrevColonScpy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
		where [Proc_dt] is not null
		--Colonoscopy
		and [ICD10Proc_code_type]='Colonoscopy'
	UNION ALL	
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as colonoscopy_dt,'PrevColonScpy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT]    --altered (ORD_...Dflt)
		where [CPTProcedureDateTime] is not null
		and [CPTCode] in (   --Colonoscopy								 			
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392' )
	UNION ALL
select patientSSN,sta3n,patientSID,[DateOfOperationNumeric] as colonoscopy_dt,'PrevColonScpy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
--select [PatientSID],[DateOfOperation] as colonoscopy_dt,'PrevColonScpy-Surg' as Datasource 
from [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_7_surg     --altered (ORD_...Dflt)
		where [DateOfOperationNumeric] is not null
		and [PrincipalProcedureCode] in (	
  			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392')
	UNION ALL
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as colonoscopy_dt,'PrevColonScpy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD'
--select [PatientSID],[DateOfOperation] as colonoscopy_dt,'PrevColonScpy-Surg' as Datasource 
from [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_9_FeeCPT     --altered (ORD_...Dflt)
		where InitialTreatmentDateTime is not null
		and CPTCode in (	
  			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392')
	
	go

-- All colectomy procedures from surgical, inpatient and outpatient tables
	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_All_2_Colectomy]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_All_2_Colectomy    --altered (ORD_...Dflt)

--select [PatientSID],[VProcedureDateTime] as colectomy_dt,'PrevColectomy-OutPat' as Datasource
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as colectomy_dt ,'PrevColectomy-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
into [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_All_2_Colectomy    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_6_Outpat]    --altered (ORD_...Dflt)
		where [VProcedureDateTime] is not null
		and  [CPTCode]  in (  
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212')
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as colectomy_dt,'PrevColectomy-InPatICD' as datasource,[ICDProcedureCode] as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
		where [Proc_dt] is not null
		and [ICDProcedureCode] in (  --colectomy
								'45.81','45.82','45.83' )
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as colectomy_dt,'PrevColectomy-InPatICD' as datasource,[ICD10ProcedureCode] as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
		where [Proc_dt] is not null
		and [ICD10Proc_code_type]='Colectomy' --colectomy
	UNION ALL	
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as colectomy_dt,'PrevColectomy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT]    --altered (ORD_...Dflt)
		where [CPTProcedureDateTime] is not null
		and [CPTCode] in (   
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212' )
							   
	UNION ALL
--select [PatientSID], [DateOfOperation] as colectomy_dt,'PrevColectomy-Surg' as Datasource
select patientSSN,sta3n,patientSID,[DateOfOperationNumeric] as colectomy_dt,'PrevColectomy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_7_surg]    --altered (ORD_...Dflt)
		where [DateOfOperationNumeric] is not null
		and   [PrincipalProcedureCode] in (  
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212')
	UNION ALL
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as colectomy_dt,'PrevColectomy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD'
from [MyDB].[MySchema].FOBT_3_Exc_NonDx_3_PrevProc_9_FeeCPT     --altered (ORD_...Dflt)
		where InitialTreatmentDateTime is not null
		and CPTCode in (	
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212')


---------------------------------All Referral------------------------------------------------
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_6C_Hlp_1_Hospice_Referral_AllVisit]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_1_Hospice_Referral_AllVisit    --altered (ORD_...Dflt)
					
							select p.patientSSN,p.patientICN,p.ScrSSN
							,V.Sta3n,V.PatientSID,V.Visitsid,V.VisitDatetime,V.primaryStopcodeSID,V.SecondaryStopcodeSID					
					into [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_1_Hospice_Referral_AllVisit										    --altered (ORD_...Dflt)
					from CDWWork.[Outpat].[Visit] as V    --altered (VINCI1)
                    inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
                    on v.sta3n=p.sta3n and v.patientsid=p.patientsid
				where 
				 V.VisitDateTime between dateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
										and DateAdd(dd,30+(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP))    --altered (ORD_...Dflt)
				--Hospice referral needs to see one year prior				
		go



if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_6C_Hlp_2_Hospice_Referral_AllVisit_StopCode]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_2_Hospice_Referral_AllVisit_StopCode    --altered (ORD_...Dflt)
					
					select v.*,code1.stopcode as PrimaryStopCode,code1.stopcodename as PrimaryStopCodeName,code2.stopcode as SecondaryStopCode,code2.stopcodename as SecondaryStopCodeName
					into [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_2_Hospice_Referral_AllVisit_StopCode    --altered (ORD_...Dflt)
					from [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_1_Hospice_Referral_AllVisit as V    --altered (ORD_...Dflt)
					left join [CDWWork].[Dim].[StopCode] as code1
					on V.PrimaryStopCodeSID=code1.StopCodeSID	and V.Sta3n=code1.Sta3n		
					left join [CDWWork].[Dim].[StopCode] as code2
					on V.SecondaryStopCodeSID=code2.StopCodeSID	and v.sta3n=code2.sta3n

go



if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_6C_Hlp_3_Hospice_Referral_VisitStopCodeTIU]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_3_Hospice_Referral_VisitStopCodeTIU    --altered (ORD_...Dflt)
go

					select v.*
					--,c.consultsid,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
					--c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName
					,T.[TIUDocumentSID],T.[EntryDateTime],T.[ReferenceDateTime]
					--,ReportText
					,e.tiustandardtitle,T.ConsultSID
					into [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_3_Hospice_Referral_VisitStopCodeTIU					    --altered (ORD_...Dflt)
					from [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_2_Hospice_Referral_AllVisit_StopCode as V    --altered (ORD_...Dflt)
				   left join [CDWWork].[TIU].[TIUDocument_8925_IEN] as T    --altered (ORD_...Src)
				   --left join [CDWWork].[TIU].[TIUDocument_8925] as T    --altered (ORD_...Src)
					on T.VisitSID=V.Visitsid
					left join [CDW_TIU].[TIU].[TIUDocument_8925_02] as RptText
					on T.TIUDocumentsid=RptText.TIUDocumentsid
					left join cdwwork.dim.[TIUDocumentDefinition] as d                                         
					on t.[TIUDocumentDefinitionSID]=d.[TIUDocumentDefinitionSID]
					left join cdwwork.dim.TIUStandardTitle as e
					on d.TIUStandardTitleSID=e.TIUStandardTitleSID
					--left join CDWWork.con.Consult as C										                        --altered (VINCI1)
					--on C.[TIUDocumentSID]=T.[TIUDocumentSID]
				--where isnull(T.OpCode,'')<>'D'



if (OBJECT_ID('[MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID    --altered (ORD_...Dflt)

						select v.*
					--,c.consultsid
					,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
					c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName,
					c.placeofconsultation,	  
					c.requestType, -- weather the request is a consult or procedure
					c.[InpatOutpat], -- the ordering person to indicate if the service is to be rendered on an outpatient or Inpatients basis.
					c.[RemoteService]
					--,T.[TIUDocumentSID],ReportText,e.tiustandardtitle
					into [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID					    --altered (ORD_...Dflt)
                    from [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_3_Hospice_Referral_VisitStopCodeTIU as V    --altered (ORD_...Dflt)
					--left join [TIU_2013].[TIU].[TIUDocument_v030] as T
					--on T.VisitSID=V.Visitsid
					--left join [TIU_2013].[TIU].[TIUDocument_8925_02] as RptText
					--on T.TIUDocumentsid=RptText.TIUDocumentsid
					left join CDWWork.con.Consult as C										                        --altered (VINCI1)
					on C.ConsultSID=V.ConsultSID
					--left join cdwwork.dim.[TIUDocumentDefinition] as d                                         
					--on t.[TIUDocumentDefinitionSID]=d.[TIUDocumentDefinitionSID]
					--left join cdwwork.dim.TIUStandardTitle as e
					--on d.TIUStandardTitleSID=e.TIUStandardTitleSID
				--where isnull(T.OpCode,'')<>'D'
				
		go



-------------------------------------------------------------------------------------------
---------------------------  Age Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

if (OBJECT_ID('[MyDB].[MySchema].FOBT_5_Ins_1_Age') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_5_Ins_1_Age    --altered (ORD_...Dflt)
select	a.* 
into [MyDB].[MySchema].FOBT_5_Ins_1_Age    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[FOBT_1_Inc_8_IncIns] as a    --altered (ORD_...Dflt)
  where DATEDIFF(yy,DOB,a.[CBC_dt]) >= 40 
	and DATEDIFF(yy,DOB,a.[CBC_dt]) < 76
	go

-------------------------------------------------------------------------------------------
---------------------------  Alive Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

if (OBJECT_ID('[MyDB].[MySchema].FOBT_5_Ins_2_ALive') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_5_Ins_2_ALive    --altered (ORD_...Dflt)
 
select a.*
into [MyDB].[MySchema].FOBT_5_Ins_2_ALive    --altered (ORD_...Dflt)
from [MyDB].[MySchema].FOBT_5_Ins_1_Age as a    --altered (ORD_...Dflt)
 where 
        [DOD] is null 		 
		or (DOD is not null 
				and ( 
					DATEADD(dd,-(select fu_period from [MyDB].[MySchema].[FOBT_0_1_inputP]),dod)> a.cbc_dt    --altered (ORD_...Dflt)
					)
				)	   	     
go

-------------------------------------------------------------------------------------------
---------------------------  3: Colon/Rectal Cancer Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		--  all instances with CRC cancer exclusions removed
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_3_PrevCRCCancer]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_3_PrevCRCCancer    --altered (ORD_...Dflt)

        select a.*
		into [MyDB].[MySchema].FOBT_5_Ins_3_PrevCRCCancer    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_5_Ins_2_ALive as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].FOBT_2_ExcDx_0_PrevCLCFromProblemList as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN]
			 			and b.EnteredDate between dateadd(yy,-1,a.CBC_dt) and a.CBC_dt)
--			 and (b.lung_cancer_dx_dt between DATEADD(yy,-1,a.[VerifiedDate]) and a.[VerifiedDate]))
			 
		go


-------------------------------------------------------------------------------------------
---------------------------  4: total colectomy Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		--  all instances with total colectomy exclusions removed
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_4_colectomy]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_4_colectomy    --altered (ORD_...Dflt)

        select a.*
		into [MyDB].[MySchema].FOBT_5_Ins_4_colectomy    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_5_Ins_3_PrevCRCCancer as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_All_2_Colectomy] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN]
			 and b.[colectomy_dt] <= DATEADD(dd,60,a.CBC_dt))
			 			 -- and not(a.CBC_dt >= DATEADD(dd,60,b.colectomy_dt)))  --brian
			 
		go

-------------------------------------------------------------------------------------------
---------------------------  5: Terminal illness or major dx Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_5_Term]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_5_Term    --altered (ORD_...Dflt)

        select a.*
		into [MyDB].[MySchema].FOBT_5_Ins_5_Term    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_5_Ins_4_colectomy as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[FOBT_2_ExcDx_4_Union_ALLDx_ICD] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN]
			 and b.[term_dx_dt] between DATEADD(yy,-1,a.CBC_dt) and DATEADD(dd,60,a.CBC_dt))
			 
		go

-------------------------------------------------------------------------------------------
---------------------------  6: Hospice or palliative care Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_6_Hospice]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_6_Hospice    --altered (ORD_...Dflt)

        select a.*
		into [MyDB].[MySchema].FOBT_5_Ins_6_Hospice    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_5_Ins_5_Term as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[FOBT_2_ExcDx_4_Union_ALLDx_ICD] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[hospice_dt] between DATEADD(yy,-1,a.CBC_dt) and DATEADD(dd,60,a.CBC_dt))
			 
		go


		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_6B1_Inpat_HospiceSpecialty]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].[FOBT_5_Ins_6B1_Inpat_HospiceSpecialty]    --altered (ORD_...Dflt)
		go


SELECT *

	into  [MyDB].[MySchema].[FOBT_5_Ins_6B1_Inpat_HospiceSpecialty]    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].FOBT_5_Ins_6_Hospice as x    --altered (ORD_...Dflt)
		where not exists(
		select * FROM [CDWWork].[Inpat].[Inpatient] as a    --altered (VINCI1)
		inner join CDWWork.Dim.Specialty as s
		on a.DischargeFromSpecialtySID=s.SpecialtySID and a.sta3n=s.sta3n
		inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(s.PTFCode)) in ('96','1F') 
		and x.patientSSN=p.patientsSN and a.[DischargeDateTime] 
		between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),x.CBC_dt)    --altered (ORD_...Dflt)
		)
		go





					--Outside Hospice care ( VA Paid/Fee Based) see the coding policy
				if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_6B2_Hospice_FeeInpatInvoice_PurposeOfVisit]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].[FOBT_5_Ins_6B2_Hospice_FeeInpatInvoice_PurposeOfVisit]    --altered (ORD_...Dflt)
		go


SELECT *

	into  [MyDB].[MySchema].[FOBT_5_Ins_6B2_Hospice_FeeInpatInvoice_PurposeOfVisit]    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[FOBT_5_Ins_6B1_Inpat_HospiceSpecialty] as x    --altered (ORD_...Dflt)
		where not exists(
		select  b.FeePurposeOfVisit,a.* 
		from CDWWork.fee.[FeeInpatInvoice] as a    --altered (VINCI1)
		inner join cdwwork.dim.FeePurposeOfVisit as b
		on a.FeePurposeOfVisitSID=b.FeePurposeOfVisitSID
		inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(b.AustinCode)) in ('43','37','38','77','78')  
		and x.patientSSN=p.patientsSN and a.TreatmentFromDateTime 
		between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),x.CBC_dt)    --altered (ORD_...Dflt)
		)
		go



					--Outside Hospice care ( VA Paid/Fee Based) see the coding policy
				if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_6B3_Hospice_FeeServiceProvided_HCFAType]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].[FOBT_5_Ins_6B3_Hospice_FeeServiceProvided_HCFAType]    --altered (ORD_...Dflt)
		go


SELECT *
	into  [MyDB].[MySchema].[FOBT_5_Ins_6B3_Hospice_FeeServiceProvided_HCFAType]    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[FOBT_5_Ins_6B2_Hospice_FeeInpatInvoice_PurposeOfVisit] as x    --altered (ORD_...Dflt)
		where not exists(
		select  b.IBTypeOfServiceCode,a.* 
		from CDWWork.[Fee].[FeeServiceProvided] as a    --altered (VINCI1)
		inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (VINCI1)
		on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
		inner join cdwwork.dim.IBTypeOfService as b
		on a.FeeInitialTreatmentSID=b.IBTypeOfServiceSID
		inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(b.IBTypeOfServiceCode)) in ('H')  
		and x.patientSSN=p.patientsSN and d.[InitialTreatmentDateTime]
		between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),x.CBC_dt)    --altered (ORD_...Dflt)
		)
		go


					--Outside Hospice care ( VA Paid/Fee Based) see the coding policy
				if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_6B4_Hospice_FeeServiceProvided_PLCSRVCType]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].[FOBT_5_Ins_6B4_Hospice_FeeServiceProvided_PLCSRVCType]    --altered (ORD_...Dflt)
		go


SELECT *
	into  [MyDB].[MySchema].[FOBT_5_Ins_6B4_Hospice_FeeServiceProvided_PLCSRVCType]    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[FOBT_5_Ins_6B3_Hospice_FeeServiceProvided_HCFAType] as x    --altered (ORD_...Dflt)
		where not exists(
		select  b.IBPlaceOfServiceCode,a.* 
		from CDWWork.[Fee].[FeeServiceProvided] as a    --altered (VINCI1)
		inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (VINCI1)
		on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
		inner join cdwwork.dim.IBPlaceOfService as b
		on a.IBPlaceOfServiceSID=b.IBPlaceOfServiceSID
		inner join [MyDB].[MySchema].[FOBT_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(b.IBPlaceOfServiceCode)) in ('34','H','Y')  
		and x.patientSSN=p.patientsSN and d.[InitialTreatmentDateTime]
		between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_0_1_inputP),x.CBC_dt)    --altered (ORD_...Dflt)
		)
		go




				-------------------------------------------------------------------------------------------
---------------------------  6C: Hospice or palliative care REFERRAL--------------------------
-------------------------------------------------------------------------------------------

  

		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_6D1_Hospice_Refer_joinByConsultSID]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_5_Ins_6D1_Hospice_Refer_joinByConsultSID    --altered (ORD_...Dflt)
				
		select *
		into [MyDB].[MySchema].FOBT_5_Ins_6D1_Hospice_Refer_joinByConsultSID    --altered (ORD_...Dflt)
        from [MyDB].[MySchema].[FOBT_5_Ins_6B4_Hospice_FeeServiceProvided_PLCSRVCType] as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID as b    --altered (ORD_...Dflt)
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (351,353)   or b.SecondaryStopCode in (351,353)   
			 -- There is a visit, but the StopCode is missing
					or 	(b.[ConsultToRequestserviceName] like '%Hospice%' or b.[ConsultToRequestserviceName] like '%palliative%'
					or b.TIUStandardTitle like '%Hospice%' or b.TIUStandardTitle like '%palliative%')
					)
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitDateTime) between DATEADD(yy,-1, convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime)) 
			 --(b.visitDateTime between DATEADD(yy,-1, convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime)))
			 and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<60  -- make sure not 2 or 3 years off
								)
go


-------------------------------------------------------------------------------------------
---------------------------  7: GI bleeding Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_7_UGIBleed]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_7_UGIBleed    --altered (ORD_...Dflt)

        select a.*
		into [MyDB].[MySchema].FOBT_5_Ins_7_UGIBleed    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_5_Ins_6D1_Hospice_Refer_joinByConsultSID as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[FOBT_2_ExcDx_4_Union_ALLDx_ICD] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN]
			 and b.[ugi_bleed_dx_dt] between DATEADD(mm,-6,a.CBC_dt) and a.CBC_dt)
			 
		go

-------------------------------------------------------------------------------------------

---------------------------  8: Colonoscopy Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_8_ColonScpy]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_8_ColonScpy    --altered (ORD_...Dflt)
        select a.*
		into [MyDB].[MySchema].FOBT_5_Ins_8_ColonScpy    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_5_Ins_7_UGIBleed as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[colonoscopy_dt] between DATEADD(yy,-3,a.CBC_dt) and a.CBC_dt)
		go




---------------------------------------------------------------------------------------------
-----------------------------  Expected Follow-up Colonoscopy within 60 days ---------------------------
---------------------------------------------------------------------------------------------
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_9_ColonScpy_60d]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_9_ColonScpy_60d    --altered (ORD_...Dflt)
        select a.*
		into [MyDB].[MySchema].FOBT_5_Ins_9_ColonScpy_60d    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_5_Ins_8_ColonScpy as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[FOBT_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[colonoscopy_dt] between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,60,convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))
		go

		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_A]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_A    --altered (ORD_...Dflt)

        select a.* --
		into [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_A    --altered (ORD_...Dflt)
    	from [MyDB].[MySchema].FOBT_5_Ins_9_ColonScpy_60d as a    --altered (ORD_...Dflt)
		where not exists --
			(select * from [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID as b    --altered (ORD_...Dflt)
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321)
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 --(coalesce(b.ReferenceDateTime,b.visitDateTime) between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
				-- use visitdatetime			 
			 (b.visitDateTime between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,60,convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime)))))
go


	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_B1]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_B1    --altered (ORD_...Dflt)

        select a.* --
		into [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_B1    --altered (ORD_...Dflt)
     	from [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_A as a    --altered (ORD_...Dflt)
		where not exists --
			(select * from [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID as b    --altered (ORD_...Dflt)
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321)
			 -- There is a visit, but the StopCode is missing
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 --(coalesce(b.ReferenceDateTime,b.visitDateTime) between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
				--  use visitdatetime			 
			 (b.ReferenceDateTime between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,60,convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))
			  and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<60  
			  and b.PrimaryStopCodeSID=-1  
			  )
go



 	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_B2]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_B2    --altered (ORD_...Dflt)

        select a.* --
		into [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_B2    --altered (ORD_...Dflt)
     	from [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_B1 as a    --altered (ORD_...Dflt)
		where not exists --
			(select * from [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID as b    --altered (ORD_...Dflt)
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321)
			 -- There is a visit, but the StopCode is missing
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 --(coalesce(b.ReferenceDateTime,b.visitDateTime) between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
				-- use visitdatetime			 
			 (b.VisitDatetime between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,60,convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))
			  --and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<60  -- make sure not 2 or 3 years off
			  and b.PrimaryStopCodeSID<>-1  
			  and isnull( b.PrimaryStopCode,'') not in (33,307,321) and  isnull( b.SecondaryStopCode,'') not in (33,307,321)
											
			  )
go


 	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID    --altered (ORD_...Dflt)

        select a.* --
		into [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID    --altered (ORD_...Dflt)
     	from [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID_B2 as a    --altered (ORD_...Dflt)
		where not exists --
			(select * from [MyDB].[MySchema].FOBT_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID as b    --altered (ORD_...Dflt)
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321)
			 -- There is a visit, but the StopCode is missing
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 --(coalesce(b.ReferenceDateTime,b.visitDateTime) between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
				--  use visitdatetime			 
			 (b.ReferenceDateTime between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,60,convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))
			  and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<60  
			  and b.PrimaryStopCodeSID<>-1  
			  and ( b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321)) 											
			  )
go

		---------------------------------------------------------------------------------------------------
-----------------   High Risk - first instance of each patient  -------------------
---------------------------------------------------------------------------------------------------
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_5_Ins_A14_FirstOfPat]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_5_Ins_A14_FirstOfPat    --altered (ORD_...Dflt)

		SELECT a.*
		into [MyDB].[MySchema].FOBT_5_Ins_A14_FirstOfPat    --altered (ORD_...Dflt)
				from [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID as a    --altered (ORD_...Dflt)
				inner join 
				(         select a.patientssn, min(a.CBC_dt) as FirstClueDate		
				from [MyDB].[MySchema].FOBT_5_Ins_A01_GIRefer60d_joinByConsultSID as a		    --altered (ORD_...Dflt)
				where a.CBC_dt between (select sp_start from [MyDB].[MySchema].FOBT_0_1_inputP)    --altered (ORD_...Dflt)
								  and (select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP)			      --altered (ORD_...Dflt)
				group by a.patientssn
				) as sub
				on a.patientssn=sub.patientssn and a.CBC_dt=sub.FirstClueDate		
		where a.CBC_dt between (select sp_start from [MyDB].[MySchema].FOBT_0_1_inputP)    --altered (ORD_...Dflt)
		                  and (select sp_end from [MyDB].[MySchema].FOBT_0_1_inputP)		    --altered (ORD_...Dflt)
go

