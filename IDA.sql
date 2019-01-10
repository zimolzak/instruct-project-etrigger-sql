
-----------------------------
----                     ----
---   Trigger  - IDA   ---
----                     ----
-----------------------------

use master	

-- Set study parameters.
-----------------------
use master

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP]') is not null)	
	begin
		--Only one row (current running parameter) in this table
		delete from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP
	end
	else
	begin	
		CREATE TABLE ORD_Singh_201210017D.[Dflt].IDA_0_1_inputP(
		[trigger] [varchar](20) NULL,
		isVISN bit null,
		isSta3n bit null,
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

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_0_1_run_count]') is null)  -- never delete, alwasys append
	begin
		CREATE TABLE [ORD_Singh_201210017D].[Dflt].IDA_0_1_run_count(
		[trigger] [varchar](20) NULL,
		[round] [smallint] Not NULL default 0,
		isVISN bit null,
		isSta3n bit null,
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
declare @isVISN bit 
declare @isSta3n bit
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

-- Set study parameters
set @trigger='IDA'
set @isVISN=1
set @isSta3n=-1
set @VISN=15
set @Sta3n=580
--set @Sta3n=580 -- -1 all sta3n
set @run_date=getdate()
set @sp_start='2012-01-01 00:00:00'
set @sp_end='2012-12-31 23:59:59'
--  Follow-up period
set @fu_period=60
set @age_lower=40
set @age_upper=75

--  Output group (I = Intervention; C = Control)
set @op_grp='C'
set @round= ( case when (select count(*) from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_run_count])>0
				then (select max(round)+1 from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_run_count])
			else 1
			end)



INSERT INTO ORD_Singh_201210017D.[Dflt].[IDA_0_1_inputP]
           ([trigger]
		   ,isVISN
		   ,isSta3n
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
		   ,@isVISN
		   ,@isSta3n
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

select * from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP]

INSERT INTO [ORD_Singh_201210017D].[Dflt].[IDA_0_1_run_count]
           ([trigger]
		   ,isVISN
		   ,isSta3n
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
		   ,isVISN
		   ,isSta3n
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
		 from ORD_Singh_201210017D.[Dflt].[IDA_0_1_inputP] as Input

go



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].IDA_0_2_DxICD10CodeExc') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].IDA_0_2_DxICD10CodeExc
go


	CREATE TABLE ORD_Singh_201210017D.[Dflt].IDA_0_2_DxICD10CodeExc (
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go




insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C18.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C18.6'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C18.7'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C18.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C18.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C18.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C18.5'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C18.8'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C18.9'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C19.'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C20.'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C21.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C21.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'PrevColonCancer','ColonCancer','C21.8'



insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.00'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.40'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.50'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.01'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.41'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.51'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.02'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.42'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.52'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C93.00'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C93.01'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C93.02'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.00'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.01'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.02'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.20'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.21'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.22'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C95.00'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C95.01'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C95.02'



insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.3'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.7'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.8'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.9'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C78.7'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C23.'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.8'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.9'


insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.3'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.5'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.8'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.9'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.3'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.5'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.6'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.8'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.9'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.3'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.5'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.6'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.7'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.8'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.9'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C79.31'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C79.32'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C79.49'
--insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Brain Cancer', 'C79.40'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Ovarian Cancer','C56.9'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Ovarian Cancer','C56.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Ovarian Cancer','C56.2'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.3'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.7'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.8'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.9'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C33.'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.00'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.01'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.02'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.10'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.11'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.12'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.30'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.31'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.32'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.80'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.81'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.82'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.90'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.91'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.92'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C78.00'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C78.01'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C78.02'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pleural Cancer & Mesothelioma','C38.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pleural Cancer & Mesothelioma','C45.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pleural Cancer & Mesothelioma','C78.2'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Uterine Cancer','C55.'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C45.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.8'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C78.6'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','C90.00'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','C90.01'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','C90.02'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','D47.Z9'

--insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Tracheal Cancer','C33'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Tracheal Cancer','C33.'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Tracheal Cancer','C78.39'
--insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Tracheal Cancer','C78.30'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Hospice','','Z51.5'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K92.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K22.11'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K25.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K25.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K25.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K25.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K25.6'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K26.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K26.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K26.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K26.6'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K27.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K27.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K27.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K27.6'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K28.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K28.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K28.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'K28.6'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'I85.01'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'UpperGIBleeding','', 'I85.11'


insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','N92.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','N92.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','N92.4'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','N95.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','R31.9'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','R31.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','R31.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','R31.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','R04.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','N89.8'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','N92.5'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','N93.8'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','R04.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','R04.9'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','R04.89'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'OtherBleeding','','T79.2XXA'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','Z34.00'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','Z34.80'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','Z34.90'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','Z33.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.00'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.10'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.291'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.40'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.211'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.291'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.291'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.30'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.511'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.521'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.611'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.621'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.891'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.892'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.893'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.899'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.90'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.91'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.92'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.93'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Thalassemic','','D56.9'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Thalassemic','','D57.40'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Thalassemic','','D57.419'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Thalassemic','','D56.0'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Thalassemic','','D56.1'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Thalassemic','','D56.2'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Thalassemic','','D56.3'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Thalassemic','','D56.5'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Thalassemic','','D56.8'




if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_0_3_PreProcICD10ProcExc]') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].[IDA_0_3_PreProcICD10ProcExc]
go

	CREATE TABLE ORD_Singh_201210017D.[Dflt].[IDA_0_3_PreProcICD10ProcExc] (
	UniqueID int Identity(1,1) not null,
	[ICD10Proc_code_type] [varchar](50) NULL,
	[ICD10Proc_code_Name] [varchar](50) NULL,
	[ICD10ProcCode] [varchar](10) NULL
	) 
go


