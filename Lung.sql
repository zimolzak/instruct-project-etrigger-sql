-----------------------------
----                     ----
---   Trigger - Lung   ---
----                     ----
-----------------------------

use master

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP]') is not null)	
	begin
		--Only one row (current running parameter) in this table
		delete from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP]
	end
	else
	begin	
		CREATE TABLE ORD_Singh_201210017D.[Dflt].[Lung_0_1_inputP](
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
		[age] [smallint] NULL,
		[op_grp] [varchar](4) NULL)
	end

go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_0_1_run_count]') is null)  -- never delete, alwasys append
	begin
		CREATE TABLE [ORD_Singh_201210017D].[Dflt].[Lung_0_1_run_count](
		[trigger] [varchar](20) NULL,
		isVISN bit null,
		isSta3n bit null,
		[round] [smallint] Not NULL default 0,
		[VISN] [smallint] NULL,
		Sta3n smallint null,
		[run_dt] [datetime] NULL,
		[sp_start] [datetime] NULL,
		[sp_end] [datetime] NULL,
		[fu_period] [smallint] NULL,
		[age] [smallint] NULL,
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
		[trig_pos_ins] [int] NULL,
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
declare @age as smallint
DECLARE @op_grp varchar(4)

-- Set study parameters
set @trigger='LC'
set @isVISN=1
set @isSta3n=0
set @VISN=12
set @Sta3n=-1
set @run_date=getdate()
set @sp_start='2012-01-01 00:00:00'
set @sp_end='2012-12-31 23:59:59' 
--  Follow-up period
set @fu_period=30
set @age=18


set @op_grp='I'
set @round= ( case when (select count(*) from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_run_count])>0
				then (select max(round)+1 from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_run_count])
			else 1
			end)

INSERT INTO ORD_Singh_201210017D.[Dflt].[Lung_0_1_inputP]
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
           ,[age]
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
           ,@age
           ,@op_grp)


go

select * from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP]

INSERT INTO [ORD_Singh_201210017D].[Dflt].[Lung_0_1_run_count]
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
           ,[age]
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
		   ,[trig_pos_ins]
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
           ,[age]
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
				  ,null
		 from ORD_Singh_201210017D.[Dflt].[Lung_0_1_inputP] as Input

		  select VISN,Sta3n,*  from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_run_count] order by [round]

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_0_2_0_LungImg') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].Lung_0_2_0_LungImg
go

	CREATE TABLE ORD_Singh_201210017D.[Dflt].[Lung_0_2_0_LungImg] (
	UniqueID int Identity(1,1) not null,
	[img_code_type] [varchar](50) NULL,
	[img_code_name] [varchar](50) NULL,
	[ImgCode] [varchar](10) NULL
	) 
go

insert into  ORD_Singh_201210017D.[Dflt].Lung_0_2_0_LungImg ([img_code_type],[img_code_name],[ImgCode]) 
values
( 'CT','','71275')
,( 'CT','','71250')
,( 'CT','','71270')
,( 'CT','','71260')
,( 'XRay','','71010')
,( 'XRay','','71015')
,( 'XRay','','71020')
,( 'XRay','','71021')
,( 'XRay','','71022')
,( 'XRay','','71030')
,( 'XRay','','71035')
,( 'XRay','','71101')
,( 'XRay','','71111')

,( 'XRay','','71045')
,( 'XRay','','71046')
,( 'XRay','','71047')
,( 'XRay','','71048')

,( 'PET','','78811')
,( 'PET','','78812')
,( 'PET','','78813')
,( 'PET','','78814')
,( 'PET','','78815')
,( 'PET','','78816')

,( 'PET','','78810')
,( 'PET','','G0125')
,( 'PET','','G0126')
,( 'PET','','G0210')
,( 'PET','','G0211')
,( 'PET','','G0212')
,( 'PET','','G0213')


go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_0_2_DxICD10CodeExc') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc]
go


	CREATE TABLE ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] (
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go


----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.00'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.01' 
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.02'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.10' 
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.11' 
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.12'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.2'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.30'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.31'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.32'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.80'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.81'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.82'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.90' 
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.91' 
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C34.92'
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C78.00' 
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C78.01' 
----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'Lung_Cancer','','C78.02'

----insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
----select 	'RecentActiveLungC','Lung Cancer','C30.'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.00'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.01'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.02'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.10'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.11'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.12'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.2'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.30'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.31'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.32'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.80'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.81'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.82'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.90'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.91'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C34.92'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C78.00'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C78.01'
--insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
--select 	'RecentActiveLungC','Lung Cancer','C78.02'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.00'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.40'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.50'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.01'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.41'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.51'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.02'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.42'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.52'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.60'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C92.A0'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C93.00'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C93.01'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C93.02'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C94.00'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C94.01'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C94.02'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C94.20'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C94.21'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C94.22'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C95.00'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C95.01'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Leukemia (Acute Only)','C95.02'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.0'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.2'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.3'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.4'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.7'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.8'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.1'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C22.9'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Hepatocelllular Cancer','C78.7'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C23.'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.0'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.1'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.8'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Biliary Cancer','C24.9'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.3'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.4'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.5'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.8'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Esophageal Cancer','C15.9'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.0'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.4'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.3'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.1'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.2'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.5'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.6'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.8'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Gastric Cancer','C16.9'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.0'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.1'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.2'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.3'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.4'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.5'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.6'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.7'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.8'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C71.9'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C79.31'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C79.32'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer','C79.49'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Brain Cancer', 'C79.40'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Ovarian Cancer','C56.9'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Ovarian Cancer','C56.1'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Ovarian Cancer','C56.2'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.0'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.1'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.2'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pancreatic Cancer','C25.3'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pleural Cancer & Mesothelioma','C38.4'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pleural Cancer & Mesothelioma','C45.0'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Pleural Cancer & Mesothelioma','C78.2'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Uterine Cancer','C55.'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C45.1'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.1'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.8'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.2'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C78.6'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','C90.00'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','C90.01'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','C90.02'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Myeloma','D47.Z9'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Tracheal Cancer','C33.'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Tracheal Cancer','C78.39'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Terminal','Tracheal Cancer','C78.30'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Hospice','','Z51.5'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Tuberculosis','','A15.0'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Tuberculosis','','A15.5'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Tuberculosis','','A15.6'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'Tuberculosis','','A15.7'



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_0_3_PreProcICD10ProcExc]') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc]
go

	CREATE TABLE ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] (
	UniqueID int Identity(1,1) not null,
	[ICD10Proc_code_type] [varchar](50) NULL,
	[ICD10Proc_code_Name] [varchar](50) NULL,
	[ICD10ProcCode] [varchar](10) NULL
	) 
go

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B933ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B934ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B937ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B938ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B943ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B944ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B947ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B948ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B953ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B954ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B957ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B958ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B963ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B964ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B967ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B968ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B973ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B974ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B977ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B978ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B983ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B984ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B987ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B988ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B993ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B994ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B997ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B998ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B3ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B4ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B7ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B8ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB33ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB34ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB37ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB38ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB43ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB44ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB47ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB48ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB53ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB54ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB57ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB58ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB63ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB64ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB67ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB68ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB73ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB74ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB77ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB78ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB83ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB84ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB87ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB88ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB93ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB94ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB97ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB98ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB3ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB4ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB7ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB8ZX'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0B930ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0B940ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0B950ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0B960ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0B970ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0B980ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0B990ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0B9B0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0BB30ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0BB40ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0BB50ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0BB60ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0BB70ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0BB80ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0BB90ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyBronchus','0BBB0ZX'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9C3ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9C4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9C7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9D3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9D4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9D7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9F3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9F4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9F7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9G3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9G4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9G7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9H3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9H4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9H7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9J3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9J4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9J7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9K3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9K4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9K7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9L3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9L4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9L7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9M3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9M4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9M7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBC3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBD3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBF3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBG3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBH3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBJ3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBK3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBL3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBM3ZX'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0B9K8ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0B9L8ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0B9M8ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBK7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBK8ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBL7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBL8ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBM4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBM7ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBM8ZX'



insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyLung','0B9K0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyLung','0B9L0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyLung','0B9M0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyLung','0BBK0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyLung','0BBL0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','OpenBiopsyLung','0BBM0ZX'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBC4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBD4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBF4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBG4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBH4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBJ4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBK4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBL4ZX'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','BiopsyChestWall','0W980ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','BiopsyChestWall','0W983ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','BiopsyChestWall','0W984ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','BiopsyChestWall','0WB80ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','BiopsyChestWall','0WB83ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','BiopsyChestWall','0WB84ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','BiopsyChestWall','0WB8XZX'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0B9N0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0B9N3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0B9N4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0B9P0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0B9P3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0B9P4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0BBN0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0BBN3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0BBP0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0BBP3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0W990ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0W993ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0W994ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0W9B0ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0W9B3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','PleuraBiopsy','0W9B4ZX'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0W9C3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0W9C4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0WBC3ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0WBC4ZX'



insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Bronchoscopy','','0BBN4ZX' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Bronchoscopy','','0BBP4ZX'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Bronchoscopy','','0BJ08ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Bronchoscopy','','0WJQ4ZZ'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Bronchoscopy','','0WJC4ZZ'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Bronchoscopy','','0BJ08ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Bronchoscopy','','0BJK8ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'Bronchoscopy','','0BJL8ZZ'


-- Lung surgery
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B534ZZ'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B538ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B544ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B548ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B554ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B558ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B564ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B568ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B574ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B578ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B584ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B588ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B594ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B598ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5B4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5B8ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB34ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB38ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB44ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB48ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB54ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB58ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB64ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB68ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB74ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB78ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB84ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB88ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB94ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB98ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBB4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBB8ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B530ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B533ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B537ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B540ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B543ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B547ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B550ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B553ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B557ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B560ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B563ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B567ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B570ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B573ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B577ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B580ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B583ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B587ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B590ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B593ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B597ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5B0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5B3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5B7ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB30ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB33ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB37ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB40ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB43ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB47ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB50ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB53ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB57ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB60ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB63ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB67ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB70ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB73ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB77ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB80ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB83ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB87ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB90ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB93ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BB97ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBB0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBB3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBB7ZZ'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT30ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT34ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT40ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT44ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT50ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT54ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT60ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT64ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT70ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT74ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT80ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT84ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT90ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BT94ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTB0ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBK4ZZ'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBL4ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5K0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5L0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5M0ZZ'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5K3ZZ'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5L3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5M3ZZ'



insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5K4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5L4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5M4ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5K7ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5K8ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5L7ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5L8ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5M7ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5M8ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5K8ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5L8ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5M8ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBK8ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBL8ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBM4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBM8ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5K0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5K3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5K7ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5L0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5L3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5L7ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5M0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5M3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0B5M7ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBK0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBK3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBK7ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBL0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBL3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBL7ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBM0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBM3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBM7ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBC4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBD4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBF4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBG4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBH4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBJ4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBK4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBL4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTH4ZZ'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])

select 	'LungSurgery','','0BBK0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBK3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBK7ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBL0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBL3ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BBL7ZZ'

insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTC4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTD4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTF4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTG4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTJ4ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTC0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTD0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTF0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTG0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTJ0ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','02JA0ZZ'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0WJC0ZZ'



insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BJ04ZZ'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0WJQ4ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTK4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTL4ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTM4ZZ'


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTK0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTL0ZZ' 
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])
select 	'LungSurgery','','0BTM0ZZ'


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_0_4_DxICD9CodeExc]') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].Lung_0_4_DxICD9CodeExc
go

	CREATE TABLE ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc] (
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go

insert into  ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc] (
	[ICD9Code]
	) 
