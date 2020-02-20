-----------------------------
----                     ----
---   Trigger -HCC   ---
----                     ----
-----------------------------


-- Set study parameters.
-----------------------
use master
go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_0_1_inputP]') is not null)	
	begin
		--Only one row (current running parameter) in this table
		delete from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP
	end
	else
	begin	
		CREATE TABLE ORD_Singh_201210017D.[Dflt].HCC_0_1_inputP(
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

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_0_1_run_count]') is null)  -- never delete, alwasys append
	begin
		CREATE TABLE [ORD_Singh_201210017D].[Dflt].HCC_0_1_run_count(
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

-- Set study parameters
set @trigger='HCC'
set @VISN=12
--set @Sta3n=580 -- -1 all sta3n
set @run_date=getdate()
set @sp_start='2012-01-01 00:00:00'
set @sp_end='2012-12-31 23:59:59'
--  Follow-up period
set @fu_period=60
set @age_lower=18
--set @age_upper=75

--  Output group (I = Intervention; C = Control)
set @op_grp='C'
set @round= ( case when (select count(*) from [ORD_Singh_201210017D].[Dflt].[HCC_0_1_run_count])>0
				then (select max(round)+1 from [ORD_Singh_201210017D].[Dflt].[HCC_0_1_run_count])
			else 1
			end)

INSERT INTO ORD_Singh_201210017D.[Dflt].[HCC_0_1_inputP]
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

select * from [ORD_Singh_201210017D].[Dflt].[HCC_0_1_inputP]

INSERT INTO [ORD_Singh_201210017D].[Dflt].[HCC_0_1_run_count]
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
		 from ORD_Singh_201210017D.[Dflt].[HCC_0_1_inputP] as Input

go





if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].HCC_0_2_DxICD10CodeExc') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].HCC_0_2_DxICD10CodeExc
go


	CREATE TABLE ORD_Singh_201210017D.[Dflt].HCC_0_2_DxICD10CodeExc (
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go


insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'ActiveHCCCancer','HCCCancer','C22.0'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'ActiveHCCCancer','HCCCancer','C22.2'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'ActiveHCCCancer','HCCCancer','C22.7'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'ActiveHCCCancer','HCCCancer','C22.8'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'ActiveHCCCancer','HCCCancer','C22.1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'ActiveHCCCancer','HCCCancer','C22.9'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'ActiveHCCCancer','HCCCancer','C78.7'



insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.40'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.50'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.60'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.01'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.41'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.51'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.02'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.42'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C92.52'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C93.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C93.01'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C93.02'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.01'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.02'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.20'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.21'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C94.22'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C95.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C95.01'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Terminal','Leukemia (Acute Only)','C95.02'



--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Hepatocelllular Cancer','C22.0'
--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Hepatocelllular Cancer','C22.2'
--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Hepatocelllular Cancer','C22.3'
--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Hepatocelllular Cancer','C22.4'
--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Hepatocelllular Cancer','C22.7'
--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Hepatocelllular Cancer','C22.8'
--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Hepatocelllular Cancer','C22.1'
--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Hepatocelllular Cancer','C22.9'
--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Hepatocelllular Cancer','C78.7'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C23.'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.0'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.8'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.9'


insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.3'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.4'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.5'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.8'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.9'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.0'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.4'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.3'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.2'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.5'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.6'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.8'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.9'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.0'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.2'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.3'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.4'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.5'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.6'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.7'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.8'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.9'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C79.31'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C79.32'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C79.49'
--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Brain Cancer', 'C79.40'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Ovarian Cancer','C56.9'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Ovarian Cancer','C56.1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Ovarian Cancer','C56.2'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.0'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.2'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.3'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.4'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.7'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.8'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.9'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C33.'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.01'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.02'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.10'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.11'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.12'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.2'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.30'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.31'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.32'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.80'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.81'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.82'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.90'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.91'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C34.92'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C78.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C78.01'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Lung Cancer','C78.02'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pleural Cancer & Mesothelioma','C38.4'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pleural Cancer & Mesothelioma','C45.0'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pleural Cancer & Mesothelioma','C78.2'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Uterine Cancer','C55.'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C45.1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.8'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.2'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C78.6'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','C90.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','C90.01'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','C90.02'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','D47.Z9'

--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Tracheal Cancer','C33'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Tracheal Cancer','C33.'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Tracheal Cancer','C78.39'
--insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'Terminal','Tracheal Cancer','C78.30'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Hospice','','Z51.5'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'GonadalTumor','OvarianTumor', 'C56.9'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'GonadalTumor','OvarianTumor', 'C57.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'GonadalTumor','OvarianTumor', 'C57.4'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'GonadalTumor','OvarianTumor', 'D27.9'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'GonadalTumor','OvarianTumor', 'C56.9'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'GonadalTumor','OvarianTumor', 'C57.00'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'GonadalTumor','TesticularTumor', 'C62.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'GonadalTumor','TesticularTumor', 'D29.20'


insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','Z34.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','Z34.80'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','Z34.90'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','Z33.1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.00'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.10'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.291'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.40'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.211'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.291'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.291'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.30'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.511'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.521'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.611'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.621'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.891'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.892'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.893'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.899'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.90'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.91'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.92'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O09.93'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','N96.'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O02.81'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O00.0'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O00.1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O00.2'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O00.8'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 'Pregnancy','','O00.9'


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_0_3_PreProcICD10ProcExc]') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc]
go

	CREATE TABLE ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] (
	UniqueID int Identity(1,1) not null,
	[ICD10Proc_code_type] [varchar](50) NULL,
	[ICD10Proc_code_Name] [varchar](50) NULL,
	[ICD10ProcCode] [varchar](10) NULL
	) 
go


insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverBiopsy ','','0F903ZX'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverBiopsy ','','0F904ZX'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverBiopsy ','','0FB03ZX'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverBiopsy ','','0F900ZX'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverBiopsy ','','0FB00ZX'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverBiopsy ','','0FB03ZX'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverBiopsy ','','0FB04ZX'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverBiopsy ','','0FJ03ZZ'



insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverImag','','BW2000Z'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverImag','','BW200ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverImag','','BW2010Z'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverImag','','BW201ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverImag','','BW20Y0Z'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverImag','','BW20YZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverImag','','BW20ZZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverImag','','BW40ZZZ'

insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0FC00ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0FC03ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0FC04ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0FB00ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0FB03ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0FB04ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0F500ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0F503ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0F504ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0FY00Z0'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0FY00Z1'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0FY00Z2'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','0F903ZZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','3E0J7GC'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','3E0J7HZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','3E0J7KZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','3E0J7TZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','3E0J8GC'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','3E0J8HZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','3E0J8KZ'
insert into ORD_Singh_201210017D.[Dflt].[HCC_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LiverSurg','','3E0J8TZ'


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].HCC_0_4_DxICD9CodeExc') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].HCC_0_4_DxICD9CodeExc
go


	CREATE TABLE ORD_Singh_201210017D.[Dflt].HCC_0_4_DxICD9CodeExc (
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go

insert into  ORD_Singh_201210017D.[Dflt].HCC_0_4_DxICD9CodeExc (
	[ICD9Code]
	) 
select distinct ICD9Code from CDWWork.dim.ICD9 as dimICD9
where	
			DimICD9.ICD9Code in (
			-------------------------------------------------------- Previous HCC
			-- Move to ProblemList
			-------------------------------------------------------- Terminal
			-- Leukemia (Acute Only)
				'205.0','206.0','207.0','208.0',
				--	'204.1','204.2','204.8','204.9','205.1','205.2','205.3','205.8','205.9','206.1',
				--	'206.2','206.8','206.9','207.1','207.2','207.8','208.1','208.2','208.8','208.9',
			---- Hepatocelllular Cancer
			--	'155.0','155.1','155.2','197.7',
			-- Biliary Cancer
			-- Esophageal Cancer
			-- Gastric Cancer
			-- Brain Cancer
				'191.0','191.1','191.2','191.3','191.4','191.5','191.6','191.7','191.8','191.9','198.3','198.4',
			-- Ovarian Cancer
				'183.0',
			-- Pancreatic Cancer
			-- Lung Cancer
				'197.0',
			---- Pleural Cancer & Mesothelioma
			--	 '197.2',
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
			----------------------------------------------------------- Pregnancy
			-- Pregnancy
				'629.81','631.0','633.0','633.01','633.10',--'633.2%','633.8%','633.9%',

				'V22.0','V22.1','V22.2','V23.0','V23.1','V23.2',
				'V23.3','V23.41','V23.49','V23.5','V23.7','V23.81',
				'V23.82','V23.83','V23.84','V23.89','V23.9',
			--Gonadal Tumors
				'183.0','183.2','183.8','186.0','222.0'--,'220.%'
		)
			-------------------------------------------------------- Previous HCC Cancer
		--or ICD99.ICD99Code like
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
		'162.2%'
		or DimICD9.ICD9Code like
		'162.3%'
		or DimICD9.ICD9Code like
		'162.4%'
		or DimICD9.ICD9Code like
		'162.5%'
		or DimICD9.ICD9Code like
		'162.8%'
		or DimICD9.ICD9Code like
		'162.9%'						
		--or DimICD9.ICD9Code like
		-- Pleural Cancer & Mesothelioma
		--		'163.%'
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
			----------------------------------------------------------- Pregnancy
		or DimICD9.ICD9Code like
		-- Pregnancy
				'633.2%'
		or DimICD9.ICD9Code like
				'633.8%'
		or DimICD9.ICD9Code like
				'633.9%'
			--------------------------------------------------------------Gonadal Tumors
		or DimICD9.ICD9Code like
		--Gonadal Tumors
				'220.%'

go

update [ORD_Singh_201210017D].[dflt].HCC_0_4_DxICD9CodeExc
                                     
set   dx_code_type = case

		when ICD9Code in (
			-- Leukemia (Acute Only)
				'205.0','206.0','207.0','208.0',
				--	'204.1','204.2','204.8','204.9','205.1','205.2','205.3','205.8','205.9','206.1',
				--	'206.2','206.8','206.9','207.1','207.2','207.8','208.1','208.2','208.8','208.9',
			---- Hepatocelllular Cancer
			--	'155.0','155.1','155.2','197.7',
			-- Biliary Cancer
			-- Esophageal Cancer
			-- Gastric Cancer
			-- Brain Cancer
				'191.0','191.1','191.2','191.3','191.4','191.5','191.6','191.7','191.8','191.9','198.3','198.4',
			-- Ovarian Cancer
				'183.0',
			-- Pancreatic Cancer
			-- Lung Cancer
				'197.0',
			---- Pleural Cancer & Mesothelioma
			--	 '197.2',
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
						'162.2%'
						or ICD9Code like
						'162.3%'
						or ICD9Code like
						'162.4%'
						or ICD9Code like
						'162.5%'
						or ICD9Code like
						'162.8%'
						or ICD9Code like
						'162.9%'
						-- Pleural Cancer & Mesothelioma
						--		'163.%'
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
			-- Pregnancy
				'629.81','631.0','633.0','633.01','633.10',--'633.2%','633.8%','633.9%',
				'V22.0','V22.1','V22.2','V23.0','V23.1','V23.2',
				'V23.3','V23.41','V23.49','V23.5','V23.7','V23.81',
				'V23.82','V23.83','V23.84','V23.89','V23.9'
			)  		or ICD9Code like
						'633.2%'
						or ICD9Code like
						'633.8%'
						or ICD9Code like
						'633.9%'
			then 'Pregnancy'
		when ICD9Code in ('183.0','183.2','183.8','186.0','222.0'
				) or ICD9Code like 				
				'220.%'
			 then 'GonadalTumors'
		else NULL
	end
go


-- Extract of all HCC values 
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_1_AllAFP]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_1_Inc_1_AllAFP

	SELECT [LabChemSID]
      ,labChem.[Sta3n]
      ,labChem.[LabChemTestSID]
      ,[PatientSID]
      ,[LabChemSpecimenDateTime] as AFP_dt
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
      ,labChem.[Units]
 into [ORD_Singh_201210017D].[Dflt].HCC_1_Inc_1_AllAFP
  FROM [ORD_Singh_201210017D].[src].[Chem_PatientLabChem] as labChem
  inner join cdwwork.dim.labchemtest as dimTest
  on labChem.[LabChemTestSID]=dimTest.LabChemTestSID
  inner join cdwwork.dim.LOINC as LOINC
  on labChem.LOINCSID=LOINC.LOINCSID
  inner join cdwwork.dim.VistaSite as VistaSite
		on labChem.sta3n=VistaSite.Sta3n
  where labChem.CohortName='Cohort20170313'and
    labChem.[LabChemCompleteDateTime] between DATEADD(mm,-13,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)) 
											and DATEADD(dd,61,(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)) 
	and VistaSite.VISN=(select VISN from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP) 	
	--and labChem.Sta3n=(select sta3n from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)	
	and (LOINC.LOINCIEN in ( '1834'
							,'53962'
							,'42332'
							,'31993'
							,'23811'
							,'19176')

			--				,'31993'
			--				,'20450'
			--				,'53961'
			--				,'83072'  --IA
			--				,'83073'  --IA
			--				)

	  --or  ltrim(rtrim([LabChemTestName])) like '%alpha%fet[a,o]%' or ltrim(rtrim([LabChemTestName]))like '%fet[a,o]%alpha%' 
	  --or (ltrim(rtrim([LabChemTestName])) like '%AFP%' and 
			--									not (ltrim(rtrim([LabChemTestName])) like '%[a-y]AFP[a-y]%'  -- zzAFP still used in earlier years
			--									or ltrim(rtrim([LabChemTestName])) like '%[a-y]AFP%'
			--									or ltrim(rtrim([LabChemTestName])) like '%AFP[a-y]%'))		 
	  --or  ltrim(rtrim([LabChemPrintTestName])) like '%alpha%fet[a,o]%' or ltrim(rtrim([LabChemPrintTestName]))like '%fet[a,o]%alpha%' 
	  --or (ltrim(rtrim([LabChemPrintTestName])) like '%AFP%' and 
			--									not (ltrim(rtrim([LabChemPrintTestName])) like '%[a-y]AFP[a-y]%'  -- zzAFP still used in earlier years
			--									or ltrim(rtrim([LabChemPrintTestName])) like '%[a-y]AFP%'
			--									or ltrim(rtrim([LabChemPrintTestName])) like '%AFP[a-y]%'))
		 )