insert into ORD_Singh_201210017D.[Dflt].[IDA_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Colectomy','','0DTE4ZZ'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Colectomy','','0DTE0ZZ'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Colectomy','','0DTE7ZZ'
insert into ORD_Singh_201210017D.[Dflt].[IDA_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Colectomy','','0DTE8ZZ'

insert into ORD_Singh_201210017D.[Dflt].[IDA_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 'Colonoscopy','','0DJD8ZZ'



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].IDA_0_4_DxICD9CodeExc') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].IDA_0_4_DxICD9CodeExc
go


	CREATE TABLE ORD_Singh_201210017D.[Dflt].IDA_0_4_DxICD9CodeExc (
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go

insert into  ORD_Singh_201210017D.[Dflt].IDA_0_4_DxICD9CodeExc (
	[ICD9Code]
	) 
select distinct ICD9Code from CDWWork.dim.ICD9 as dimICD9
where	
			DimICD9.ICD9Code in (
					-------------------------------------------------------- Previous Colorectal Cancer
			-- Move to ProblemList
			---- Colon Cancer Codes
			--	'154.0','154.1','154.8',
			-------------------------------------------------------- Terminal
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
		--or DimICD9.ICD9Code like
		---- Colon Cancer Codes
		--	'153.%'			
			-------------------------------------------------------- Terminal				
		or DimICD9.ICD9Code like
		-- Leukemia (Acute Only)
			'207.2%'
		-- Hepatocelllular Cancer

		or DimICD9.ICD9Code like
		-- Biliary Cancer
			'156.%'
		or DimICD9.ICD9Code like
		-- Esophageal Cancer
			'150.%'
		or DimICD9.ICD9Code like
		-- Gastric Cancer
			'151.%'
		-- Brain Cancer
		-- Ovarian Cancer
		or DimICD9.ICD9Code like
		-- Pancreatic Cancer
			'157.%'
		-- Lung Cancer			
		or DimICD9.ICD9Code like
		-- Pleural Cancer & Mesothelioma
				'163.%'
		or DimICD9.ICD9Code like
		--Uterine Cancer
				'179.%'
		--Peritonel, Omental & Mesenteric Cancer
		or DimICD9.ICD9Code like
		--Myeloma
				'203.0%'
		--Tracheal Cancer
			-------------------------------------------------------- Hospice / Palliative Care
		-- Hospice / Palliative Care
			-------------------------------------------------------- Evidence of Upper Bleeding
		-- Hematamesis		
		-- Ulcer of Esophagus,stomach or duodenum with Bleeding		
		or DimICD9.ICD9Code like '531.0%' or DimICD9.ICD9Code like '531.2%' or DimICD9.ICD9Code like '531.4%' or DimICD9.ICD9Code like '531.6%'
		or DimICD9.ICD9Code like '532.0%' or DimICD9.ICD9Code like '532.2%' or DimICD9.ICD9Code like '532.4%' or DimICD9.ICD9Code like '532.6%'
		or DimICD9.ICD9Code like '533.0%' or DimICD9.ICD9Code like '533.2%' or DimICD9.ICD9Code like '533.4%' or DimICD9.ICD9Code like '533.6%'
		or DimICD9.ICD9Code like '534.0%' or DimICD9.ICD9Code like '534.2%' or DimICD9.ICD9Code like '534.4%' or DimICD9.ICD9Code like '534.6%'
		-- Esophageal Varices with Bleeding		
			----------------------------------------------------------- Only IDA only--------------------------
			-------------------------------------------------------- Other bleeding source			
		or DimICD9.ICD9Code like
		-- Hematuria
			'599.7%'
		-- Menorrhagia
		-- Epistaxis	
		-- Uterine, cervical or Vaginal Bleeding	
		or DimICD9.ICD9Code like
		-- Hemoptysis
			'786.3%' 
		--Second Hemorrhage
			----------------------------------------------------------- Thalessemia
    	or DimICD9.ICD9Code like
		-- Thalessemia
			'282.4%'
			----------------------------------------------------------- Pregnancy
		-- Pregnancy

go

update [ORD_Singh_201210017D].[dflt].IDA_0_4_DxICD9CodeExc
                                     
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


-- Extract of all IDA values
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_1_AllIDA]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_1_AllIDA]

	SELECT [LabChemSID]
      ,labChem.[Sta3n]
      ,labChem.[LabChemTestSID]
      ,[PatientSID]
      ,[LabChemSpecimenDateTime] 
      ,[LabChemCompleteDateTime] 
      ,[LabChemResultValue]
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
	  ,component
      ,labChem.[Units]
 into [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_1_AllIDA]
  FROM [ORD_Singh_201210017D].[src].Chem_PatientLabChem as labChem
  inner join cdwwork.dim.labchemtest as dimTest
  on labChem.[LabChemTestSID]=dimTest.LabChemTestSID
  inner join cdwwork.dim.LOINC as LOINC
  on labChem.LOINCSID=LOINC.LOINCSID
  inner join cdwwork.dim.VistaSite as VistaSite
		on labChem.sta3n=VistaSite.Sta3n
  where 
    labChem.[LabChemCompleteDateTime] between DATEADD(mm,-13,(select sp_start from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)) --12 month before Clue Date for Ferritin
											and DATEADD(dd,61,(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)) 
	and VistaSite.VISN=(select VISN from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP) 	
	and ( LOINC.LOINC in ( '718-7','30313-1','30350-3','30352-9'  ----HEMOGLOBIN 
							,'30428-7','787-2' --MCV
							,'2276-4'  --FERRITIN

							--'11272-2'
							--,'47282-9'
							--,'62242-3' --MCV

							--,'14723-1'
							--,'14724-9'
							--,'20567-4'
							----,'2276-4'
							--,'24373-3'
							--,'35209-6'
							--,'48141-6'
							--,'53048-5'
							--,'74807-9'
							--,'86914-9' --FERRITIN
							)
	--or component like '%HEMOGLOBIN%'		--HEMOGLOBIN 
	)								
	--and labchem.sta3n<>556 -- Exclude NorthChicago	
go


-- Extract of all Low HGB values 
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_2_LowHGB]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_2_LowHGB]
go

select [LabChemSID]
      ,a.[Sta3n]
      ,[LabChemTestSID]
      ,a.[PatientSID]
      ,[LabChemSpecimenDateTime]
      ,[LabChemCompleteDateTime] as HGB_dt
      ,[LabChemResultValue]	
      ,[LabChemResultNumericValue] as HGB_value
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
	  ,component
      ,[Units]
	 	,VStatus.DateOfBirth as DOB
		,VStatus.DateOfDeath as DOD
		,VStatus.Gender as Sex
		,VStatus.PatientSSN
		,VStatus.ScrSSN
		,VStatus.PatientICN
into [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_2_LowHGB]
from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_1_AllIDA] as a
left join (select distinct * from ORD_Singh_201210017D.src.SPatient_SPatient) as VStatus
on a.PatientSID=VStatus.PatientSID and a.sta3n=VStatus.sta3n
where ([LabChemCompleteDateTime] between (select sp_start from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)
											and DateAdd(dd,1,(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)))
	  and (
			
		LOINC in ( '718-7','30313-1','30350-3','30352-9')  ----HEMOGLOBIN
		--or component like '%HEMOGLOBIN%'
			)	
	 and [LabChemResultNumericValue]<=11

go

-- Extract of all low MCV values
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_3_LowMCV]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_3_LowMCV]
go

select [LabChemSID]
      ,a.[Sta3n]
      ,[LabChemTestSID]
      ,a.[PatientSID]
      ,[LabChemSpecimenDateTime]
      ,[LabChemCompleteDateTime] as MCV_dt
      ,[LabChemResultValue]	
      ,[LabChemResultNumericValue] as MCV_value
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
	 	,VStatus.DateOfBirth as DOB
		,VStatus.DateOfDeath as DOD
		,VStatus.Gender as Sex
		,VStatus.PatientSSN
		,VStatus.ScrSSN
		,VStatus.PatientICN
into [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_3_LowMCV]
from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_1_AllIDA] as a
left join (select distinct * from ORD_Singh_201210017D.src.SPatient_SPatient) as VStatus
on a.PatientSID=VStatus.PatientSID and a.sta3n=VStatus.sta3n
where ([LabChemCompleteDateTime] between (select sp_start from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP) 
											and DateAdd(dd,1,(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)))
											--and DATEADD(d,1,(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)))
	 and (
		LOINC in ( '30428-7','787-2'

							--'11272-2'
							--,'47282-9'
							--,'62242-3' --MCV
		          ) 
		  ) 
	 and [LabChemResultNumericValue]<=81
	 

go

-- Extract of all ferretin values for all patients
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_4_ferretin]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_4_ferretin]
go

select [LabChemSID]
      ,a.[Sta3n]
      ,[LabChemTestSID]
      ,a.[PatientSID]
      ,[LabChemSpecimenDateTime]
      ,[LabChemCompleteDateTime] as fer_dt
      ,[LabChemResultValue]
      ,[LabChemResultNumericValue] as fer_value
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
	 	,VStatus.DateOfBirth as DOB
		,VStatus.DateOfDeath as DOD
		,VStatus.Gender as Sex
		,VStatus.PatientSSN
		,VStatus.ScrSSN
		,VStatus.PatientICN
into [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_4_ferretin]
from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_1_AllIDA] as a
left join (select distinct * from ORD_Singh_201210017D.src.SPatient_SPatient) as VStatus
on a.PatientSID=VStatus.PatientSID and a.sta3n=VStatus.sta3n
where 	  (
			
		LOINC in ( '2276-4'  ----FERRITIN 
				--,'14723-1'
				--,'14724-9'
				--,'20567-4'
				----,'2276-4'
				--,'24373-3'
				--,'35209-6'
				--,'48141-6'
				--,'53048-5'
				--,'74807-9'
				--,'86914-9' 
				)
		  ) 

go 





-- hgb_mcv
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_5_HGB_MCV]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_5_HGB_MCV]
go

select a.[PatientSID],a.[HGB_dt] as Result_dt,a.[HGB_value],b.[MCV_value]
     ,a.[LabChemSID] as HGB_LabChemSID,a.[LOINC] as HGB_LOINC,a.[LabChemTestIEN] as HGB_LabChemTestIEN,a.[RequestingStaffSID] as HGB_RequestingStaffSID
	 ,b.[LabChemSID] as MCV_LabChemSID,b.[LOINC] as MCV_LOINC,b.[LabChemTestIEN] as MCV_LabChemTestIEN,b.[RequestingStaffSID] as MCV_RequestingStaffSID
	 ,a.[Sta3n]
	 ,a.DOB,a.DOD,a.Sex,a.PatientSSN,a.ScrSSN,a.PatientICN