select distinct ICD9Code from CDWWork.dim.ICD9 as dimICD9
where	
	-- Recent active Lung Cancer  -- Move to ProblemList
	--   DimICD9.ICD9Code like '162.2%'
	--or DimICD9.ICD9Code like '162.3%'
	--or DimICD9.ICD9Code like '162.4%'
	--or DimICD9.ICD9Code like '162.5%'
	--or DimICD9.ICD9Code like '162.8%'
	--or DimICD9.ICD9Code like '162.9%'
	--or DimICD9.ICD9Code like '197.0'
	--or DimICD9.ICD9Code like '163.%'
	--or DimICD9.ICD9Code like '197.2%'
	 --Pancreatic
	 dimICD9.ICD9Code like '157.%'
		-- Leukemia (Acute Only)
	or dimICD9.ICD9Code like '207.2%'		
	or dimICD9.ICD9Code in ('205.0','206.0','207.0','208.0')
		-- Hepatocelllular Cancer and intrahepatic bile duct cancer
	or dimICD9.ICD9Code in ('155.0','155.1','155.2','197.7')
		-- Gallbladder and Biliary Cancer 
	or dimICD9.ICD9Code like '156.%'
		-- Esophageal Cancer
	or dimICD9.ICD9Code like '150.%'
		-- Gastric Cancer
	or dimICD9.ICD9Code like '151.%'
		-- Brain Cancer
	or dimICD9.ICD9Code in ('191.0','191.1','191.2','191.3','191.4','191.5','191.6','191.7','191.8','191.9','198.3','198.4')
		--Uterine Cancer 
	or dimICD9.ICD9Code like '179.%' -- checked cdwwork.dim.icd
		-- Ovarian Cancer
	or dimICD9.ICD9Code in  ('183.0')
		--Peritoneal, omeantal, &Mesenteric Cancer
	or dimICD9.ICD9Code in ('158.8','158.9','197.6')
		--Myeloma
	or dimICD9.ICD9Code in ('238.6')
	or dimICD9.ICD9Code like '203.0%'
		--Tracheal Cancer
	or dimICD9.ICD9Code in ('162.0','197.3')
		-- Hospice / Palliative Care
	or dimICD9.ICD9Code in ('V66.7')
		-- Tuberculosis
	or dimICD9.ICD9Code in (
			'010.0','010.00','010.01','010.02','010.03','010.04','010.05','010.06',
			'010.1','010.10','010.11','010.12','010.13','010.14','010.15','010.16',
			'010.8','010.80','010.81','010.82','010.83','010.84','010.85','010.86',
			'010.9','010.90','010.91','010.92','010.93','010.94','010.95','010.96',
			'011.0','011.00','011.01','011.02','011.03','011.04','011.05','011.06',
			'011.1','011.10','011.11','011.12','011.13','011.14','011.15','011.16',
			'011.2','011.20','011.21','011.22','011.23','011.24','011.25','011.26',
			'011.3','011.30','011.31','011.32','011.33','011.34','011.35','011.36',
			'011.4','011.40','011.41','011.42','011.43','011.44','011.45','011.46',
			'011.5','011.50','011.51','011.52','011.53','011.54','011.55','011.56',
			'011.6','011.60','011.61','011.62','011.63','011.64','011.65','011.66',
			'011.7','011.70','011.71','011.72','011.73','011.74','011.75','011.76',
			'011.8','011.80','011.81','011.82','011.83','011.84','011.85','011.86',
			'011.9','011.90',
			'011.91','011.92','011.93','011.94','011.95','011.96'
			)

update  ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc] 
 set dx_code_type = case
		--when 	-- Recent active Lung Cancer moved to Problemlist
		--	   ICD9Code like '162.2%'
		--	or ICD9Code like '162.3%'
		--	or ICD9Code like '162.4%'
		--	or ICD9Code like '162.5%'
		--	or ICD9Code like '162.8%'
		--	or ICD9Code like '162.9%'
		--	or ICD9Code like '197.0'
		--	or ICD9Code like '163.%'
		--	or ICD9Code like '197.2%' 
		--then 'RecentActiveLungC'
		when  	-- Pancreatic Cancer 
			ICD9Code like '157.%'
				-- Leukemia (Acute Only)
			or ICD9Code like '207.2%'		
			or ICD9Code in ('205.0','206.0','207.0','208.0')
				-- Hepatocelllular Cancer and intrahepatic bile duct cancer
			or ICD9Code in ('155.0','155.1','155.2','197.7')
				-- Gallbladder and Biliary Cancer 
			or ICD9Code like '156.%'
				-- Esophageal Cancer
			or ICD9Code like '150.%'
				-- Gastric Cancer
			or ICD9Code like '151.%'
				-- Brain Cancer
			or ICD9Code in ('191.0','191.1','191.2','191.3','191.4','191.5','191.6','191.7','191.8','191.9','198.3','198.4')
				--Uterine Cancer 
			or ICD9Code like '179.%' -- checked cdwwork.dim.icd
				-- Ovarian Cancer
			or ICD9Code in  ('183.0')
				--Peritoneal, omeantal, &Mesenteric Cancer
			or ICD9Code in ('158.8','158.9','197.6')
				--Myeloma
			or ICD9Code in ('238.6')
			or ICD9Code like '203.0%'
				--Tracheal Cancer
			or ICD9Code in ('162.0','197.3')
	    then 'Terminal'
		when 	-- Hospice / Palliative Care
			 ICD9Code in ('V66.7')
		 then 'Hospice'
		when 	-- Tuberculosis
		     ICD9Code in (
			'010.0','010.00','010.01','010.02','010.03','010.04','010.05','010.06',
			'010.1','010.10','010.11','010.12','010.13','010.14','010.15','010.16',
			'010.8','010.80','010.81','010.82','010.83','010.84','010.85','010.86',
			'010.9','010.90','010.91','010.92','010.93','010.94','010.95','010.96',
			'011.0','011.00','011.01','011.02','011.03','011.04','011.05','011.06',
			'011.1','011.10','011.11','011.12','011.13','011.14','011.15','011.16',
			'011.2','011.20','011.21','011.22','011.23','011.24','011.25','011.26',
			'011.3','011.30','011.31','011.32','011.33','011.34','011.35','011.36',
			'011.4','011.40','011.41','011.42','011.43','011.44','011.45','011.46',
			'011.5','011.50','011.51','011.52','011.53','011.54','011.55','011.56',
			'011.6','011.60','011.61','011.62','011.63','011.64','011.65','011.66',
			'011.7','011.70','011.71','011.72','011.73','011.74','011.75','011.76',
			'011.8','011.80','011.81','011.82','011.83','011.84','011.85','011.86',
			'011.9','011.90','011.91','011.92','011.93','011.94','011.95','011.96'
			) then 'Tuberculosis'
		else NULL		
	end
	


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_0_5_PreProcICD9ProcExc]') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].Lung_0_5_PreProcICD9ProcExc
go

	CREATE TABLE ORD_Singh_201210017D.[Dflt].Lung_0_5_PreProcICD9ProcExc (
	UniqueID int Identity(1,1) not null,
	[ICD9Proc_code_type] [varchar](50) NULL,
	[ICD9Proc_code_Name] [varchar](50) NULL,
	[ICD9ProcCode] [varchar](10) NULL
	) 
go


insert into  ORD_Singh_201210017D.[Dflt].Lung_0_5_PreProcICD9ProcExc ([ICD9Proc_code_type],[ICD9Proc_code_Name],[ICD9ProcCode]) 
values( 'LungSurgery','','32.0')
,( 'LungSurgery','','32.01')
,( 'LungSurgery','','32.09')
,( 'LungSurgery','','32.1')
,( 'LungSurgery','','32.20')
,( 'LungSurgery','','32.23')
,( 'LungSurgery','','32.24')
,( 'LungSurgery','','32.25')
,( 'LungSurgery','','32.26')
,( 'LungSurgery','','32.28')
,( 'LungSurgery','','32.29')
,( 'LungSurgery','','32.3')
,( 'LungSurgery','','32.39')
,( 'LungSurgery','','32.4')
,( 'LungSurgery','','32.41')
,( 'LungSurgery','','32.49')
,( 'LungSurgery','','32.5')
,( 'LungSurgery','','32.59')
,( 'LungSurgery','','34.02')
,( 'LungSurgery','','34.21')

,( 'LungBiopsy','','33.24')
,( 'LungBiopsy','','33.25')
,( 'LungBiopsy','','33.26')
,( 'LungBiopsy','','33.27')
,( 'LungBiopsy','','33.28')
,( 'LungBiopsy','','34.20')
,( 'LungBiopsy','','34.23')
,( 'LungBiopsy','','34.24')
,( 'LungBiopsy','','34.25')
 
,( 'Bronchoscopy','','33.20')
,( 'Bronchoscopy','','33.21')
,( 'Bronchoscopy','','33.22')
,( 'Bronchoscopy','','33.23') 
	

			
			 if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_0_6_LungCancerDxICD10CodeExc') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].Lung_0_6_LungCancerDxICD10CodeExc
go


	CREATE TABLE ORD_Singh_201210017D.[Dflt].Lung_0_6_LungCancerDxICD10CodeExc (
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go


insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.00'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.01'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.02'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.10'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.11'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.12'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.2'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.30'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.31'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.32'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.80'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.81'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.82'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.90'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.91'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C34.92'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C78.00'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C78.01'
insert into ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])
select 	'RecentActiveLungC','Lung Cancer','C78.02'




if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_0_7_LungCancerDxICD9CodeExc]') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].Lung_0_7_LungCancerDxICD9CodeExc
go

	CREATE TABLE ORD_Singh_201210017D.[Dflt].Lung_0_7_LungCancerDxICD9CodeExc (
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go

insert into  ORD_Singh_201210017D.[Dflt].Lung_0_7_LungCancerDxICD9CodeExc (
[dx_code_type],
	[dx_code_name],
	[ICD9Code]
	) 
select distinct 'RecentActiveLungC','', ICD9Code from CDWWork.dim.ICD9 as dimICD9
where	
	--  Lung Cancer 
	   DimICD9.ICD9Code like '162.2%'
	or DimICD9.ICD9Code like '162.3%'
	or DimICD9.ICD9Code like '162.4%'
	or DimICD9.ICD9Code like '162.5%'
	or DimICD9.ICD9Code like '162.8%'
	or DimICD9.ICD9Code like '162.9%'
	or DimICD9.ICD9Code like '197.0'
	or DimICD9.ICD9Code like '163.%'
	or DimICD9.ICD9Code like '197.2%'


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_0_8_PrevProcCPTCodeExc]') is not null) 		
	drop table ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc
go

	CREATE TABLE ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc (
	UniqueID int Identity(1,1) not null,
	[CPT_code_type] [varchar](50) NULL,
	[CPT_code_name] [varchar](50) NULL,
	[CPTCode] [varchar](10) NULL
	) 
go

insert into  ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc (
	[CPT_code_type],
	[CPT_code_name] ,
	[CPTCode] 
	) 
Values('Bronchoscopy','','31621')
,('Bronchoscopy','','31622')
,('Bronchoscopy','','31623')
,('Bronchoscopy','','31624')
,('Bronchoscopy','','31630')
,('Bronchoscopy','','31631')
,('Bronchoscopy','','31632')
,('Bronchoscopy','','31634')
,('Bronchoscopy','','31635')
,('Bronchoscopy','','31636')
,('Bronchoscopy','','31637')
,('Bronchoscopy','','31638')
,('Bronchoscopy','','31641')
,('Bronchoscopy','','31643')
,('Bronchoscopy','','31645')
,('Bronchoscopy','','31646')
,('Bronchoscopy','','31647')
,('Bronchoscopy','','31648')
,('Bronchoscopy','','31649')
,('Bronchoscopy','','31650')
,('Bronchoscopy','','31651')
,('Bronchoscopy','','31656')
,('Bronchoscopy','','31659')
,('Bronchoscopy','','31660')
,('Bronchoscopy','','31661')
,('Bronchoscopy','','31725')
,('Bronchoscopy','','32035')

-- Above Bronchoscopy
					 
,('LungBiopsy','','31625')
,('LungBiopsy','','31626')
,('LungBiopsy','','31627')
,('LungBiopsy','','31628')
,('LungBiopsy','','31629')
,('LungBiopsy','','31633')
,('LungBiopsy','','31640')
,('LungBiopsy','','31717')
,('LungBiopsy','','32098')
,('LungBiopsy','','32400')
,('LungBiopsy','','32402')
,('LungBiopsy','','32405')
,('LungBiopsy','','32601')
,('LungBiopsy','','32607')
,('LungBiopsy','','32608')
,('LungBiopsy','','32608')