go


	 -- compare with 20
	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_1_AllAFP_GT20]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_1_AllAFP_GT20]

	select DISTINCT * into [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_1_AllAFP_GT20]
	from [ORD_Singh_201210017D].[Dflt].HCC_1_Inc_1_AllAFP
	where [LabChemResultNumericValue]>20									 
	or (labchemResultValue like '%>%' and isnumeric(substring(replace(replace(replace(ltrim(rtrim(LabChemResultValue)),'>',''),',',''),' ',''),patindex('%>%',replace(replace(replace(ltrim(rtrim(LabChemResultValue)),'>',''),',',''),' ',''))+1,3))=1
								  and convert(float,substring(replace(replace(replace(ltrim(rtrim(LabChemResultValue)),'>',''),',',''),' ',''),patindex('%>%',replace(replace(replace(ltrim(rtrim(LabChemResultValue)),'>',''),',',''),' ',''))+1,3))>20)

  go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_8_IncIns]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_1_Inc_8_IncIns
go

select 	DISTINCT [LabChemSID]
      ,a.[Sta3n]
      ,[LabChemTestSID]
      ,a.[PatientSID]
      ,[AFP_dt]
      ,[LabChemCompleteDateTime]
      ,[LabChemResultValue]
      ,[LabChemResultNumericValue]
      ,[RequestingStaffSID]
      ,[LabChemTestIEN]
      ,[LabChemTestName]
      ,[LabChemPrintTestName]
      ,[LOINCSID]
      ,[LOINC]
      ,[LOINCIEN]
	    ,convert(varchar(10),VStatus.BirthDateTime,120) as DOB
		,convert(varchar(10),VStatus.DeathDateTime,120) as DOD
		,VStatus.gender as Sex
		,VStatus.PatientSSN
		,VStatus.ScrSSN
		,VStatus.PatientICN
into [ORD_Singh_201210017D].[Dflt].HCC_1_Inc_8_IncIns
from [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_1_AllAFP_GT20] as a
left join ORD_Singh_201210017D.src.SPatient_SPatient as VStatus
on a.PatientSID=VStatus.PatientSID and a.sta3n=VStatus.sta3n
where 
 [AFP_dt] between (select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP) 
											and (select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)

go



-- Get all the patients 
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_1_Inc_9_IncPat
go

	select distinct VStatus.Sta3n,VStatus.PatientSID,VStatus.patientSSN, VStatus.ScrSSN,VStatus.PatientICN
	into [ORD_Singh_201210017D].[Dflt].HCC_1_Inc_9_IncPat
 	from [ORD_Singh_201210017D].[Dflt].HCC_1_Inc_8_IncIns as a
    left join ORD_Singh_201210017D.src.SPatient_SPatient as VStatus
    on a.patientSSN=VStatus.PatientSSN	
	where VStatus.CohortName='Cohort20170313'
go



---------------------------------------Exclusion Dx----------------------------------------
-------------------------------------------------------------------------------------------
--  Extract of previous HCC cancer codes from patient problemlist
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD9

SELECT 
	 	p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	  ,Plist.*	  
	  --,ICD9.icddescription
	  ,icd9.icd9code
into [ORD_Singh_201210017D].[Dflt].HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD9
   FROM [ORD_Singh_201210017D].[Src].[Outpat_ProblemList] as Plist
  inner join CDWWork.Dim.ICD9 as ICD9
  on Plist.ICD9SID=ICD9.ICD9SID
inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on Plist.sta3n=p.sta3n and Plist.patientsid=p.patientsid
where Plist.CohortName='Cohort20170313'and
 
plist.[EnteredDateTime] <= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[HCC_0_1_inputP]),(select sp_end from [ORD_Singh_201210017D].[Dflt].[HCC_0_1_inputP]))
and ICD9.ICD9Code in (
			-- recent active HCC diagnosis
				'155.0','155.1','155.2','197.7')


if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD10

SELECT 
	   p.patientSSN
	  ,Plist.*	
   --   ,Plist.[ICD9SID]
	  --,Plist.[ICD10SID]
	  ,ICD10.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type
	  ,ICD10Diag.ICD10Diagnosis as ICDDiagnosis
into [ORD_Singh_201210017D].[Dflt].HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD10
 FROM [ORD_Singh_201210017D].[Src].[Outpat_ProblemList] as Plist
  inner join CDWWork.Dim.ICD10 as ICD10
  on Plist.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Plist.ICD10SID=ICD10Diag.ICD10SID
  inner join ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] as  ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code
inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on Plist.sta3n=p.sta3n and Plist.patientsid=p.patientsid
where Plist.CohortName='Cohort20170313'and
 
plist.[EnteredDateTime] <= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[HCC_0_1_inputP]),(select sp_end from [ORD_Singh_201210017D].[Dflt].[HCC_0_1_inputP]))
and 			-- recent active HCC diagnosis
	ICD10CodeList.dx_code_type='ActiveHCCCancer'
go

if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD9ICD10Union]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD9ICD10Union

	select PatientSSN,PatientSID,Sta3n,EnteredDateTime,ICD9SID,ICD10SID,ICD9Code as ICDCode,ProblemListSID
	into [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD9ICD10Union
	from [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD9
	union
	select PatientSSN,PatientSID,Sta3n,EnteredDateTime,ICD9SID,ICD10SID,ICD10Code as ICDCode,ProblemListSID
	from [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD10
go


--  Extract of all DX codes from outpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_1_OutPatDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_1_OutPatDx_ICD9

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
into [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_1_OutPatDx_ICD9
  FROM [ORD_Singh_201210017D].[src].[Outpat_VDiagnosis] as Diag
  inner join CDWWork.Dim.ICD9 as ICD9
  on Diag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DiagnosisVersion as ICD9Diag
  on ICD9.ICD9SID=ICD9Diag.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].HCC_0_4_DxICD9CodeExc as targetCode
on targetCode.ICD9Code=ICD9.ICD9Code
inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where Diag.CohortName='Cohort20170313'and
 
[VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))  
go


--  Extract of all DX codes from outpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_1_OutPatDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_1_OutPatDx_ICD10

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
into [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_1_OutPatDx_ICD10
  FROM [ORD_Singh_201210017D].[src].[Outpat_VDiagnosis] as Diag
  inner join CDWWork.Dim.ICD10 as ICD10
  on Diag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Diag.ICD10SID=ICD10Diag.ICD10SID
inner join ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code
inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where Diag.CohortName='Cohort20170313'and
 
[VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)) 



--  Extract of all DX codes from inpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_2_InPatDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_2_InPatDx_ICD9

SELECT 
	  [InpatientDiagnosisSID] 
      ,InPatDiag.[Sta3n]
      --,[OrdinalNumber]
      ,[InpatientSID]  
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
	into  [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_2_InPatDx_ICD9
  FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientDiagnosis] as InPatDiag
  inner join CDWWork.Dim.ICD9 as ICD9
  on InPatDiag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DiagnosisVersion as ICD9Diag
  on InPatDiag.ICD9SID=ICD9Diag.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].HCC_0_4_DxICD9CodeExc as targetCode
on targetCode.ICD9Code=ICD9.ICD9Code
  inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
  where InpatDiag.CohortName='Cohort20170313'and
  
[DischargeDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)) 

	go


	--  Extract of all DX codes from inpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_2_InPatDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_2_InPatDx_ICD10

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
	into  [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_2_InPatDx_ICD10
  FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientDiagnosis] as InPatDiag
  inner join CDWWork.Dim.ICD10 as ICD10
  on InPatDiag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on InPatDiag.ICD10SID=ICD10Diag.ICD10SID