into [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_5_HGB_MCV]
from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_2_LowHGB] as a 
inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_3_LowMCV] as b
on a.PatientSSN = b.PatientSSN and a.[HGB_dt] = b.[MCV_dt]
go



--hgb_mcv_ferr
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_6_hgb_mcv_ferr]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_6_hgb_mcv_ferr]
go

select * 
into [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_6_hgb_mcv_ferr]
from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_5_HGB_MCV] as a
where not exists 
	(select * from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_4_ferretin] as b
	 where a.PatientSSN = b.PatientSSN and	 
	    b.[fer_dt] between DATEADD(mm,-12,a.[Result_dt]) 
											and DATEADD(dd,60,a.[Result_dt]) 
	 and  b.[fer_value] >= 100)



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_7_Recent_ferr]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_1_Inc_7_Recent_ferr
go


select a.PatientSSN, a.result_dt,max(b.[fer_dt]) as ferr_dt
into  [ORD_Singh_201210017D].[Dflt].IDA_1_Inc_7_Recent_ferr
from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_6_hgb_mcv_ferr] as a 
left join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_4_ferretin] as b
on a.PatientSSN=b.PatientSSN and b.[fer_dt] <=DATEADD(dd,60,a.[Result_dt])											
group by a.PatientSSN,a.result_dt




if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_7_Recent_ferr_Value]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_1_Inc_7_Recent_ferr_Value
go

select a.PatientSSN, a.result_dt, a.ferr_dt, b.[fer_value]
into [ORD_Singh_201210017D].[Dflt].IDA_1_Inc_7_Recent_ferr_Value
from [ORD_Singh_201210017D].[Dflt].IDA_1_Inc_7_Recent_ferr as a
left join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_4_ferretin]  as b  
on a.PatientSSN = b.PatientSSN and a.ferr_dt = b.[fer_dt]
group by a.PatientSSN, a.result_dt, a.ferr_dt, b.[fer_value]


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_8_IncIns]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_1_Inc_8_IncIns
go

select distinct * 
into [ORD_Singh_201210017D].[Dflt].IDA_1_Inc_8_IncIns
from (
select a.PatientSSN
	  ,a.[PatientSID]
	  ,a.[Sta3n]  
      ,a.[Result_dt] as CBC_dt
      ,[HGB_value]
      ,[MCV_value]
	  ,b.Ferr_dt as latest_ferr_dt
	  ,b.[fer_value] as latest_ferr_value
      ,[HGB_LabChemSID]
      ,[HGB_LOINC]
	  ,HGB_LabChemTestIEN
      ,[MCV_LabChemSID]
      ,[MCV_LOINC]
	  ,MCV_LabChemTestIEN 
	  ,a.HGB_RequestingStaffSID     
	  ,a.DOB,a.DOD,a.Sex,a.ScrSSN,a.PatientICN
from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_6_hgb_mcv_ferr] as a
left join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_7_Recent_ferr_Value] as b
on a.patientssn = b.patientssn and a.[Result_dt] = b.result_dt
where a.[Result_dt] between (select sp_start from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP])
             and (select sp_end from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP])
			) sub


go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_1_Inc_9_IncPat
go

	select distinct VStatus.Sta3n,VStatus.PatientSID,VStatus.patientSSN, VStatus.ScrSSN,VStatus.PatientICN
	into [ORD_Singh_201210017D].[Dflt].IDA_1_Inc_9_IncPat
	from [ORD_Singh_201210017D].[Dflt].IDA_1_Inc_8_IncIns as a
	left join (select distinct * from ORD_Singh_201210017D.src.SPatient_SPatient) as VStatus
	on a.PatientSSN=VStatus.PatientSSN 
	

go

---------------------------------------Exclusion Dx----------------------------------------
-------------------------------------------------------------------------------------------
--  Extract of previous colon cancer codes from patient problemlist

if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_0_PrevCLCFromProblemList_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_0_PrevCLCFromProblemList_ICD9
go

SELECT 
	 	p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	  ,Plist.*	  
into [ORD_Singh_201210017D].[Dflt].IDA_2_ExcDx_0_PrevCLCFromProblemList_ICD9
 FROM [ORD_Singh_201210017D].[Src].[Outpat_ProblemList] as Plist
  inner join CDWWork.Dim.ICD as ICD
  on Plist.ICD9SID=ICD.ICDSID
inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on Plist.sta3n=p.sta3n and Plist.patientsid=p.patientsid
where 
 
plist.[EnteredDate] <= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP]),(select sp_end from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP]))
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


if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_0_PrevCLCFromProblemList_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_0_PrevCLCFromProblemList_ICD10
go


SELECT 
	 	p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	  ,Plist.*	  
into [ORD_Singh_201210017D].[Dflt].IDA_2_ExcDx_0_PrevCLCFromProblemList_ICD10
 FROM [ORD_Singh_201210017D].[Src].[Outpat_ProblemList] as Plist
  inner join CDWWork.Dim.ICD10 as ICD10
  on Plist.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Plist.ICD10SID=ICD10Diag.ICD10SID
  inner join ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] as  ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code
inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on Plist.sta3n=p.sta3n and Plist.patientsid=p.patientsid
where 
 
plist.[EnteredDate] <= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP]),(select sp_end from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP]))
and
( 
 ICD10CodeList.dx_code_type='PrevColonCancer'	
)

if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_0_PrevCLCFromProblemList]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_0_PrevCLCFromProblemList
go

select * into [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_0_PrevCLCFromProblemList
	from (
		select * from [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_0_PrevCLCFromProblemList_ICD9
		union
		select * from [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_0_PrevCLCFromProblemList_ICD10
	) sub
	go

--  Extract of all DX codes from outpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_1_OutPatDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_1_OutPatDx_ICD9

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
into [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_1_OutPatDx_ICD9
  FROM [ORD_Singh_201210017D].[src].[outpat_VDiagnosis] as Diag
  inner join CDWWork.Dim.ICD9 as ICD9
  on Diag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DiagnosisVersion as ICD9Diag
  on Diag.ICD9SID=ICD9Diag.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].IDA_0_4_DxICD9CodeExc as targetCode
on targetCode.ICD9Code=ICD9.ICD9Code
inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
 
[VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)) 
go


--  Extract of all DX codes from outpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_1_OutPatDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_1_OutPatDx_ICD10

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
into [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_1_OutPatDx_ICD10
  FROM [ORD_Singh_201210017D].[src].[outpat_VDiagnosis] as Diag
  inner join CDWWork.Dim.ICD10 as ICD10
  on Diag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Diag.ICD10SID=ICD10Diag.ICD10SID
inner join ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code
inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
 
[VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)) 

go


-- Extract of all DX Codes for all potential patients from surgical files
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_2_SurgDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_2_SurgDx_ICD9

SELECT 
	  -- surg.[SurgerySID]
      surg.[Sta3n]
      ,[SurgeryIEN]
      ,Surg.[PatientSID]
      ,[VisitSID]
      ,[DateOfOperationNumeric]  as dx_dt
      ,[PrincipalDiagnosis]
      ,[PrincipalPostOpDiag]
      ,[PrincipalPreOpDiagnosis]
      ,[PrincipalProcedure]
      ,[ProcedureCompleted]  
	  ,SurgDx.[PrinPostopDiagnosisCode] as ICDCode
	  ,targetCode.dx_code_type
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
  into [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_2_SurgDx_ICD9
    FROM [ORD_Singh_201210017D].[Src].[Surgery_Surgery_130] as surg
	inner join [ORD_Singh_201210017D].[Src].[Surgery_surgeryprcdrdgnsscodes_136] as SurgDx  
  --on surg.[SurgerySID]=SurgDx.[SurgerySID]
  on surg.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  and surg.Sta3n=SurgDx.Sta3n
  inner join [ORD_Singh_201210017D].[dflt].IDA_0_4_DxICD9CodeExc as targetCode
on targetCode.ICD9Code=SurgDx.PrinPostopDiagnosisCode
    inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on Surg.sta3n=p.sta3n and surg.patientsid=p.patientsid
   where  
  
  [DateOfOperationNumeric]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)) 


	go


if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_2_SurgDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_2_SurgDx_ICD10

SELECT 
	  -- surg.[SurgerySID]
      surg.[Sta3n]
      ,[SurgeryIEN]
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
  into [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_2_SurgDx_ICD10
    FROM [ORD_Singh_201210017D].[Src].[Surgery_Surgery_130] as surg
	inner join [ORD_Singh_201210017D].[Src].[Surgery_surgeryprcdrdgnsscodes_136] as SurgDx  
  --on surg.[SurgerySID]=SurgDx.[SurgerySID]
  on surg.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  and surg.Sta3n=SurgDx.Sta3n
inner join ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] as ICD10CodeList
on SurgDx.PrinPostopDiagnosisCode=ICD10CodeList.ICD10Code
    inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on Surg.sta3n=p.sta3n and surg.patientsid=p.patientsid
   where  
  
  [DateOfOperationNumeric]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)) 

	go