--Above Lung Biopay
,('LungSurgery','','32036')
,('LungSurgery','','32095')
,('LungSurgery','','32096')
,('LungSurgery','','32097')
,('LungSurgery','','32100')
,('LungSurgery','','32120')
,('LungSurgery','','32140')
,('LungSurgery','','32141')
,('LungSurgery','','32150')
,('LungSurgery','','32200')
,('LungSurgery','','32201')
,('LungSurgery','','32310')
,('LungSurgery','','32315')
,('LungSurgery','','32320')
,('LungSurgery','','32440')
,('LungSurgery','','32442')
,('LungSurgery','','32445')
,('LungSurgery','','32450')
,('LungSurgery','','32480')
,('LungSurgery','','32482')
,('LungSurgery','','32484')
,('LungSurgery','','32485')
,('LungSurgery','','32486')
,('LungSurgery','','32488')
,('LungSurgery','','32490')
,('LungSurgery','','32491')
,('LungSurgery','','32500')
,('LungSurgery','','32503')
,('LungSurgery','','32504')
,('LungSurgery','','32505')
,('LungSurgery','','32520')
,('LungSurgery','','32522')
,('LungSurgery','','32525')
,('LungSurgery','','32540')
,('LungSurgery','','32545')
,('LungSurgery','','32656')
,('LungSurgery','','32657')
,('LungSurgery','','32663')
,('LungSurgery','','32666')
,('LungSurgery','','32667')
,('LungSurgery','','32668')
,('LungSurgery','','32669')
,('LungSurgery','','32670')
,('LungSurgery','','32671')
,('LungSurgery','','32672')
,('LungSurgery','','32700')
,('LungSurgery','','32705')
--Above Lung Surgery		

	

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_1_In_1_All_Chest_XRayCTPET_Redundant') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_1_In_1_All_Chest_XRayCTPET_Redundant


select [RadiologyExamSID]
      ,[RadiologyPatientSID]
      ,[RadiologyPatientIEN]
      ,[RadiologyRegisteredExamSID]
      ,[RadiologyRegisteredExamIEN]
      ,[RadiologyExamIEN]
      ,Rad.[Sta3n]
      ,[CaseNumber]
      ,[PatientSID]
      ,[ExamDateTime]
      ,Rad.[RadiologyProcedureSID]
	  ,code.CPTCode
	  ,TargetImg.[img_code_type]
	  ,[RadiologyExamStatus]
      ,[ExamCategory]
      ,[WardLocationSID]
      ,[PrincipalLocationSID]
      ,[PrimaryInterpretingResidentStaffSID]
      ,Rad.[RadiologyDiagnosticCodeSID]
	  ,[RadiologyDiagnosticCode]
	  ,[RadiologyDiagnosticCodeDescription]
      ,[RequestingPhysicianStaffSID]
      ,[PrimaryInterpretingStaffSID]
      ,[RadiologyComplicationTypeSID]
      ,[RadiologyNuclearMedicineReportSID]
      ,[RequestedDateTime]
      ,[RequestingLocationSID]
      ,[ClinicStopRecordedFlag]
      ,[VisitSID]
      ,[NuclearMedicineExamSID]
into [ORD_Singh_201210017D].[Dflt].Lung_1_In_1_All_Chest_XRayCTPET_Redundant 
FROM [ORD_Singh_201210017D].[Src].[Rad_RadiologyExam] as Rad
left join cdwwork.dim.[RadiologyProcedure] as prc
on rad.sta3n=prc.sta3n and rad.[RadiologyProcedureSID]=prc.[RadiologyProcedureSID]
left join cdwwork.dim.CPT as code
on prc.CPTSID=code.CPTSID and prc.sta3n=code.sta3n 
inner join  ORD_Singh_201210017D.[Dflt].Lung_0_2_0_LungImg as TargetImg
on TargetImg.ImgCode=code.CPTCode
left join cdwwork.dim.[RadiologyExamStatus] as sta
on Rad.sta3n=sta.sta3n and Rad.[RadiologyExamStatusSID]=sta.[RadiologyExamStatusSID]
left join cdwwork.dim.[RadiologyDiagnosticCode] as diag
on Rad.sta3n=diag.sta3n and Rad.[RadiologyDiagnosticCodeSID]=diag.[RadiologyDiagnosticCodeSID]
--inner join [ORD_Singh_201210017D].[Src].[Radiology_RadNuc_Med_Reports_74] as rpt
-- --on rpt.[RadNucMedReportIEN]=Rad.[ReportTextIEN] and rpt.Sta3n=Rad.Sta3n
-- on rtrim(ltrim(replace(convert(varchar,convert(decimal(20,6),rpt.row_id)),'.000000',''))) =Rad.[ReportTextIEN] and rpt.Sta3n=Rad.Sta3n
  inner join cdwwork.dim.VistaSite as VistaSite
		on Rad.sta3n=VistaSite.Sta3n
		----inner join [ORD_Singh_201210017D].[Src].[Radiology_radnuc_med_procedures_71] as code
		--inner join [ORD_Singh_201210017D].[Src].[Radiology_radnuc_med_procedures_71] as code		
  --on rad.procedure2=code.RadnucMedProceduresIEN
  --and rad.sta3n=code.sta3n  
  where Rad.CohortName='Cohort20180712' and
	 Rad.ExamDateTime--VerifiedDate
	  between (select sp_start from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP) and DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup
	and sta.[RadiologyExamStatus] like'%COMPLETE%'
	and VISN=(select VISN from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)
	 ----and rad.Sta3n<>556 -- Exclude NorthChicago
	

go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_1_In_1_All_Chest_XRayCTPET_SSN') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_1_In_1_All_Chest_XRayCTPET_SSN

	select distinct *  
	into [ORD_Singh_201210017D].[Dflt].Lung_1_In_1_All_Chest_XRayCTPET_SSN
	from (
		select b.patientSSN,convert(varchar(10),b.BirthDateTime,120) as DOB,convert(varchar(10),b.DeathDateTime,120) as DOD,b.Gender as Sex
				,a.* 	
		from [ORD_Singh_201210017D].[Dflt].Lung_1_In_1_All_Chest_XRayCTPET_Redundant as a
		left join (select distinct sta3n, patientsid,patientssn,BirthDateTime,DeathDateTime,Gender from ORD_Singh_201210017D.src.SPatient_SPatient) as b
		on a.sta3n=b.sta3n and a.[PatientSID]=b.patientsid
	) sub	


  if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_1_In_2_All_Chest_XRayCT') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_1_In_2_All_Chest_XRayCT

	select * into [ORD_Singh_201210017D].[Dflt].Lung_1_In_2_All_Chest_XRayCT
	from [ORD_Singh_201210017D].[Dflt].[Lung_1_In_1_All_Chest_XRayCTPET_SSN]
    where [img_code_type] in ('CT','XRay')
go



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_1_In_3_DxIEN') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_1_In_3_DxIEN
select  Rad.* into [ORD_Singh_201210017D].[Dflt].Lung_1_In_3_DxIEN
from [ORD_Singh_201210017D].[Dflt].[Lung_1_In_2_All_Chest_XRayCT] as Rad
inner join 
(
select distinct [PrimaryDiagnosticCode] from [ORD_Singh_201210017D].[Dflt].[Rad_0_0_RadDiagIEN_ForDaniel] 
			where [IncludedOrNot]=1
) as code
on rad.[RadiologyDiagnosticCode]=code.[PrimaryDiagnosticCode]



 if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_1_In_6_IncIns') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_1_In_6_IncIns

select 	distinct
		[RadiologyExamSID]
	  ,PatientSSN
	  ,[Sta3n]
      ,[PatientSID]
      ,[RadiologyPatientSID]
      ,[RadiologyPatientIEN]
      ,[RadiologyRegisteredExamSID]
      ,[RadiologyRegisteredExamIEN]
      ,[RadiologyExamIEN]
      ,[CaseNumber]
      ,[ExamDateTime]
      ,Rad.[RadiologyProcedureSID]
	  ,CPTCode
	  ,[RadiologyExamStatus]
      ,[ExamCategory]
      ,[WardLocationSID]
      ,[PrincipalLocationSID]
      ,[PrimaryInterpretingResidentStaffSID]
      ,Rad.[RadiologyDiagnosticCodeSID]
	  ,[RadiologyDiagnosticCode]
	  ,[RadiologyDiagnosticCodeDescription]
      ,[RequestingPhysicianStaffSID]
      ,[PrimaryInterpretingStaffSID]
      ,[RadiologyComplicationTypeSID]
      ,[RadiologyNuclearMedicineReportSID]
      ,[RequestedDateTime]
      ,[RequestingLocationSID]
      ,[ClinicStopRecordedFlag]
      ,[VisitSID]
      ,[NuclearMedicineExamSID]
	  ,DOB
	  ,DOD
	  ,Sex
into [ORD_Singh_201210017D].[Dflt].Lung_1_In_6_IncIns
from [ORD_Singh_201210017D].[Dflt].Lung_1_In_3_DxIEN as Rad
where ExamDateTime between (select sp_start from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)
				and (select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)

go


 if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_1_In_8_IncPat') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_1_In_8_IncPat

select distinct VStatus.Sta3n,VStatus.PatientSID,VStatus.patientSSN, VStatus.ScrSSN,VStatus.PatientICN
into [ORD_Singh_201210017D].[Dflt].Lung_1_In_8_IncPat
from [ORD_Singh_201210017D].[Dflt].Lung_1_In_6_IncIns as a
left join ORD_Singh_201210017D.src.SPatient_SPatient  as VStatus
on a.patientSSN=VStatus.PatientSSN
order by patientssn

go




--------------------------------------------------------------------------------------------
----------------------------- Exclusions DxCode---------------------------------------------
--------------------------------------------------------------------------------------------


-- Extract of all DX Codes for all potential patients from surgical
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_1_SurgDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_1_SurgDx_ICD9]

SELECT distinct
		surgPre.[SurgerySID] as SurgPre_SurgerySID
	  , surgDx.[SurgerySID]  as SurgDx_SurgerySID
	  ,surgDx.SurgeryProcedureDiagnosisCodeSID
	  ,SurgeryOtherPostOpDiagnosisSID
	  ,SurgeryPrincipalAssociatedDiagnosisSID
      ,surgPre.[Sta3n]
      ,[VisitSID]
      ,SurgPre.[PatientSID]
      ,[CancelDateTime]
      ,surgPre.[SurgeryDateTime]  as dx_dt

	  , PreICD9.ICD9Code as PreICDDiagnosis
	  ,PrincipalPostOpICD9.ICD9Code as PrincipalPostOpICDDiagnosis
	  ,OtherPostICD9.ICD9Code as OtherPostICDDiagnosis
	  ,assocDxICD9.ICD9Code as assocDxICDDiagnosis
	  ,(case when PrincipalPostOpICD9.ICD9Code in (select ICD9Code from ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc])
			then PrincipalPostOpICD9.ICD9Code
            when OtherPostICD9.ICD9Code in (select ICD9Code from ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc])
	        then OtherPostICD9.ICD9Code
            when assocDxICD9.ICD9Code in (select ICD9Code from ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc])
	   	    then assocDxICD9.ICD9Code
	        else null
	   end ) as ICD9Code    
	  ,(case when PrincipalPostOpICD9.ICD9Code in (select ICD9Code from ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc])
			then 
			(select dx_code_type from ORD_Singh_201210017D.[Dflt].Lung_0_4_DxICD9CodeExc where ICD9Code=PrincipalPostOpICD9.ICD9Code)
            when OtherPostICD9.ICD9Code in (select ICD9Code from ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc])
	        then 
			(select dx_code_type from ORD_Singh_201210017D.[Dflt].Lung_0_4_DxICD9CodeExc where ICD9Code=OtherPostICD9.ICD9Code)
            when assocDxICD9.ICD9Code in (select ICD9Code from ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc])
	   	    then 
			(select dx_code_type from ORD_Singh_201210017D.[Dflt].Lung_0_4_DxICD9CodeExc where ICD9Code=assocDxICD9.ICD9Code)
	        else null
	   end ) as dx_code_type 
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	 
  into [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_1_SurgDx_ICD9]
  --Raw
  --FROM [ORD_Singh_201210017D].[Src].[Surgery_Surgery_130] as surg
  --inner join [ORD_Singh_201210017D].[Src].[Surgery_surgeryprcdrdgnsscodes_136] as SurgDx
  --on SurgDx.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  --and SurgDx.Sta3n=SurgDx.Sta3n
  FROM [ORD_Singh_201210017D].[Src].[Surg_SurgeryPre] as surgPre
  inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  on SurgPre.sta3n=p.sta3n and SurgPre.patientsid=p.patientsid
  left join CDWWork.dim.ICD9 as PreICD9
  on SurgPre.PrincipalPreOpICD9SID=PreICD9.ICD9SID and SurgPre.Sta3n=PreICD9.Sta3n
  left join[ORD_Singh_201210017D].[Src].[Surg_SurgeryProcedureDiagnosisCode]as surgDx
  on surgPre.SurgerySID=SurgDx.SurgerySID and surgPre.sta3n=SurgDx.sta3n
  left join CDWWork.dim.ICD9 as PrincipalPostOpICD9
  on SurgDx.[PrincipalPostOpICD9SID]=PrincipalPostOpICD9.ICD9SID and SurgDx.Sta3n=PrincipalPostOpICD9.Sta3n
  left join [ORD_Singh_201210017D].[Src].Surg_SurgeryOtherPostOpDiagnosis as otherPostDx
   on surgDx.SurgeryProcedureDiagnosisCodeSID=otherPostDx.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=otherPostDx.sta3n
  left join CDWWork.dim.ICD9 as OtherPostICD9
  on otherPostDx.OtherPostopICD9SID=OtherPostICD9.ICD9SID and otherPostDx.Sta3n=OtherPostICD9.Sta3n
  left join [ORD_Singh_201210017D].[Src].Surg_SurgeryPrincipalAssociatedDiagnosis as assocDx
  on  surgDx.SurgeryProcedureDiagnosisCodeSID=assocDx.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=assocDx.sta3n
  left join CDWWork.dim.ICD9 as assocDxICD9
  on assocDx.[SurgeryPrincipalAssociatedDiagnosisICD9SID]=assocDxICD9.ICD9SID and assocDx.sta3n=assocDxICD9.sta3n
   where  
  
  SurgPre.[SurgeryDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup and
  and  SurgPre.CohortName='Cohort20180712'
  and  surgDx.CohortName='Cohort20180712'
  and  otherPostDx.CohortName='Cohort20180712'
  and  assocDx.CohortName='Cohort20180712'
  and (
  	--PreICD9.ICD9Code in (select ICD9Code from ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc])
	PrincipalPostOpICD9.ICD9Code in (select ICD9Code from ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc])
	or 	OtherPostICD9.ICD9Code in (select ICD9Code from ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc])
	or 	assocDxICD9.ICD9Code in (select ICD9Code from ORD_Singh_201210017D.[Dflt].[Lung_0_4_DxICD9CodeExc])
	) 
	go