inner join ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code
  inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
  where InpatDiag.CohortName='Cohort20170313'and
  
[DischargeDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)) 

	go



-- Extract of all DX Codes for all potential patients from surgical files
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_3_SurgDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_3_SurgDx_ICD9

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
	  ,targetCode.dx_code_type
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
  into [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_3_SurgDx_ICD9
    FROM [ORD_Singh_201210017D].[Src].[Surgery_Surgery_130] as surg
	inner join [ORD_Singh_201210017D].[Src].[Surgery_surgeryprcdrdgnsscodes_136] as SurgDx  
  --on surg.[SurgerySID]=SurgDx.[SurgerySID]
  on surg.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  and surg.Sta3n=SurgDx.Sta3n
  inner join [ORD_Singh_201210017D].[dflt].HCC_0_4_DxICD9CodeExc as targetCode
on targetCode.ICD9Code=SurgDx.[PrinPostopDiagnosisCode]
    inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on Surg.sta3n=p.sta3n and surg.patientsid=p.patientsid
   where    
  Surg.CohortName='Cohort20170313'and
  [DateOfOperationNumeric]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))  

	go


	if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_3_SurgDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_3_SurgDx_ICD10

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
  into [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_3_SurgDx_ICD10
    FROM [ORD_Singh_201210017D].[Src].[Surgery_Surgery_130] as surg
	inner join [ORD_Singh_201210017D].[Src].[Surgery_surgeryprcdrdgnsscodes_136] as SurgDx  
  --on surg.[SurgerySID]=SurgDx.[SurgerySID]
  on surg.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  and surg.Sta3n=SurgDx.Sta3n
inner join ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] as ICD10CodeList
on SurgDx.PrinPostopDiagnosisCode=ICD10CodeList.ICD10Code
    inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on Surg.sta3n=p.sta3n and surg.patientsid=p.patientsid
   where  
  
  Surg.CohortName='Cohort20170313'and
  [DateOfOperationNumeric]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))  
  go

	--  Extract of all exclusion diagnoses from inpat fee

	if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9

SELECT 
       Diag.[Sta3n]
      ,Diag.[PatientSID]
	  ,ICD9.ICD9Code as ICD9
	  ,v.[ICD9Description]
	  ,targetCode.dx_code_type
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
into [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9
FROM [ORD_Singh_201210017D].[src].Inpat_InpatientFeeDiagnosis as Diag
  inner join CDWWork.Dim.ICD9 as ICD9
  on Diag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DescriptionVersion AS V
  on icd9.ICD9SID=v.ICD9SID
  inner join [ORD_Singh_201210017D].[dflt].HCC_0_4_DxICD9CodeExc as targetCode
on targetCode.ICD9Code=ICD9.ICD9Code
inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where Diag.CohortName='Cohort20170313'and
 
[AdmitDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))  

go



	if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[HCC_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10

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
into [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10
FROM [ORD_Singh_201210017D].[src].Inpat_InpatientFeeDiagnosis as Diag
  inner join CDWWork.Dim.ICD10 as ICD10
  on Diag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Diag.ICD10SID=ICD10Diag.ICD10SID
inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
  inner join ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
where Diag.CohortName='Cohort20170313' and 
[AdmitDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))  

go


--Fee ICD Dx 
  		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9]') is not null)
		drop table ORD_Singh_201210017D.[Dflt].HCC_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9


SELECT  
	  c.patientssn
	,d.InitialTreatmentDateTime as dx_dt
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,[ServiceProvidedCPTSID]
      ,a.[ICD9SID]
      ,[ICD10SID]
	  ,ICD9.ICD9Code as ICD9
	  ,v.[ICD9Description]
	  ,targetCode.dx_code_type
      ,[AmountClaimed]
      ,[AmountPaid]
	  ,patientICN
	  ,ScrSSN
into ORD_Singh_201210017D.[Dflt].HCC_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9
  FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as d
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join CDWWork.Dim.ICD9 as ICD9
  on a.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DescriptionVersion AS V
  on icd9.ICD9SID=v.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].HCC_0_4_DxICD9CodeExc as targetCode
on targetCode.ICD9Code=ICD9.ICD9Code
  inner join ORD_Singh_201210017D.[Dflt].[HCC_1_Inc_9_IncPat] as c
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where a.CohortName='Cohort20170313'and
  d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from ORD_Singh_201210017D.[Dflt].HCC_0_1_inputP))

go



--Fee ICD Dx 
  		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10]') is not null)
		drop table ORD_Singh_201210017D.[Dflt].HCC_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10


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
into ORD_Singh_201210017D.[Dflt].HCC_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10
  FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as d
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join CDWWork.Dim.ICD10 as ICD10
  on a.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on a.ICD10SID=ICD10Diag.ICD10SID
  inner join ORD_Singh_201210017D.[Dflt].[HCC_1_Inc_9_IncPat] as c
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
inner join ORD_Singh_201210017D.[Dflt].[HCC_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
  where a.CohortName='Cohort20170313'and
  d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from ORD_Singh_201210017D.[Dflt].HCC_0_1_inputP))

go


	--  Extract of all exclusion diagnoses from surgical, inpatient, and outpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_4_ALLDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_4_ALLDx_ICD9
go

select patientSSN,sta3n, PatientSID,dx_dt,ICDCode as ICD9,dx_code_type,'Dx-Surg' as dataSource,patientICN,ScrSSN
into [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_4_ALLDx_ICD9
from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_3_SurgDx_ICD9]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICDCode as ICD9,dx_code_type,'DX-OutPat' as dataSource,patientICN,ScrSSN from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_1_OutPatDx_ICD9]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICDCode as ICD9,dx_code_type,'Dx-InPat' as dataSource,patientICN,ScrSSN from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_2_InPatDx_ICD9]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD9,dx_code_type,'Dx-InPatFee' as dataSource,patientICN,ScrSSN from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD9,dx_code_type,'Dx-InPatFeeService' as dataSource,patientICN,ScrSSN from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9]
go


alter table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_4_ALLDx_ICD9
add
	Recent_Active_dt datetime,
	term_dx_dt datetime,
	hospice_dt datetime,
	preg_dx_dt datetime,
	GonadalTumor_dx_dt datetime
go

update [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_4_ALLDx_ICD9
set 

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
	preg_dx_dt = case
		when  dx_code_type='Pregnancy'
		 then dx_dt
		else NULL
	end,
	GonadalTumor_dx_dt = case
		when dx_code_type='GonadalTumors'
			 then dx_dt
		else NULL
	end
go



	--  Extract of all exclusion diagnoses from surgical, inpatient, and outpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_4_ALLDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_4_ALLDx_ICD10
go

select patientSSN,sta3n, PatientSID,dx_dt,ICDCode as ICDCode,dx_code_type,'Dx-Surg' as dataSource
into [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_4_ALLDx_ICD10
from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_3_SurgDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'DX-OutPat' as dataSource from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_1_OutPatDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10Code,dx_code_type,'Dx-InPat' as dataSource from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_2_InPatDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'Dx-InPatFee' as dataSource from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,[InitialTreatmentDateTime] as [dx_dt],[ICD10code],dx_code_type,'Dx-InPatFee' as dataSource from [ORD_Singh_201210017D].[Dflt].HCC_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD10

Alter table [ORD_Singh_201210017D].[Dflt].HCC_2_ExcDx_4_ALLDx_ICD10
add
	--Recent_Active_dt datetime,
	term_dx_dt datetime,
	hospice_dt datetime,
	preg_dx_dt datetime,
	GonadalTumor_dx_dt datetime
go

update [ORD_Singh_201210017D].[Dflt].HCC_2_ExcDx_4_ALLDx_ICD10
set term_dx_dt= case when dx_code_type='Terminal' then dx_dt else null end,
	hospice_dt= case when dx_code_type='hospice' then dx_dt else null end,
	--Recent_Active_dt= case when dx_code_type='ActiveHCCCancer' then dx_dt else null end,
	preg_dx_dt=case when dx_code_type='Pregnancy' then dx_dt else null end,
	GonadalTumor_dx_dt= case when dx_code_type='GonadalTumor' then dx_dt else null end
go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_4_Union_ALLDx_ICD9ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].HCC_2_ExcDx_4_Union_ALLDx_ICD9ICD10
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
	  ,GonadalTumor_dx_dt
into [ORD_Singh_201210017D].[Dflt].HCC_2_ExcDx_4_Union_ALLDx_ICD9ICD10
from [ORD_Singh_201210017D].[Dflt].HCC_2_ExcDx_4_ALLDx_ICD9
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
	  ,GonadalTumor_dx_dt
from [ORD_Singh_201210017D].[Dflt].HCC_2_ExcDx_4_ALLDx_ICD10
go




	------------------------------------------------------------------------------------------------------------
	-------------------------------- trigger Non-Dx exclusions
	------------------------------------------------------------------------------------------------------------

	-- Extract of all HCG values 
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_2_AllHCG]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_2_AllHCG]

	 
	SELECT [LabChemSID]
      ,labChem.[Sta3n]
      ,labChem.[LabChemTestSID]
      ,labChem.[PatientSID]
      ,[LabChemSpecimenDateTime] as HCG_dt
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
      ,labChem.[Units]
 into [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_2_AllHCG]
  FROM [ORD_Singh_201210017D].[src].[Chem_PatientLabChem] as labChem
  inner join cdwwork.dim.labchemtest as dimTest
  on labChem.[LabChemTestSID]=dimTest.LabChemTestSID
  inner join cdwwork.dim.LOINC as LOINC
  on labChem.LOINCSID=LOINC.LOINCSID
  inner join cdwwork.dim.VistaSite as VistaSite
		on labChem.sta3n=VistaSite.Sta3n
  inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on labChem.sta3n=p.sta3n and labChem.patientsid=p.patientsid
  where labChem.CohortName='Cohort20170313'and
    labChem.[LabChemCompleteDateTime] between DATEADD(mm,-13,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)) 
											and DATEADD(dd,61,(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)) 
	and VistaSite.VISN=(select VISN from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP) 	
	--and labChem.Sta3n=(select sta3n from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)		
	and (
	(labchemtestname like '%HUMAN%CHORIONIC%GONADO%' or labchemtestname like'hcg'
	 or labchemPrintTestname like '%HUMAN%CHORIONIC%GONADO%' or labchemPrintTestname like 'hcg')
	 or LOINC.LOINCIEN in ( '2106','2110','2112')
	 )
	and ([LabChemResultNumericValue]>25 or LabChemResultValue like 'pos%') 
		
	
	go

	
-- Previous ICD procedures from inpatient 

				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc

						  select pat.patientssn,pat.scrssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime]
	      ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,pat.patientICN