--  Extract of all DX codes from inpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_3_A_InPatDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_3_A_InPatDx_ICD9

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
	  ,targetCode.dx_code_type
	  ,ICD9Diag.ICD9Diagnosis as ICDDiagnosis	    
	  ,InPatDiag.[ICD10SID]
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	into  [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_3_A_InPatDx_ICD9
  FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientDiagnosis] as InPatDiag
  inner join CDWWork.Dim.ICD9 as ICD9
  on InPatDiag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DiagnosisVersion as ICD9Diag
  on InPatDiag.ICD9SID=ICD9Diag.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].IDA_0_4_DxICD9CodeExc as targetCode
on targetCode.ICD9Code=ICD9.ICD9Code
  inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
  where 
  
[DischargeDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)) 
	go


if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_3_A_InPatDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_3_A_InPatDx_ICD10

SELECT 
	  [InpatientDiagnosisSID] 
      ,InPatDiag.[Sta3n]
      --,[OrdinalNumber]
      ,[InpatientSID]  
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
	into  [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_3_A_InPatDx_ICD10
  FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientDiagnosis] as InPatDiag
  inner join CDWWork.Dim.ICD10 as ICD10
  on InPatDiag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on InPatDiag.ICD10SID=ICD10Diag.ICD10SID
inner join ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code
  inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
  where 
  
[DischargeDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)) 

	go



if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9

SELECT 
       Diag.[Sta3n]
      ,Diag.[PatientSID]
	  ,ICD9.ICD9Code as ICD9
	  ,targetCode.dx_code_type
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
into [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9
  FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientFeeDiagnosis] as Diag
  inner join CDWWork.Dim.ICD9 as ICD9
  on Diag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DescriptionVersion AS V
  on icd9.ICD9SID=v.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].IDA_0_4_DxICD9CodeExc as targetCode
on targetCode.ICD9Code=ICD9.ICD9Code
inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
 
[AdmitDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)) 
go



	if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[IDA_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10

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
into [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10
  FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientFeeDiagnosis] as Diag
  inner join CDWWork.Dim.ICD10 as ICD10
  on Diag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Diag.ICD10SID=ICD10Diag.ICD10SID
inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
  inner join ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
where 
 
[AdmitDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)) 

go




--Fee ICD Dx 
  		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9]') is not null)
		drop table ORD_Singh_201210017D.[Dflt].IDA_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9


SELECT  
	  c.patientssn
	,d.InitialTreatmentDateTime as dx_dt
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,[ServiceProvidedCPTSID]
      ,a.[ICD9SID]
      ,[ICD10SID]
	  ,ICD9.ICD9Code as ICD9
	  ,targetCode.dx_code_type
	  ,v.[ICD9Description]
      ,[AmountClaimed]
      ,[AmountPaid]
	  ,patientICN
	  ,ScrSSN
into ORD_Singh_201210017D.[Dflt].IDA_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9
  FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as d
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join CDWWork.Dim.ICD9 as ICD9
  on a.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DescriptionVersion AS V
  on icd9.ICD9SID=v.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].IDA_0_4_DxICD9CodeExc as targetCode
on targetCode.ICD9Code=ICD9.ICD9Code
  inner join ORD_Singh_201210017D.[Dflt].[IDA_1_Inc_9_IncPat] as c
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from ORD_Singh_201210017D.[Dflt].IDA_0_1_inputP))

go



--Fee ICD Dx 
  		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10]') is not null)
		drop table ORD_Singh_201210017D.[Dflt].IDA_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10


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
into ORD_Singh_201210017D.[Dflt].IDA_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10
  FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as d
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join CDWWork.Dim.ICD10 as ICD10
  on a.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on a.ICD10SID=ICD10Diag.ICD10SID
  inner join ORD_Singh_201210017D.[Dflt].[IDA_1_Inc_9_IncPat] as c
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
inner join ORD_Singh_201210017D.[Dflt].[IDA_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
  where d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from ORD_Singh_201210017D.[Dflt].IDA_0_1_inputP))

go


	--  Extract of all exclusion diagnoses from surgical, inpatient, and outpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_4_ALLDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_4_ALLDx_ICD9
go

select patientSSN,sta3n, PatientSID,dx_dt,ICDCode as ICD9,dx_code_type,'Dx-Surg' as dataSource,patientICN,ScrSSN
into [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_4_ALLDx_ICD9
from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_2_SurgDx_ICD9]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICDCode as ICD9,dx_code_type,'DX-OutPat' as dataSource,patientICN,ScrSSN from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_1_OutPatDx_ICD9]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICDCode as ICD9,dx_code_type,'Dx-InPat' as dataSource,patientICN,ScrSSN from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_3_A_InPatDx_ICD9]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD9,dx_code_type,'Dx-InPatFee' as dataSource,patientICN,ScrSSN from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD9,dx_code_type,'Dx-InPatFeeService' as dataSource,patientICN,ScrSSN from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9]


alter table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_4_ALLDx_ICD9
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

update [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_4_ALLDx_ICD9
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


	--  Extract of all exclusion diagnoses from surgical, inpatient, and outpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_4_ALLDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_4_ALLDx_ICD10
go

select patientSSN,sta3n, PatientSID,dx_dt,ICDCode as ICDCode,dx_code_type,'Dx-Surg' as dataSource
into [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_4_ALLDx_ICD10
from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_2_SurgDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'DX-OutPat' as dataSource from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_1_OutPatDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10Code,dx_code_type,'Dx-InPat' as dataSource from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_3_A_InPatDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'Dx-InPatFee' as dataSource from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,[InitialTreatmentDateTime] as [dx_dt],[ICD10code],dx_code_type,'Dx-InPatFee' as dataSource from [ORD_Singh_201210017D].[Dflt].IDA_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10

Alter table [ORD_Singh_201210017D].[Dflt].IDA_2_ExcDx_4_ALLDx_ICD10
	add 
	--crc_dx_dt datetime, 
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


update [ORD_Singh_201210017D].[Dflt].IDA_2_ExcDx_4_ALLDx_ICD10
set term_dx_dt= case when dx_code_type='Terminal' then dx_dt else null end,
	hospice_dt= case when dx_code_type='hospice' then dx_dt else null end,
	--crc_dx_dt= case when dx_code_type='PrevColonCancer' then dx_dt else null end,
	preg_dx_dt=case when dx_code_type='Pregnancy' then dx_dt else null end,
	ugi_bleed_dx_dt= case when dx_code_type='UpperGIBleeding' then dx_dt else null end,
	other_bleed_dx_dt=case when dx_code_type='OtherBleeding' then dx_dt else null end,
	thal_dx_dt=case when dx_code_type='Thalassemic' then dx_dt else null end




if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_4_Union_ALLDx_ICD]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].IDA_2_ExcDx_4_Union_ALLDx_ICD
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
	,thal_dx_dt
	--,colonoscopy_dt
	--,colectomy_dt
into [ORD_Singh_201210017D].[Dflt].IDA_2_ExcDx_4_Union_ALLDx_ICD
from [ORD_Singh_201210017D].[Dflt].IDA_2_ExcDx_4_ALLDx_ICD9
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
	,thal_dx_dt
	--,colonoscopy_dt
	--,colectomy_dt