if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_1_SurgDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_1_SurgDx_ICD10]

SELECT 
		surgPre.[SurgerySID] as SurgPre_SurgerySID
	  , surgDx.[SurgerySID]  as SurgDx_SurgerySID
      ,surgPre.[Sta3n]
      ,[VisitSID]
      ,SurgPre.[PatientSID]
      ,[CancelDateTime]
      ,surgPre.[SurgeryDateTime]  as dx_dt
		, PreICD10.ICD10Code as PreICDDiagnosis
	  ,PrincipalPostOpICD10.ICD10Code as PrincipalPostOpICDDiagnosis
	  ,OtherPostICD10.ICD10Code as OtherPostICDDiagnosis
	  ,assocDxICD10.ICD10Code as assocDxICDDiagnosis
	  ,(case when PrincipalPostOpICD10.ICD10Code in (select ICD10Code from ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc])
			then PrincipalPostOpICD10.ICD10Code
            when OtherPostICD10.ICD10Code in (select ICD10Code from ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc])
	        then OtherPostICD10.ICD10Code
            when assocDxICD10.ICD10Code in (select ICD10Code from ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc])
	   	    then assocDxICD10.ICD10Code
	        else null
	   end ) as ICD10Code  

	  ,(case when PrincipalPostOpICD10.ICD10Code in (select ICD10Code from ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc])
			then (select dx_code_type from ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] where ICD10Code=PrincipalPostOpICD10.ICD10Code)
            when OtherPostICD10.ICD10Code in (select ICD10Code from ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc])
			then (select dx_code_type from ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] where ICD10Code=OtherPostICD10.ICD10Code)
            when assocDxICD10.ICD10Code in (select ICD10Code from ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc])
			then (select dx_code_type from ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] where ICD10Code=assocDxICD10.ICD10Code)
	        else null
	   end ) as dx_code_type  

	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	 
  into [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_1_SurgDx_ICD10]
  --Raw
  --FROM [ORD_Singh_201210017D].[Src].[Surgery_Surgery_130] as surg
  --inner join [ORD_Singh_201210017D].[Src].[Surgery_surgeryprcdrdgnsscodes_136] as SurgDx
  --on SurgDx.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  --and SurgDx.Sta3n=SurgDx.Sta3n
  FROM [ORD_Singh_201210017D].[Src].[Surg_SurgeryPre] as surgPre
  inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  on SurgPre.sta3n=p.sta3n and SurgPre.patientsid=p.patientsid
  left join CDWWork.dim.ICD10 as PreICD10
  on SurgPre.PrincipalPreOpICD10SID=PreICD10.ICD10SID and SurgPre.Sta3n=PreICD10.Sta3n
  left join[ORD_Singh_201210017D].[Src].[Surg_SurgeryProcedureDiagnosisCode]as surgDx
  on surgPre.SurgerySID=SurgDx.SurgerySID and surgPre.sta3n=SurgDx.sta3n
  left join CDWWork.dim.ICD10 as PrincipalPostOpICD10
  on SurgDx.[PrincipalPostOpICD10SID]=PrincipalPostOpICD10.ICD10SID and SurgDx.Sta3n=PrincipalPostOpICD10.Sta3n
  left join [ORD_Singh_201210017D].[Src].Surg_SurgeryOtherPostOpDiagnosis as otherPostDx
   on surgDx.SurgeryProcedureDiagnosisCodeSID=otherPostDx.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=otherPostDx.sta3n
  left join CDWWork.dim.ICD10 as OtherPostICD10
  on otherPostDx.OtherPostopICD10SID=OtherPostICD10.ICD10SID and otherPostDx.Sta3n=OtherPostICD10.Sta3n
  left join [ORD_Singh_201210017D].[Src].Surg_SurgeryPrincipalAssociatedDiagnosis as assocDx
  on  surgDx.SurgeryProcedureDiagnosisCodeSID=assocDx.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=assocDx.sta3n
  left join CDWWork.dim.ICD10 as assocDxICD10
  on assocDx.[SurgeryPrincipalAssociatedDiagnosisICD10SID]=assocDxICD10.ICD10SID and assocDx.sta3n=assocDxICD10.sta3n 
   where  
  SurgPre.[SurgeryDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup and
  and  SurgPre.CohortName='Cohort20180712'
  and  surgDx.CohortName='Cohort20180712'
  and  otherPostDx.CohortName='Cohort20180712'
  and  assocDx.CohortName='Cohort20180712'
  and
(

    --PreICD10.ICD10Code in (select ICD10Code from [ORD_Singh_201210017D].[Dflt].[Lung_0_2_DxICD10CodeExc])
	  PrincipalPostOpICD10.ICD10Code in (select ICD10Code from [ORD_Singh_201210017D].[Dflt].[Lung_0_2_DxICD10CodeExc])
	or OtherPostICD10.ICD10Code in (select ICD10Code from [ORD_Singh_201210017D].[Dflt].[Lung_0_2_DxICD10CodeExc])
	or assocDxICD10.ICD10Code in (select ICD10Code from [ORD_Singh_201210017D].[Dflt].[Lung_0_2_DxICD10CodeExc])
	) --end of surgial dx
	go






--  Extract of all DX codes from outpatient 
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_2_OutPatDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_2_OutPatDx_ICD9]


SELECT 
	 [VDiagnosisSID]
	,p.PatientSSN
      ,Diag.[Sta3n]
      ,Diag.[ICD9SID]
	  ,Diag.[ICD10SID]
      ,Diag.[PatientSID]
	  ,dx_code_type
	  ,ICD9.ICD9Code as ICDCode
	  ,ICD9Diag.ICD9Diagnosis as ICDDiagnosis
      ,[VisitSID]
      ,[VisitDateTime]
      ,[VDiagnosisDateTime] as dx_dt
      ,[ProblemListSID] 
into [ORD_Singh_201210017D].[dflt].Lung_2_Ex_2_OutPatDx_ICD9
  FROM [ORD_Singh_201210017D].[src].[Outpat_VDiagnosis] as Diag
  inner join CDWWork.Dim.ICD9 as ICD9
  on Diag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DiagnosisVersion as ICD9Diag
  on Diag.ICD9SID=ICD9Diag.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].Lung_0_4_DxICD9CodeExc as TargetCode
on ICD9.ICD9Code=TargetCode.ICD9Code
inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
 
[VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup and
and Diag.CohortName='Cohort20180712'
go


--  Extract of all DX codes from outpatient
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_2_OutPatDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].Lung_2_Ex_2_OutPatDx_ICD10


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
into [ORD_Singh_201210017D].[dflt].Lung_2_Ex_2_OutPatDx_ICD10
FROM [ORD_Singh_201210017D].[src].[Outpat_VDiagnosis] as Diag
  inner join CDWWork.Dim.ICD10 as ICD10
  on Diag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Diag.ICD10SID=ICD10Diag.ICD10SID
inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
inner join ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code
where 
 
[VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup and
and Diag.CohortName='Cohort20180712'
go


--  Extract of all DX codes from inpatient
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_3_A_InPatDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_3_A_InPatDx_ICD9]	

SELECT 
	  [InpatientDiagnosisSID] --Primary Key
      ,InPatDiag.[Sta3n]
      --,[OrdinalNumber]
      ,[InpatientSID]  --foreign key to Inpatient table
      ,InPatDiag.[PatientSID]
      --,[AdmitDateTime]
      ,[DischargeDateTime] as dx_dt
	  ,dx_code_type
      ,InPatDiag.[ICD9SID]
	  ,ICD9.ICD9Code as ICDCode
	  ,ICD9Diag.ICD9Diagnosis as ICDDiagnosis	    
	  ,InPatDiag.[ICD10SID]
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	into  [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_3_A_InPatDx_ICD9]
  FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientDiagnosis] as InPatDiag
  inner join CDWWork.Dim.ICD9 as ICD9
  on InPatDiag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DiagnosisVersion as ICD9Diag
  on InPatDiag.ICD9SID=ICD9Diag.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].Lung_0_4_DxICD9CodeExc as TargetCode
on ICD9.ICD9Code=TargetCode.ICD9Code
inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
  where 
  
[DischargeDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup
and InPatDiag.CohortName='Cohort20180712'
	go


	--  Extract of all DX codes from inpatient
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_3_A_InPatDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_3_A_InPatDx_ICD10]

SELECT 
	  [InpatientDiagnosisSID] --Primary Key
      ,InPatDiag.[Sta3n]
      --,[OrdinalNumber]
      ,InPatDiag.[InpatientSID]  --foreign key to Inpatient table
      ,InPatDiag.[PatientSID]
      --,[AdmitDateTime]
      ,[DischargeDateTime] as dx_dt
      ,InPatDiag.[ICD9SID]
	  ,InPatDiag.[ICD10SID]
	  ,ICD10.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type
	  ,ICD10Diag.ICD10Diagnosis as ICDDiagnosis
	  ,p.patientSSN
	  ,p.ScrSSN 
	  ,p.patientICN
	into  [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_3_A_InPatDx_ICD10]
  FROM [ORD_Singh_201210017D].[src].[inpat_InpatientDiagnosis] as InPatDiag
  inner join CDWWork.Dim.ICD10 as ICD10
  on InPatDiag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on InPatDiag.ICD10SID=ICD10Diag.ICD10SID
inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
inner join ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code  
  where 
  
[DischargeDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup
and InPatDiag.CohortName='Cohort20180712'
	go


if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].Lung_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9

SELECT 
       Diag.[Sta3n]
      ,Diag.[PatientSID]
	  ,dx_code_type
	  ,ICD9.ICD9Code as ICD9
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
into [ORD_Singh_201210017D].[dflt].Lung_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9
FROM [ORD_Singh_201210017D].[src].Inpat_InpatientFeeDiagnosis as Diag
  inner join CDWWork.Dim.ICD9 as ICD9
  on Diag.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DescriptionVersion AS V
  on icd9.ICD9SID=v.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].Lung_0_4_DxICD9CodeExc as TargetCode