into [ORD_Singh_201210017D].[dflt].HCC_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc
			  FROM [ORD_Singh_201210017D].[src].[inpat_InpatientICDProcedure] as ICDProc
			  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on ICDProc.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat]) as pat
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where ICDProc.CohortName='Cohort20170313' 
  and (DimICD9Proc.[ICD9ProcedureCode] in (  
							--Liver Surgery
								'50.0','50.20','50.21','50.22','50.23','50.24','50.25','50.26','50.29','50.30','50.40','50.50','50.51','50.59','50.60','50.90','50.91','50.93',
							--Liver Imaging
								'88.01','88.02','88.03','88.04','88.76'
							)
							or DimICD9Proc.[ICD9ProcedureCode] like '50.1%'  -- liver biopsy
		)

 and [ICDProcedureDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))

go


	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc

						  select pat.patientssn,pat.scrssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
into [ORD_Singh_201210017D].[dflt].HCC_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc
			  FROM [ORD_Singh_201210017D].[Src].[Inpat_InpatientICDProcedure] as ICDProc
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on ICDProc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join [ORD_Singh_201210017D].[Dflt].[HCC_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat]) as pat
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where ICDProc.CohortName='Cohort20170313'and

 [ICDProcedureDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))

go


			if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc

 			select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[ICDProcedureDateTime]
	      ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,pat.patientICN
		into [ORD_Singh_201210017D].[dflt].HCC_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc
			FROM [ORD_Singh_201210017D].[Src].[Inpat_CensusICDProcedure] as a
			  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
   inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where a.CohortName='Cohort20170313' and
 (DimICD9Proc.[ICD9ProcedureCode] in (   
							--Liver Surgery
								'50.0','50.20','50.21','50.22','50.23','50.24','50.25','50.26','50.29','50.30','50.40','50.50','50.51','50.59','50.60','50.90','50.91','50.93',
							--Liver Imaging
								'88.01','88.02','88.03','88.04','88.76'
							)
							or DimICD9Proc.[ICD9ProcedureCode] like '50.1%'  -- liver biopsy
							)

 and [ICDProcedureDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
go




			if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc

			select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[ICDProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
		into [ORD_Singh_201210017D].[dflt].HCC_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc
			FROM [ORD_Singh_201210017D].[Src].[Inpat_CensusICDProcedure] as a
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on DimICD10Proc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join [ORD_Singh_201210017D].[Dflt].[HCC_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
   inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where a.CohortName='Cohort20170313'

 and [ICDProcedureDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc

			select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
	      ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,pat.patientICN
into [ORD_Singh_201210017D].[dflt].HCC_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc
			FROM [ORD_Singh_201210017D].[Src].[Inpat_InpatientSurgicalProcedure] as a
			  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where a.CohortName='Cohort20170313'and
 (DimICD9Proc.[ICD9ProcedureCode] in (   
							--Liver Surgery
								'50.0','50.20','50.21','50.22','50.23','50.24','50.25','50.26','50.29','50.30','50.40','50.50','50.51','50.59','50.60','50.90','50.91','50.93',
							--Liver Imaging
								'88.01','88.02','88.03','88.04','88.76'
							)
							or DimICD9Proc.[ICD9ProcedureCode] like '50.1%'  -- liver biopsy
)

 and [SurgicalProcedureDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))

go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc

			select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
into [ORD_Singh_201210017D].[dflt].HCC_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc
			FROM [ORD_Singh_201210017D].[Src].[Inpat_InpatientSurgicalProcedure] as a
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on DimICD10Proc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join [ORD_Singh_201210017D].[Dflt].[HCC_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where a.CohortName='Cohort20170313'

 and [SurgicalProcedureDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))

go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc

 		 select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
				  ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,pat.patientICN
into [ORD_Singh_201210017D].[dflt].HCC_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc
		  FROM [ORD_Singh_201210017D].[Src].[Inpat_CensusSurgicalProcedure] as a
			  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where a.CohortName='Cohort20170313'and
 (DimICD9Proc.[ICD9ProcedureCode] in (   
							--Liver Surgery
								'50.0','50.20','50.21','50.22','50.23','50.24','50.25','50.26','50.29','50.30','50.40','50.50','50.51','50.59','50.60','50.90','50.91','50.93',
							--Liver Imaging
								'88.01','88.02','88.03','88.04','88.76'
							)
							or DimICD9Proc.[ICD9ProcedureCode] like '50.1%'  -- liver biopsy
							)

 and [SurgicalProcedureDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))

go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc

		 select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
into [ORD_Singh_201210017D].[dflt].HCC_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc
		  FROM [ORD_Singh_201210017D].[Src].[Inpat_CensusSurgicalProcedure] as a
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on DimICD10Proc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join [ORD_Singh_201210017D].[Dflt].[HCC_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where a.CohortName='Cohort20170313'
 and [SurgicalProcedureDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))

go


	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc	

	select pat.patientssn,pat.scrssn,a.sta3n,b.patientsid,b.[TreatmentFromDateTime]
	      ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,pat.patientICN
	into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc
	from [ORD_Singh_201210017D].[Src].[Fee_FeeInpatInvoiceICDProcedure] as a
	inner join [ORD_Singh_201210017D].[Src].[Fee_FeeInpatInvoice] as b
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
			  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on a.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where a.CohortName='Cohort20170313'and
	  (DimICD9Proc.[ICD9ProcedureCode] in (
							--Liver Surgery
								'50.0','50.20','50.21','50.22','50.23','50.24','50.25','50.26','50.29','50.30','50.40','50.50','50.51','50.59','50.60','50.90','50.91','50.93',
							--Liver Imaging
								'88.01','88.02','88.03','88.04','88.76'
							)
							or DimICD9Proc.[ICD9ProcedureCode] like '50.1%'  -- liver biopsy
							)
 and [TreatmentFromDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
go


	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc	

	select pat.patientssn,pat.scrssn,a.sta3n,b.patientsid,b.[TreatmentFromDateTime],ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
	into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc	
	--from vinci1.[Fee].[FeeInpatInvoiceICDProcedure] as a  --not available in VINCI1
	from [ORD_Singh_201210017D].src.[Fee_FeeInpatInvoiceICDProcedure] as a	
	inner join [ORD_Singh_201210017D].[Src].[Fee_FeeInpatInvoice] as b
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on a.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join [ORD_Singh_201210017D].[Dflt].[HCC_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where a.CohortName='Cohort20170313'
 and [TreatmentFromDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
go


	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_5_HLP_FeeICDProc_FeeServiceProvided_ICD9Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_5_HLP_FeeICDProc_FeeServiceProvided_ICD9Proc	

	select pat.patientssn,pat.scrssn,a.sta3n,b.patientsid,b.InitialTreatmentDateTime
	      ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,pat.patientICN
	into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_5_HLP_FeeICDProc_FeeServiceProvided_ICD9Proc
  FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as b
  on a.FeeInitialTreatmentSID=b.FeeInitialTreatmentSID			  
  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on a.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where a.CohortName='Cohort20170313'and
	  (DimICD9Proc.[ICD9ProcedureCode] in (
							--Liver Surgery
								'50.0','50.20','50.21','50.22','50.23','50.24','50.25','50.26','50.29','50.30','50.40','50.50','50.51','50.59','50.60','50.90','50.91','50.93',
							--Liver Imaging
								'88.01','88.02','88.03','88.04','88.76'
							)
							or DimICD9Proc.[ICD9ProcedureCode] like '50.1%'  -- liver biopsy
						)

 and InitialTreatmentDateTime between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
go


	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_5_HLP_FeeICDProc_FeeServiceProvided_ICD10Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_5_HLP_FeeICDProc_FeeServiceProvided_ICD10Proc	

	select pat.patientssn,pat.scrssn,a.sta3n,b.patientsid,b.InitialTreatmentDateTime,ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
	into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_5_HLP_FeeICDProc_FeeServiceProvided_ICD10Proc	
	--from vinci1.[Fee].[FeeInpatInvoiceICDProcedure] as a -- not available in VINCI1
  FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as b
  on a.FeeInitialTreatmentSID=b.FeeInitialTreatmentSID	
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on DimICD10Proc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join [ORD_Singh_201210017D].[Dflt].[HCC_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where a.CohortName='Cohort20170313' 
 and InitialTreatmentDateTime between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
go



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD9Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD9Proc	
	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9ProcedureDescription
	  ,'Inp-InpICD'	  as datasource
    into  [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD9Proc
	from ORD_Singh_201210017D.[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc]
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9ProcedureDescription
	  ,'Inp-CensusICD'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9ProcedureDescription      
	 ,'Inp-InpSurg'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc]
	union	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9ProcedureDescription
	 ,'Inp-CensusSurg'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9ProcedureDescription      
	 ,'Inp-FeeICDProc'	  as datasource
	from ORD_Singh_201210017D.[Dflt].HCC_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc
--	union
--	select patientssn
--      ,[sta3n]
--      ,[patientsid]
--      ,InitialTreatmentDateTime as Proc_dt
--      ,[ICD9ProcedureCode]
--      ,ICD9ProcedureDescription      
--	 ,'Inp-FeeICDProc'	  as datasource
--from ORD_Singh_201210017D.[Dflt].HCC_3_Exc_NonDx_3_PrevProc_5_HLP_FeeICDProc_FeeServiceProvided_ICD9Proc

	go


	
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD10Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD10Proc	

		select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10ProcedureDescription
	,[ICD10Proc_code_type]
	  ,'Inp-InpICD'	  as datasource
    into  [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD10Proc
	from ORD_Singh_201210017D.[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc]
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10ProcedureDescription
	  ,[ICD10Proc_code_type]
	  ,'Inp-CensusICD'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10ProcedureDescription      
	  ,[ICD10Proc_code_type]
	 ,'Inp-InpSurg'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc]
	union	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
	  ,[ICD10Proc_code_type]
      ,ICD10ProcedureDescription
	 ,'Inp-CensusSurg'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10ProcedureDescription  
	  ,[ICD10Proc_code_type]	      
	 ,'Inp-FeeICDProc'	  as datasource
	from ORD_Singh_201210017D.[Dflt].HCC_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc
	--union
	--select patientssn
 --     ,[sta3n]
 --     ,[patientsid]
 --     ,InitialTreatmentDateTime as Proc_dt
 --     ,[ICD10ProcedureCode]
 --     ,ICD10ProcedureDescription  
	--  ,[ICD10Proc_code_type]	      
	-- ,'Inp-FeeICDProc'	  as datasource
 --   from ORD_Singh_201210017D.[Dflt].HCC_3_Exc_NonDx_3_PrevProc_5_HLP_FeeICDProc_FeeServiceProvided_ICD10Proc

	go


  -- Previous CPT from inpatient

	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_5_Inpat_1_CPT]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_5_Inpat_1_CPT

select pat.patientssn,pat.scrssn,CPTProc.sta3n,CPTProc.patientsid,CPTProc.[CPTProcedureDateTime]
	      ,DimCPT.[CPTCode],DimCPT.CPTName,DimCPT.CPTDescription ,patientICN
into  [ORD_Singh_201210017D].[dflt].HCC_3_Exc_NonDx_3_PrevProc_5_Inpat_1_CPT
  FROM [ORD_Singh_201210017D].[Src].[Inpat_InpatientCPTProcedure] as CPTProc
  inner join cdwwork.dim.CPT as DimCPT
  on CPTProc.[CPTSID]=DimCPT.CPTSID  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[HCC_1_Inc_9_IncPat]) as pat
  on CPTProc.patientsid=pat.patientsid and CPTProc.sta3n=pat.sta3n
 where CPTProc.CohortName='Cohort20170313'and
 DimCPT.[CPTCode] in (   
			--Liver Biopsy
			'47000','47001','47100',
			--Liver Surgery
			'47010','47015','47120','47122','47125','47130','47135','47136','47140','47141','47143','47144','47300','47370','47371',
			--Liver Imaging
			'76705','76700','93975','93976','74150','74160','74170','74714','74175','74176','74177','74178','74181','74182','74183','74185','74190',
			--Liver tumor Embolization
			'37204','37243'
			)
 and CPTProc.[CPTProcedureDateTime]  between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))


-- Previous procedures from outpat 

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_6_Outpat') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_6_Outpat
		
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
  into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_6_Outpat
  FROM [ORD_Singh_201210017D].[Src].[outpat_VProcedure] as VProc
  inner join CDWWork.[Dim].[CPT] as DimCPT 
  on  VProc.[CPTSID]=DimCPT.CPTSID
  inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on VProc.sta3n=p.sta3n and VProc.patientsid=p.patientsid
  where  VProc.CohortName='Cohort20170313'and
  --CPRSOrderSID<>-1  -- Even [VProcedureDateTime] is not null but the order could be canceled.
  --and 
  dimCPT.[CPTCode] in  (
			--Liver Biopsy
			'47000','47001','47100',
			--Liver Surgery
			'47010','47015','47120','47122','47125','47130','47135','47136','47140','47141','47143','47144','47300','47370','47371',
			--Liver Imaging
			'76705','76700','93975','93976','74150','74160','74170','74714','74175','74176','74177','74178','74181','74182','74183','74185','74190'
			--Liver tumor Embolization
			,'37204','37243'
			)	
 and [VProcedureDateTime] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))