from [ORD_Singh_201210017D].[Dflt].IDA_2_ExcDx_4_ALLDx_ICD10
go


	------------------------------------------------------------------------------------------------------------
	-------------------------------- trigger Non-Dx exclusions
	------------------------------------------------------------------------------------------------------------

--if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_1_Hospit_Admit]') is not null)
--	drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_1_Hospit_Admit
--go

--SELECT [InpatientSID]
--      ,inpat.[Sta3n]
--	  ,'Hospit-Admit' as DataSource
--      ,[PatientSID]
--      ,[AdmitDateTime]
--      ,[DischargeDateTime]      
--  into  [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_1_Hospit_Admit
--  FROM [VINCI1].[Inpat].[Inpatient] as inpat  
--  where patientsid in (select patientsid from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat])
--  and
--	(
--		([AdmitDateTime] between DATEADD(DD,-14,(select sp_start from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP])) and DATEADD(DD,14,(select sp_end from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP])))
--		 or
--		([DischargeDateTime] between DATEADD(DD,-14,(select sp_start from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP])) and DATEADD(DD,14,(select sp_end from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP])))
--		 or
--		(
--			 ([AdmitDateTime] < DATEADD(DD,-14,(select sp_start from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP])))
--			  and (   ([DischargeDateTime] is null) or 
--			                             ([DischargeDateTime] > DATEADD(DD,14,(select sp_end from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP])))
--			      )
--		 )
--	 )

--	 go



	-- Previous ICD procedures from inpatient  

				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc

			  select pat.patientssn,pat.scrssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime]
	      ,DimICD9Proc.[ICDProcedureCode],DimICD9Proc.ProcedureName,DimICD9Proc.ICDProcedureDescription,pat.patientICN
into [ORD_Singh_201210017D].[dflt].IDA_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc
  FROM [ORD_Singh_201210017D].[src].[inpat_InpatientICDProcedure] as ICDProc
  inner join cdwwork.dim.ICDProcedure as DimICD9Proc
  on ICDProc.[ICD9ProcedureSID]=DimICD9Proc.[ICDProcedureSID]  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat]) as pat
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where DimICD9Proc.[ICDProcedureCode] in (  
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
							)

 and [ICDProcedureDateTime] < DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
 go


				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc

			  select pat.patientssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime]
		      ,ICDProc.ICD9ProcedureSID	  
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
into [ORD_Singh_201210017D].[dflt].IDA_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc
  FROM [ORD_Singh_201210017D].[src].[inpat_InpatientICDProcedure] as ICDProc
  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat]) as pat
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
inner join   [ORD_Singh_201210017D].[Dflt].[IDA_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
 where 

  [ICDProcedureDateTime] < DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
  go


			if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc

select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[ICDProcedureDateTime]
	      ,DimICD9Proc.[ICDProcedureCode],DimICD9Proc.ProcedureName,DimICD9Proc.ICDProcedureDescription,pat.patientICN
into [ORD_Singh_201210017D].[dflt].IDA_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc
  FROM [ORD_Singh_201210017D].[src].[inpat_CensusICDProcedure] as a
  inner join cdwwork.dim.ICDProcedure as DimICD9Proc
  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICDProcedureSID]  
   inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[IDA_1_Inc_9_IncPat]) as pat
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where DimICD9Proc.[ICDProcedureCode] in (   
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
							)

 and [ICDProcedureDateTime] < DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
go


			if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc

 select pat.patientssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime]
	      		      ,ICDProc.ICD9ProcedureSID	  
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
into [ORD_Singh_201210017D].[dflt].IDA_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc
  FROM [ORD_Singh_201210017D].[src].[inpat_CensusICDProcedure] as ICDProc
    inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
inner join   [ORD_Singh_201210017D].[Dflt].[IDA_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
   inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[IDA_1_Inc_9_IncPat]) as pat
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where [ICDProcedureDateTime] < DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc

select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
	      ,DimICD9Proc.[ICDProcedureCode],DimICD9Proc.ProcedureName,DimICD9Proc.ICDProcedureDescription,pat.patientICN
into [ORD_Singh_201210017D].[dflt].IDA_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc
  FROM [ORD_Singh_201210017D].[src].[inpat_InpatientSurgicalProcedure] as a
  inner join cdwwork.dim.ICDProcedure as DimICD9Proc
  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICDProcedureSID]  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[IDA_1_Inc_9_IncPat]) as pat
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where DimICD9Proc.[ICDProcedureCode] in (   
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
								)

 and [SurgicalProcedureDateTime] <dateadd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))

go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc

select pat.patientssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[SurgicalProcedureDateTime]
		      ,ICDProc.ICD9ProcedureSID	  
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
into [ORD_Singh_201210017D].[dflt].IDA_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc
  FROM [ORD_Singh_201210017D].[src].[inpat_InpatientSurgicalProcedure] as ICDProc
  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
inner join   [ORD_Singh_201210017D].[Dflt].[IDA_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[IDA_1_Inc_9_IncPat]) as pat
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where [SurgicalProcedureDateTime] <dateadd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))

go



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc

 select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
	      ,DimICD9Proc.[ICDProcedureCode],DimICD9Proc.ProcedureName,DimICD9Proc.ICDProcedureDescription,pat.patientICN
into [ORD_Singh_201210017D].[dflt].IDA_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc
  FROM [ORD_Singh_201210017D].[src].[inpat_CensusSurgicalProcedure] as a
  inner join cdwwork.dim.ICDProcedure as DimICD9Proc
  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICDProcedureSID] 
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[IDA_1_Inc_9_IncPat]) as pat
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where DimICD9Proc.[ICDProcedureCode] in (   
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
						)

 and [SurgicalProcedureDateTime] <DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc

 select pat.patientssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
		      ,a.ICD9ProcedureSID	  
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
into [ORD_Singh_201210017D].[dflt].IDA_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc
  FROM [ORD_Singh_201210017D].[src].[inpat_CensusSurgicalProcedure] as a
  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
inner join   [ORD_Singh_201210017D].[Dflt].[IDA_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[IDA_1_Inc_9_IncPat]) as pat
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where 
 [SurgicalProcedureDateTime] <DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
go


	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc	

	select pat.patientssn,pat.scrssn,a.sta3n,b.patientsid,b.[TreatmentFromDateTime]
	      ,DimICD9Proc.[ICDProcedureCode],DimICD9Proc.ProcedureName,DimICD9Proc.ICDProcedureDescription,pat.patientICN
	into [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc
	--from vinci1.[Fee].[FeeInpatInvoiceICDProcedure] as a
	from [ORD_Singh_201210017D].src.[Fee_FeeInpatInvoiceICDProcedure] as a
	inner join[ORD_Singh_201210017D].src.[Fee_FeeInpatInvoice] as b
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
	 inner join cdwwork.dim.ICDProcedure as DimICD9Proc
	  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICDProcedureSID] 
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[IDA_1_Inc_9_IncPat]) as pat
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where DimICD9Proc.[ICDProcedureCode] in (
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
							)

 and [TreatmentFromDateTime] < DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
 go


 if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc	

	select pat.patientssn,a.sta3n,b.patientsid,b.[TreatmentFromDateTime]
	      		      ,a.ICD9ProcedureSID	  
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDesc.ICD10ProcedureDescription
		  	  ,PreProcICD10Proclist.ICD10Proc_code_type
	into [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc
	--from vinci1.[Fee].[FeeInpatInvoiceICDProcedure] as a
	from [ORD_Singh_201210017D].src.[Fee_FeeInpatInvoiceICDProcedure] as a
	inner join[ORD_Singh_201210017D].src.[Fee_FeeInpatInvoice] as b
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
inner join   [ORD_Singh_201210017D].[Dflt].[IDA_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[IDA_1_Inc_9_IncPat]) as pat
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where [TreatmentFromDateTime] < DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
 go


 --Fee ICD
  		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD9Proc]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD9Proc
										 


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
into [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD9Proc
  FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as d
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join cdwwork.dim.icd as b
  on a.[ICD9SID]=b.icdsid
  inner join ORD_Singh_201210017D.[Dflt].[IDA_1_Inc_9_IncPat] as c
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where  b.ICDcode in 		(	
							  --Colonoscopy
								'45.23'
							   --Colectomy
							   ,'45.81','45.82','45.83'
					)
and	d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP]))
go	
											

 --Fee ICD
  		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD10Proc]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD10Proc


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
into [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD10Proc
FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as d
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
    inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
  on a.[ICD10SID]=DimICD10Proc.[ICD10ProcedureSID] 
  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDesc
  on DimICD10Proc.ICD10ProcedureSID=DimICD10ProcDesc.ICD10ProcedureSID
inner join   [ORD_Singh_201210017D].[Dflt].[IDA_0_3_PreProcICD10ProcExc] as PreProcICD10Proclist
on PreProcICD10Proclist.ICD10ProcCode=DimICD10Proc.ICD10ProcedureCode
  inner join ORD_Singh_201210017D.[Dflt].[IDA_1_Inc_9_IncPat] as c
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where  d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP]))
go	