on ICD9.ICD9Code=TargetCode.ICD9Code
inner join [ORD_Singh_201210017D].[Dflt].Lung_1_In_8_IncPat as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
 
[AdmitDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup and
and Diag.CohortName='Cohort20180712'

go


if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].Lung_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD10

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
into [ORD_Singh_201210017D].[dflt].Lung_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD10
FROM [ORD_Singh_201210017D].[src].Inpat_InpatientFeeDiagnosis as Diag
  inner join CDWWork.Dim.ICD10 as ICD10
  on Diag.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Diag.ICD10SID=ICD10Diag.ICD10SID
  inner join ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
inner join [ORD_Singh_201210017D].[Dflt].Lung_1_In_8_IncPat as p
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
 
[AdmitDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup and
and Diag.CohortName='Cohort20180712'

go






--Fee ICD Dx 
  		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9]') is not null)
		drop table ORD_Singh_201210017D.[Dflt].Lung_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9


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
	  ,dx_code_type
      ,[AmountClaimed]
      ,[AmountPaid]
	  ,patientICN
	  ,ScrSSN
into ORD_Singh_201210017D.[Dflt].Lung_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9
  FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as d
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join CDWWork.Dim.ICD9 as ICD9
  on a.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DescriptionVersion AS V
  on icd9.ICD9SID=v.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].Lung_0_4_DxICD9CodeExc as TargetCode
on ICD9.ICD9Code=TargetCode.ICD9Code
  inner join ORD_Singh_201210017D.[Dflt].Lung_1_In_8_IncPat as c
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from ORD_Singh_201210017D.[Dflt].Lung_0_1_inputP))
  and a.CohortName='Cohort20180712'
  and d.CohortName='Cohort20180712'
go


		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD10]') is not null)
		drop table ORD_Singh_201210017D.[Dflt].Lung_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD10


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
into ORD_Singh_201210017D.[Dflt].Lung_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD10
  FROM [ORD_Singh_201210017D].src.[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as d
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join CDWWork.Dim.ICD10 as ICD10
  on a.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on a.ICD10SID=ICD10Diag.ICD10SID
  inner join ORD_Singh_201210017D.[Dflt].Lung_1_In_8_IncPat as c
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  inner join ORD_Singh_201210017D.[Dflt].[Lung_0_2_DxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
  where d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from ORD_Singh_201210017D.[Dflt].Lung_0_1_inputP))
  and a.CohortName='Cohort20180712'
  and d.CohortName='Cohort20180712'

go


	--  Extract of all exclusion diagnoses from surgical, inpatient, and outpatient tables
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_4_AllDx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_4_AllDx_ICD9]
go

select patientSSN,Sta3n,PatientSID,dx_dt,ICD9Code as ICD9,'Surg' as dataSource,dx_code_type
into [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_4_AllDx_ICD9]
from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_1_SurgDx_ICD9]
	UNION ALL
select patientSSN,Sta3n,PatientSID,dx_dt,ICDCode as ICD9,'OutPat' as dataSource,dx_code_type
from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_2_OutPatDx_ICD9]
	UNION ALL
select patientSSN,Sta3n,PatientSID,dx_dt,ICDCode as ICD9,'InPat' as dataSource,dx_code_type
from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_3_A_InPatDx_ICD9]
	UNION ALL
select patientSSN,Sta3n,PatientSID,dx_dt,ICD9,'Dx-InPatFee' as dataSource,dx_code_type
from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9]
	UNION ALL
select patientSSN,Sta3n,PatientSID,dx_dt,ICD9,'Dx-InPatFeeService' as dataSource,dx_code_type
from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9]

go



alter table [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_4_AllDx_ICD9]
add lung_cancer_dx_dt datetime,
	term_dx_dt datetime,
	hospice_dt datetime,
	tuberc_dx_dt datetime,
	chf_dx_dt datetime,
	cld_dx_dt datetime
go

update [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_4_AllDx_ICD9]
set lung_cancer_dx_dt = case
		when  	-- Recent active Lung Cancer
		    dx_code_type='RecentActiveLungC'
	   then dx_dt
		else NULL
	end,
	term_dx_dt = case
		when 
			dx_code_type='Terminal'
	   then dx_dt
		else NULL
	end,
	hospice_dt = case
		when -- Hospice / Palliative Care
			 dx_code_type='Hospice'
	   then dx_dt
		else NULL
	end,
	tuberc_dx_dt = case
		when 
			dx_code_type='Tuberculosis'
		 then dx_dt
		else NULL
	end

go



if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_4_AllDx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_4_AllDx_ICD10]
go

select patientSSN,sta3n, PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'Dx-Surg' as dataSource
into [ORD_Singh_201210017D].[dflt].[Lung_2_Ex_4_AllDx_ICD10]
from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_1_SurgDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'DX-OutPat' as dataSource from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_2_OutPatDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10Code,dx_code_type,'Dx-InPat' as dataSource from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_3_A_InPatDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'Dx-InPatFee' as dataSource from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD10]
	UNION ALL
select patientSSN,sta3n,PatientSID,[InitialTreatmentDateTime] as [dx_dt],[ICD10code],dx_code_type,'Dx-FeeServiceProvided' as dataSource from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD10]

go

Alter table [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_4_AllDx_ICD10]
add --Lung_Cancer_dx_dt datetime,
	term_dx_dt datetime,
	hospice_dt datetime,
	tuberc_dx_dt datetime
	--chf_dx_dt datetime,
	--cld_dx_dt datetime
	go

update [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_4_AllDx_ICD10]
set term_dx_dt= case when dx_code_type='Terminal' then dx_dt else null end,
	hospice_dt= case when dx_code_type='hospice' then dx_dt else null end,
--	lung_cancer_dx_dt= case when dx_code_type='Active_Lung_Cancer' then dx_dt else null end,
	tuberc_dx_dt=case when dx_code_type='Tuberculosis' then dx_dt else null end
go


if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_4_UnionAllDx_ICD9ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].Lung_2_Ex_4_UnionAllDx_ICD9ICD10
go


select
	  [patientSSN]
      ,[sta3n]
      ,[PatientSID]
      ,[ICD9] as ICD9ICD10Code
	  ,dx_code_type
	  --,lung_cancer_dx_dt
      ,[term_dx_dt]
      ,[hospice_dt]
	  ,[tuberc_dx_dt]
into [ORD_Singh_201210017D].[dflt].Lung_2_Ex_4_UnionAllDx_ICD9ICD10
from [ORD_Singh_201210017D].[dflt].Lung_2_Ex_4_AllDx_ICD9
union
select 
	  [patientSSN]
      ,[sta3n]
      ,[PatientSID]
      ,[ICDCode] as ICD9ICD10Code
	  ,dx_code_type
	  --,[Lung_Cancer_dx_dt]
      ,[term_dx_dt]
      ,[hospice_dt]
	  ,[tuberc_dx_dt]
from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_4_AllDx_ICD10]
go


--  Extract of all DX codes from outpatient table for all potential patients
if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_7_ProblemListLC_Dx_ICD9]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].Lung_2_Ex_7_ProblemListLC_Dx_ICD9


SELECT distinct 
	   [ProblemListSID]
      ,ProblemList.[Sta3n]
      ,ProblemList.[ICD9SID]
      ,[ICD10SID]
	  ,ICD9CodeList.[dx_code_type]
	  ,ICD9.ICD9Code as ICD9
	  ,v.[ICD9Description]
      ,ProblemList.[PatientSID]
      ,[LastModifiedDateTime] as [LastModifiedDate]
      ,[EnteredDateTime] as EnteredDate
      ,[RecordedDateTime] as [RecordedDate]
      ,[ResolvedDateTime] as [ResolvedDate]
      ,[ActiveFlag]
      ,[OnsetDateTime] as [OnsetDate]
      ,[ProblemListClass]
      ,[InstitutionSID]
      ,[ProblemUniqueNumber]
      ,[ClinicalTermSID]
      ,[ProblemListCondition]
      ,[LocationSID]
      ,[ServiceConnectedFlag]  
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
into [ORD_Singh_201210017D].[dflt].Lung_2_Ex_7_ProblemListLC_Dx_ICD9
  FROM [ORD_Singh_201210017D].[src].[Outpat_ProblemList] as ProblemList
  inner join CDWWork.Dim.ICD9 as ICD9
  on ProblemList.ICD9SID=ICD9.ICD9SID
  inner join cdwwork.dim.ICD9DescriptionVersion AS V
  on icd9.ICD9SID=v.ICD9SID
inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  on ProblemList.sta3n=p.sta3n and ProblemList.patientsid=p.patientsid
inner join [ORD_Singh_201210017D].[Dflt].[Lung_0_7_LungCancerDxICD9CodeExc] as ICD9CodeList
on ICD9.ICD9Code=ICD9CodeList.ICD9Code
where 
 
[EnteredDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup and
and ProblemList.CohortName='Cohort20180712'
and ICD9CodeList.dx_code_type='RecentActiveLungC'



if (OBJECT_ID('[ORD_Singh_201210017D].[dflt].[Lung_2_Ex_7_ProblemListLC_Dx_ICD10]') is not null)
	drop table [ORD_Singh_201210017D].[dflt].Lung_2_Ex_7_ProblemListLC_Dx_ICD10


SELECT distinct [ProblemListSID]
      ,ProblemList.[Sta3n]
      ,ProblemList.[ICD9SID]
      ,ProblemList.[ICD10SID]
	  ,ICD10.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type
	  ,ICD10Diag.ICD10Diagnosis as ICDDiagnosis
      ,ProblemList.[PatientSID]
      ,[LastModifiedDateTime] as [LastModifiedDate]
      ,[EnteredDateTime] as EnteredDate
      ,[RecordedDateTime] as [RecordedDate]
      ,[ResolvedDateTime] as [ResolvedDate]
      ,[ActiveFlag]
      ,[OnsetDateTime] as [OnsetDate]
      ,[ProblemListClass]
      ,[InstitutionSID]
      ,[ProblemUniqueNumber]
      ,[ClinicalTermSID]
      ,[ProblemListCondition]
      ,[LocationSID]
      ,[ServiceConnectedFlag]  
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
into [ORD_Singh_201210017D].[dflt].Lung_2_Ex_7_ProblemListLC_Dx_ICD10
  FROM [ORD_Singh_201210017D].[src].[outpat_ProblemList] as ProblemList
  inner join CDWWork.Dim.ICD10 as ICD10
  on ProblemList.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on ProblemList.ICD10SID=ICD10Diag.ICD10SID
  inner join ORD_Singh_201210017D.[Dflt].[Lung_0_6_LungCancerDxICD10CodeExc] as ICD10CodeList
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  on ProblemList.sta3n=p.sta3n and ProblemList.patientsid=p.patientsid
where 
 
[EnteredDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup and
and ICD10CodeList.dx_code_type='RecentActiveLungC'
and ProblemList.CohortName='Cohort20180712'
go

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_7_ProblemListLC_Dx_ICD9ICD10]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_2_Ex_7_ProblemListLC_Dx_ICD9ICD10

select 	 patientSSN
      ,[PatientSID]
      ,[Sta3n]
	  ,'ICD9' as ICDVersion
      ,[ICD9SID] 
      ,[ICD10SID]
	  ,ICD9 as ICDCode
	  ,dx_code_type
	  ,[ICD9Description] as ICDDescription
      ,[EnteredDate]
      ,[RecordedDate]
      ,[ResolvedDate]
      ,[ActiveFlag]
      ,[OnsetDate]
		,[LastModifiedDate]
      ,[ProblemListClass]
      ,[InstitutionSID]
      ,[LocationSID]
		,[ProblemListSID]
into [ORD_Singh_201210017D].[Dflt].Lung_2_Ex_7_ProblemListLC_Dx_ICD9ICD10
from [ORD_Singh_201210017D].[dflt].Lung_2_Ex_7_ProblemListLC_Dx_ICD9
union
select   patientSSN
		,patientsid
      ,[Sta3n]
	  ,'ICD10' as ICDVersion
      ,[ICD9SID]
      ,[ICD10SID]
	  ,ICD10Code as ICDCode
	  ,dx_code_type
	  ,ICDDiagnosis as ICDDescription
      ,[EnteredDate]
      ,[RecordedDate]
      ,[ResolvedDate]
      ,[ActiveFlag]
      ,[OnsetDate]
      ,[LastModifiedDate]
      ,[ProblemListClass]
      ,[InstitutionSID]
      ,[LocationSID]
	,[ProblemListSID]
from [ORD_Singh_201210017D].[Dflt].Lung_2_Ex_7_ProblemListLC_Dx_ICD10
go

------------------------------------- NonDx Previous Proc------------------------------

  				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc

						  select pat.patientssn,pat.scrssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime]
	      ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,ICD9Proc_code_type, pat.patientICN
			into [ORD_Singh_201210017D].[dflt].Lung_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc
			  FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientICDProcedure] as ICDProc
			  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on ICDProc.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
			  inner join  [ORD_Singh_201210017D].[Dflt].Lung_0_5_PreProcICD9ProcExc as TargetCode
			  on DimICD9Proc.ICD9ProcedureCode=TargetCode.ICD9ProcCode
			  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[Dflt].[Lung_1_In_8_IncPat]) as pat
			  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
			 where ICDProc.CohortName='Cohort20180712'