go

  		-- previous procedures from surgical tables

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_7_surg]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_7_surg
		SELECT 
	   --[SurgerySID]
	   p.patientSSN
      ,surg.[Sta3n]
      --,[SurgeryIEN]
      --,[PatientIEN]
      --,[VisitIEN]
      ,surg.[PatientSID]
      ,[VisitSID]
      ,[DateOfOperationNumeric] as [DateOfOperation]
      ,[PrincipalDiagnosis]
      ,[PrincipalPostOpDiag]
      ,[PrincipalPreOpDiagnosis]
      ,[PrincipalProcedure]
	  ,SurgDx.[PrincipalProcedureCode]
      ,[ProcedureCompleted]
		,p.ScrSSN,p.patientICN
  into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_7_surg
    FROM [ORD_Singh_201210017D].[Src].[Surgery_Surgery_130] as surg
  inner join [ORD_Singh_201210017D].[Src].[Surgery_surgeryprcdrdgnsscodes_136] as SurgDx
  --on surg.[SurgerySID]=SurgDx.[SurgerySID]
    on surg.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  and surg.Sta3n=SurgDx.Sta3n
    inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
  on Surg.sta3n=p.sta3n and surg.patientsid=p.patientsid
  where  
  Surg.CohortName='Cohort20170313'and
  [DateOfOperationNumeric] is not null and 
  SurgDx.[PrincipalProcedureCode] in (
			--Liver Biopsy
			'47000','47001','47100',
			--Liver Surgery
			'47010','47015','47120','47122','47125','47130','47135','47136','47140','47141','47143','47144','47300','47370','47371',
			--Liver Imaging
			'76705','76700','93975','93976','74150','74160','74170','74714','74175','74176','74177','74178','74181','74182','74183','74185','74190'
			--Liver tumor Embolization
			,'37204','37243'
			)	
 and [DateOfOperationNumeric] between DateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
									and DateAdd(dd,120+(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))

  go



  ----- Fee: Surg, proc, img
  --Fee CPT
  		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_8_FeeServiceProvidedCPT]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_8_FeeServiceProvidedCPT

SELECT  
	  c.patientssn
	  ,a.VendorInvoiceDate
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,[ServiceProvidedCPTSID]
	  ,b.cptcode
	  ,cptdescription
      ,[AmountClaimed]
      ,[AmountPaid]
	  ,patientICN
	  ,ScrSSN
into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_8_FeeServiceProvidedCPT
  FROM [ORD_Singh_201210017D].[Src].[Fee_FeeServiceProvided] as a
  inner join cdwwork.dim.cpt as b
  on a.[ServiceProvidedCPTSID]=b.cptsid
  inner join ORD_Singh_201210017D.[Dflt].[HCC_1_Inc_9_IncPat] as c
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where a.CohortName='Cohort20170313'and
  b.cptcode in (
  			--Liver Biopsy
			'47000','47001','47100',
			--Liver Surgery
			'47010','47015','47120','47122','47125','47130','47135','47136','47140','47141','47143','47144','47300','47370','47371',
			--Liver Imaging
			'76705','76700','93975','93976','74150','74160','74170','74714','74175','74176','74177','74178','74181','74182','74183','74185','74190'
			--Liver tumor Embolization
			,'37204','37243'
			)
 and 			 (a.VendorInvoiceDate > DATEADD(yy,-1, (select sp_start from [ORD_Singh_201210017D].[Dflt].[HCC_0_1_inputP]))														
					and	a.VendorInvoiceDate<= DATEADD(dd,120+60,(select sp_end from [ORD_Singh_201210017D].[Dflt].[HCC_0_1_inputP])))



					
-- All  biopsy from surgical, inpatient and outpatient tables, Fee
	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverBiopsy]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverBiopsy


select patientSSN,sta3n,patientSID,[VProcedureDateTime] as LiverBiopsy_dt ,'LiverBiopsy-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverBiopsy
from [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_6_Outpat 
		where [VProcedureDateTime] is not null
		and [CPTCode] in (  
			--Liver Biopsy
			'47000','47001','47100')
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as LiverBiopsy_dt,'LiverBiopsy-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD9Proc]
		where [Proc_dt] is not null
		and [ICD9ProcedureCode] like '50.1%'  -- liver biopsy		
	Union all
select patientSSN,sta3n,patientSID,[Proc_dt] as LiverBiopsy_dt,'LiverBiopsy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD'									
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD10Proc]
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='LiverBiopsy'	
	UNION ALL	
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as LiverBiopsy_dt,'LiverBiopsy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_5_Inpat_1_CPT]
		where [CPTProcedureDateTime] is not null
		and [CPTCode] in  (  
			--Liver Biopsy
			'47000','47001','47100')
	UNION ALL
select patientSSN,sta3n,patientSID,[DateOfOperation] as LiverBiopsy_dt,'LiverBiopsy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
--select [PatientSID],[DateOfOperation] as LiverBiopsy_dt,'LiverBiopsy-Surg' as Datasource 
from [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_7_surg 
		where [DateOfOperation] is not null
		and [PrincipalProcedureCode] in (	
			--Liver Biopsy
			'47000','47001','47100')
	UNION ALL
select patientSSN,sta3n,patientSID,VendorInvoiceDate as LiverBiopsy_dt,'LiverBiopsy-FeeCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_8_FeeServiceProvidedCPT]
		where VendorInvoiceDate is not null
		and [CPTCode] in  (  
			--Liver Biopsy
			'47000','47001','47100')
	go

-- All liver surgery procedures from surgical, inpatient and outpatient 
	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverSurgery]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverSurgery


select patientSSN,sta3n,patientSID,[VProcedureDateTime] as LiverSurg_dx_dt ,'LiverSurg-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverSurgery
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_6_Outpat]
		where [VProcedureDateTime] is not null
		and  [CPTCode]  in (  
			--Liver Surgery
			'47010','47015','47120','47122','47125','47130','47135','47136','47140','47141','47143','47144','47300','47370','47371'
			)
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as LiverSurg_dx_dt,'LiverSurg-InPatICD' as datasource,[ICD9ProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD9Proc]
		where [Proc_dt] is not null
		and [ICD9ProcedureCode] in (  --Liver Surgery
								'50.0','50.20','50.21','50.22','50.23','50.24','50.25','50.26','50.29','50.30','50.40','50.50','50.51','50.59','50.60','50.90','50.91','50.93'
								)
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as LiverSurg_dx_dt,'LiverSurg-InPatICD' as datasource,[ICD10ProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD10Proc]
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='LiverSurg'
	UNION ALL	
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as LiverSurg_dx_dt,'LiverSurg-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_5_Inpat_1_CPT]
		where [CPTProcedureDateTime] is not null
		and [CPTCode] in (   
			--Liver Surgery
			'47010','47015','47120','47122','47125','47130','47135','47136','47140','47141','47143','47144','47300','47370','47371'
			)
							   
	UNION ALL

select patientSSN,sta3n,patientSID,[DateOfOperation] as LiverSurg_dx_dt,'LiverSurg-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_7_surg]
		where [DateOfOperation] is not null
		and   [PrincipalProcedureCode] in (  
			--Liver Surgery
			'47010','47015','47120','47122','47125','47130','47135','47136','47140','47141','47143','47144','47300','47370','47371'
		)
	UNION ALL	
select patientSSN,sta3n,patientSID,VendorInvoiceDate as LiverSurg_dx_dt,'LiverSurgery-FeeCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_8_FeeServiceProvidedCPT]
		where VendorInvoiceDate is not null
		and [CPTCode] in  (  
			--Liver Surgery
			'47010','47015','47120','47122','47125','47130','47135','47136','47140','47141','47143','47144','47300','47370','47371'
			)

-- All liver image  from surgical, inpatient and outpatient 
	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverImg]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverImg
												 

select patientSSN,sta3n,patientSID,[VProcedureDateTime] as LiverImg_dx_dt ,'LiverImg-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverImg
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_6_Outpat]
		where [VProcedureDateTime] is not null
		and  [CPTCode]  in (  
			--Liver Img
		'76705','76700','93975','93976','74150','74160','74170','74714','74175','74176','74177','74178','74181','74182','74183','74185','74190'
			)
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as LiverImg_dx_dt,'LiverImg-InPatICD' as datasource,[ICD9ProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD9Proc]
		where [Proc_dt] is not null
		and [ICD9ProcedureCode] in (  
						--Liver Imaging
								'88.01','88.02','88.03','88.04','88.76'
								)
	UNION ALL
select patientSSN,sta3n,patientSID,[Proc_dt] as LiverImg_dx_dt,'LiverImg-InPatICD' as datasource,[ICD10ProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_4_Inpat_0_UnionAllInpICD10Proc]
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='LiverImag'

	UNION ALL	
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as LiverImg_dx_dt,'LiverImg-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_5_Inpat_1_CPT]
		where [CPTProcedureDateTime] is not null
		and [CPTCode] in (   
			--Liver Img
	'76705','76700','93975','93976','74150','74160','74170','74714','74175','74176','74177','74178','74181','74182','74183','74185','74190'
			)
							   
	UNION ALL