if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc
	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICDProcedureCode]
      ,[ICDProcedureDescription]
	  ,'Inp-InpICD'	  as datasource
    into  [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc
	from ORD_Singh_201210017D.[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc]
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICDProcedureCode]
      ,[ICDProcedureDescription]
	  ,'Inp-CensusICD'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICDProcedureCode]
      ,[ICDProcedureDescription]
	 ,'Inp-InpSurg'	  as datasource	 
	from ORD_Singh_201210017D.[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICDProcedureCode]
      ,[ICDProcedureDescription]
	 ,'Inp-CensusSurg'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICDProcedureCode]      
      ,[ICDProcedureDescription]
	 ,'Inp-FeeICDProc'	  as datasource
	 from ORD_Singh_201210017D.[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,InitialTreatmentDateTime as Proc_dt
	  ,ICDcode
	  ,[ICDDescription]
	 ,'FeeICDProc'	  as datasource
	 from ORD_Singh_201210017D.[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD9Proc

	
go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc
	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	  ,'Inp-InpICD'	  as datasource
    into  [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc
	from ORD_Singh_201210017D.[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc]
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	  ,'Inp-CensusICD'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	 ,'Inp-InpSurg'	  as datasource	 
	from ORD_Singh_201210017D.[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	 ,'Inp-CensusSurg'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	 ,'Inp-FeeICDProc'	  as datasource
	 from ORD_Singh_201210017D.[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,InitialTreatmentDateTime as Proc_dt
      ,[ICD10ProcedureCode]
      ,[ICD10ProcedureDescription]
      ,ICD10Proc_code_type
	 ,'Inp-FeeICDProc'	  as datasource
	 from ORD_Singh_201210017D.[Dflt].IDA_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_ICD10Proc

	
go


			-- Previous  procedures from outpatient 

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_6_Outpat') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_6_Outpat
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
  into [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_6_Outpat
  FROM [ORD_Singh_201210017D].[src].[outpat_VProcedure] as VProc
  inner join CDWWork.[Dim].[CPT] as DimCPT 
  on  VProc.[CPTSID]=DimCPT.CPTSID
  inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
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

  
  		-- previous procedures from surgical 

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_7_surg]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_7_surg
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
  into [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_7_surg
    FROM [ORD_Singh_201210017D].[Src].[Surgery_Surgery_130] as surg
  inner join [ORD_Singh_201210017D].[Src].[Surgery_surgeryprcdrdgnsscodes_136] as SurgDx
    on surg.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  and surg.Sta3n=SurgDx.Sta3n
    inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
  on Surg.sta3n=p.sta3n and surg.patientsid=p.patientsid
  where  

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

	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT

select pat.patientssn,pat.scrssn,CPTProc.sta3n,CPTProc.patientsid,CPTProc.[CPTProcedureDateTime]
	      ,DimCPT.[CPTCode],DimCPT.CPTName,DimCPT.CPTDescription ,patientICN
into  [ORD_Singh_201210017D].[dflt].IDA_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT
  FROM [ORD_Singh_201210017D].[Src].[Inpat_InpatientCPTProcedure] as CPTProc
  inner join cdwwork.dim.CPT as DimCPT
  on CPTProc.[CPTSID]=DimCPT.CPTSID  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[IDA_1_Inc_9_IncPat]) as pat
  on CPTProc.patientsid=pat.patientsid and CPTProc.sta3n=pat.sta3n
 where DimCPT.[CPTCode] in (   
 			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392',
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212')							
and CPTProc.[CPTProcedureDateTime] <= DateAdd(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
go


----- Fee: Surg, proc, img
  --Fee CPT
  		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_9_FeeCPT]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_9_FeeCPT

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
into [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_9_FeeCPT
  FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as d
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join cdwwork.dim.cpt as b
  on a.[ServiceProvidedCPTSID]=b.cptsid
  inner join ORD_Singh_201210017D.[Dflt].[IDA_1_Inc_9_IncPat] as c
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
  and	d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP]))

  go



-- All colonoscopy procedures  
	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy


select patientSSN,sta3n,patientSID,[VProcedureDateTime] as colonoscopy_dt ,'PrevColonScpy-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
into [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy
from [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_6_Outpat 
		where [VProcedureDateTime] is not null
		and [CPTCode] in (  
			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392')
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as colonoscopy_dt,'PrevColonScpy-InPatICD' as datasource,ICDProcedureCode as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc]
		where [Proc_dt] is not null
		and ICDProcedureCode in (   --Colonoscopy
								'45.23' )
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as colonoscopy_dt,'PrevColonScpy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc]
		where [Proc_dt] is not null
		--Colonoscopy
		and [ICD10Proc_code_type]='Colonoscopy'
	UNION ALL	
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as colonoscopy_dt,'PrevColonScpy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT]
		where [CPTProcedureDateTime] is not null
		and [CPTCode] in (   --Colonoscopy								 			
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392' )
	UNION ALL
select patientSSN,sta3n,patientSID,[DateOfOperationNumeric] as colonoscopy_dt,'PrevColonScpy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_7_surg 
		where [DateOfOperationNumeric] is not null
		and [PrincipalProcedureCode] in (	
  			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392')
	UNION ALL
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as colonoscopy_dt,'PrevColonScpy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_9_FeeCPT 
		where InitialTreatmentDateTime is not null
		and CPTCode in (	
  			--colonoscopy
			'44387','44388','44389','44391','44392','44394',
			'45378','45379','45380','45381','45382','45383','45384','45385','45386','45387',
			'45355','45391','45392')
	
	go

-- All colectomy procedures 
	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_All_2_Colectomy]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_All_2_Colectomy


select patientSSN,sta3n,patientSID,[VProcedureDateTime] as colectomy_dt ,'PrevColectomy-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
into [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_All_2_Colectomy
from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_6_Outpat]
		where [VProcedureDateTime] is not null
		and  [CPTCode]  in (  
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212')
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as colectomy_dt,'PrevColectomy-InPatICD' as datasource,[ICDProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc]
		where [Proc_dt] is not null
		and [ICDProcedureCode] in (  --colectomy
								'45.81','45.82','45.83' )
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as colectomy_dt,'PrevColectomy-InPatICD' as datasource,[ICD10ProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc]
		where [Proc_dt] is not null
		and [ICD10ProcedureCode]='Colectomy' --colectomy
	UNION ALL	
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as colectomy_dt,'PrevColectomy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT]
		where [CPTProcedureDateTime] is not null
		and [CPTCode] in (   
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212' )
							   
	UNION ALL
select patientSSN,sta3n,patientSID,[DateOfOperationNumeric] as colectomy_dt,'PrevColectomy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_7_surg]
		where [DateOfOperationNumeric] is not null
		and   [PrincipalProcedureCode] in (  
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212')
	UNION ALL
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as colectomy_dt,'PrevColectomy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].IDA_3_Exc_NonDx_3_PrevProc_9_FeeCPT 
		where InitialTreatmentDateTime is not null
		and CPTCode in (	
			--colectomy
			'44150','44151','44155','44156','44157','44158',
			'44202','44210','44211','44212')


---------------------------------All Referral------------------------------------------------
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_6C_Hlp_1_Hospice_Referral_AllVisit]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_1_Hospice_Referral_AllVisit
					
							select p.patientSSN,p.patientICN,p.ScrSSN
							,V.Sta3n,V.PatientSID,V.Visitsid,V.VisitDatetime,V.primaryStopcodeSID,V.SecondaryStopcodeSID					
					into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_1_Hospice_Referral_AllVisit										
					from [ORD_Singh_201210017D].[src].[outpat_Visit] as V
                    inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
                    on v.sta3n=p.sta3n and v.patientsid=p.patientsid
				where 
				 V.VisitDateTime between dateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
										and DateAdd(dd,30+(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP))
				--Hospice referral needs to see one year prior				
		go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_6C_Hlp_2_Hospice_Referral_AllVisit_StopCode]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_2_Hospice_Referral_AllVisit_StopCode
					
					select v.*,code1.stopcode as PrimaryStopCode,code1.stopcodename as PrimaryStopCodeName,code2.stopcode as SecondaryStopCode,code2.stopcodename as SecondaryStopCodeName
					into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_2_Hospice_Referral_AllVisit_StopCode
					from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_1_Hospice_Referral_AllVisit as V
					left join [CDWWork].[Dim].[StopCode] as code1
					on V.PrimaryStopCodeSID=code1.StopCodeSID	and V.Sta3n=code1.Sta3n		
					left join [CDWWork].[Dim].[StopCode] as code2
					on V.SecondaryStopCodeSID=code2.StopCodeSID	and v.sta3n=code2.sta3n

go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_6C_Hlp_3_Hospice_Referral_VisitStopCodeTIU]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_3_Hospice_Referral_VisitStopCodeTIU
go

					select v.*
					--,c.consultsid,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
					--c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName
					,T.[TIUDocumentSID],T.[EntryDateTime],T.[ReferenceDateTime],ReportText,e.tiustandardtitle,T.ConsultSID
					into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_3_Hospice_Referral_VisitStopCodeTIU					
					from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_2_Hospice_Referral_AllVisit_StopCode as V
				   left join ORD_Singh_201210017D.[src].[TIU_TIUDocument_8925_IEN] as T
				   --left join ORD_Singh_201210017D.[src].[TIU_TIUDocument_8925] as T
					on T.VisitSID=V.Visitsid
					left join [CDW_TIU].[TIU].[TIUDocument_8925_02] as RptText
					on T.TIUDocumentsid=RptText.TIUDocumentsid
					left join cdwwork.dim.[TIUDocumentDefinition] as d                                         
					on t.[TIUDocumentDefinitionSID]=d.[TIUDocumentDefinitionSID]
					left join cdwwork.dim.TIUStandardTitle as e
					on d.TIUStandardTitleSID=e.TIUStandardTitleSID
					--left join vinci1.con.Consult as C										                    
					--on C.[TIUDocumentSID]=T.[TIUDocumentSID]
				--where isnull(T.OpCode,'')<>'D'



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID

						select v.*
					--,c.consultsid
					,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
					c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName,
					c.placeofconsultation,	  
					c.requestType, -- weather the request is a consult or procedure
					c.[InpatOutpat], -- the ordering person to indicate if the service is to be rendered on an outpatient or Inpatients basis.
					c.[RemoteService]
					--,T.[TIUDocumentSID],ReportText,e.tiustandardtitle
					into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID					
                    from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_3_Hospice_Referral_VisitStopCodeTIU as V
					--left join [TIU_2013].[TIU].[TIUDocument_v030] as T
					--on T.VisitSID=V.Visitsid
					--left join [TIU_2013].[TIU].[TIUDocument_8925_02] as RptText
					--on T.TIUDocumentsid=RptText.TIUDocumentsid
					left join vinci1.con.Consult as C										                    
					on C.ConsultSID=V.ConsultSID
				
		go



-------------------------------------------------------------------------------------------
---------------------------  Age Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].IDA_5_Ins_1_Age') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_1_Age
select	a.* 
into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_1_Age
from [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_8_IncIns] as a
  where DATEDIFF(yy,DOB,a.[CBC_dt]) >= 40 
	and DATEDIFF(yy,DOB,a.[CBC_dt]) < 76
	go

-------------------------------------------------------------------------------------------
---------------------------  Alive Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].IDA_5_Ins_2_ALive') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_2_ALive
select a.*
into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_2_ALive
from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_1_Age as a
 where 
        [DOD] is null 		 
		or (DOD is not null 
				and ( 
					DATEADD(dd,-(select fu_period from [ORD_Singh_201210017D].[Dflt].[IDA_0_1_inputP]),dod)> a.cbc_dt
					)
				)	   	     
go

-------------------------------------------------------------------------------------------
---------------------------  3: Colon/Rectal Cancer Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		--  all instances with CRC cancer exclusions removed
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_3_PrevCRCCancer]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_3_PrevCRCCancer

        select a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_3_PrevCRCCancer
		from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_2_ALive as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].IDA_2_ExcDx_0_PrevCLCFromProblemList as b
			 where a.[PatientSSN] = b.[PatientSSN]
			 			and b.EnteredDate between dateadd(yy,-1,a.CBC_dt) and a.CBC_dt)
			 
		go


-------------------------------------------------------------------------------------------
---------------------------  4: total colectomy Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		--  all instances with total colectomy exclusions removed
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_4_colectomy]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_4_colectomy

        select a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_4_colectomy
		from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_3_PrevCRCCancer as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_All_2_Colectomy] as b
			 where a.[PatientSSN] = b.[PatientSSN]
			 and b.[colectomy_dt] <= DATEADD(dd,60,a.CBC_dt))
			 
		go