go

				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc

						  select pat.patientssn,pat.scrssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
			into [ORD_Singh_201210017D].[dflt].Lung_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc
			  FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientICDProcedure] as ICDProc
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on ICDProc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
			  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[Dflt].[Lung_1_In_8_IncPat]) as pat
			  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
			  where ICDProc.CohortName='Cohort20180712'
		go


			if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc

			select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[ICDProcedureDateTime]
	      ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,ICD9Proc_code_type,pat.patientICN
			into [ORD_Singh_201210017D].[dflt].Lung_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc
			FROM [ORD_Singh_201210017D].[src].[Inpat_CensusICDProcedure] as a
			  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
			  inner join  [ORD_Singh_201210017D].[Dflt].Lung_0_5_PreProcICD9ProcExc as TargetCode
			  on DimICD9Proc.ICD9ProcedureCode=TargetCode.ICD9ProcCode
				   inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[Lung_1_In_8_IncPat]) as pat
				  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
				 where a.CohortName='Cohort20180712'															
		
		go


		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc

			select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[ICDProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
			into [ORD_Singh_201210017D].[dflt].Lung_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc
			FROM [ORD_Singh_201210017D].[src].[Inpat_CensusICDProcedure] as a
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on DimICD10Proc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
				   inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[Lung_1_In_8_IncPat]) as pat
				  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
				 where 
				 a.CohortName='Cohort20180712'
		
				
		go



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc

			select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
	      ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,ICD9Proc_code_type,pat.patientICN
			into [ORD_Singh_201210017D].[dflt].Lung_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc
			FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientSurgicalProcedure] as a
			  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
			  inner join  [ORD_Singh_201210017D].[Dflt].Lung_0_5_PreProcICD9ProcExc as TargetCode
			  on DimICD9Proc.ICD9ProcedureCode=TargetCode.ICD9ProcCode
			  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[Lung_1_In_8_IncPat]) as pat
			  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
		 where  a.CohortName='Cohort20180712'

go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc

			select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
			into [ORD_Singh_201210017D].[dflt].Lung_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc
			FROM [ORD_Singh_201210017D].[src].[Inpat_InpatientSurgicalProcedure] as a
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on DimICD10Proc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
			  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[Lung_1_In_8_IncPat]) as pat
			  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
			  where a.CohortName='Cohort20180712'
go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc

      
		 select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
				  ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,ICD9Proc_code_type,pat.patientICN
		 into [ORD_Singh_201210017D].[dflt].Lung_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc		  
		  FROM [ORD_Singh_201210017D].[src].[Inpat_CensusSurgicalProcedure] as a
			  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
			  inner join  [ORD_Singh_201210017D].[Dflt].Lung_0_5_PreProcICD9ProcExc as TargetCode
			  on DimICD9Proc.ICD9ProcedureCode=TargetCode.ICD9ProcCode
		  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[Lung_1_In_8_IncPat]) as pat
		  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
		 where a.CohortName='Cohort20180712'

go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc]') is not null)
			drop table  [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc

      
		 select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
		 into [ORD_Singh_201210017D].[dflt].Lung_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc
		  FROM [ORD_Singh_201210017D].[src].[Inpat_CensusSurgicalProcedure] as a
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on DimICD10Proc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
		  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[Lung_1_In_8_IncPat]) as pat
		  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
		  where a.CohortName='Cohort20180712'
		  go



	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc]') is not null)
	drop table  [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc	

	select pat.patientssn,pat.scrssn,a.sta3n,b.patientsid,b.[TreatmentFromDateTime]
	      ,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,ICD9Proc_code_type,pat.patientICN
	into [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc
	from [ORD_Singh_201210017D].[src].[Fee_FeeInpatInvoiceICDProcedure] as a
	inner join [ORD_Singh_201210017D].[src].[Fee_FeeInpatInvoice] as b
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
			  inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
			  on a.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
			  inner join  [ORD_Singh_201210017D].[Dflt].Lung_0_5_PreProcICD9ProcExc as TargetCode
			  on DimICD9Proc.ICD9ProcedureCode=TargetCode.ICD9ProcCode
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat) as pat
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where  a.CohortName='Cohort20180712'
		and b.CohortName='Cohort20180712'
go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc]') is not null)
	drop table  [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc

	select pat.patientssn,pat.scrssn,a.sta3n,b.patientsid,b.[TreatmentFromDateTime],ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
	into [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc
	--[ICD10ProcedureSID] is not available in VINCI1
	--from vinci1.[Fee].[FeeInpatInvoiceICDProcedure] as a  
	from [ORD_Singh_201210017D].src.[Fee_FeeInpatInvoiceICDProcedure] as a
	inner join [ORD_Singh_201210017D].[src].[Fee_FeeInpatInvoice] as b
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
			  inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			  inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
			  on a.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
			    inner join ORD_Singh_201210017D.[Dflt].[Lung_0_3_PreProcICD10ProcExc] as ICD10CodeList
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat) as pat
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  and a.CohortName='Cohort20180712'
	  and b.CohortName='Cohort20180712'
go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc
	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9ProcedureDescription
	  ,'Inp-InpICD'	  as datasource
	  ,ICD9Proc_code_type
    into  [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc
	from ORD_Singh_201210017D.[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc]
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9ProcedureDescription
	  ,'Inp-CensusICD'	  as datasource
	  ,ICD9Proc_code_type
	from ORD_Singh_201210017D.[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9ProcedureDescription      
	 ,'Inp-InpSurg'	  as datasource
	  ,ICD9Proc_code_type
	from ORD_Singh_201210017D.[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9ProcedureDescription
	 ,'Inp-CensusSurg'	  as datasource
	  ,ICD9Proc_code_type
	from ORD_Singh_201210017D.[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9ProcedureDescription      
	 ,'Inp-FeeICDProc'	  as datasource
	  ,ICD9Proc_code_type
	from ORD_Singh_201210017D.[Dflt].Lung_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc
	go
	


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc
	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10ProcedureDescription
	  ,ICD10Proc_Code_Type
	  ,'Inp-InpICD'	  as datasource
    into  [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc
	from ORD_Singh_201210017D.[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc]
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10ProcedureDescription
	  ,ICD10Proc_Code_Type
	  ,'Inp-CensusICD'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10ProcedureDescription      
	  ,ICD10Proc_Code_Type
	 ,'Inp-InpSurg'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10ProcedureDescription
	  ,ICD10Proc_Code_Type
	 ,'Inp-CensusSurg'	  as datasource
	from ORD_Singh_201210017D.[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc]
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10ProcedureDescription  
	  ,ICD10Proc_Code_Type    
	 ,'Inp-FeeICDProc'	  as datasource
	from ORD_Singh_201210017D.[Dflt].Lung_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc
	go


  -- Previous CPT from inpatient

	if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT

select pat.patientssn,pat.scrssn,CPTProc.sta3n,CPTProc.patientsid,CPTProc.[CPTProcedureDateTime]
	      ,DimCPT.[CPTCode],DimCPT.CPTName,DimCPT.CPTDescription ,CPT_code_type, patientICN
into  [ORD_Singh_201210017D].[dflt].Lung_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT
  FROM [ORD_Singh_201210017D].[Src].[Inpat_InpatientCPTProcedure] as CPTProc
  inner join cdwwork.dim.CPT as DimCPT
  on CPTProc.[CPTSID]=DimCPT.CPTSID  
  inner join  [ORD_Singh_201210017D].[Dflt].Lung_0_8_PrevProcCPTCodeExc as TargetCode
  on DimCPT.CPTCode=TargetCode.CPTCode
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].[Lung_1_In_8_IncPat]) as pat
  on CPTProc.patientsid=pat.patientsid and CPTProc.sta3n=pat.sta3n
 where  CPTProc.CohortName='Cohort20180712'
and CPTProc.[CPTProcedureDateTime] <= DateAdd(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP))




	-- Lung procedures from outpatient tables

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_5_PrevProc_Outpat') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_5_PrevProc_Outpat
		
		SELECT 
		--[VINCI1].[Outpat].[VProcedure].[VProcedureSID]
		p.patientSSN,
      VProc.[Sta3n]
      ,VProc.[CPTSID]
	  ,dimCPT.[CPTCode]
	  ,CPT_code_type
	  ,DimCPT.[CPTName]
      ,VProc.[PatientSID]
      ,VProc.[VisitSID]
      --,VProc.[EventDateTime]
      ,VProc.[VisitDateTime]
      ,VProc.[VProcedureDateTime] --ProcDate
      ,VProc.[CPRSOrderSID]
		,p.ScrSSN,p.patientICN
into [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_5_PrevProc_Outpat
  FROM [ORD_Singh_201210017D].[src].[Outpat_VProcedure] as VProc
  inner join CDWWork.[Dim].[CPT] as DimCPT 
  on  VProc.[CPTSID]=DimCPT.CPTSID
  inner join  [ORD_Singh_201210017D].[Dflt].Lung_0_8_PrevProcCPTCodeExc as TargetCode
  on DimCPT.CPTCode=TargetCode.CPTCode
inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  on VProc.sta3n=p.sta3n and VProc.patientsid=p.patientsid
  where 
  [VProcedureDateTime] is not null
  and VProc.CohortName='Cohort20180712'

go

	-- Lung procedures from surgical tables

			if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_6_PrevProc_surg]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_6_PrevProc_surg
	

SELECT 
		surgPre.[SurgerySID] as SurgPre_SurgerySID
	  , surgDx.[SurgerySID]  as SurgDx_SurgerySID
      ,surgPre.[Sta3n]
      ,[VisitSID]
      ,SurgPre.[PatientSID]
      ,[CancelDateTime]

      ,surgPre.[SurgeryDateTime]  as [DateOfOperation]

	  ,PrincipalCPT.CPTCode as PrincipalProcedureCode
	  ,PrincipalCPT.CPTDescription as PrincipalProcedureDescription
	  ,assocCPT.CPTCode as assocProcedureCode
	  ,assocCPT.CPTDescription as assocProcedureDescription
	  ,OtherCPT.CPTCode as OtherProcedureCode
	  ,OtherCPT.CPTDescription as OtherProcedureDescription

	  ,(case when PrincipalCPT.CPTCode in (select CPTCode from ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc)
			then PrincipalCPT.CPTCode
            when assocCPT.CPTCode in (select CPTCode from ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc)
	        then assocCPT.CPTCode
            when OtherCPT.CPTCode in (select CPTCode from ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc)
	   	    then OtherCPT.CPTCode
	        else null
	   end ) as CPTCode    
	  ,(case when PrincipalCPT.CPTCode in (select CPTCode from ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc)
			then 
			(select CPT_code_type from ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc where CPTCode=PrincipalCPT.CPTCode)
            when assocCPT.CPTCode in (select CPTCode from ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc)
	        then 
			(select CPT_code_type from ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc where CPTCode=assocCPT.CPTCode)
            when OtherCPT.CPTCode in (select CPTCode from ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc)
	   	    then 
			(select CPT_code_type from ORD_Singh_201210017D.[Dflt].Lung_0_8_PrevProcCPTCodeExc where CPTCode=OtherCPT.CPTCode)
	        else null
	   end ) as CPT_code_type   

	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN	 
  into [ORD_Singh_201210017D].[dflt].[Lung_3_Exc_NonDx_6_PrevProc_surg]
  --FROM [ORD_Singh_201210017D].[Src].[Surgery_Surgery_130] as surg
  --  inner join [ORD_Singh_201210017D].[Src].[Surgery_surgeryprcdrdgnsscodes_136] as SurgDx
  --  on surg.[SurgeryIEN]=SurgDx.[SurgeryPrcdrDgnssCodesIEN]
  --inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  --on Surg.sta3n=p.sta3n and Surg.patientsid=p.patientsid
  --select  *  
  FROM [ORD_Singh_201210017D].[Src].[Surg_SurgeryPre] as surgPre
  inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
  on SurgPre.sta3n=p.sta3n and SurgPre.patientsid=p.patientsid
  left join[ORD_Singh_201210017D].[Src].[Surg_SurgeryProcedureDiagnosisCode]as surgDx
  on surgPre.SurgerySID=SurgDx.SurgerySID and surgPre.sta3n=SurgDx.sta3n
  left join CDWWork.dim.CPT as PrincipalCPT
  on SurgDx.PrincipalCPTSID=PrincipalCPT.CPTSID and SurgDx.Sta3n=PrincipalCPT.Sta3n
  left join [ORD_Singh_201210017D].[Src].Surg_SurgeryPrincipalAssociatedProcedure as assocProc
  on  surgDx.SurgeryProcedureDiagnosisCodeSID=assocProc.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=assocProc.sta3n
  left join CDWWork.dim.CPT as assocCPT
  on assocProc.SurgeryPrincipalAssociatedProcedureSID=assocCPT.CPTSID and assocProc.sta3n=assocCPT.sta3n 
  left join CDWWork.dim.CPT as OtherCPT
  on assocProc.OtherProcedureCPTSID=OtherCPT.CPTSID and assocProc.sta3n=OtherCPT.sta3n 
   where  
  
  SurgPre.[SurgeryDateTime]<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)) --Clue Date Range+followup and
  and  SurgPre.CohortName='Cohort20180712'
  and  surgDx.CohortName='Cohort20180712'
  and  assocProc.CohortName='Cohort20180712'
  and (
		  PrincipalCPT.CPTCode in 
		  (select CPTCode from 	[ORD_Singh_201210017D].[Dflt].[Lung_0_8_PrevProcCPTCodeExc])
		  or assocCPT.CPTCode in
		  (select CPTCode from 	[ORD_Singh_201210017D].[Dflt].[Lung_0_8_PrevProcCPTCodeExc])					 
		  or OtherCPT.CPTCode in
		  (select CPTCode from 	[ORD_Singh_201210017D].[Dflt].[Lung_0_8_PrevProcCPTCodeExc])					 
		)



  
 
  		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]') is not null)
		drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT
										 