--select [PatientSID], [DateOfOperation] as LiverImg_dx_dt,'PrevColectomy-Surg' as Datasource
select patientSSN,sta3n,patientSID,[DateOfOperation] as LiverImg_dx_dt,'LiverImg-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_7_surg]
		where [DateOfOperation] is not null
		and   [PrincipalProcedureCode] in (  
			--Liver Img
		'76705','76700','93975','93976','74150','74160','74170','74714','74175','74176','74177','74178','74181','74182','74183','74185','74190'
		)
	UNION ALL
select patientSSN,sta3n,patientSID,VendorInvoiceDate as LiverImg_dx_dt,'LiverImg-FeeCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_8_FeeServiceProvidedCPT]
		where VendorInvoiceDate is not null
		and [CPTCode] in  (  
			--Liver Img
		'76705','76700','93975','93976','74150','74160','74170','74714','74175','74176','74177','74178','74181','74182','74183','74185','74190'
			)

go

-- All liver LiverTumorEmbolization  from surgical, inpatient and outpatient 
	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_LiverTumorEmbolization]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_LiverTumorEmbolization


select patientSSN,sta3n,patientSID,[VProcedureDateTime] as LiverTumorEmbol_dt ,'LiverTumorEmbol-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
into [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_LiverTumorEmbolization
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_6_Outpat]
		where [VProcedureDateTime] is not null
		and  [CPTCode]  in (  
			--Liver Tumor Embolization
		'37204','37243'
			)		
	UNION ALL	
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as LiverTumorEmbol_dt,'LiverTumorEmbol-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_5_Inpat_1_CPT]
		where [CPTProcedureDateTime] is not null
		and [CPTCode] in  (  
			--Liver Tumor Embolization
		'37204','37243'
			)								   
	UNION ALL

select patientSSN,sta3n,patientSID,[DateOfOperation] as LiverTumorEmbol_dt,'LiverTumorEmbol-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_7_surg]
		where [DateOfOperation] is not null
		and   [PrincipalProcedureCode] in (  
			--Liver Tumor Embolization
		'37204','37243'
		)
	UNION ALL	
select patientSSN,sta3n,patientSID,VendorInvoiceDate as LiverTumorEmbol_dt,'LiverTumorEmbol-FeeCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_8_FeeServiceProvidedCPT]
		where VendorInvoiceDate is not null
		and [CPTCode] in  (  
			--Liver Tumor Embolization
		'37204','37243'
			)

go

--------------------------------Radiology ----------------------------------------------------------------				


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].HCC_5_Exc_NonDx_HLP1_LiverRadImg_exam7003') is not null)
	drop table ORD_Singh_201210017D.[Dflt].HCC_5_Exc_NonDx_HLP1_LiverRadImg_exam7003
			                               
											 

SELECT
      rad.[Sta3n]
      ,[RowId]
	  ,radpat.PatientSID
      ,rad.[RadnucMedPatientIEN]
      ,[Parentrowid70]
      ,[SubRegisteredExams]
      ,[RadxExaminationsIEN]
      ,[RadxSubExaminationsIEN]
      ,[ExamDate] as ExamDateTime
      ,[CaseNumber]
      ,[Procedure2]
	  ,rtrim(ltrim(replace(convert(varchar(50),convert(decimal(15,6),[Procedure2])),'.000000',''))) as [RadNucMedProcIEN]
      ,[Procedure2X]
      ,[ExamStatus]
      ,[EXamstatusX]
      ,[CategoryOfExam]
      ,[ImagingOrder]
      ,[ImagingorderX]
      ,[PrimaryInterpretingResident]
      ,[PrimaryinterpretingresidentX]
      ,[PrimaryDiagnosticCode]
      ,[PrimarydiagnosticcodeX]
      ,[RequestingPhysician]
      ,[RequestingphysicianX]
      ,[PrimaryInterpretingStaff]
      ,[PrimaryinterpretingstaffX]
      ,[ReportText]
      ,[ReportteXtX]
      ,[Bedsection]
      ,[BedsectionX]
      ,[DiagnosticPrintDate]
      ,[RequestedDate]
      ,[RequestingLocation]
      ,[RequestinglocationX]
      ,[ClinicStopRecorded]
      ,[VisitIEN]
      ,[VisitSID]
      ,[VisitX]
      ,[Clinicalhistoryforexamwp]
into ORD_Singh_201210017D.[Dflt].HCC_5_Exc_NonDx_HLP1_LiverRadImg_exam7003
FROM [ORD_Singh_201210017D].[Src].[Radiology_radx_examinations_70_03] as Rad
inner join [ORD_Singh_201210017D].[Src].[Radiology_RadNuc_Med_Patient_70] as Radpat
on Radpat.patientien=Rad.[RadnucMedPatientIEN] and Radpat.sta3n=Rad.sta3n and Radpat.CohortName='Cohort20170313'
inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as pat
on Radpat.Sta3n=pat.sta3n and radpat.patientsid=pat.patientsid
--inner join [ORD_Singh_201210017D].[Src].[Radiology_RadNuc_Med_Reports_74] as rpt
 --on rpt.[RadNucMedReportIEN]=Rad.[ReportTextIEN] and rpt.Sta3n=Rad.Sta3n
 --on rtrim(ltrim(replace(convert(varchar,convert(decimal(20,6),rpt.row_id)),'.000000',''))) =Rad.[ReportTextIEN] and rpt.Sta3n=Rad.Sta3n
  --inner join cdwwork.dim.VistaSite as VistaSite
		--on Rad.sta3n=VistaSite.Sta3n
--		--inner join [ORD_Singh_201210017D].[Src].[Radiology_radnuc_med_procedures_71] as code
--		inner join [ORD_Singh_201210017D].[Src].[dim_Radiology_radnuc_med_procedures_71] as code
  --on rad.[RadNucMedProcIEN]=code.[RadNucMedProcIEN]
  --and rad.sta3n=code.sta3n  
  where Rad.CohortName='Cohort20170313'and
	 rad.examdate
	  between  DATEADD(dd,-61,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
	  and DATEADD(dd,120,(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
	and Rad.[ExamStatusX] like'%COMPLETE%'
	 --and rad.Sta3n<>556 -- Exclude NorthChicago

go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].HCC_5_Exc_NonDx_HLP3_LiverRadImg_CPT') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Exc_NonDx_HLP3_LiverRadImg_CPT

	SELECT  code.CPTCode,
		Rad.*
  into ORD_Singh_201210017D.[Dflt].HCC_5_Exc_NonDx_HLP3_LiverRadImg_CPT
  FROM ORD_Singh_201210017D.[Dflt].HCC_5_Exc_NonDx_HLP1_LiverRadImg_exam7003 as Rad
  inner join [ORD_Singh_201210017D].[Src].[Radiology_radnuc_med_procedures_71] as code
  on Rad.[RadNucMedProcIEN]=code.[RadnucMedProceduresIEN] and Rad.sta3n=code.sta3n
  where code.cptcode in ('76705','76700','93975','93976','74150','74160','74170','74714','74175',
		                 '74176','74177','74178','74181','74182','74183','74185','74190')
						
go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].HCC_5_Exc_NonDx_HLP4_LiverRadImg_rpt') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Exc_NonDx_HLP4_LiverRadImg_rpt

	SELECT VerifiedDate
      --,rpt.[row_id] as rpt_Row_id_7003ReportTextIEN
	  ,rpt.[RadnucMedReportsIEN] as Rpt74ReportRadnucMedReportsIEN
	  ,rpt.Impressiontextwp as Rpt74ReportImpression
	  --,rpt.Reporttextwp as Rpt74ReportText
		,Rad.*
  into ORD_Singh_201210017D.[Dflt].HCC_5_Exc_NonDx_HLP4_LiverRadImg_rpt
  FROM ORD_Singh_201210017D.[Dflt].HCC_5_Exc_NonDx_HLP3_LiverRadImg_CPT as Rad
inner join [ORD_Singh_201210017D].[Src].[Radiology_RadNuc_Med_Reports_74] as rpt
 --on rpt.[RadNucMedReportIEN]=Rad.[ReportTextIEN] and rpt.Sta3n=Rad.Sta3n
 --on rtrim(ltrim(replace(convert(varchar,convert(decimal(20,6),rpt.row_id)),'.000000',''))) =Rad.[ReportTextIEN] and rpt.Sta3n=Rad.Sta3n
 on rpt.[RadnucMedReportsIEN]=rtrim(ltrim(replace(convert(varchar(50),convert(decimal(20,6),Rad.[ReportText] )),'.000000','')))
 and rpt.CohortName='Cohort20170313'
						
go



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].HCC_5_Exc_NonDx_HLP5_LiverRadImg_SSN') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Exc_NonDx_HLP5_LiverRadImg_SSN
											

	select distinct *  
	into ORD_Singh_201210017D.[Dflt].HCC_5_Exc_NonDx_HLP5_LiverRadImg_SSN
	from (
		select b.patientssn,b.ScrSSN,b.patientICN,convert(varchar(10),b.BirthDateTime,120) as DOB,convert(varchar(10),b.DeathDateTime,120) as DOD,b.Gender as Sex
				,a.* 	
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Exc_NonDx_HLP4_LiverRadImg_rpt as a
		left join (select distinct * from ORD_Singh_201210017D.src.SPatient_SPatient) as b
		on a.sta3n=b.sta3n and a.patientsid=b.patientsid and b.CohortName='Cohort20170313'
	) sub	
go



-------------------------------------------------------------------------------------------
---------------------------  Age Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].HCC_5_Ins_1_Age') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_1_Age
select	a.* 
into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_1_Age
from [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_8_IncIns] as a
  where DATEDIFF(yy,DOB,a.[AFP_dt]) >=18	
	go

-------------------------------------------------------------------------------------------
---------------------------  Alive Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].HCC_5_Ins_2_ALive') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_2_ALive
select a.*
into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_2_ALive
from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_1_Age as a
 where 
        [DOD] is null 		 
		or (DOD is not null 
				and ( 
					DATEADD(dd,-(select fu_period from [ORD_Singh_201210017D].[Dflt].[HCC_0_1_inputP]),dod)> a.AFP_dt
					)
				)	   	     
go

-------------------------------------------------------------------------------------------
---------------------------  3: Active HCC Cancer Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		--  all instances with CRC cancer exclusions removed
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_3_RecentActiveHCC]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_3_RecentActiveHCC

        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_3_RecentActiveHCC
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_2_ALive as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].HCC_2_ExcDx_0_PrevHCCCFromProblemList_ICD9ICD10Union as b
			 where a.[PatientSSN] = b.[PatientSSN]
			 			and b.EnteredDate between dateadd(yy,-1,a.AFP_dt) and 
						DATEADD(dd,0, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime)) 												
						)
			
		go

		