-------------------------------------------------------------------------------------------
---------------------------  5: Terminal illness or major dx Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_5_Term]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_5_Term

        select a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_5_Term
		from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_4_colectomy as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_4_Union_ALLDx_ICD] as b
			 where a.[PatientSSN] = b.[PatientSSN]
			 and b.[term_dx_dt] between DATEADD(yy,-1,a.CBC_dt) and DATEADD(dd,60,a.CBC_dt))
			 
		go



-------------------------------------------------------------------------------------------
---------------------------  7: GI bleeding Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_7_UGIBleed]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_7_UGIBleed

        select a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_7_UGIBleed
		from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_5_Term as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_4_Union_ALLDx_ICD] as b
			 where a.[PatientSSN] = b.[PatientSSN]
			 and b.[ugi_bleed_dx_dt] between DATEADD(mm,-6,a.CBC_dt) and a.CBC_dt)
			 
		go

-------------------------------------------------------------------------------------------

---------------------------  8: Colonoscopy Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_8_ColonScpy]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_8_ColonScpy
        select a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_8_ColonScpy
		from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_7_UGIBleed as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy] as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[colonoscopy_dt] between DATEADD(yy,-3,a.CBC_dt) and a.CBC_dt)

		go




		-------------------------------------------------------------------------------------------
---------------------------  9b: Other bleeding Exclusions-Other  IDA only---------------------------
-------------------------------------------------------------------------------------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_9_OtherBleed_Other]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_9_OtherBleed_Other
        select a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_9_OtherBleed_Other		
		from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_8_ColonScpy as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_4_Union_ALLDx_ICD] as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[other_bleed_dx_dt] between DATEADD(mm,-6,a.CBC_dt) and a.CBC_dt)			 
		go



-------------------------------------------------------------------------------------------
---------------------------  12: Pregnant IDA only ---------------------------
-------------------------------------------------------------------------------------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A12_Pregnant]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A12_Pregnant
        select a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A12_Pregnant
		from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_9_OtherBleed_Other as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_4_Union_ALLDx_ICD] as b
				inner join [ORD_Singh_201210017D].[src].[SPatient_SPatient] as VStatus
				on b.PatientSID=VStatus.PatientSID
			 where a.[PatientSSN] = b.[PatientSSN] 
			 and b.[preg_dx_dt] between DATEADD(yy,-1,a.CBC_dt) and DATEADD(dd,60,a.CBC_dt)			 
			)
		go