SELECT  
	  Pat.patientssn
	,d.InitialTreatmentDateTime
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,[ServiceProvidedCPTSID]
      ,[AmountClaimed]
      ,[AmountPaid]
,DimCPT.CPTCode,DimCPT.CPTName,
CPT_code_type,pat.patientICN
into [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT
FROM [ORD_Singh_201210017D].[src].[Fee_FeeServiceProvided] as a
  inner join [ORD_Singh_201210017D].src.Fee_FeeInitialTreatment as d
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
			  inner join cdwwork.dim.CPT as DimCPT
			  on a.[ServiceProvidedCPTSID]=DimCPT.[CPTSID]  
  inner join  [ORD_Singh_201210017D].[Dflt].Lung_0_8_PrevProcCPTCodeExc as TargetCode
  on DimCPT.CPTCode=TargetCode.CPTCode
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat) as pat
  on a.sta3n=pat.sta3n and a.patientsid=pat.patientsid
  where a.CohortName='Cohort20180712' 
	and DimCPT.CPTCode in 	(		
 select CPTCode from 	[ORD_Singh_201210017D].[Dflt].[Lung_0_8_PrevProcCPTCodeExc])
go	
											
											
		

			if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy


select patientSSN,sta3n,patientSID,[Proc_dt] as LungBiopsy_dt,'LungBiopsy-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD','LungBiopsy' as code_type
into  [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc]
		where [Proc_dt] is not null 
		and ICD9Proc_code_type='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[Proc_dt] as LungBiopsy_dt,'LungBiopsy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc]
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as LungBiopsy_dt,'LungBiopsy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]
		where [CPTProcedureDateTime] is not null 
		and CPT_code_type='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as LungBiopsy_dt ,'LungBiopsy-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_5_PrevProc_Outpat]
		where [VProcedureDateTime] is not null
		and CPT_code_type='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[DateOfOperation] as LungBiopsy_dt,'LungBiopsy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_6_PrevProc_surg]
		where [DateOfOperation] is not null
		and CPT_code_type='LungBiopsy'
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as LungBiopsy_dt,'LungBiopsy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]
		where InitialTreatmentDateTime is not null
		and CPT_code_type='LungBiopsy'
		go



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy


select patientSSN,sta3n,patientSID,[Proc_dt] as Bronchoscopy_dt,'Bronchoscopy-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD','Bronchoscopy' as code_type
into  [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc]
		where [Proc_dt] is not null
		and ICD9Proc_code_type='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[Proc_dt] as Bronchoscopy_dt,'Bronchoscopy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc]
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as Bronchoscopy_dt,'Bronchoscopy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]
		where [CPTProcedureDateTime] is not null
		and CPT_code_type='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as Bronchoscopy_dt ,'Bronchoscopy-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_5_PrevProc_Outpat]
		where [VProcedureDateTime] is not null
		and CPT_code_type='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[DateOfOperation] as Bronchoscopy_dt,'Bronchoscopy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_6_PrevProc_surg]
		where [DateOfOperation] is not null
		and CPT_code_type='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as Bronchoscopy_dt,'Bronchoscopy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]
		where InitialTreatmentDateTime is not null
		and CPT_code_type='Bronchoscopy'
		go



if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery


select patientSSN,sta3n,patientSID,[Proc_dt] as LungSurgery_dt,'LungSurgery-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD','LungSurgery' as code_type
into  [ORD_Singh_201210017D].[Dflt].Lung_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc]
		where [Proc_dt] is not null
		and ICD9Proc_code_type='LungSurgery'   
union
select patientSSN,sta3n,patientSID,[Proc_dt] as LungSurgery_dt,'LungSurgery-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc]
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='LungSurgery'
union
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as LungSurgery_dt,'LungSurgery-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]
		where [CPTProcedureDateTime] is not null
		and CPT_code_type='LungSurgery'   								 			
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as LungSurgery_dt ,'LungSurgery-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_5_PrevProc_Outpat]
		where [VProcedureDateTime] is not null
		and CPT_code_type='LungSurgery'
union
select patientSSN,sta3n,patientSID,[DateOfOperation] as LungSurgery_dt,'LungSurgery-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_6_PrevProc_surg]
		where [DateOfOperation] is not null
		and CPT_code_type='LungSurgery'
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as LungSurgery_dt,'LungSurgery-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD'
from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]
		where InitialTreatmentDateTime is not null
		and CPT_code_type='LungSurgery'
		go



---------------------------All Referral------------------------------------------------------
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_1_AllVisits]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_1_AllVisits]
					
					select p.patientSSN,p.patientICN,p.ScrSSN
					,V.Sta3n,V.PatientSID,V.Visitsid,V.VisitDatetime,V.primaryStopcodeSID,V.SecondaryStopcodeSID					
					into [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_1_AllVisits]					
					from [ORD_Singh_201210017D].[src].[Outpat_Visit] as V
					inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
                    on v.sta3n=p.sta3n and v.patientsid=p.patientsid
				where 	CohortName='Cohort20180712'	and	
				V.VisitDateTime between dateAdd(yy,-1,(select sp_start from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP))
										and DateAdd(dd,30,(select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP))
										  
		go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_1_AllVisits_StopCode]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_9_Ex_1_AllVisits_StopCode
					
					select v.*,code1.stopcode as PrimaryStopCode,code1.stopcodename as PrimaryStopCodeName,code2.stopcode as SecondaryStopCode,code2.stopcodename as SecondaryStopCodeName
					into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_9_Ex_1_AllVisits_StopCode
					from [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_1_AllVisits] as V
					left join [CDWWork].[Dim].[StopCode] as code1
					on V.PrimaryStopCodeSID=code1.StopCodeSID	and V.Sta3n=code1.Sta3n		
					left join [CDWWork].[Dim].[StopCode] as code2
					on V.SecondaryStopCodeSID=code2.StopCodeSID	and v.sta3n=code2.sta3n

go

if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_2_VisitTIU]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_2_VisitTIU]


					select v.*
					--,c.consultsid,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
					--c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName
					,T.[TIUDocumentSID],T.[EntryDateTime],T.[ReferenceDateTime]--,ReportText
					,e.tiustandardtitle,T.ConsultSID
					into [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_2_VisitTIU]					
					from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_9_Ex_1_AllVisits_StopCode as V
					left join ORD_Singh_201210017D.[src].[TIU_TIUDocument_8925] as T --[TIUDocument_8925_IEN]
				   --left join ORD_Singh_201210017D.[src].[TIU_TIUDocument_8925] as T
					on T.VisitSID=V.Visitsid and T.CohortName='Cohort20180712'
					--left join [CDW_TIU].[TIU].[TIUDocument_8925_02] as RptText
					--on T.TIUDocumentsid=RptText.TIUDocumentsid
					left join cdwwork.dim.[TIUDocumentDefinition] as d                                         
					on t.[TIUDocumentDefinitionSID]=d.[TIUDocumentDefinitionSID]
					left join cdwwork.dim.TIUStandardTitle as e
					on d.TIUStandardTitleSID=e.TIUStandardTitleSID
					--left join vinci1.con.Consult as C										                    
					--on C.[TIUDocumentSID]=T.[TIUDocumentSID]
				--where isnull(T.OpCode,'')<>'D'
				
		go


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID]') is not null)
					drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID

						select v.*
					--,c.consultsid
					,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
					c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName,
					c.placeofconsultation,	  
					c.requestType, --  the request is a consult or procedure
					c.[InpatOutpat], -- the ordering person to indicate if the service is to be rendered on an outpatient or Inpatients basis.
					c.[RemoteService]
					--,T.[TIUDocumentSID],ReportText,e.tiustandardtitle
					into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID					
                    from [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_2_VisitTIU] as V
					--left join [TIU_2013].[TIU].[TIUDocument_v030] as T
					--on T.VisitSID=V.Visitsid
					--left join [TIU_2013].[TIU].[TIUDocument_8925_02] as RptText
					--on T.TIUDocumentsid=RptText.TIUDocumentsid
					left join [ORD_Singh_201210017D].[src].Con_Consult as C										                    
					on C.ConsultSID=V.ConsultSID and CohortName='Cohort20180712'
					--left join cdwwork.dim.[TIUDocumentDefinition] as d                                         
					--on t.[TIUDocumentDefinitionSID]=d.[TIUDocumentDefinitionSID]
					--left join cdwwork.dim.TIUStandardTitle as e
					--on d.TIUStandardTitleSID=e.TIUStandardTitleSID
				--where isnull(T.OpCode,'')<>'D'
				--where  c.CohortName='Cohort20180712' left join, transform to inner join
				
		go


drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_9_Ex_1_AllVisits
drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_9_Ex_1_AllVisits_StopCode
drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_9_Ex_2_VisitTIU
go


-------------------------------------------------------------------------------------------
---------------------------  1: Lung Cancer Exclusions  ---------------------------
-------------------------------------------------------------------------------------------


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_3_Ins_0_1_In_4_Age') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_0_1_In_4_Age
select 
		Rad.* 
into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_0_1_In_4_Age
from [ORD_Singh_201210017D].[Dflt].Lung_1_In_6_IncIns as Rad		
where (DATEDIFF(yy,DOB,Rad.[ExamDateTime]) >= (select age from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP)
		 or patientssn is null -- patient is missing
         )  