-------------------------------------------------------------------------------------------
---------------------------  5: Terminal illness or major dx Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_5_Term]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_5_Term

        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_5_Term
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_3_RecentActiveHCC as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_4_Union_ALLDx_ICD9ICD10] as b
			 where a.[PatientSSN] = b.[PatientSSN]
			 and b.[term_dx_dt] between DATEADD(yy,-1,a.[AFP_dt]) and
			 		DATEADD(dd,0, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime)) 					
						)

		go


-------------------------------------------------------------------------------------------
---------------------------  7: Gonadal Tumor  Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_7_GonadalTumor]') is not null)
			drop table  [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_7_GonadalTumor

        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_7_GonadalTumor
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_5_Term as a		
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_4_Union_ALLDx_ICD9ICD10] as b
			 where a.[PatientSSN] = b.[PatientSSN]
			 and b.[GonadalTumor_dx_dt] between DATEADD(yy,-1, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime)))
			 
		go
		

-------------------------------------------------------------------------------------------
---------------------------  7: Pregnant  ---------------------------
-------------------------------------------------------------------------------------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_7_Pregnant]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_7_Pregnant
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_7_Pregnant
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_7_GonadalTumor as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_4_Union_ALLDx_ICD9ICD10] as b
			 where a.[PatientSSN] = b.[PatientSSN] 
			 and b.[preg_dx_dt] between DATEADD(mm,-9, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))
			)
		go

				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_7_PregnantHCG]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_7_PregnantHCG
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_7_PregnantHCG
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_7_Pregnant as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_2_AllHCG] as b
			 inner join ORD_Singh_201210017D.src.SPatient_SPatient as p
			 on b.PatientSID=p.PatientSID and b.sta3n=p.sta3n
			 where a.patientssn=p.patientssn
			 and b.[HCG_dt] between DATEADD(mm,-9, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))
			)
		go


		-------------------------------------------------------------------------------------------
---------------------------  6: Hospice or palliative care Exclusions  ---------------------------
-------------------------------------------------------------------------------------------
		
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8_Hospice]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8_Hospice

        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8_Hospice
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_7_PregnantHCG as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_2_ExcDx_4_Union_ALLDx_ICD9ICD10] as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[hospice_dt] between DATEADD(yy,-1,a.AFP_dt) and DATEADD(dd,60,DATEADD(dd,0, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))))
			 
		go


		--[ORD_Singh_201210017D].[src].[Inpat_Inpatient] specilty, bedsection code
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B1_Inpat_HospiceSpecialty]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B1_Inpat_HospiceSpecialty]
		go


SELECT *

	into  [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B1_Inpat_HospiceSpecialty]
	from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8_Hospice as x
		where not exists(
		select * FROM [ORD_Singh_201210017D].[src].[Inpat_Inpatient] as a
		inner join CDWWork.Dim.Specialty as s
		on a.DischargeFromSpecialtySID=s.SpecialtySID and a.sta3n=s.sta3n
		inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(s.PTFCode)) in ('96','1F') 
		and x.patientSSN=p.patientsSN and a.[DischargeDateTime] 
		between DATEADD(yy,-1,x.AFP_dt) and 
					  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),x.AFP_dt)
		)
		go





		--Outside Hospice care ( VA Paid/Fee Based) see the coding policy
			if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B2_Hospice_FeeInpatInvoice_PurposeOfVisit]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B2_Hospice_FeeInpatInvoice_PurposeOfVisit]
		go


SELECT *

	into  [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B2_Hospice_FeeInpatInvoice_PurposeOfVisit]
	from [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B1_Inpat_HospiceSpecialty] as x
		where not exists(
		select  b.FeePurposeOfVisit,a.* 
		from [ORD_Singh_201210017D].[src].[Fee_FeeInpatInvoice] as a
		inner join cdwwork.dim.FeePurposeOfVisit as b
		on a.FeePurposeOfVisitSID=b.FeePurposeOfVisitSID
		inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(b.AustinCode)) in ('43','37','38','77','78')  
		and x.patientSSN=p.patientsSN and a.TreatmentFromDateTime 
		between DATEADD(yy,-1,x.AFP_dt) and 
					  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),x.AFP_dt)
		)
		go



		--Outside Hospice care ( VA Paid/Fee Based) see the coding policy
				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B3_Hospice_FeeServiceProvided_HCFAType]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B3_Hospice_FeeServiceProvided_HCFAType]
		go


SELECT *
	into  [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B3_Hospice_FeeServiceProvided_HCFAType]
	from [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B2_Hospice_FeeInpatInvoice_PurposeOfVisit] as x
		where not exists(
		select  b.IBTypeOfServiceCode,a.* 
		from [ORD_Singh_201210017D].[src].[Fee_FeeServiceProvided] as a
		inner join [ORD_Singh_201210017D].[src].[Fee_FeeInitialTreatment] as d
		on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
		inner join cdwwork.dim.IBTypeOfService as b
		on a.FeeInitialTreatmentSID=b.IBTypeOfServiceSID
		inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(b.IBTypeOfServiceCode)) in ('H')  
		and x.patientSSN=p.patientsSN and d.[InitialTreatmentDateTime]
		between DATEADD(yy,-1,x.AFP_dt) and 
					  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),x.AFP_dt)
		)
		go


		--Outside Hospice care ( VA Paid/Fee Based) see the coding policy
				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B4_Hospice_FeeServiceProvided_PLCSRVCType]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B4_Hospice_FeeServiceProvided_PLCSRVCType]
		go


SELECT *
	into  [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B4_Hospice_FeeServiceProvided_PLCSRVCType]
	from [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B3_Hospice_FeeServiceProvided_HCFAType] as x
		where not exists(
		select  b.IBPlaceOfServiceCode,a.* 
		from [ORD_Singh_201210017D].[src].[Fee_FeeServiceProvided] as a
		inner join [ORD_Singh_201210017D].[src].[Fee_FeeInitialTreatment] as d
		on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
		inner join cdwwork.dim.IBPlaceOfService as b
		on a.IBPlaceOfServiceSID=b.IBPlaceOfServiceSID
		inner join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as p
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where ltrim(rtrim(b.IBPlaceOfServiceCode)) in ('34','H','Y')  
		and x.patientSSN=p.patientsSN and d.[InitialTreatmentDateTime]
		between DATEADD(yy,-1,x.AFP_dt) and 
					  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),x.AFP_dt)
		)
		go


-----------------------------------Referrals------------------------------------------------
--------------------------------------------------------------------------------------------




  if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_4_Exc_NonDx_HLP0_Referral_AllVisitDup]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP0_Referral_AllVisitDup
					
							select  p.patientSSN
							,V.Sta3n,V.PatientSID,V.Visitsid,V.VisitDatetime,V.primaryStopcodeSID,V.SecondaryStopcodeSID					
					into [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP0_Referral_AllVisitDup										
					from [ORD_Singh_201210017D].[src].[outpat_Visit] as V
                    inner join 
						(select distinct pat.*,ins.AFP_dt 
							from [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_9_IncPat] as pat
							left join [ORD_Singh_201210017D].[Dflt].[HCC_1_Inc_8_Incins] as ins
							on pat.patientSSN=ins.PatientSSN  -- populate every patientsid+sta3n with AFP_dt, even not real
							--on pat.patientSid=ins.PatientSid and pat.sta3n=ins.sta3n  -- real AFP_dt added to patientsid+sta3n
						) as p  -- All possible combination of patientsid+sta3n with clue date if possible
                    on v.sta3n=p.sta3n and v.patientsid=p.patientsid 
					--only get 1 year before and 60 days after each AFP_dt, hence reduced dramatically the num of records
						and v.VisitDateTime between dateAdd(yy,-1,p.AFP_dt)
										and DateAdd(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),p.AFP_dt)
				where V.CohortName='Cohort20170313'and
				 V.VisitDateTime between dateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
										and DateAdd(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP))
				
		go

	
	  if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_4_Exc_NonDx_HLP1_Referral_AllVisit]') is not null)
						drop table [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP1_Referral_AllVisit
	   select *
	   into [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP1_Referral_AllVisit
	   from [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP0_Referral_AllVisitDup
	   union
	   select * from [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP0_Referral_AllVisitDup
					


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_4_Exc_NonDx_HLP2_Referral_AllVisit_StopCode]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP2_Referral_AllVisit_StopCode
					
					select v.*,code1.stopcode as PrimaryStopCode,code1.stopcodename as PrimaryStopCodeName,code2.stopcode as SecondaryStopCode,code2.stopcodename as SecondaryStopCodeName
					into [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP2_Referral_AllVisit_StopCode
					from [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP1_Referral_AllVisit as V
					left join [CDWWork].[Dim].[StopCode] as code1
					on V.PrimaryStopCodeSID=code1.StopCodeSID	and V.Sta3n=code1.Sta3n		
					left join [CDWWork].[Dim].[StopCode] as code2
					on V.SecondaryStopCodeSID=code2.StopCodeSID	and v.sta3n=code2.sta3n

go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_4_Exc_NonDx_HLP3_Referral_VisitStopCodeTIU]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP3_Referral_VisitStopCodeTIU
																													
go

		select v.*
					--,c.consultsid,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
					--c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName
					,T.[TIUDocumentSID],T.[EntryDateTime],T.[ReferenceDateTime],RptText.ReportText,e.tiustandardtitle,T.ConsultSID
					into [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP3_Referral_VisitStopCodeTIU					
					from [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP2_Referral_AllVisit_StopCode as V
					left join ORD_Singh_201210017D.[src].[TIU_TIUDocument_8925] as T
					on T.VisitSID=V.Visitsid and T.CohortName='Cohort20180712'
					left join [CDW_TIU].[TIU].[TIUDocument_8925_02] as RptText
					on T.TIUDocumentsid=RptText.TIUDocumentsid and  RptText.CohortName='Cohort20180712'
					left join cdwwork.dim.[TIUDocumentDefinition] as d                                         
					on t.[TIUDocumentDefinitionSID]=d.[TIUDocumentDefinitionSID]
					left join cdwwork.dim.TIUStandardTitle as e
					on d.TIUStandardTitleSID=e.TIUStandardTitleSID

go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID

						select v.*
					--,c.consultsid
					,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
					c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName,
					c.placeofconsultation,	  
					c.requestType, --the request is a consult or procedure
					c.[InpatOutpat], -- the ordering person to indicate if the service is to be rendered on an outpatient or Inpatients basis.
					c.[RemoteService]
					--,T.[TIUDocumentSID],ReportText,e.tiustandardtitle
					into [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID
                    from [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP3_Referral_VisitStopCodeTIU as V
					--left join [TIU_2013].[TIU].[TIUDocument_v030] as T
					--on T.VisitSID=V.Visitsid
					--left join [TIU_2013].[TIU].[TIUDocument_8925_02] as RptText
					--on T.TIUDocumentsid=RptText.TIUDocumentsid
					left join [ORD_Singh_201210017D].[src].con_Consult as C										                    
					on C.ConsultSID=V.ConsultSID and C.CohortName='Cohort20170313'


go


		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_A]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_A
				
		select *
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_A
        from [ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8B4_Hospice_FeeServiceProvided_PLCSRVCType] as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID as b
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (351,353)   or b.SecondaryStopCode in (351,353)   
			 -- There is a visit, but no StopCode 
					or 	(b.[ConsultToRequestserviceName] like '%Hospice%' or b.[ConsultToRequestserviceName] like '%palliative%'
					or b.TIUStandardTitle like '%Hospice%' or b.TIUStandardTitle like '%palliative%')
					)
					and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and			 
			 (b.visitdatetime between DATEADD(yy,-1, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime)))
			 )
go



		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_B]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_B
				
		select *
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_B
        from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_A as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID as b
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (351,353)   or b.SecondaryStopCode in (351,353)   
					or 	(b.[ConsultToRequestserviceName] like '%Hospice%' or b.[ConsultToRequestserviceName] like '%palliative%'
					or b.TIUStandardTitle like '%Hospice%' or b.TIUStandardTitle like '%palliative%')
					)
					and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and			 
			 (b.ReferenceDateTime between DATEADD(yy,-1, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime)))
			  and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<60  
			  and b.PrimaryStopCodeSID=-1  
			 )