-------------------------------------------------------------------------------------------
---------------------------  13: Thalassemia IDA only---------------------------
-------------------------------------------------------------------------------------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13_Thalasemia]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A13_Thalasemia
        select a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A13_Thalasemia
		from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A12_Pregnant as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_4_Union_ALLDx_ICD] as b
			 where a.[PatientSSN] = b.[PatientSSN] 
			 and b.[thal_dx_dt] < DATEADD(dd,60,a.CBC_dt)			 
			)
		go



		-------------------------------------------------------------------------------------------
---------------------------  6: Hospice or palliative care Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13A_Hospice]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A13A_Hospice

        select a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A13A_Hospice
		from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A13_Thalasemia as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[IDA_2_ExcDx_4_Union_ALLDx_ICD] as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[hospice_dt] between DATEADD(yy,-1,a.CBC_dt) and DATEADD(dd,60,a.CBC_dt))
			 
		go

		--[VINCI1].[Inpat].[Inpatient] specilty, bedsection code
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B1_Inpat_HospiceSpecialty]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B1_Inpat_HospiceSpecialty]
		go


SELECT *

	into  [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B1_Inpat_HospiceSpecialty]
	 from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A13A_Hospice as x
		where not exists(
		select * FROM [ORD_Singh_201210017D].[src].[Inpat_Inpatient] as a
		inner join CDWWork.Dim.Specialty as s
		on a.DischargeFromSpecialtySID=s.SpecialtySID and a.sta3n=s.sta3n
		inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(s.PTFCode)) in ('96','1F') 
		and x.patientSSN=p.patientsSN and a.[DischargeDateTime] 
		between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),x.CBC_dt)
		)
		go


					--Outside Hospice care ( VA Paid/Fee Based) see the coding policy
				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B2_Hospice_FeeInpatInvoice_PurposeOfVisit]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B2_Hospice_FeeInpatInvoice_PurposeOfVisit]
		go


SELECT *

	into  [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B2_Hospice_FeeInpatInvoice_PurposeOfVisit]
	from [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B1_Inpat_HospiceSpecialty] as x
		where not exists(
		select  b.FeePurposeOfVisit,a.* 
		from [ORD_Singh_201210017D].[src].[Fee_FeeInpatInvoice] as a
		inner join cdwwork.dim.FeePurposeOfVisit as b
		on a.FeePurposeOfVisitSID=b.FeePurposeOfVisitSID
		inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(b.AustinCode)) in ('43','37','38','77','78')  
		and x.patientSSN=p.patientsSN and a.TreatmentFromDateTime 
		between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),x.CBC_dt)
		)
		go



				--Outside Hospice care ( VA Paid/Fee Based) see the coding policy
				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B3_Hospice_FeeServiceProvided_HCFAType]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B3_Hospice_FeeServiceProvided_HCFAType]
		go


SELECT *
	into  [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B3_Hospice_FeeServiceProvided_HCFAType]
	from [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B2_Hospice_FeeInpatInvoice_PurposeOfVisit] as x
		where not exists(
		select  b.IBTypeOfServiceCode,a.* 
		from [ORD_Singh_201210017D].[src].[fee_FeeServiceProvided] as a
		inner join [ORD_Singh_201210017D].[src].[fee_FeeInitialTreatment] as d
		on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
		inner join cdwwork.dim.IBTypeOfService as b
		on a.FeeInitialTreatmentSID=b.IBTypeOfServiceSID
		inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(b.IBTypeOfServiceCode)) in ('H')  
		and x.patientSSN=p.patientsSN and d.[InitialTreatmentDateTime]
		between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),x.CBC_dt)
		)
		go


					--Outside Hospice care ( VA Paid/Fee Based) see the coding policy
				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B4_Hospice_FeeServiceProvided_PLCSRVCType]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B4_Hospice_FeeServiceProvided_PLCSRVCType]
		go


SELECT *
	into  [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B4_Hospice_FeeServiceProvided_PLCSRVCType]
	from [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B3_Hospice_FeeServiceProvided_HCFAType] as x
		where not exists(
		select  b.IBPlaceOfServiceCode,a.* 
		from [ORD_Singh_201210017D].[src].[Fee_FeeServiceProvided] as a
		inner join [ORD_Singh_201210017D].[src].[Fee_FeeInitialTreatment] as d
		on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
		inner join cdwwork.dim.IBPlaceOfService as b
		on a.IBPlaceOfServiceSID=b.IBPlaceOfServiceSID
		inner join [ORD_Singh_201210017D].[Dflt].[IDA_1_Inc_9_IncPat] as p
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(b.IBPlaceOfServiceCode)) in ('34','H','Y')  
		and x.patientSSN=p.patientsSN and d.[InitialTreatmentDateTime]
		between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP),x.CBC_dt)
		)
		go




-------------------------------------------------------------------------------------------
---------------------------  6C: Hospice or palliative care REFERRAL--------------------------
-------------------------------------------------------------------------------------------

  

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13D1_Hospice_Refer_joinByConsultSID]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A13D1_Hospice_Refer_joinByConsultSID
				
		select *
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A13D1_Hospice_Refer_joinByConsultSID
        from [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A13B4_Hospice_FeeServiceProvided_PLCSRVCType] as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID as b
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (351,353)   or b.SecondaryStopCode in (351,353)   
			 -- There is a visit, but the StopCode is missing
					or 	(b.[ConsultToRequestserviceName] like '%Hospice%' or b.[ConsultToRequestserviceName] like '%palliative%'
					or b.TIUStandardTitle like '%Hospice%' or b.TIUStandardTitle like '%palliative%')
					)
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitdatetime) between DATEADD(yy,-1, convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime)))
				and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<60  
								)

go

---------------------------------------------------------------------------------------------
-----------------------------  Expected Follow-up Colonoscopy within 60 days ---------------------------
---------------------------------------------------------------------------------------------
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A14_ColonScpy_60d]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A14_ColonScpy_60d
        select a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A14_ColonScpy_60d
		from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A13D1_Hospice_Refer_joinByConsultSID as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[IDA_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy] as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[colonoscopy_dt] between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,60,convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))
		go


		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_A]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_A

        select a.* --
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_A
    	from [ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A14_ColonScpy_60d] as a
		where not exists --
			(select * from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID as b
			 where (                              
			 --With Stopcode
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321)
			 -- There is a visit, but no StopCode
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


	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_B1]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_B1

        select a.* --
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_B1
     	from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_A as a
		where not exists --
			(select * from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID as b
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
			 (b.ReferenceDateTime between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,60,convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))
			  and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<60  
			  and b.PrimaryStopCodeSID=-1  
			  )
go


 	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_B2]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_B2

        select a.* --
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_B2
     	from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_B1 as a
		where not exists --
			(select * from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID as b
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321)
			 -- There is a visit, but no StopCode
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and		 
			 (b.VisitDatetime between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,60,convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))
			  --and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<60  
			  and b.PrimaryStopCodeSID<>-1 
			  and isnull( b.PrimaryStopCode,'') not in (33,307,321) and  isnull( b.SecondaryStopCode,'') not in (33,307,321)
											
			  )
go


 	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A15_GIRefer60d_joinByConsultSID]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID

        select a.* --
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID
     	from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID_B2 as a
		where not exists --
			(select * from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_6C_Hlp_4_Hospice_Referral_VisitTIUConsult_joinByConsultSID as b
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321)
			 -- There is a visit, but no StopCode 
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 --(coalesce(b.ReferenceDateTime,b.visitDateTime) between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))			 
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
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[IDA_5_Ins_A16_FirstOfPat]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A16_FirstOfPat

		SELECT a.*
		into [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A16_FirstOfPat
				from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID as a
				inner join 
				(         select a.patientssn, min(a.CBC_dt) as FirstClueDate		
				from [ORD_Singh_201210017D].[Dflt].IDA_5_Ins_A15_GIRefer60d_joinByConsultSID as a		
				where a.CBC_dt between (select sp_start from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)
								  and (select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)			  
				group by a.patientssn
				) as sub
				on a.patientssn=sub.patientssn and a.CBC_dt=sub.FirstClueDate	
		where a.CBC_dt between (select sp_start from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)
		                  and (select sp_end from [ORD_Singh_201210017D].[Dflt].IDA_0_1_inputP)		
go