go

	
if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_3_Ins_0_2_In_5_Alive') is not null)
	drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_0_2_In_5_Alive

select age.* into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_0_2_In_5_Alive
 from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_0_1_In_4_Age as age  
 where 
        [DOD] is null 		--no DOD value , still alive 
		or (DOD is not null 
				and ( 
					DATEADD(dd,-(select fu_period from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP),dod)>age.ExamDateTime
					)
				)	   	     
go
	


		--  all instances with lung cancer exclusions removed
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_1_Ex_LungCancer]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_1_Ex_LungCancer
		go

		select a.*

		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_1_Ex_LungCancer
		from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_0_2_In_5_Alive as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].Lung_2_Ex_7_ProblemListLC_Dx_ICD9ICD10 as b
			 where a.[PatientSSN] = b.[PatientSSN]
			 and (b.[EnteredDate] between DATEADD(yy,-1,a.[ExamDateTime]) and a.[ExamDateTime]))			 
		go
			 
	
-------------------------------------------------------------------------------------------
----------------------------  2: Terminal/Major DX Exclusions  ----------------------------
-------------------------------------------------------------------------------------------




		--  all instances with terminal/major DX exclusions removed
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_2_Ex_Termi_Major]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_2_Ex_Termi_Major]
		go

		select *
		into [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_2_Ex_Termi_Major]
		from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_1_Ex_LungCancer as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_4_UnionAllDx_ICD9ICD10] as b
			 where a.[PatientSSN] = b.[PatientSSN]and
			 (b.term_dx_dt between DATEADD(yy,-1,a.[ExamDateTime]) and DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP]),a.[ExamDateTime])))
		go
		

-------------------------------------------------------------------------------------------
---------------------------  3: Hospice/Palliative Exclusions  ----------------------------
-------------------------------------------------------------------------------------------
		-- All instances with hospice/palliative care exclusions removed
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_3_Ex_Hospi_1_ByDx]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_3_Ex_Hospi_1_ByDx
		go

		select *
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_3_Ex_Hospi_1_ByDx
		from [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_2_Ex_Termi_Major] as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_4_UnionAllDx_ICD9ICD10] as b
			 where a.[PatientSSN] = b.[PatientSSN]and
			 (b.hospice_dt between DATEADD(yy,-1,a.[ExamDateTime]) and 
			  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP]),a.[ExamDateTime])))		
		go


		--Outside Hospice care ( VA Paid/Fee Based) see the coding policy
				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_3_Ex_Hospi_2_Fee]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_3_Ex_Hospi_2_Fee
		go


		select * 
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_3_Ex_Hospi_2_Fee
		from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_3_Ex_Hospi_1_ByDx as x
		where not exists(
		select  b.FeePurposeOfVisit,a.* 
		from [ORD_Singh_201210017D].[src].[Fee_FeeInpatInvoice] as a
		inner join cdwwork.dim.FeePurposeOfVisit as b
		on a.FeePurposeOfVisitSID=b.FeePurposeOfVisitSID
		inner join [ORD_Singh_201210017D].[dflt].Lung_1_In_8_IncPat as p
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where a.CohortName='Cohort20180712' and b.CohortName='Cohort20180712' and
		b.AustinCode in ('43','77','78')  
		and x.patientSSN=p.patientsSN and a.TreatmentFromDateTime 
		between DATEADD(yy,-1,x.[ExamDateTime]) and 
					  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP]),X.[ExamDateTime])
		)
		go

		--Hispice Referral----------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID
													 
				
		select *
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID
        from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_3_Ex_Hospi_2_Fee as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID] as b
			 where (
			 --With Stopcode
			 b.[primaryStopcode] in (351,353) or b.[secondaryStopcode] in (351,353)   --Hospice
			 -- There is a visit, but the StopCode is missing
					or 	(
						b.[ConsultToRequestserviceName] like '%Hospice%' or b.[ConsultToRequestserviceName] like '%palliative%'
						or b.TIUStandardTitle like '%Hospice%' or b.TIUStandardTitle like '%palliative%'
					     )
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitdatetime) between DATEADD(yy,-1, convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,30, convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))
			   and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
					  ) 
							)

go


-------------------------------------------------------------------------------------------
------------------------------  4: Tuberculosis Exclusions  -------------------------------
-------------------------------------------------------------------------------------------
		--  all instances with tuberculosis exclusions removed
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_4_Ex_Tuber]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_4_Ex_Tuber
		go

				select *
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_4_Ex_Tuber
		from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_2_Ex_4_UnionAllDx_ICD9ICD10] as b
			 where a.[PatientSSN] = b.[PatientSSN]and
			 			 (b.[tuberc_dx_dt] between DATEADD(yy,-1,a.[ExamDateTime]) and
			  DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP]),a.[ExamDateTime]))
			 )
		
		go
	


---------------------------------------Follw ups -----------------------------------------


-------------------------------------------------------------------------------------------
---------------------  Lung Procedures (Biopsy, Bronchoscopy, etc.)  -------------------
-------------------------------------------------------------------------------------------
		
		-- instances_7: all instances with lung procedures removed
				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy
	
		select *
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy
		from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_4_Ex_Tuber as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy] as b
			 where a.patientSSN = b.PatientSSN and
			 b.LungBiopsy_dt between DATEADD(dd,-(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
											,convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00' as datetime)) 
						and DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
											,convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59:997' as datetime)))
		--Need double check Brain's code is 60 days

go


				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy
	
		select *
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy
		from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy] as b
			 where a.patientSSN = b.PatientSSN and
			 b.Bronchoscopy_dt between DATEADD(dd,-(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
											,convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00' as datetime)) 
						and DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
											,convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59:997' as datetime)))


		go
		
				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery
	
		select *
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery
		from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery] as b
			 where a.patientSSN = b.PatientSSN and
			 b.LungSurgery_dt between DATEADD(dd,-(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
											,convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00' as datetime)) 
						and DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
											,convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59:997' as datetime)))


		go

	

	
-------------------------------------------------------------------------------------------
-------------------------------  Another Imaging Test  --------------------------------
-------------------------------------------------------------------------------------------



				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_8_OutCome_Rep_Img_A_XRay]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_8_OutCome_Rep_Img_A_XRay

					select a.*
		into  [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_8_OutCome_Rep_Img_A_XRay
		from  [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery] as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_1_In_1_All_Chest_XRayCTPET_SSN] as b
			 where a.PatientSSN = b.patientSSN and			 
			 (b.ExamDateTime > a.examDateTime
					and	b.ExamDateTime<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
														,(convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime))))
			 and b.[img_code_type]='XRay'
			 )			 
go


				if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_8_OutCome_Rep_Img_B_CT]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_8_OutCome_Rep_Img_B_CT

					select a.*
		into  [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_8_OutCome_Rep_Img_B_CT
		from  [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_8_OutCome_Rep_Img_A_XRay as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_1_In_1_All_Chest_XRayCTPET_SSN] as b
			 where a.PatientSSN = b.patientSSN and			 
			 (b.ExamDateTime > a.ExamDateTime
					and	b.ExamDateTime<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
														,(convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime))))
			 and b.[img_code_type]='CT'
			 )			 
go


			if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_8_OutCome_Rep_Img_C_PET]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_8_OutCome_Rep_Img_C_PET

					select a.*
		into  [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_8_OutCome_Rep_Img_C_PET
		from  [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_8_OutCome_Rep_Img_B_CT as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_1_In_1_All_Chest_XRayCTPET_SSN] as b
			 where a.PatientSSN = b.patientSSN and			 
			 (b.ExamDateTime > a.ExamDateTime
					and	b.ExamDateTime<= DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
														,(convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime))))
			 and b.[img_code_type]='PET'
			 )			 
go


	

	
		------------pulm--------------------
		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID
				
		select *
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID
        from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_8_OutCome_Rep_Img_C_PET as a		
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID] as b
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (312,104)   or b.SecondaryStopCode in (312,104)   --pulm
			 -- There is a visit, but the StopCode is missing
					or 	((b.[ConsultToRequestserviceName] like '%pulm%' or b.[tiustandardtitle] like '%pulm%')
							and b.[tiustandardtitle] not like '%CARDIO%' 
							and b.[tiustandardtitle] not like '%RESPIRATORY%'
							and b.[tiustandardtitle] not like '%THERAPY%'
							and b.[tiustandardtitle] not like '%TELEPHONE%'
							and b.[tiustandardtitle] not like '%PFT%'
							and b.[tiustandardtitle] not like '%function%'
							and b.[tiustandardtitle] not like '%EKG%'
							and b.[tiustandardtitle] not like '%Study%'
							and b.[tiustandardtitle] not like '%Sleep%'

							and isnull(b.[ConsultToRequestserviceName],'*Missing*') not like '%CARDIO%' 
							and isnull(b.[ConsultToRequestserviceName],'*Missing*') not like '%RESPIRATORY%'
							and isnull(b.[ConsultToRequestserviceName],'*Missing*') not like '%THERAPY%'
							and isnull(b.[ConsultToRequestserviceName],'*Missing*') not like '%TELEPHONE%'
							and isnull(b.[ConsultToRequestserviceName],'*Missing*') not like '%PFT%'
							and isnull(b.[ConsultToRequestserviceName],'*Missing*') not like '%function%'
							and isnull(b.[ConsultToRequestserviceName],'*Missing*') not like '%EKG%'
							and isnull(b.[ConsultToRequestserviceName],'*Missing*') not like '%Study%'
							and isnull(b.[ConsultToRequestserviceName],'*Missing*') not like '%Sleep%'
					     )
					)
						and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00.000' as datetime)) and 
					DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
							, convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))
			   and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
					  )) 
						
go



    
----------------ThoracicSurgery  --------------------------


		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID
				
		select *
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID
        from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID] as b
			 where (
					 --With Stopcode
					b.[primaryStopcode] in (413,64) or b.[SecondaryStopcode] in (413,64)   --THORACIC SURGERY
					 -- There is a visit, but the StopCode is missing
					or 	(
								(
								(b.[ConsultToRequestserviceName] like '%Thoracic%' and b.[ConsultToRequestserviceName] like '%Surgery%')
								or (b.TIUStandardTitle like '%Surgery%' and b.TIUStandardTitle like '%Thoracic%')
								)
								and b.[ConsultToRequestserviceName] not like '%CARDIAC%' 
								and b.TIUStandardTitle not like '%CARDIAC%'
						)
					     
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00.000' as datetime)) and 
					DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
									, convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))
			   and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
					  ) 
									)

go





----------------tumor board  --------------------------

		if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID]') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID
				
		select *
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID
        from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID as a
		where not exists
			(select * from [ORD_Singh_201210017D].[Dflt].[Lung_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID] as b
			 where  (
					((b.[primaryStopcode] in (316) or b.[SecondaryStopcode] in (316)) and [tiustandardtitle] like '%Tumor%Board%')
			        or b.TIUStandardTitle like '%tumor%board%' --(and ConsultSID is not null and ConsultSID<>-1)					
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 --Tumor, stopcode+title
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00.000' as datetime)) and 
					DATEADD(dd,(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
									, convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))
			   and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from [ORD_Singh_201210017D].[Dflt].[Lung_0_1_inputP])
					  ) 
									)

go






-------------------------------------------------------------------------------------------
-------------------------------  High Risk   --------------------------------
-------------------------------------------------------------------------------------------


if (OBJECT_ID('[ORD_Singh_201210017D].[Dflt].Lung_3_Ins_V_HighRisk_FirstOfPat_SP') is not null)
			drop table [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_V_HighRisk_FirstOfPat_SP
		go

		select *
		into [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_V_HighRisk_FirstOfPat_SP
		from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID as a
		where not exists
			(select *
			 from [ORD_Singh_201210017D].[Dflt].Lung_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID as b
			 where a.PatientSSN = b.patientSSN and			 
			 b.ExamDateTime < a.ExamDateTime)
		and a.[ExamDateTime] between (select sp_start from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP) 
							and (select sp_end from [ORD_Singh_201210017D].[Dflt].Lung_0_1_inputP) 
			 	
go