go

 
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_C]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_C
				
		select *
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_C
        from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_B as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID as b
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (351,353)   or b.SecondaryStopCode in (351,353)   
					or 	(b.[ConsultToRequestserviceName] like '%Hospice%' or b.[ConsultToRequestserviceName] like '%palliative%'
					or b.TIUStandardTitle like '%Hospice%' or b.TIUStandardTitle like '%palliative%')
					)
					and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and			 
			 (b.VisitDatetime between DATEADD(yy,-1, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime)))
			  --and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<60  			  
			  and b.PrimaryStopCodeSID<>-1  
			  and isnull( b.PrimaryStopCode,'') not in (351,353) and  isnull( b.SecondaryStopCode,'') not in (351,353)
											
			 )
go



		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_D]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_D
				
		select *
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_D
        from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_C as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID as b
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (351,353)   or b.SecondaryStopCode in (351,353)   
					or 	(b.[ConsultToRequestserviceName] like '%Hospice%' or b.[ConsultToRequestserviceName] like '%palliative%'
					or b.TIUStandardTitle like '%Hospice%' or b.TIUStandardTitle like '%palliative%')
					)
					and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and			 
			 (b.ReferenceDateTime between DATEADD(yy,-1, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime)))
			  and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<60  
			  and b.PrimaryStopCodeSID<>-1  
			  and isnull( b.PrimaryStopCode,'') not in (351,353) and  isnull( b.SecondaryStopCode,'') not in (351,353)
			  and ( b.PrimaryStopCode in (351,353)   or b.SecondaryStopCode in (351,353)) 	
			 )
go

-------------------------------------------------------------------------------------------

---------------------------Expected Followup Exclusions------------------------------

---------------------------  8: LiverBiopsy Exclusions  ---------------------------
-------------------------------------------------------------------------------------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_1_LiverBiopsy]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_1_LiverBiopsy
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_1_LiverBiopsy
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_8D1_Hospice_Refer_joinByConsultSID_D as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverBiopsy] as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[LiverBiopsy_dt] between DATEADD(dd,-60, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))
							)
		go

---------------------------  Liversurgery Exclusions  ---------------------------


		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_2_LiverSurg]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_2_LiverSurg
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_2_LiverSurg
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_1_LiverBiopsy as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverSurgery] as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[LiverSurg_dx_dt] between DATEADD(dd,-60, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))
							)
		go


		---------------------------  LiverImg Exclusions  ---------------------------


		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_3_LiverImg_Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_3_LiverImg_Proc
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_3_LiverImg_Proc
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_2_LiverSurg as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_3_Exc_NonDx_3_PrevProc_AllNonDxProcICD9ICD10Proc_LiverImg] as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[LiverImg_dx_dt] between DATEADD(dd,-60, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))
							)
		go

				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_3_LiverImg_Rad]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_3_LiverImg_Rad
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_3_LiverImg_Rad
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_3_LiverImg_Proc as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].HCC_5_Exc_NonDx_HLP5_LiverRadImg_SSN as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[ExamDateTime] between DATEADD(dd,-60, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))
							)
		go


		---------------------------  Liver Tumor Embolization  ---------------------------


		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_4_0_TumorEmbolization]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_4_0_TumorEmbolization
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_4_0_TumorEmbolization
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_3_LiverImg_Rad as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].HCC_3_Exc_NonDx_3_PrevProc_LiverTumorEmbolization as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.LiverTumorEmbol_dt between DATEADD(dd,-60, convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))
							)
		go


---------------------------------------------------------------------------------------------
----------------------------- Referrals within 60 days---------------------------
---------------------------------------------------------------------------------------------

---------------------------Gastroenterology Referral-------------------------------


  
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_4_GIRefer60d_joinByConsultSID]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_4_GIRefer60d_joinByConsultSID

        select a.* --
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_4_GIRefer60d_joinByConsultSID
    	from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_4_0_TumorEmbolization as a
		where not exists --
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID] as b
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321)
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.[AFP_dt],120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,60,convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))))
			   and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<60  
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<60 )) 
go

---------------------------Hepatology referral --------------------------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_5_HepaRefer_ByConsultSID]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_5_HepaRefer_ByConsultSID
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_5_HepaRefer_ByConsultSID
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_4_GIRefer60d_joinByConsultSID as a
			 		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID] as b
			 where (
			 b.PrimaryStopCode in (337,454)   or b.SecondaryStopCode in (337,454)
					or 	b.[ConsultToRequestserviceName] like '%hepa%' or b.[ConsultToRequestserviceName] like '%Liver%' 
					or b.TIUStandardTitle like '%hepa%'  or b.TIUStandardTitle like '%Liver%'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.[AFP_dt],120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,60,convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))))
			   and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<60  
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<60 ) 
			  )
		go



---------------------------TumorBoard Referral-------------------------------
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_6_TumorBoard_ByConsultSID]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_6_TumorBoard_ByConsultSID
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_6_TumorBoard_ByConsultSID
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_5_HepaRefer_ByConsultSID as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID] as b
			 where  (
					((b.[primaryStopcode] in (316) or b.[SecondaryStopcode] in (316)) and [tiustandardtitle] like '%Tumor%Board%')
			        or b.TIUStandardTitle like '%tumor%board%' --(and ConsultSID is not null and ConsultSID<>-1)					
					)
			 --Tumor, stopcode+title
			 	and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
				and	DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime)))
			   and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<60  
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<60 ) 
				)
		go




		--------------------------- Oncology Referral-------------------------------
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_7_OncologyRefer_ByConsultSID]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_7_OncologyRefer_ByConsultSID
        select a.*                         
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_7_OncologyRefer_ByConsultSID
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_6_TumorBoard_ByConsultSID as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID] as b
				 where (
			 --With Stopcode
			 b.PrimaryStopCode in (316)   or b.SecondaryStopCode in (316)
					or 	b.[ConsultToRequestserviceName] like '%oncol%' 
					or b.TIUStandardTitle like '%oncol%' 
					)		 
				and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.AFP_dt,120)+cast('00:00:00.000' as datetime)) 
				and	DATEADD(dd,60, convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime)))
			   and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<60  
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<60 ) 
				)
		go


		------------------------- Transplant Referral-------------------------------

			if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_8_TransplantRefer]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_8_TransplantRefer
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_8_TransplantRefer
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_7_OncologyRefer_ByConsultSID as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID] as b
			 where (
				        (	 
							 (PrimaryStopCodeName like '%Transpl%'
							or ConsultToRequestserviceName like '%Transpl%'
							or tiustandardtitle like '%Transpl%'							
							)
							and
							(
								   PrimaryStopCodeName like '%GI %'
								or PrimaryStopCodeName like '%GASTROENTERO%'
								or PrimaryStopCodeName like '%HEPA%'
								or PrimaryStopCodeName like '%Liver%'

								or ConsultToRequestserviceName like '%GI %'
								or ConsultToRequestserviceName like '%GASTROENTERO%'
								or ConsultToRequestserviceName like '%HEPA%'
								or ConsultToRequestserviceName like '%Liver%'

								or tiustandardtitle like '%GI %'
								or tiustandardtitle like '%GASTROENTERO%'
								or tiustandardtitle like '%HEPA%'
								or tiustandardtitle like '%Liver%')				
						 )
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
				and a.patientSSN = b.patientSSN and
				(coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.[AFP_dt],120)+cast('00:00:00.000' as datetime))
				and (DATEADD(dd,60,convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))))
			   and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<60  
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<60 ) 
				)
				)
		go


		--  key word in PrimaryStopCodeName or ConsultToRequestserviceName or tiustandardtitle
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_5_Ins_Exp_9_LiverSurgRefer]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_9_LiverSurgRefer
        select a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_9_LiverSurgRefer
		from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_8_TransplantRefer as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[HCC_4_Exc_NonDx_HLP4_Referral_VisitTIUConsult_joinByConsultSID] as b
				 where (
				          (	
								(PrimaryStopCodeName like '%Surg%'
								or ConsultToRequestserviceName like '%Surg%'
								or tiustandardtitle like '%Surg%'							
								)
								and
								(  
									PrimaryStopCodeName like '%HEPA%'
									or PrimaryStopCodeName like '%Liver%'

									or ConsultToRequestserviceName like '%HEPA%'
									or ConsultToRequestserviceName like '%Liver%'

									or tiustandardtitle like '%HEPA%'
									or tiustandardtitle like '%Liver%')								
						    )
							and a.patientSSN = b.patientSSN and
							(coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.[AFP_dt],120)+cast('00:00:00.000' as datetime))
							and (DATEADD(dd,60,convert(varchar(10),a.AFP_dt,120)+cast('23:59:59.997' as datetime))))
							 and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<60  
								 or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<60 ) 
							)
				)
		go





		---------------------------------------------------------------------------------------------------
-----------------   High Risk - first instance of each patient  -------------------
---------------------------------------------------------------------------------------------------
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[HCC_6_Ins_FirstOfPat]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].HCC_6_Ins_FirstOfPat

		SELECT distinct a.*
		into [ORD_Singh_201210017D].[Dflt].HCC_6_Ins_FirstOfPat
				from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_9_LiverSurgRefer as a
				inner join 
				(         select a.patientssn, min(a.AFP_dt) as FirstClueDate		
				from [ORD_Singh_201210017D].[Dflt].HCC_5_Ins_Exp_9_LiverSurgRefer as a		
				where a.AFP_dt between (select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)
								  and (select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)			  
				group by a.patientssn
				) as sub
				on a.patientssn=sub.patientssn and a.AFP_dt=sub.FirstClueDate	
		where a.AFP_dt between (select sp_start from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)
		                  and (select sp_end from [ORD_Singh_201210017D].[Dflt].HCC_0_1_inputP)		
go






