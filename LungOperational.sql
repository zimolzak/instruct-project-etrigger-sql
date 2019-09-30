--------------------------------------------
--- Lung Cancer Trigger 
--------------------------------------------

--		1. What this SQL script does: Extract chest images which are diagnosed as suspicious for malignancy (nodule). Among these red-flagged images, exclude those from patients who have clinical explanations or have 
--			completed timely follow up. The rest of red-flagged images are considered missed followed up, and we call them "trigger positive".
--          This script runs across sta3n level data. ALBANY,NY(528A8) was coded as an example.
--
--		2. Give 30 days followup window: A red-flagged chest image needs 30 days to follow up. Always make sure, when setting up the study period, that the clinical data within 30 days after the chest image date is available.
--
--      TobeAltered:
--		3. This SQL script is written for CDW Research Data Warehouse, so it needs corresponding changes if run in Operational Data Warehouse. Search for the following string and replace
--			them with your corresponding database name, data schema, cohortName and table names:
--			database name: MyDB 
--			data schema:   MySchema 
--			CohortName:    'MyCohort'
--			Table names:   We have mapped table names from Research data to Operational. But we currently do not have live access to Operational 	--			       	       data to test the mappings. 
--
--      TobeAltered:
--		4. Table Lung_Sta3n528_0_xxx has all the input parameters, including site info, study period, standard codes( CPT, ICD, ICDproc etc.).
--		  Although these codes are standardized, if your local site uses them in different flavors, you need to do some customization. Also exam these tables after being populated to make sure codes
--		  used in your site are all included.
--							--Set your site code sta6a,sta3n and study period.
--							set @Sta3n=528
--							set @Sta6a='528A8'   -- ALBANY,NY(528A8) as an example
--							set @sp_start='2017-01-01 00:00:00'
--							set @sp_end='2017-01-31 23:59:59' 
--
--      TobeAltered:
--		5. Red-flagged chest image Diagnostic Codes
--		   Table MyDB.[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] will have the list of red-flagged chest image Diagnostic Codes.
--		   Add any additional codes that your site might use, or remove any that your site does not use by setting isRedFlag=0.
--							select * from [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] 
--							where sta3n=@yourSta3n
--						 
--		6. Other possible changes
--		   Standard codes ( CPT,ICD, ICDProcedure, LOINC etc.) might change every year, with addition of new codes and removal of old ones. These changes require corresponding updates of this script. 
--		   Always add new codes to parameter tables. Do NOT remove old codes because script still checks back for clinical history.		  
--
--		7. Since we will be running the query in data of year 2019 and after, parameter tables of ICD9 and ICD9Procedure code are set to empty
--
--		8. Numerator and denumerators: select * from [MyDB].[MySchema].Lung_Sta3n528_4_01_Count
--
--		9. If you want to delete the intermediate table generated during execution, uncomment the block at the end of the script.


--------------------------------------------------------------------------------------------------------------------------------
-----  1. Initial set up: Input parameters, CPT and ICD diagnosis code, and ICDProcedure code lists used in the trigger measurement
--------------------------------------------------------------------------------------------------------------------------------

use master
go

declare @trigger varchar(20)		--Name of the trigger
declare @isVISN bit 				--Trigger runs on VISN levle
declare @VISN smallint				
declare @isSta3n bit				--Trigger runs on Sta3n levle
declare @Sta3n smallint				
declare @Sta6a varchar(10)			--Site Code
declare @run_date datetime			--Date time of trigger run
declare @sp_start datetime			--Study starting date time
declare @sp_end datetime			--Study ending date time
declare @fu_period as smallint		--follow-up window for red-flagged patients  
declare @age as smallint			--patient age upper limit
declare @ICD9Needed bit				--ICD9 and ICD9Proc are not searched if run trigger in year 2017 and beyond, set to 0

-- Set study parameters
set @trigger='LungCancer'
set @isVISN=0	--Disabled since trigger will run on sta3n level
set @VISN=-1
set @isSta3n=1

--Set your site code sta6a,sta3n and study period. 
set @Sta3n=528
set @Sta6a='528A8'   -- ALBANY,NY(528A8) as an example
set @sp_start='2017-01-01 00:00:00'
set @sp_end='2017-01-31 23:59:59' 

set @run_date=getdate()
set @fu_period=30
set @age=18
set @ICD9Needed=0


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP]') is not null)	    --altered (ORD_...Dflt)
	begin
		delete from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP]    --altered (ORD_...Dflt)
	end
	else
	begin	
		CREATE TABLE [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP](    --altered (ORD_...Dflt)
		[trigger] [varchar](20) NULL,
		isVISN bit null,
		isSta3n bit null,
		[VISN] [smallint] NULL,		 
		Sta3n smallint null,
		ICD9Needed bit null,
		Sta6a [varchar](10) NULL,
		[run_dt] [datetime] NULL,
		[sp_start] [datetime] NULL,
		[sp_end] [datetime] NULL,
		[fu_period] [smallint] NULL,
		[age] [smallint] NULL)
	end


INSERT INTO [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP]    --altered (ORD_...Dflt)
           ([trigger]
		   ,isVISN
		   ,isSta3n
		   ,[VISN]
		   ,Sta3n
		   ,ICD9Needed
		   ,Sta6a
           ,[run_dt]
           ,[sp_start]
           ,[sp_end]
           ,[fu_period]
           ,[age])
     VALUES
           (
           @trigger
		   ,@isVISN
		   ,@isSta3n
		   ,@VISN
		   ,@Sta3n
		   ,@ICD9Needed
		   ,@Sta6a           
		   ,@run_date
           ,@sp_start
           ,@sp_end
           ,@fu_period
           ,@age)


go

select * from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP]    --altered (ORD_...Dflt)


-- CPT Code lists for Lung images
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg    --altered (ORD_...Dflt)

	CREATE TABLE [MyDB].[MySchema].[Lung_Sta3n528_0_2_0_LungImg] (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[img_code_type] [varchar](50) NULL,
	[img_code_name] [varchar](50) NULL,
	[ImgCode] [varchar](10) NULL
	) 
go

insert into  [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg ([img_code_type],[img_code_name],[ImgCode])     --altered (ORD_...Dflt)
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

-- ICD10 Diagnostic Code list
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_0_2_DxICD10CodeExc') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc]    --altered (ORD_...Dflt)

	CREATE TABLE [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.00'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.40'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.50'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.01'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.41'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.51'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.02'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.42'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.52'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.60'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C92.A0'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C93.00'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C93.01'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C93.02'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C94.00'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C94.01'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C94.02'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C94.20'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C94.21'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C94.22'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C95.00'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C95.01'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Leukemia (Acute Only)','C95.02'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.0'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.2'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.3'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.4'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.7'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.8'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.1'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.9'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C78.7'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C23.'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.0'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.1'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.8'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.9'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.3'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.4'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.5'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.8'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.9'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.0'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.4'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.3'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.1'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.2'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.5'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.6'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.8'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.9'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.0'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.1'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.2'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.3'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.4'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.5'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.6'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.7'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.8'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.9'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C79.31'

--insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Brain Cancer','C79.32'
--insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Brain Cancer','C79.49'
--insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Brain Cancer', 'C79.40'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Ovarian Cancer','C56.9'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Ovarian Cancer','C56.1'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Ovarian Cancer','C56.2'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.0'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.1'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.2'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.3'

--insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Pleural Cancer & Mesothelioma','C38.4'
--insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Pleural Cancer & Mesothelioma','C45.0'
--insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Pleural Cancer & Mesothelioma','C78.2'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Uterine Cancer','C55.'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C45.1'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.1'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.8'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.2'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C78.6'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','C90.00'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','C90.01'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','C90.02'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','D47.Z9'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Tracheal Cancer','C33.'

--insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Tracheal Cancer','C78.39'
--insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
--select 	'Terminal','Tracheal Cancer','C78.30'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Hospice','','Z51.5'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Tuberculosis','','A15.0'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Tuberculosis','','A15.5'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Tuberculosis','','A15.6'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Tuberculosis','','A15.7'


-- ICD10Proc Code lists
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc]    --altered (ORD_...Dflt)


	CREATE TABLE [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[ICD10Proc_code_type] [varchar](50) NULL,
	[ICD10Proc_code_Name] [varchar](50) NULL,
	[ICD10ProcCode] [varchar](10) NULL
	) 
go

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B933ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B934ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B937ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B938ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B943ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B944ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B947ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B948ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B953ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B954ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B957ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B958ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B963ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B964ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B967ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B968ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B973ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B974ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B977ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B978ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B983ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B984ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B987ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B988ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B993ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B994ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B997ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B998ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B3ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B4ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B7ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B8ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB33ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB34ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB37ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB38ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB43ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB44ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB47ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB48ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB53ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB54ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB57ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB58ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB63ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB64ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB67ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB68ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB73ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB74ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB77ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB78ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB83ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB84ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB87ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB88ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB93ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB94ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB97ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB98ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB3ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB4ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB7ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB8ZX'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0B930ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0B940ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0B950ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0B960ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0B970ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0B980ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0B990ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0B9B0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB30ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB40ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB50ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB60ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB70ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB80ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB90ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyBronchus','0BBB0ZX'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9C3ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9C4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9C7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9D3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9D4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9D7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9F3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9F4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9F7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9G3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9G4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9G7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9H3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9H4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9H7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9J3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9J4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9J7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9K3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9K4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9K7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9L3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9L4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9L7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9M3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9M4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9M7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBC3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBD3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBF3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBG3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBH3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBJ3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBK3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBL3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBM3ZX'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0B9K8ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0B9L8ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0B9M8ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBK7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBK8ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBL7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBL8ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBM4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBM7ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBM8ZX'



insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyLung','0B9K0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyLung','0B9L0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyLung','0B9M0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyLung','0BBK0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyLung','0BBL0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','OpenBiopsyLung','0BBM0ZX'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBC4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBD4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBF4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBG4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBH4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBJ4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBK4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBL4ZX'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','BiopsyChestWall','0W980ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','BiopsyChestWall','0W983ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','BiopsyChestWall','0W984ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','BiopsyChestWall','0WB80ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','BiopsyChestWall','0WB83ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','BiopsyChestWall','0WB84ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','BiopsyChestWall','0WB8XZX'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0B9N0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0B9N3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0B9N4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0B9P0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0B9P3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0B9P4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0BBN0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0BBN3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0BBP0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0BBP3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0W990ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0W993ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0W994ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0W9B0ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0W9B3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','PleuraBiopsy','0W9B4ZX'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0W9C3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0W9C4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0WBC3ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0WBC4ZX'



insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Bronchoscopy','','0BBN4ZX' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Bronchoscopy','','0BBP4ZX'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Bronchoscopy','','0BJ08ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Bronchoscopy','','0WJQ4ZZ'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Bronchoscopy','','0WJC4ZZ'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Bronchoscopy','','0BJ08ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Bronchoscopy','','0BJK8ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Bronchoscopy','','0BJL8ZZ'


-- Lung surgery
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B534ZZ'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B538ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B544ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B548ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B554ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B558ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B564ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B568ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B574ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B578ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B584ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B588ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B594ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B598ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5B4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5B8ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB34ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB38ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB44ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB48ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB54ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB58ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB64ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB68ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB74ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB78ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB84ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB88ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB94ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB98ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBB4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBB8ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B530ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B533ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B537ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B540ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B543ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B547ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B550ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B553ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B557ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B560ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B563ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B567ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B570ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B573ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B577ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B580ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B583ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B587ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B590ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B593ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B597ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5B0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5B3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5B7ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB30ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB33ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB37ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB40ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB43ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB47ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB50ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB53ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB57ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB60ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB63ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB67ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB70ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB73ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB77ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB80ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB83ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB87ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB90ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB93ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BB97ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBB0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBB3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBB7ZZ'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT30ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT34ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT40ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT44ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT50ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT54ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT60ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT64ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT70ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT74ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT80ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT84ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT90ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BT94ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTB0ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBK4ZZ'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBL4ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5K0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5L0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5M0ZZ'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5K3ZZ'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5L3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5M3ZZ'



insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5K4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5L4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5M4ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5K7ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5K8ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5L7ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5L8ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5M7ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5M8ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5K8ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5L8ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5M8ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBK8ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBL8ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBM4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBM8ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5K0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5K3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5K7ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5L0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5L3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5L7ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5M0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5M3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0B5M7ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBK0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBK3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBK7ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBL0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBL3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBL7ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBM0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBM3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBM7ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBC4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBD4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBF4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBG4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBH4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBJ4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBK4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBL4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTH4ZZ'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)

select 	'LungSurgery','','0BBK0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBK3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBK7ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBL0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBL3ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BBL7ZZ'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTC4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTD4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTF4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTG4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTJ4ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTC0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTD0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTF0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTG0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTJ0ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','02JA0ZZ'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0WJC0ZZ'



insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BJ04ZZ'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0WJQ4ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTK4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTL4ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTM4ZZ'


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTK0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTL0ZZ' 
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'LungSurgery','','0BTM0ZZ'

-- ICD9 Diagnostic Code list
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_0_4_DxICD9CodeExc    --altered (ORD_...Dflt)

	CREATE TABLE [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc] (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go


insert into  [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc] (    --altered (ORD_...Dflt)
	[ICD9Code]
	) 
select distinct ICD9Code from CDWWork.dim.ICD9 as dimICD9
where (select ICD9Needed from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)=1    --altered (ORD_...Dflt)
	and (dimICD9.ICD9Code like '157.%'
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
	or dimICD9.ICD9Code like '179.%' 
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
	)

update  [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc]     --altered (ORD_...Dflt)
 set dx_code_type = case
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
			or ICD9Code like '179.%' 
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
	

-- ICD9Proc Code list
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_0_5_PreProcICD9ProcExc]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_0_5_PreProcICD9ProcExc    --altered (ORD_...Dflt)

	CREATE TABLE [MyDB].[MySchema].Lung_Sta3n528_0_5_PreProcICD9ProcExc (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[ICD9Proc_code_type] [varchar](50) NULL,
	[ICD9Proc_code_Name] [varchar](50) NULL,
	[ICD9ProcCode] [varchar](10) NULL
	) 
go

If Exists (select ICD9Needed from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP where ICD9Needed=1)    --altered (ORD_...Dflt)
	insert into  [MyDB].[MySchema].Lung_Sta3n528_0_5_PreProcICD9ProcExc ([ICD9Proc_code_type],[ICD9Proc_code_Name],[ICD9ProcCode])     --altered (ORD_...Dflt)
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
	 --above Lung Surgery
	,( 'LungBiopsy','','33.24')
	,( 'LungBiopsy','','33.25')
	,( 'LungBiopsy','','33.26')
	,( 'LungBiopsy','','33.27')
	,( 'LungBiopsy','','33.28')
	,( 'LungBiopsy','','34.20')
	,( 'LungBiopsy','','34.23')
	,( 'LungBiopsy','','34.24')
	,( 'LungBiopsy','','34.25')
	 --above Lung Biopsy
	,( 'Bronchoscopy','','33.20')
	,( 'Bronchoscopy','','33.21')
	,( 'Bronchoscopy','','33.22')
	,( 'Bronchoscopy','','33.23') 
	--above Bronchoscopy	




-- ICD10 diagnostic code list for lung cancer
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc    --altered (ORD_...Dflt)

	CREATE TABLE [MyDB].[MySchema].Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go


insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.00'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.01'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.02'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.10'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.11'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.12'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.2'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.30'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.31'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.32'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.80'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.81'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.82'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.90'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.91'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C34.92'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C78.00'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C78.01'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C78.02'

insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C38.4'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C45.0'
insert into [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'RecentActiveLungC','Lung Cancer','C78.2'

-- ICD9 diagnostic code list for lung cancer
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc    --altered (ORD_...Dflt)

	CREATE TABLE [MyDB].[MySchema].Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go

insert into  [MyDB].[MySchema].Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc (    --altered (ORD_...Dflt)
[dx_code_type],
	[dx_code_name],
	[ICD9Code]
	) 
select distinct 'RecentActiveLungC','', ICD9Code from CDWWork.dim.ICD9 as dimICD9
where	(select ICD9Needed from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)=1    --altered (ORD_...Dflt)
	 and(  DimICD9.ICD9Code like '162.2%'
	or DimICD9.ICD9Code like '162.3%'
	or DimICD9.ICD9Code like '162.4%'
	or DimICD9.ICD9Code like '162.5%'
	or DimICD9.ICD9Code like '162.8%'
	or DimICD9.ICD9Code like '162.9%'
	or DimICD9.ICD9Code like '197.0'
	-- these are Pleural cancer & Mesothelioma cancer, a kind of lung problem
	or DimICD9.ICD9Code like '163.%'
	or DimICD9.ICD9Code like '197.2%')
go

-- CPT procedure code list
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_0_8_PrevProcCPTCodeExc]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
go

	CREATE TABLE [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[CPT_code_type] [varchar](50) NULL,
	[CPT_code_name] [varchar](50) NULL,
	[CPTCode] [varchar](10) NULL
	) 
go

insert into  [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc (    --altered (ORD_...Dflt)
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

,('Bronchoscopy','','31899')

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

,('LungSurgery','','49405')
,('LungSurgery','','32506')
,('LungSurgery','','32507')
,('LungSurgery','','32602')
,('LungSurgery','','32603')
,('LungSurgery','','32604')
,('LungSurgery','','32605')
,('LungSurgery','','32606')
,('LungSurgery','','32609') 
--Above Lung Surgery		
go


-- Chest XRay/CT RadiologyDiagnosticCode list ( which will be red-flagged)
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode    --altered (ORD_...Dflt)
go

	CREATE TABLE [MyDB].[MySchema].Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	Sta3n smallint null,
	RadiologyDiagnosticCode [varchar](100) NULL,
	[IsRedFlag] [bit] NULL,
	RadiologyDiagnosticCodeSID int null
)
go


-- Add red-flagged RadiologyDiagnosticCode. Check if all the codes used in your site are included

	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'POSSIBLE MALIGNANCY', 1, 800001068)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 800001096)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 800001097)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 800001098)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 800001113)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'HIGHLY SUGGESTIVE OF MALIGNANCY', 1, 800001142)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 800001146)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'POSSIBLE MALIGNANCY', 1, 800001883)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 800001904)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 800001905)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 800001906)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 800001921)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'LESION SUSPICIOUS FOR LUNG CA', 1, 800001925)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'ABNORMALITY: POSSIBLE MALIGNANCY, ATTN. NEEDED', 1, 800001928)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 800001933)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'PULMONARY NODULE PRESENT', 1, 800002109)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'HIGHLY SUG OF MALIG, TK ACTION', 1, 1000000002)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'SUSPICIOUS ABNORM, CONSIDER BX', 1, 1000000003)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'POSSIBLE MALIGNANCY', 1, 1000000340)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000000361)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000000362)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000000363)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000000378)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1000000416)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'POSSIBLE MALIGNANCY', 1, 1000000423)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000000446)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000000447)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000000448)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'IMPORTANT REPORT/POSSIBLE MALIGNANCY', 1, 1000000462)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000000463)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'POSSIBLE MALIGNANCY', 1, 1000001015)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000001036)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000001037)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000001038)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000001053)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'CLINICAL ALERT-POSS. MALIGNANCY-E-MAIL', 1, 1000001064)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'CLINICAL ALERT-POSSIBLE MALIGNANCY', 1, 1000001069)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'POSSIBLE MALIGNACY, FOLLOW-UP NEEDED', 1, 1000001073)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'POSSIBLE MALIGNANCY', 1, 1000001552)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'Suspicious for Malignancy-Clinical Follow-up Action Needed', 1, 1000001555)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000001583)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000001584)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000001585)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000001600)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'Suspicious for New Malignancy Need FU', 1, 1000001605)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'PULMONARY EMBOLISM, IMMEDIATE ATTN NEEDED', 1, 1000001615)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'PULMONARY EMBOLISM, IMMEDIATE ATTN NEEDED', 1, 1000001617)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'NODULES 4mm TO LESS THAN 2cm', 1, 1000001619)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'NODULES/MASSES GREATER THAN 2cm', 1, 1000001620)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1000001628)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'POSSIBLE MALIGNANCY', 1, 1000002243)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000002263)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000002264)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000002265)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000002279)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1000002307)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'POSSIBLE MALIGNANCY', 1, 1400000451)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1400000472)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1400000473)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1400000474)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1400000489)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1400000495)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'POSSIBLE MALIGNANCY', 1, 1400000529)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'Lung Lesion for follow-up team', 1, 1400000530)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'POSSIBLE MALIGNANCY', 1, 1400000537)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'Lung Lesion for follow up team', 1, 1400000538)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'LUNG NODULE FOLLOW UP', 1, 1400000540)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'POSSIBLE MALIGNANCY', 1, 1400000629)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1400000650)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1400000651)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1400000652)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1400000667)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'POSS PROBABLE TUMOR, PROVIDER NOTIFIED', 1, 1400000672)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'CATEGORY 5 HIGHLY SUGG MALIGNANCY', 1, 1400000688)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'POSSIBLE MALIGNANCY, FOLLOWUP NEEDED', 1, 1400000716)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'POSSIBLE MALIGNANCY', 1, 1400000805)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1400000824)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1400000825)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1400000826)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1400000840)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'POSS MALIGN, F/U NEEDED, ALERT SENT    ', 1, 1400000843)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'POSSIBLE MALIGNANCY', 1, 1400001450)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1400001471)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1400001472)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1400001473)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1400001488)    --altered (ORD_...Dflt)
	GO
	INSERT [MyDB].[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] ([sta3n], [RadiologyDiagnosticCode], [IsRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'MAJOR ABNORMALITY/POSSIBLE MALIGNANCY', 1, 1400002196)    --altered (ORD_...Dflt)
	GO



--------------------------------------------------------------------------------------------------------------------------------
-----  2. Extract red-flagged chest images
--------------------------------------------------------------------------------------------------------------------------------
	
-- Extract of all chest XRay/CT during study period + follow-up days
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET    --altered (ORD_...Dflt)


select [RadiologyExamSID]
      ,[RadiologyPatientSID]
      ,[RadiologyPatientIEN]
      ,[RadiologyRegisteredExamSID]
      ,[RadiologyRegisteredExamIEN]
      ,[RadiologyExamIEN]
      ,Rad.[Sta3n]
	  ,d.sta6a
      ,[CaseNumber]
      ,[PatientSID]
      ,[ExamDateTime]
      ,Rad.[RadiologyProcedureSID]
	  ,code.CPTCode
	  ,TargetImg.[img_code_type]
	  ,[RadiologyExamStatus]
      ,[ExamCategory]
      ,Rad.[WardLocationSID]
      ,Rad.[PrincipalLocationSID]
      ,[RequestedDateTime]
      ,[RequestingLocationSID]
      ,[PrimaryInterpretingResidentStaffSID]
      ,Rad.[RadiologyDiagnosticCodeSID]
	  ,[RadiologyDiagnosticCode]
	  ,[RadiologyDiagnosticCodeDescription]
      ,[RequestingPhysicianStaffSID]
      ,[PrimaryInterpretingStaffSID]
      ,[RadiologyComplicationTypeSID]
      ,[RadiologyNuclearMedicineReportSID]
      ,[ClinicStopRecordedFlag]
      ,[VisitSID]
      ,[NuclearMedicineExamSID]
into [MyDB].[MySchema].Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET     --altered (ORD_...Dflt)
FROM [CDWWork].[Rad].[RadiologyExam] as Rad    --altered (ORD_...Src)
left join CDWWork.Dim.location as b
		on Rad.RequestingLocationSID=b.LocationSID
left join CDWWork.dim.Division as d
		on b.DivisionSID=d.DivisionSID
left join cdwwork.dim.[RadiologyProcedure] as prc
on rad.sta3n=prc.sta3n and rad.[RadiologyProcedureSID]=prc.[RadiologyProcedureSID]
left join cdwwork.dim.CPT as code
on prc.CPTSID=code.CPTSID and prc.sta3n=code.sta3n 
inner join  [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg as TargetImg    --altered (ORD_...Dflt)
on TargetImg.ImgCode=code.CPTCode
left join cdwwork.dim.[RadiologyExamStatus] as sta
on Rad.sta3n=sta.sta3n and Rad.[RadiologyExamStatusSID]=sta.[RadiologyExamStatusSID]
left join cdwwork.dim.[RadiologyDiagnosticCode] as diag
on Rad.sta3n=diag.sta3n and Rad.[RadiologyDiagnosticCodeSID]=diag.[RadiologyDiagnosticCodeSID]
  inner join cdwwork.dim.VistaSite as VistaSite
		on Rad.sta3n=VistaSite.Sta3n  
  where Rad.CohortName='MyCohort' and
	 Rad.ExamDateTime
	  between (select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt)
	  and DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)) --Clue Date Range+followup    --altered (ORD_...Dflt)
	and sta.[RadiologyExamStatus] like'%COMPLETE%'
	and d.sta3n=(select sta3n from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)


go


if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN    --altered (ORD_...Dflt)

	select distinct b.patientSSN,convert(varchar(10),b.BirthDateTime,120) as DOB,convert(varchar(10),b.DeathDateTime,120) as DOD,b.Gender as Sex
				,a.* 	
	into [MyDB].[MySchema].Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET as a    --altered (ORD_...Dflt)
	left join [CDWWork].[SPatient].[SPatient] as b    --altered (ORD_...Src)
	on a.sta3n=b.sta3n and a.[PatientSID]=b.patientsid
	where CohortName='MyCohort' 

	
go

-- All Chest_XRay/CT images during study period from local site sta6a
  if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a    --altered (ORD_...Dflt)

	select * into [MyDB].[MySchema].Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN]    --altered (ORD_...Dflt)
    where [img_code_type] in ('CT','XRay')
	and ExamDateTime
	  between (select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt)
	  and (select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt)
	and Sta6a=(select Sta6a from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt)

go


-- Chest_XRay/CT images that are flagged during study period from your site 
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_1_In_3_RedFlagXRayCT') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_3_RedFlagXRayCT    --altered (ORD_...Dflt)

select  Rad.* into [MyDB].[MySchema].Lung_Sta3n528_1_In_3_RedFlagXRayCT    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a] as Rad    --altered (ORD_...Dflt)
inner join 
(
	select distinct RadiologyDiagnosticCode,Sta3n  from [MyDB].[MySchema].Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode     --altered (ORD_...Dflt)
				where [IsRedFlag]=1
) as code
on rad.[RadiologyDiagnosticCode]=code.RadiologyDiagnosticCode and rad.Sta3n=code.Sta3n 
go




-- Red-flagged instances in study period
 if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_1_In_6_IncIns') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_6_IncIns    --altered (ORD_...Dflt)

select 	distinct
		[RadiologyExamSID]
	  ,PatientSSN
	  ,[Sta3n]
	  ,[Sta6a]
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
into [MyDB].[MySchema].Lung_Sta3n528_1_In_6_IncIns    --altered (ORD_...Dflt)
from [MyDB].[MySchema].Lung_Sta3n528_1_In_3_RedFlagXRayCT as Rad    --altered (ORD_...Dflt)
where ExamDateTime between (select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
				and (select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)

go


-- Get other possible patientSID outside your sta3n
 if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat    --altered (ORD_...Dflt)

	select distinct VStatus.Sta3n,VStatus.PatientSID,VStatus.patientSSN, VStatus.ScrSSN,VStatus.PatientICN
	into [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].Lung_Sta3n528_1_In_6_IncIns as a    --altered (ORD_...Dflt)
	left join [CDWWork].[SPatient].[SPatient]  as VStatus    --altered (ORD_...Src)
	on a.patientSSN=VStatus.PatientSSN
	where CohortName='MyCohort'
	order by patientssn

	go




--------------------------------------------------------------------------------------------------------------------------------
-----  3. Extract red-flagged patients' clinical diagnosis, procedures and consults etc
--------------------------------------------------------------------------------------------------------------------------------

-- Extract of all DX Codes for all potential patients from surgical files
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD9_Hlp1]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD9_Hlp1]    --altered (ORD_...Dflt)


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
	  ,(case when PrincipalPostOpICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)
			then PrincipalPostOpICD9.ICD9Code
            when OtherPostICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)
	        then OtherPostICD9.ICD9Code
            when assocDxICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)
	   	    then assocDxICD9.ICD9Code
	        else null
	   end ) as ICD9Code    
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	 
  into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_1_SurgDx_ICD9_Hlp1    --altered (ORD_...Dflt)
  FROM [CDWWork].[Surg].[SurgeryPre] as surgPre    --altered (ORD_...Src)
  inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
  on SurgPre.sta3n=p.sta3n and SurgPre.patientsid=p.patientsid
  left join CDWWork.dim.ICD9 as PreICD9
  on SurgPre.PrincipalPreOpICD9SID=PreICD9.ICD9SID and SurgPre.Sta3n=PreICD9.Sta3n
  left join[CDWWork].[Surg].[SurgeryProcedureDiagnosisCode]as surgDx    --altered (ORD_...Src)
  on surgPre.SurgerySID=SurgDx.SurgerySID and surgPre.sta3n=SurgDx.sta3n
  left join CDWWork.dim.ICD9 as PrincipalPostOpICD9
  on SurgDx.[PrincipalPostOpICD9SID]=PrincipalPostOpICD9.ICD9SID and SurgDx.Sta3n=PrincipalPostOpICD9.Sta3n
  left join [CDWWork].[Surg].[SurgeryOtherPostOpDiagnosis] as otherPostDx    --altered (ORD_...Src)
   on surgDx.SurgeryProcedureDiagnosisCodeSID=otherPostDx.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=otherPostDx.sta3n
  left join CDWWork.dim.ICD9 as OtherPostICD9
  on otherPostDx.OtherPostopICD9SID=OtherPostICD9.ICD9SID and otherPostDx.Sta3n=OtherPostICD9.Sta3n
  left join [CDWWork].[Surg].[SurgeryPrincipalAssociatedDiagnosis] as assocDx    --altered (ORD_...Src)
  on  surgDx.SurgeryProcedureDiagnosisCodeSID=assocDx.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=assocDx.sta3n
  left join CDWWork.dim.ICD9 as assocDxICD9
  on assocDx.[SurgeryPrincipalAssociatedDiagnosisICD9SID]=assocDxICD9.ICD9SID and assocDx.sta3n=assocDxICD9.sta3n
   where  
  SurgPre.[SurgeryDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
  and SurgPre.[SurgeryDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)) --Clue Date Range+followup and    --altered (ORD_...Dflt)
  and  SurgPre.CohortName='MyCohort'
  and  surgDx.CohortName='MyCohort'
  and  otherPostDx.CohortName='MyCohort'
  and  assocDx.CohortName='MyCohort'
  and (
  	--PreICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)
	PrincipalPostOpICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)
	or 	OtherPostICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)
	or 	assocDxICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)
	) 
	go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD9]    --altered (ORD_...Dflt)

	select a.*,dx_code_type
	into [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD9]    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].Lung_Sta3n528_2_Ex_1_SurgDx_ICD9_Hlp1 as a    --altered (ORD_...Dflt)
	inner join [MyDB].[MySchema].[Lung_Sta3n528_0_4_DxICD9CodeExc] as b    --altered (ORD_...Dflt)
	on b.ICD9Code=a.ICD9Code
go
	

if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD10_Hlp1]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD10_Hlp1]    --altered (ORD_...Dflt)

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
	  ,(case when PrincipalPostOpICD10.ICD10Code in (select ICD10Code from [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc])    --altered (ORD_...Dflt)
			then PrincipalPostOpICD10.ICD10Code
            when OtherPostICD10.ICD10Code in (select ICD10Code from [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc])    --altered (ORD_...Dflt)
	        then OtherPostICD10.ICD10Code
            when assocDxICD10.ICD10Code in (select ICD10Code from [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc])    --altered (ORD_...Dflt)
	   	    then assocDxICD10.ICD10Code
	        else null
	   end ) as ICD10Code  
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
	 
  into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_1_SurgDx_ICD10_Hlp1    --altered (ORD_...Dflt)
  FROM [CDWWork].[Surg].[SurgeryPre] as surgPre    --altered (ORD_...Src)
  inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
  on SurgPre.sta3n=p.sta3n and SurgPre.patientsid=p.patientsid
  left join CDWWork.dim.ICD10 as PreICD10
  on SurgPre.PrincipalPreOpICD10SID=PreICD10.ICD10SID and SurgPre.Sta3n=PreICD10.Sta3n
  left join[CDWWork].[Surg].[SurgeryProcedureDiagnosisCode]as surgDx    --altered (ORD_...Src)
  on surgPre.SurgerySID=SurgDx.SurgerySID and surgPre.sta3n=SurgDx.sta3n
  left join CDWWork.dim.ICD10 as PrincipalPostOpICD10
  on SurgDx.[PrincipalPostOpICD10SID]=PrincipalPostOpICD10.ICD10SID and SurgDx.Sta3n=PrincipalPostOpICD10.Sta3n
  left join [CDWWork].[Surg].[SurgeryOtherPostOpDiagnosis] as otherPostDx    --altered (ORD_...Src)
   on surgDx.SurgeryProcedureDiagnosisCodeSID=otherPostDx.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=otherPostDx.sta3n
  left join CDWWork.dim.ICD10 as OtherPostICD10
  on otherPostDx.OtherPostopICD10SID=OtherPostICD10.ICD10SID and otherPostDx.Sta3n=OtherPostICD10.Sta3n
  left join [CDWWork].[Surg].[SurgeryPrincipalAssociatedDiagnosis] as assocDx    --altered (ORD_...Src)
  on  surgDx.SurgeryProcedureDiagnosisCodeSID=assocDx.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=assocDx.sta3n
  left join CDWWork.dim.ICD10 as assocDxICD10
  on assocDx.[SurgeryPrincipalAssociatedDiagnosisICD10SID]=assocDxICD10.ICD10SID and assocDx.sta3n=assocDxICD10.sta3n 
   where  
  SurgPre.[SurgeryDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)) and    --altered (ORD_...Dflt)
  SurgPre.[SurgeryDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
  and  SurgPre.CohortName='MyCohort'
  and  surgDx.CohortName='MyCohort'
  and  otherPostDx.CohortName='MyCohort'
  and  assocDx.CohortName='MyCohort'
  and
(
	  PrincipalPostOpICD10.ICD10Code in (select ICD10Code from [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc])    --altered (ORD_...Dflt)
	or OtherPostICD10.ICD10Code in (select ICD10Code from [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc])    --altered (ORD_...Dflt)
	or assocDxICD10.ICD10Code in (select ICD10Code from [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc])    --altered (ORD_...Dflt)
	) 
	go



if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD10]    --altered (ORD_...Dflt)

	select a.*,dx_code_type
	into [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD10]    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD10_Hlp1] as a    --altered (ORD_...Dflt)
	inner join [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] as b    --altered (ORD_...Dflt)
	on a.ICD10Code=b.ICD10Code
go

--  Extract of all DX codes from outpatient table for all potential patients
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9]    --altered (ORD_...Dflt)


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
into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9    --altered (ORD_...Dflt)
FROM [CDWWork].[Outpat].[VDiagnosis] as Diag    --altered (ORD_...Src)
inner join CDWWork.Dim.ICD9 as ICD9
	on Diag.ICD9SID=ICD9.ICD9SID
inner join cdwwork.dim.ICD9DiagnosisVersion as ICD9Diag
	on Diag.ICD9SID=ICD9Diag.ICD9SID
inner join [MyDB].[MySchema].Lung_Sta3n528_0_4_DxICD9CodeExc as TargetCode    --altered (ORD_...Dflt)
	on ICD9.ICD9Code=TargetCode.ICD9Code
inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
	[VDiagnosisDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)) and    --altered (ORD_...Dflt)
	[VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and Diag.CohortName='MyCohort'
go


--  Extract of all DX codes from outpatient table for all potential patients
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_2_OutPatDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_2_OutPatDx_ICD10    --altered (ORD_...Dflt)


SELECT 
	 [VDiagnosisSID]
      ,Diag.[Sta3n]
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
into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_2_OutPatDx_ICD10    --altered (ORD_...Dflt)
FROM [CDWWork].[Outpat].[VDiagnosis] as Diag    --altered (ORD_...Src)
inner join CDWWork.Dim.ICD10 as ICD10
  on Diag.ICD10SID=ICD10.ICD10SID
inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on Diag.ICD10SID=ICD10Diag.ICD10SID
inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
inner join [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] as ICD10CodeList    --altered (ORD_...Dflt)
  on ICD10.ICD10Code=ICD10CodeList.ICD10Code
where 
	[VDiagnosisDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)) and    --altered (ORD_...Dflt)
	[VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
	and Diag.CohortName='MyCohort'
go


--  Extract of all DX codes from inpatient tables for all potential patients
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9]	    --altered (ORD_...Dflt)

SELECT 
	  [InpatientDiagnosisSID] 
      ,InPatDiag.[Sta3n]
      ,[InpatientSID] 
      ,InPatDiag.[PatientSID]
      ,[DischargeDateTime] as dx_dt
	  ,dx_code_type
      ,InPatDiag.[ICD9SID]
	  ,ICD9.ICD9Code as ICDCode
	  ,ICD9Diag.ICD9Diagnosis as ICDDiagnosis	    
	  ,InPatDiag.[ICD10SID]
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN
into  [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9]    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[InpatientDiagnosis] as InPatDiag    --altered (ORD_...Src)
inner join CDWWork.Dim.ICD9 as ICD9
	on InPatDiag.ICD9SID=ICD9.ICD9SID
inner join cdwwork.dim.ICD9DiagnosisVersion as ICD9Diag
	on InPatDiag.ICD9SID=ICD9Diag.ICD9SID
inner join [MyDB].[MySchema].Lung_Sta3n528_0_4_DxICD9CodeExc as TargetCode    --altered (ORD_...Dflt)
	on ICD9.ICD9Code=TargetCode.ICD9Code
inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
	on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where 
	[DischargeDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))  and    --altered (ORD_...Dflt)
	[DischargeDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
	and InPatDiag.CohortName='MyCohort'
	go


	--  Extract of all DX codes from inpatient tables for all potential patients
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD10]    --altered (ORD_...Dflt)

SELECT 
	  [InpatientDiagnosisSID] 
      ,InPatDiag.[Sta3n]
      ,InPatDiag.[InpatientSID] 
      ,InPatDiag.[PatientSID]
      ,[DischargeDateTime] as dx_dt
      ,InPatDiag.[ICD9SID]
	  ,InPatDiag.[ICD10SID]
	  ,ICD10.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type
	  ,ICD10Diag.ICD10Diagnosis as ICDDiagnosis
	  ,p.patientSSN
	  ,p.ScrSSN 
	  ,p.patientICN
into  [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD10]    --altered (ORD_...Dflt)
FROM [CDWWork].[inpat].[InpatientDiagnosis] as InPatDiag    --altered (ORD_...Src)
inner join CDWWork.Dim.ICD10 as ICD10
	on InPatDiag.ICD10SID=ICD10.ICD10SID
inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
	on InPatDiag.ICD10SID=ICD10Diag.ICD10SID
inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
	on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
inner join [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] as ICD10CodeList    --altered (ORD_...Dflt)
	on ICD10.ICD10Code=ICD10CodeList.ICD10Code  
where 
	[DischargeDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))  and    --altered (ORD_...Dflt)
	[DischargeDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and InPatDiag.CohortName='MyCohort'
go

	--  Extract of all DX codes from inpatientFee tables for all potential patients
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9    --altered (ORD_...Dflt)

SELECT 
       Diag.[Sta3n]
      ,Diag.[PatientSID]
	  ,dx_code_type
	  ,ICD9.ICD9Code as ICD9
	  ,v.[ICD9Description]
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
into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[InpatientFeeDiagnosis] as Diag    --altered (ORD_...Src)
inner join CDWWork.Dim.ICD9 as ICD9
on Diag.ICD9SID=ICD9.ICD9SID
inner join cdwwork.dim.ICD9DescriptionVersion AS V
on icd9.ICD9SID=v.ICD9SID
inner join [MyDB].[MySchema].Lung_Sta3n528_0_4_DxICD9CodeExc as TargetCode    --altered (ORD_...Dflt)
on ICD9.ICD9Code=TargetCode.ICD9Code
inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
	[AdmitDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))  and    --altered (ORD_...Dflt)
	[AdmitDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
	and Diag.CohortName='MyCohort'

go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD10    --altered (ORD_...Dflt)

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
into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD10    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[InpatientFeeDiagnosis] as Diag    --altered (ORD_...Src)
inner join CDWWork.Dim.ICD10 as ICD10
on Diag.ICD10SID=ICD10.ICD10SID
inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
on Diag.ICD10SID=ICD10Diag.ICD10SID
inner join [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] as ICD10CodeList    --altered (ORD_...Dflt)
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where 
[AdmitDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))  and    --altered (ORD_...Dflt)
[AdmitDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and Diag.CohortName='MyCohort'

go

--  Extract of all DX codes from FeeService tables for all potential patients
  		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9    --altered (ORD_...Dflt)


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
into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9    --altered (ORD_...Dflt)
FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
inner join CDWWork.Dim.ICD9 as ICD9
on a.ICD9SID=ICD9.ICD9SID
inner join cdwwork.dim.ICD9DescriptionVersion AS V
on icd9.ICD9SID=v.ICD9SID
inner join [MyDB].[MySchema].Lung_Sta3n528_0_4_DxICD9CodeExc as TargetCode    --altered (ORD_...Dflt)
on ICD9.ICD9Code=TargetCode.ICD9Code
inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as c    --altered (ORD_...Dflt)
on a.sta3n=c.sta3n and a.patientsid=c.patientsid
where 
d.InitialTreatmentDateTime>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))  and    --altered (ORD_...Dflt)
d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
and a.CohortName='MyCohort'
and d.CohortName='MyCohort'
go


		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD10]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD10    --altered (ORD_...Dflt)


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
into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD10    --altered (ORD_...Dflt)
  FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
  inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join CDWWork.Dim.ICD10 as ICD10
  on a.ICD10SID=ICD10.ICD10SID
  inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
  on a.ICD10SID=ICD10Diag.ICD10SID
  inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as c    --altered (ORD_...Dflt)
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  inner join [MyDB].[MySchema].[Lung_Sta3n528_0_2_DxICD10CodeExc] as ICD10CodeList    --altered (ORD_...Dflt)
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
  where 
  d.InitialTreatmentDateTime>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)) and    --altered (ORD_...Dflt)
  d.InitialTreatmentDateTime<= DATEADD(dd,120+60,(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
  and a.CohortName='MyCohort'
  and d.CohortName='MyCohort'

go






	--  Extract of all exclusion diagnoses from surgical, inpatient, and outpatient tables
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_AllDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_AllDx_ICD9]    --altered (ORD_...Dflt)
go

select patientSSN,Sta3n,PatientSID,dx_dt,ICD9Code as ICD9,'Surg' as dataSource,dx_code_type
into [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_AllDx_ICD9]    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD9]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,Sta3n,PatientSID,dx_dt,ICDCode as ICD9,'OutPat' as dataSource,dx_code_type
from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,Sta3n,PatientSID,dx_dt,ICDCode as ICD9,'InPat' as dataSource,dx_code_type
from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,Sta3n,PatientSID,dx_dt,ICD9,'Dx-InPatFee' as dataSource,dx_code_type
from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,Sta3n,PatientSID,dx_dt,ICD9,'Dx-InPatFeeService' as dataSource,dx_code_type
from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9]    --altered (ORD_...Dflt)

go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_AllDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_AllDx_ICD10]    --altered (ORD_...Dflt)
go

select patientSSN,sta3n, PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'Dx-Surg' as dataSource
into [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_AllDx_ICD10]    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_1_SurgDx_ICD10]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'DX-OutPat' as dataSource from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_2_OutPatDx_ICD10]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10Code,dx_code_type,'Dx-InPat' as dataSource from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD10]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICDCode,dx_code_type,'Dx-InPatFee' as dataSource from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD10]    --altered (ORD_...Dflt)
	UNION ALL
select patientSSN,sta3n,PatientSID,[InitialTreatmentDateTime] as [dx_dt],[ICD10code],dx_code_type,'Dx-FeeServiceProvided' as dataSource from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD10]    --altered (ORD_...Dflt)

go




if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10    --altered (ORD_...Dflt)
go

select patientSSN,Sta3n,PatientSID,dx_dt,ICD9 as ICDCode,dataSource,dx_code_type
into [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10]    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_AllDx_ICD9]    --altered (ORD_...Dflt)
Union ALL
select patientSSN,Sta3n,PatientSID,dx_dt,ICDCode,dataSource,dx_code_type
from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_AllDx_ICD10]    --altered (ORD_...Dflt)
go


--  Look into ProblemList for Previous ACTIVE lung canccer 
-- ProblemList data is very spotty
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9    --altered (ORD_...Dflt)


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
into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9    --altered (ORD_...Dflt)
FROM [CDWWork].[Outpat].[ProblemList] as ProblemList    --altered (ORD_...Src)
inner join CDWWork.Dim.ICD9 as ICD9
on ProblemList.ICD9SID=ICD9.ICD9SID
inner join cdwwork.dim.ICD9DescriptionVersion AS V
on icd9.ICD9SID=v.ICD9SID
inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
on ProblemList.sta3n=p.sta3n and ProblemList.patientsid=p.patientsid
inner join [MyDB].[MySchema].[Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc] as ICD9CodeList    --altered (ORD_...Dflt)
on ICD9.ICD9Code=ICD9CodeList.ICD9Code
where 
[EnteredDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)) and    --altered (ORD_...Dflt)
[EnteredDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
and ProblemList.CohortName='MyCohort'
and ICD9CodeList.dx_code_type='RecentActiveLungC'



if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD10    --altered (ORD_...Dflt)


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
into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD10    --altered (ORD_...Dflt)
FROM [CDWWork].[outpat].[ProblemList] as ProblemList    --altered (ORD_...Src)
inner join CDWWork.Dim.ICD10 as ICD10
on ProblemList.ICD10SID=ICD10.ICD10SID
inner join cdwwork.dim.ICD10DiagnosisVersion as ICD10Diag
on ProblemList.ICD10SID=ICD10Diag.ICD10SID
inner join [MyDB].[MySchema].[Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc] as ICD10CodeList    --altered (ORD_...Dflt)
on ICD10.ICD10Code=ICD10CodeList.ICD10Code    
inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
on ProblemList.sta3n=p.sta3n and ProblemList.patientsid=p.patientsid
where 
[EnteredDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)) and     --altered (ORD_...Dflt)
[EnteredDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
and ICD10CodeList.dx_code_type='RecentActiveLungC'
and ProblemList.CohortName='MyCohort'
go

if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9ICD10    --altered (ORD_...Dflt)

select patientSSN
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
into [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9ICD10    --altered (ORD_...Dflt)
from [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9    --altered (ORD_...Dflt)
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
from [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD10    --altered (ORD_...Dflt)
go



--Inpatient Procedure from all potential patients
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime]
		,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,ICD9Proc_code_type, pat.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[InpatientICDProcedure] as ICDProc    --altered (ORD_...Src)
inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
	on ICDProc.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
	on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
inner join  [MyDB].[MySchema].Lung_Sta3n528_0_5_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt)
	on DimICD9Proc.ICD9ProcedureCode=TargetCode.ICD9ProcCode
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[Lung_Sta3n528_1_In_8_IncPat]) as pat    --altered (ORD_...Dflt)
	on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
where ICDProc.CohortName='MyCohort'
	and ICDProc.[ICDProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and ICDProc.[ICDProcedureDateTime] <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
go

if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,ICDProc.sta3n,ICDProc.patientsid,ICDProc.[ICDProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[InpatientICDProcedure] as ICDProc    --altered (ORD_...Src)
inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
	on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
	on ICDProc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
inner join [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] as ICD10CodeList    --altered (ORD_...Dflt)
	on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[Lung_Sta3n528_1_In_8_IncPat]) as pat    --altered (ORD_...Dflt)
	on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
where ICDProc.CohortName='MyCohort'
	and ICDProc.[ICDProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and ICDProc.[ICDProcedureDateTime] <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)

go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[ICDProcedureDateTime]
	,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,ICD9Proc_code_type,pat.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[CensusICDProcedure] as a    --altered (ORD_...Src)
inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
	on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
	on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
inner join  [MyDB].[MySchema].Lung_Sta3n528_0_5_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt)
	on DimICD9Proc.ICD9ProcedureCode=TargetCode.ICD9ProcCode
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[Lung_Sta3n528_1_In_8_IncPat]) as pat    --altered (ORD_...Dflt)
	on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
where a.CohortName='MyCohort'															
	and a.[ICDProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and a.[ICDProcedureDateTime] <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)

go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[ICDProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[CensusICDProcedure] as a    --altered (ORD_...Src)
inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
	on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
	on DimICD10Proc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
inner join [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] as ICD10CodeList    --altered (ORD_...Dflt)
	on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[Lung_Sta3n528_1_In_8_IncPat]) as pat    --altered (ORD_...Dflt)
	on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
where 
	a.CohortName='MyCohort'
	and a.[ICDProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and a.[ICDProcedureDateTime] <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)

				
go



if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
	,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,ICD9Proc_code_type,pat.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[InpatientSurgicalProcedure] as a    --altered (ORD_...Src)
inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
	on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
		on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
inner join  [MyDB].[MySchema].Lung_Sta3n528_0_5_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt)
on DimICD9Proc.ICD9ProcedureCode=TargetCode.ICD9ProcCode
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[Lung_Sta3n528_1_In_8_IncPat]) as pat    --altered (ORD_...Dflt)
	on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
where  a.CohortName='MyCohort'
	and a.SurgicalProcedureDateTime >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and a.SurgicalProcedureDateTime <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[InpatientSurgicalProcedure] as a    --altered (ORD_...Src)
inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
	on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
	on DimICD10Proc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
inner join [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] as ICD10CodeList    --altered (ORD_...Dflt)
	on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[Lung_Sta3n528_1_In_8_IncPat]) as pat    --altered (ORD_...Dflt)
	on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
where a.CohortName='MyCohort'
	and a.SurgicalProcedureDateTime >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and a.SurgicalProcedureDateTime <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc    --altered (ORD_...Dflt)

      
select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
	,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,ICD9Proc_code_type,pat.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[CensusSurgicalProcedure] as a    --altered (ORD_...Src)
inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
	on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
	on DimICD9Proc.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
inner join  [MyDB].[MySchema].Lung_Sta3n528_0_5_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt)
	on DimICD9Proc.ICD9ProcedureCode=TargetCode.ICD9ProcCode
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[Lung_Sta3n528_1_In_8_IncPat]) as pat    --altered (ORD_...Dflt)
	on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
where a.CohortName='MyCohort'
	and a.SurgicalProcedureDateTime >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and a.SurgicalProcedureDateTime <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)

go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
drop table  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc    --altered (ORD_...Dflt)

      
select pat.patientssn,pat.scrssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime],ICD10CodeList.ICD10Proc_Code_Type
	,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[CensusSurgicalProcedure] as a    --altered (ORD_...Src)
inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
	on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
	on DimICD10Proc.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
inner join [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] as ICD10CodeList    --altered (ORD_...Dflt)
	on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[Lung_Sta3n528_1_In_8_IncPat]) as pat    --altered (ORD_...Dflt)
	on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
where a.CohortName='MyCohort'
	and a.SurgicalProcedureDateTime >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and a.SurgicalProcedureDateTime <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)

go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc]') is not null)    --altered (ORD_...Dflt)
	drop table  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc	    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,a.sta3n,b.patientsid,b.[TreatmentFromDateTime],b.InvoiceReceivedDateTime
	,DimICD9Proc.[ICD9ProcedureCode],DimICD9ProcDescription.ICD9ProcedureDescription,ICD9Proc_code_type,pat.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
-- the statistics of the tables can effect the query time
from [CDWWork].[Fee].[FeeInpatInvoice] as b    --altered (ORD_...Src)
inner join [CDWWork].[Fee].[FeeInpatInvoiceICDProcedure] as a    --altered (ORD_...Src)
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
inner join cdwwork.dim.ICD9Procedure as DimICD9Proc
	on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
inner join cdwwork.dim.ICD9ProcedureDescriptionVersion as DimICD9ProcDescription
	on a.[ICD9ProcedureSID]=DimICD9ProcDescription.[ICD9ProcedureSID]
inner join  [MyDB].[MySchema].Lung_Sta3n528_0_5_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt)
	on DimICD9Proc.ICD9ProcedureCode=TargetCode.ICD9ProcCode
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat) as pat    --altered (ORD_...Dflt)
	on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
where  a.CohortName='MyCohort'
	and b.CohortName='MyCohort'
--and b.[TreatmentFromDateTime] 
-- cluster index
	and b.InvoiceReceivedDateTime>= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and b.InvoiceReceivedDateTime <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)

go

if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
	drop table  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,a.sta3n,b.patientsid,b.[TreatmentFromDateTime],ICD10CodeList.ICD10Proc_Code_Type
	,DimICD10Proc.[ICD10ProcedureCode],DimICD10ProcDescription.ICD10ProcedureDescription,pat.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
-- the statistics of the tables can effect the query time
from [CDWWork].[Fee].[FeeInpatInvoice] as b    --altered (ORD_...Src)
inner join [CDWWork].[Fee].[FeeInpatInvoiceICDProcedure] as a    --altered (ORD_...Src)
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
inner join cdwwork.dim.ICD10Procedure as DimICD10Proc
	on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
inner join cdwwork.dim.ICD10ProcedureDescriptionVersion as DimICD10ProcDescription
	on a.[ICD10ProcedureSID]=DimICD10ProcDescription.[ICD10ProcedureSID]
inner join [MyDB].[MySchema].[Lung_Sta3n528_0_3_PreProcICD10ProcExc] as ICD10CodeList    --altered (ORD_...Dflt)
	on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode    
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat) as pat    --altered (ORD_...Dflt)
	on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
where a.CohortName='MyCohort'
and b.CohortName='MyCohort'
--and b.[TreatmentFromDateTime] 
-- cluster index
and b.InvoiceReceivedDateTime >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
and b.InvoiceReceivedDateTime <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)

go

-- ICD9Proc from all potential patients
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc    --altered (ORD_...Dflt)
	
select patientssn
	,[sta3n]
	,[patientsid]
	,[ICDProcedureDateTime] as Proc_dt
	,[ICD9ProcedureCode]
	,ICD9ProcedureDescription
	,'Inp-InpICD'	  as datasource
	,ICD9Proc_code_type
into  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
union 
select patientssn
	,[sta3n]
	,[patientsid]
	,[ICDProcedureDateTime] as Proc_dt
	,[ICD9ProcedureCode]
	,ICD9ProcedureDescription
	,'Inp-CensusICD'	  as datasource
	,ICD9Proc_code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
union
	select patientssn
	,[sta3n]
	,[patientsid]
	,[SurgicalProcedureDateTime] as Proc_dt
	,[ICD9ProcedureCode]
	,ICD9ProcedureDescription      
	,'Inp-InpSurg'	  as datasource
	,ICD9Proc_code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
union
	select patientssn
	,[sta3n]
	,[patientsid]
	,[SurgicalProcedureDateTime] as Proc_dt
	,[ICD9ProcedureCode]
	,ICD9ProcedureDescription
	,'Inp-CensusSurg'	  as datasource
	,ICD9Proc_code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
union
	select patientssn
	,[sta3n]
	,[patientsid]
	,[TreatmentFromDateTime] as Proc_dt
	,[ICD9ProcedureCode]
	,ICD9ProcedureDescription      
	,'Inp-FeeICDProc'	  as datasource
	,ICD9Proc_code_type
from [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
go
	

-- ICD10Proc from all potential patients
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc    --altered (ORD_...Dflt)
	
select patientssn
	,[sta3n]
	,[patientsid]
	,[ICDProcedureDateTime] as Proc_dt
	,[ICD10ProcedureCode]
	,ICD10ProcedureDescription
	,ICD10Proc_Code_Type
	,'Inp-InpICD'	  as datasource
into  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
union 
	select patientssn
	,[sta3n]
	,[patientsid]
	,[ICDProcedureDateTime] as Proc_dt
	,[ICD10ProcedureCode]
	,ICD10ProcedureDescription
	,ICD10Proc_Code_Type
	,'Inp-CensusICD'	  as datasource
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
union
	select patientssn
	,[sta3n]
	,[patientsid]
	,[SurgicalProcedureDateTime] as Proc_dt
	,[ICD10ProcedureCode]
	,ICD10ProcedureDescription      
	,ICD10Proc_Code_Type
	,'Inp-InpSurg'	  as datasource
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
union
	select patientssn
	,[sta3n]
	,[patientsid]
	,[SurgicalProcedureDateTime] as Proc_dt
	,[ICD10ProcedureCode]
	,ICD10ProcedureDescription
	,ICD10Proc_Code_Type
	,'Inp-CensusSurg'	  as datasource
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
union
	select patientssn
	,[sta3n]
	,[patientsid]
	,[TreatmentFromDateTime] as Proc_dt
	,[ICD10ProcedureCode]
	,ICD10ProcedureDescription  
	,ICD10Proc_Code_Type    
	,'Inp-FeeICDProc'	  as datasource
from [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
go


-- Inpatien CPT procedure
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt)

select pat.patientssn,pat.scrssn,CPTProc.sta3n,CPTProc.patientsid,CPTProc.[CPTProcedureDateTime]
	,DimCPT.[CPTCode],DimCPT.CPTName,DimCPT.CPTDescription ,CPT_code_type, patientICN
into  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[InpatientCPTProcedure] as CPTProc    --altered (ORD_...Src)
inner join cdwwork.dim.CPT as DimCPT
	on CPTProc.[CPTSID]=DimCPT.CPTSID  
inner join 
	(select CPT_code_type,CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
	union
	select img_code_type,ImgCode as CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg    --altered (ORD_...Dflt)
	) as TargetCode
	on DimCPT.CPTCode=TargetCode.CPTCode
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[Lung_Sta3n528_1_In_8_IncPat]) as pat    --altered (ORD_...Dflt)
	on CPTProc.patientsid=pat.patientsid and CPTProc.sta3n=pat.sta3n
where  CPTProc.CohortName='MyCohort'
	and CPTProc.[CPTProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and CPTProc.[CPTProcedureDateTime] <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
go



-- Outpatient CPT procedure
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt)
		
SELECT 
	p.patientSSN,
	VProc.[Sta3n]
	,VProc.[CPTSID]
	,dimCPT.[CPTCode]
	,CPT_code_type
	,DimCPT.[CPTName]
	,VProc.[PatientSID]
	,VProc.[VisitSID]
	,VProc.[VisitDateTime]
	,VProc.[VProcedureDateTime]
	,VProc.[CPRSOrderSID]
	,p.ScrSSN,p.patientICN
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt)
FROM [CDWWork].[Outpat].[VProcedure] as VProc    --altered (ORD_...Src)
inner join CDWWork.[Dim].[CPT] as DimCPT 
	on  VProc.[CPTSID]=DimCPT.CPTSID
inner join 
	(select CPT_code_type,CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
	union
	select img_code_type,ImgCode as CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg    --altered (ORD_...Dflt)
	) as TargetCode
	on DimCPT.CPTCode=TargetCode.CPTCode
inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
	on VProc.sta3n=p.sta3n and VProc.patientsid=p.patientsid
where 
	VProc.CohortName='MyCohort'
	and [VProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	and [VProcedureDateTime] <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
go

-- Surgical CPT procedures
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg_Hlp1]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg_Hlp1    --altered (ORD_...Dflt)
	

SELECT 
	  surgPre.[SurgerySID] as SurgPre_SurgerySID
	  ,surgDx.[SurgerySID]  as SurgDx_SurgerySID
      ,surgPre.[Sta3n]
      ,[VisitSID]
      ,SurgPre.[PatientSID]
      ,[CancelDateTime]

      ,surgPre.[SurgeryDateTime]  as [DateOfOperation]

	  ,PrincipalCPT.CPTCode as PrincipalProcedureCode
	  ,PrincipalCPT.CPTDescription as PrincipalProcedureDescription
	  ,OtherCPT.CPTCode as OtherProcedureCode
	  ,OtherCPT.CPTDescription as OtherProcedureDescription

	  ,(case when PrincipalCPT.CPTCode in (select CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
											union
											select ImgCode as CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg)    --altered (ORD_...Dflt)
			then PrincipalCPT.CPTCode
            when OtherCPT.CPTCode in  (select CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
											union
											select ImgCode as CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg)    --altered (ORD_...Dflt)
	   	    then OtherCPT.CPTCode
	        else null
	   end ) as CPTCode    
	  ,p.patientSSN
	  ,p.ScrSSN
	  ,p.patientICN	 
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg_Hlp1    --altered (ORD_...Dflt)
FROM [CDWWork].[Surg].[SurgeryPre] as surgPre    --altered (ORD_...Src)
  inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
  on SurgPre.sta3n=p.sta3n and SurgPre.patientsid=p.patientsid
  left join[CDWWork].[Surg].[SurgeryProcedureDiagnosisCode]as surgDx    --altered (ORD_...Src)
  on surgPre.SurgerySID=SurgDx.SurgerySID and surgPre.sta3n=SurgDx.sta3n
  left join CDWWork.dim.CPT as PrincipalCPT
  on SurgDx.PrincipalCPTSID=PrincipalCPT.CPTSID and SurgDx.Sta3n=PrincipalCPT.Sta3n
  left join [CDWWork].[Surg].[SurgeryPrincipalAssociatedProcedure] as assocProc    --altered (ORD_...Src)
  on  surgDx.SurgeryProcedureDiagnosisCodeSID=assocProc.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=assocProc.sta3n
  left join CDWWork.dim.CPT as OtherCPT
  on assocProc.OtherProcedureCPTSID=OtherCPT.CPTSID and assocProc.sta3n=OtherCPT.sta3n 
   where  
    SurgPre.[SurgeryDateTime] >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
  and SurgPre.[SurgeryDateTime] <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)

  and  SurgPre.CohortName='MyCohort'
  and  surgDx.CohortName='MyCohort'
  and  assocProc.CohortName='MyCohort'
  and (
		  PrincipalCPT.CPTCode in 
		  (select CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
			union
			select ImgCode as CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg)					     --altered (ORD_...Dflt)
		  or OtherCPT.CPTCode in
		  (select CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
			union
			select ImgCode as CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg)					     --altered (ORD_...Dflt)
		)
go

if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg    --altered (ORD_...Dflt)
	
	select a.*,CPT_code_type
	into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt)
	from [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg_Hlp1 as a    --altered (ORD_...Dflt)
	inner join (
			select CPT_code_type,CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
			union
			select img_code_type as CPT_code_type,imgCode as CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg     --altered (ORD_...Dflt)
		     ) as b
	on a.cptcode=b.CPTCode
go

 --Fee CPT procedure
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt)
							 
SELECT  
	Pat.patientssn
	,d.InitialTreatmentDateTime
	,a.[PatientSID]
	,a.[Sta3n]
	,[ServiceProvidedCPTSID]
	,[AmountClaimed]
	,[AmountPaid]
	,DimCPT.CPTCode,DimCPT.CPTName
	,CPT_code_type
into [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt)
FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
	on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
inner join cdwwork.dim.CPT as DimCPT
	on a.[ServiceProvidedCPTSID]=DimCPT.[CPTSID]  
inner join 
(select CPT_code_type,CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
union
select img_code_type,ImgCode as CPTCode from  [MyDB].[MySchema].Lung_Sta3n528_0_2_0_LungImg    --altered (ORD_...Dflt)
) as TargetCode
	on DimCPT.CPTCode=TargetCode.CPTCode
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat) as pat    --altered (ORD_...Dflt)
	on a.sta3n=pat.sta3n and a.patientsid=pat.patientsid
where a.CohortName='MyCohort'  and d.CohortName='MyCohort'
  and   InitialTreatmentDateTime >= DateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
  and InitialTreatmentDateTime <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
go	
											
	
-- LungBiopsy procedure
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy    --altered (ORD_...Dflt)


select patientSSN,sta3n,patientSID,[Proc_dt] as LungBiopsy_dt,'LungBiopsy-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD','LungBiopsy' as code_type
into  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc]    --altered (ORD_...Dflt)
		where [Proc_dt] is not null 
		and ICD9Proc_code_type='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[Proc_dt] as LungBiopsy_dt,'LungBiopsy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD','LungBiopsy' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc]    --altered (ORD_...Dflt)
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as LungBiopsy_dt,'LungBiopsy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','LungBiopsy' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]    --altered (ORD_...Dflt)
		where [CPTProcedureDateTime] is not null 
		and CPT_code_type='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as LungBiopsy_dt ,'LungBiopsy-OutPat' as datasource,[CPTCode] as 'CPTOrICD','LungBiopsy' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat]    --altered (ORD_...Dflt)
		where [VProcedureDateTime] is not null
		and CPT_code_type='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[DateOfOperation] as LungBiopsy_dt,'LungBiopsy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','LungBiopsy' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg]    --altered (ORD_...Dflt)
		where [DateOfOperation] is not null
		and CPT_code_type='LungBiopsy'
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as LungBiopsy_dt,'LungBiopsy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','LungBiopsy' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]    --altered (ORD_...Dflt)
		where InitialTreatmentDateTime is not null
		and CPT_code_type='LungBiopsy'
go


-- Bronchoscopy procedure
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy    --altered (ORD_...Dflt)

select patientSSN,sta3n,patientSID,[Proc_dt] as Bronchoscopy_dt,'Bronchoscopy-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD','Bronchoscopy' as code_type
into  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc]    --altered (ORD_...Dflt)
		where [Proc_dt] is not null
		and ICD9Proc_code_type='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[Proc_dt] as Bronchoscopy_dt,'Bronchoscopy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD','Bronchoscopy' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc]    --altered (ORD_...Dflt)
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as Bronchoscopy_dt,'Bronchoscopy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','Bronchoscopy' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]    --altered (ORD_...Dflt)
		where [CPTProcedureDateTime] is not null
		and CPT_code_type='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as Bronchoscopy_dt ,'Bronchoscopy-OutPat' as datasource,[CPTCode] as 'CPTOrICD','Bronchoscopy' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat]    --altered (ORD_...Dflt)
		where [VProcedureDateTime] is not null
		and CPT_code_type='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[DateOfOperation] as Bronchoscopy_dt,'Bronchoscopy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','Bronchoscopy' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg]    --altered (ORD_...Dflt)
		where [DateOfOperation] is not null
		and CPT_code_type='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as Bronchoscopy_dt,'Bronchoscopy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','Bronchoscopy' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]    --altered (ORD_...Dflt)
		where InitialTreatmentDateTime is not null
		and CPT_code_type='Bronchoscopy'
go


--Lung Surgery
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery    --altered (ORD_...Dflt)


select patientSSN,sta3n,patientSID,[Proc_dt] as LungSurgery_dt,'LungSurgery-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD','LungSurgery' as code_type
into  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc]    --altered (ORD_...Dflt)
		where [Proc_dt] is not null
		and ICD9Proc_code_type='LungSurgery'   
union
select patientSSN,sta3n,patientSID,[Proc_dt] as LungSurgery_dt,'LungSurgery-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD','LungSurgery' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc]    --altered (ORD_...Dflt)
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='LungSurgery'
union
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as LungSurgery_dt,'LungSurgery-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','LungSurgery' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]    --altered (ORD_...Dflt)
		where [CPTProcedureDateTime] is not null
		and CPT_code_type='LungSurgery'   								 			
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as LungSurgery_dt ,'LungSurgery-OutPat' as datasource,[CPTCode] as 'CPTOrICD','LungSurgery' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat]    --altered (ORD_...Dflt)
		where [VProcedureDateTime] is not null
		and CPT_code_type='LungSurgery'
union
select patientSSN,sta3n,patientSID,[DateOfOperation] as LungSurgery_dt,'LungSurgery-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','LungSurgery' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg]    --altered (ORD_...Dflt)
		where [DateOfOperation] is not null
		and CPT_code_type='LungSurgery'
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as LungSurgery_dt,'LungSurgery-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','LungSurgery' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]    --altered (ORD_...Dflt)
		where InitialTreatmentDateTime is not null
		and CPT_code_type='LungSurgery'
go


-- Chest XRay
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_E_PrevProc_AllNonDxProcICD9ICD10Proc_XRay]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_E_PrevProc_AllNonDxProcICD9ICD10Proc_XRay    --altered (ORD_...Dflt)


select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as img_dt,'XRAY-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','XRay' as code_type
into  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_E_PrevProc_AllNonDxProcICD9ICD10Proc_XRay    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]    --altered (ORD_...Dflt)
		where [CPTProcedureDateTime] is not null
		and CPT_code_type ='XRay'
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as Img_dt ,'XRAY-OutPat' as datasource,[CPTCode] as 'CPTOrICD','XRay' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat]    --altered (ORD_...Dflt)
		where [VProcedureDateTime] is not null
		and CPT_code_type ='XRay'
union
select patientSSN,sta3n,patientSID,[DateOfOperation] as Img_dt,'XRAY-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','XRay' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg]    --altered (ORD_...Dflt)
		where [DateOfOperation] is not null
		and CPT_code_type ='XRay'
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as Img_dt,'XRAY-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','XRay' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]    --altered (ORD_...Dflt)
		where InitialTreatmentDateTime is not null
		and CPT_code_type ='XRay'

go

--Chest CT
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_F_PrevProc_AllNonDxProcICD9ICD10Proc_CT]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_F_PrevProc_AllNonDxProcICD9ICD10Proc_CT    --altered (ORD_...Dflt)


select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as img_dt,'CT-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','CT' as code_type
into  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_F_PrevProc_AllNonDxProcICD9ICD10Proc_CT    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]    --altered (ORD_...Dflt)
		where [CPTProcedureDateTime] is not null
		and CPT_code_type ='CT'
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as Img_dt ,'CT-OutPat' as datasource,[CPTCode] as 'CPTOrICD','CT' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat]    --altered (ORD_...Dflt)
		where [VProcedureDateTime] is not null
		and CPT_code_type ='CT'
union
select patientSSN,sta3n,patientSID,[DateOfOperation] as Img_dt,'CT-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','CT' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg]    --altered (ORD_...Dflt)
		where [DateOfOperation] is not null
		and CPT_code_type ='CT'
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as Img_dt,'CT-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','CT' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]    --altered (ORD_...Dflt)
		where InitialTreatmentDateTime is not null
		and CPT_code_type ='CT'
go

--Chest PET
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_G_PrevProc_AllNonDxProcICD9ICD10Proc_PET]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_G_PrevProc_AllNonDxProcICD9ICD10Proc_PET    --altered (ORD_...Dflt)


select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as img_dt,'PET-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','PET' as code_type
into  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_G_PrevProc_AllNonDxProcICD9ICD10Proc_PET    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT]    --altered (ORD_...Dflt)
		where [CPTProcedureDateTime] is not null
		and CPT_code_type ='PET'
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as Img_dt ,'PET-OutPat' as datasource,[CPTCode] as 'CPTOrICD','PET' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat]    --altered (ORD_...Dflt)
		where [VProcedureDateTime] is not null
		and CPT_code_type ='PET'
union
select patientSSN,sta3n,patientSID,[DateOfOperation] as Img_dt,'PET-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','PET' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg]    --altered (ORD_...Dflt)
		where [DateOfOperation] is not null
		and CPT_code_type ='PET'
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as Img_dt,'PET-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','PET' as code_type
from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT]    --altered (ORD_...Dflt)
		where InitialTreatmentDateTime is not null
		and CPT_code_type ='PET'
go


-- Visit,referral and physician's note from potential patient

if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1    --altered (ORD_...Dflt)
					
select p.patientSSN
	,V.Sta3n,V.PatientSID,V.Visitsid,V.VisitDatetime,V.primaryStopcodeSID,V.SecondaryStopcodeSID					
into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1					    --altered (ORD_...Dflt)
from [CDWWork].[Outpat].[Visit] as V    --altered (ORD_...Src)
inner join 
	(select distinct pat.*,ins.ExamDateTime 
		from [MyDB].[MySchema].[Lung_Sta3n528_1_In_8_IncPat] as pat    --altered (ORD_...Dflt)
		left join [MyDB].[MySchema].Lung_Sta3n528_1_In_6_IncIns as ins    --altered (ORD_...Dflt)
		on pat.patientSSN=ins.PatientSSN 
	) as p 
	on v.sta3n=p.sta3n and v.patientsid=p.patientsid 
	and v.VisitDateTime between dateAdd(yy,-1,p.ExamDateTime)
					and DateAdd(dd,60,p.ExamDateTime)
where 	CohortName='MyCohort'	and	
	V.VisitDateTime between dateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
						and DateAdd(dd,60,(select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP))						      --altered (ORD_...Dflt)
go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits    --altered (ORD_...Dflt)

   select PatientSSN,VisitSID,VisitDateTime,PrimaryStopCodeSID,SecondaryStopCodeSID
   into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits    --altered (ORD_...Dflt)
   from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1    --altered (ORD_...Dflt)
   union
   select PatientSSN,VisitSID,VisitDateTime,PrimaryStopCodeSID,SecondaryStopCodeSID
   from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1    --altered (ORD_...Dflt)
go


if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits_StopCode]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits_StopCode    --altered (ORD_...Dflt)
					
	select v.*,code1.stopcode as PrimaryStopCode,code1.stopcodename as PrimaryStopCodeName
			,code2.stopcode as SecondaryStopCode,code2.stopcodename as SecondaryStopCodeName
	into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits_StopCode    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits as V    --altered (ORD_...Dflt)
	left join [CDWWork].[Dim].[StopCode] as code1
	on V.PrimaryStopCodeSID=code1.StopCodeSID		
	left join [CDWWork].[Dim].[StopCode] as code2
	on V.SecondaryStopCodeSID=code2.StopCodeSID

go

--Physician's notes from the visit
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_2_VisitTIU') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_2_VisitTIU    --altered (ORD_...Dflt)


	select v.*
	,T.[TIUDocumentSID],T.[EntryDateTime],T.[ReferenceDateTime]
	,e.tiustandardtitle,T.ConsultSID
	into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_2_VisitTIU				    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits_StopCode as V    --altered (ORD_...Dflt)
	left join [CDWWork].[TIU].[TIUDocument_8925] as T    --altered (ORD_...Src)
	on T.VisitSID=V.Visitsid and T.CohortName='MyCohort'
	left join cdwwork.dim.[TIUDocumentDefinition] as d                                         
	on t.[TIUDocumentDefinitionSID]=d.[TIUDocumentDefinitionSID]
	left join cdwwork.dim.TIUStandardTitle as e
	on d.TIUStandardTitleSID=e.TIUStandardTitleSID
	--where isnull(T.OpCode,'')<>'D'

				
go

-- Referrals
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID    --altered (ORD_...Dflt)

			select v.*
			,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
			c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName,
			c.placeofconsultation,	  
			c.requestType, -- weather the request is a consult or procedure
			c.[InpatOutpat], -- the ordering person to indicate if the service is to be rendered on an outpatient or Inpatients basis.
			c.[RemoteService]
			into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID				    --altered (ORD_...Dflt)
            from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_2_VisitTIU as V    --altered (ORD_...Dflt)
			left join [CDWWork].[Con].[Consult] as C										                        --altered (ORD_...Src)
			on C.ConsultSID=V.ConsultSID and CohortName='MyCohort'			
go

--------------------------------------------------------------------------------------------------------------------------------
-----  4. Exclude red-flagged patients with certain clinical diagnosis and other 
--------------------------------------------------------------------------------------------------------------------------------

--  Red-flagged instances: Exclude patients <18 years old 
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_3_Ins_0_1_In_4_Age') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_0_1_In_4_Age    --altered (ORD_...Dflt)
select Rad.* 
into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_0_1_In_4_Age    --altered (ORD_...Dflt)
from [MyDB].[MySchema].Lung_Sta3n528_1_In_6_IncIns as Rad    --altered (ORD_...Dflt)
where (DATEDIFF(yy,DOB,Rad.[ExamDateTime]) >= (select age from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
		 or patientssn is null 
         )  

go

--  Red-flagged instances: Exclude deseased patients
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_3_Ins_0_2_In_5_Alive') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_0_2_In_5_Alive    --altered (ORD_...Dflt)

select age.* into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_0_2_In_5_Alive    --altered (ORD_...Dflt)
 from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_0_1_In_4_Age as age      --altered (ORD_...Dflt)
 where 
        [DOD] is null 		
		or (DOD is not null 
				and ( 
					DATEADD(dd,-(select fu_period from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP),dod)>age.ExamDateTime    --altered (ORD_...Dflt)
					)
				)	   	     
go
	
--  Red-flagged instances: Exclude patients with previous lung cancer
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_1_Ex_LungCancer]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_1_Ex_LungCancer    --altered (ORD_...Dflt)
go

select a.*
into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_1_Ex_LungCancer    --altered (ORD_...Dflt)
from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_0_2_In_5_Alive as a    --altered (ORD_...Dflt)
where not exists
	(select * from [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9ICD10 as b    --altered (ORD_...Dflt)
		where a.[PatientSSN] = b.[PatientSSN]
		and (b.[EnteredDate] between DATEADD(yy,-1,a.[ExamDateTime]) and a.[ExamDateTime]))			 
go
			 
	
--  Red-flagged instances: Exclude patients with terminal/major DX		
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_2_Ex_Termi_Major]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].[Lung_Sta3n528_3_Ins_2_Ex_Termi_Major]    --altered (ORD_...Dflt)
		go

		select *
		into [MyDB].[MySchema].[Lung_Sta3n528_3_Ins_2_Ex_Termi_Major]    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_1_Ex_LungCancer as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10] as b    --altered (ORD_...Dflt)
				where a.[PatientSSN] = b.[PatientSSN] and b.dx_code_type='Terminal' and 
			 (b.dx_dt between DATEADD(yy,-1,a.[ExamDateTime]) and DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP]),a.[ExamDateTime])))    --altered (ORD_...Dflt)
		go
		

 --  Red-flagged instances: Exclude patients with hospice/palliative diagnosis
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx    --altered (ORD_...Dflt)
		go

		select *
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].[Lung_Sta3n528_3_Ins_2_Ex_Termi_Major] as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN] and b.dx_code_type='Hospice'  and 
			 b.dx_dt between DATEADD(yy,-1,a.[ExamDateTime] ) and 
			 DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP]),a.[ExamDateTime]))		    --altered (ORD_...Dflt)
		go

--  Red-flagged instances: Exclude patients with hospice/palliative care
				if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee    --altered (ORD_...Dflt)
		go


		select * 
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx as x    --altered (ORD_...Dflt)
		where not exists(
		select  b.FeePurposeOfVisit,a.* 
		from [CDWWork].[Fee].[FeeInpatInvoice] as a    --altered (ORD_...Src)
		inner join cdwwork.dim.FeePurposeOfVisit as b
		on a.FeePurposeOfVisitSID=b.FeePurposeOfVisitSID
		inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where a.CohortName='MyCohort' and
		b.AustinCode in ('43','77','78')  
		and x.patientSSN=p.patientsSN and a.TreatmentFromDateTime 
		between DATEADD(yy,-1,x.[ExamDateTime]) and 
					  DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP]),X.[ExamDateTime])    --altered (ORD_...Dflt)
		)
		go

--  Red-flagged instances: Exclude patients with Inpatient hospice/palliative care
	if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_ByPTF]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_ByPTF    --altered (ORD_...Dflt)
		go

        select b.*
		into [MyDB].[MySchema].[Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_ByPTF]    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee as b    --altered (ORD_...Dflt)
		where not exists(
		select * FROM [CDWWork].[Inpat].[Inpatient] as a    --altered (ORD_...Src)
		inner join CDWWork.Dim.Specialty as s
		on a.DischargeFromSpecialtySID=s.SpecialtySID and a.sta3n=s.sta3n 
		inner join [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt)
        on a.sta3n=p.sta3n and a.patientsid=p.patientsid
		where a.CohortName='MyCohort'
		and ltrim(rtrim(s.PTFCode)) in ('96','1F') 
		and b.patientSSN=p.patientsSN and a.[DischargeDateTime] 
		between DATEADD(yy,-1,b.ExamDateTime) and 
					  DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP]),b.ExamDateTime)    --altered (ORD_...Dflt)

		)
		go

		
--  Red-flagged instances: Exclude patients with hospice/palliative referral
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID    --altered (ORD_...Dflt)
													 
				
		select *
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID    --altered (ORD_...Dflt)
        from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_ByPTF as a    --altered (ORD_...Dflt)
		where not exists
			(	select * from [MyDB].[MySchema].[Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID] as b    --altered (ORD_...Dflt)
				 where (
						 --With Stopcode
						   b.[primaryStopcode] in (351,353) or b.[secondaryStopcode] in (351,353)   --Hospice
						 -- There is a visit, but the StopCode is missing
							or (
							b.[ConsultToRequestserviceName] like '%Hospice%' or b.[ConsultToRequestserviceName] like '%palliative%'
							or b.TIUStandardTitle like '%Hospice%' or b.TIUStandardTitle like '%palliative%'
							))				
				 and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				 and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
				 and a.patientSSN = b.patientSSN
				 and (coalesce(b.ReferenceDateTime,b.visitdatetime) between DATEADD(yy,-1, convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP]), convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))    --altered (ORD_...Dflt)
				 and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
					  ) 
			)

go

--  Red-flagged instances: Exclude patients with tuberculosis diagnosis
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_4_Ex_Tuber]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_4_Ex_Tuber    --altered (ORD_...Dflt)
		go

				select *
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_4_Ex_Tuber    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN] and b.dx_code_type='Tuberculosis' and
			 			 (b.dx_dt between DATEADD(yy,-1,a.[ExamDateTime]) and
			  DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP]),a.[ExamDateTime]))    --altered (ORD_...Dflt)
			 )
		
		go
	
--------------------------------------------------------------------------------------------------------------------------------
-----  5. Exclude red-flagged patients with timely follow up
--------------------------------------------------------------------------------------------------------------------------------
		
--  Red-flagged instances: Exclude patients with LungBiopsy completed
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy    --altered (ORD_...Dflt)
	
		select *
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_4_Ex_Tuber as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy] as b    --altered (ORD_...Dflt)
			 where a.patientSSN = b.PatientSSN and
			 b.LungBiopsy_dt between DATEADD(dd,-(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
											,convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00' as datetime)) 
						and DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
											,convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59:997' as datetime)))

go

--  Red-flagged instances: Exclude patients with Bronchoscopy completed
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy    --altered (ORD_...Dflt)
	
		select *
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy] as b    --altered (ORD_...Dflt)
			 where a.patientSSN = b.PatientSSN and
			 b.Bronchoscopy_dt between DATEADD(dd,-(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
											,convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00' as datetime)) 
						and DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
											,convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59:997' as datetime)))
		go
		
--  Red-flagged instances: Exclude patients with Lung Surgery completed
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery    --altered (ORD_...Dflt)
	
		select *
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[Lung_Sta3n528_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery] as b    --altered (ORD_...Dflt)
			 where a.patientSSN = b.PatientSSN and
			 b.LungSurgery_dt between DATEADD(dd,-(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
											,convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00' as datetime)) 
						and DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
											,convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59:997' as datetime)))

		go

	

--  Red-flagged instances: Exclude patients with follow up chest XRay completed
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_A_XRay]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_A_XRay    --altered (ORD_...Dflt)

					select a.*
		into  [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_A_XRay    --altered (ORD_...Dflt)
		from  [MyDB].[MySchema].[Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery] as a    --altered (ORD_...Dflt)
		where not exists
			(select * from (select PatientSSN,ExamDateTime,img_code_type from [MyDB].[MySchema].[Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN]     --altered (ORD_...Dflt)
						where [img_code_type]='XRay'
					 union  select patientssn, img_dt as ExamDateTime,code_type as img_code_type from  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_E_PrevProc_AllNonDxProcICD9ICD10Proc_XRay    --altered (ORD_...Dflt)
						   where code_type='XRAY'
			   ) as b
			 where a.PatientSSN = b.patientSSN and			 
			 (b.ExamDateTime > a.examDateTime
					and	b.ExamDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
														,(convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime))))
			 and b.[img_code_type]='XRay'
			 )			 
go

--  Red-flagged instances: Exclude patients with follow up chest CT completed
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_B_CT]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_B_CT    --altered (ORD_...Dflt)

					select a.*
		into  [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_B_CT    --altered (ORD_...Dflt)
		from  [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_A_XRay as a    --altered (ORD_...Dflt)
		where not exists
				(select * from (select PatientSSN,ExamDateTime,img_code_type from [MyDB].[MySchema].[Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN]     --altered (ORD_...Dflt)
				       where [img_code_type]='CT'
					 union  select patientssn, img_dt as ExamDateTime,code_type as img_code_type from  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_F_PrevProc_AllNonDxProcICD9ICD10Proc_CT    --altered (ORD_...Dflt)
						   where code_type='CT'
			   ) as b
			 where a.PatientSSN = b.patientSSN and			 
			 (b.ExamDateTime > a.ExamDateTime
					and	b.ExamDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
														,(convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime))))
			 and b.[img_code_type]='CT'
			 )			 
go

--  Red-flagged instances: Exclude patients with follow up chest PET completed
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_C_PET]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_C_PET    --altered (ORD_...Dflt)

					select a.*
		into  [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_C_PET    --altered (ORD_...Dflt)
		from  [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_B_CT as a    --altered (ORD_...Dflt)
		where not exists
				(select * from (select PatientSSN,ExamDateTime,img_code_type from [MyDB].[MySchema].[Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN]     --altered (ORD_...Dflt)
				where [img_code_type]='PET'
					 union  select patientssn, img_dt as ExamDateTime,code_type as img_code_type from  [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_G_PrevProc_AllNonDxProcICD9ICD10Proc_PET    --altered (ORD_...Dflt)
						   where code_type='PET'
			   ) as b
			 where a.PatientSSN = b.patientSSN and			 
			 (b.ExamDateTime > a.ExamDateTime
					and	b.ExamDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
														,(convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime))))
			 and b.[img_code_type]='PET'
			 )			 
go

	
--  Red-flagged instances: Exclude patients with pulm consult completed
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID    --altered (ORD_...Dflt)
				
		select *
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID    --altered (ORD_...Dflt)
        from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_C_PET as a		    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID] as b    --altered (ORD_...Dflt)
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (312,104)   or b.SecondaryStopCode in (312,104)   
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
				and a.patientSSN = b.patientSSN
				and (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00.000' as datetime)) and 
					DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
							, convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))
			    and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
					))
						
go


--  Red-flagged instances: Exclude patients with THORACIC SURGERY consult completed
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID    --altered (ORD_...Dflt)
				
		select *
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID    --altered (ORD_...Dflt)
        from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID] as b    --altered (ORD_...Dflt)
			 where (
					 --With Stopcode
					b.[primaryStopcode] in (413,64) or b.[SecondaryStopcode] in (413,64)   
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
					and a.patientSSN = b.patientSSN 
					and (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00.000' as datetime)) and 
					DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
									, convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))
					and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
						-- make sure not 2 or 3 years off
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
					  ))						

go


--  Red-flagged instances: Exclude patients with Tumor Board conference completed
		if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID    --altered (ORD_...Dflt)
				
		select *
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID    --altered (ORD_...Dflt)
        from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID] as b    --altered (ORD_...Dflt)
			 where  (
					((b.[primaryStopcode] in (316) or b.[SecondaryStopcode] in (316)) and [tiustandardtitle] like '%Tumor%Board%')
			        or b.TIUStandardTitle like '%tumor%board%'					
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				    and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
					--Tumor, stopcode+title
					and a.patientSSN = b.patientSSN 
					and (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00.000' as datetime)) and 
						DATEADD(dd,(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
										, convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))
					and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
							or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from [MyDB].[MySchema].[Lung_Sta3n528_0_1_inputP])    --altered (ORD_...Dflt)
							) )

go


--------------------------------------------------------------------------------------------------------------------------------
-----  6. Trigger positive chest images from potential patients
--------------------------------------------------------------------------------------------------------------------------------

--  Trigger Positive instances
if (OBJECT_ID('[MyDB].[MySchema].[Lung_Sta3n528_3_Ins_U_TriggerPos]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_U_TriggerPos    --altered (ORD_...Dflt)

	select distinct * 
	into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_U_TriggerPos    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[Lung_Sta3n528_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID]    --altered (ORD_...Dflt)
go
--  First instance in the study period in case of multiple trigger position instances, 
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_3_Ins_V_TriggerPos_FirstOfPat_SP') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_V_TriggerPos_FirstOfPat_SP    --altered (ORD_...Dflt)
		go

		select *
		into [MyDB].[MySchema].Lung_Sta3n528_3_Ins_V_TriggerPos_FirstOfPat_SP    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_U_TriggerPos as a    --altered (ORD_...Dflt)
		where not exists
			(select *
			 from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_U_TriggerPos as b    --altered (ORD_...Dflt)
			 where a.PatientSSN = b.patientSSN and			 
			 b.ExamDateTime < a.ExamDateTime)
		and a.[ExamDateTime] between (select sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt)
							and (select sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt)
			 	
go

--------------------------------------------------------------------------------------------------------------------------------
-----  7. counts
--------------------------------------------------------------------------------------------------------------------------------

-- Numerator and Denumerator
if (OBJECT_ID('[MyDB].[MySchema].Lung_Sta3n528_4_01_Count') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].Lung_Sta3n528_4_01_Count    --altered (ORD_...Dflt)
		go

		CREATE TABLE [MyDB].[MySchema].Lung_Sta3n528_4_01_Count(    --altered (ORD_...Dflt)
			Sta6a [varchar](10) NULL	
			,[run_dt] [datetime] NULL
			,[sp_start] [datetime] NULL
			,[sp_end] [datetime] NULL
			,NumOfTotalChestXRayCT int NULL
			,NumOfTotalPatWithChestXRayCT int NULL
			,NumOfRedFlaggedChestXRayCT int NULL
			,NumOfPatWithRedFlaggedChestXRayCT int NULL
			,NumOfTriggerPosChestXRayC int NULL
			,NumOfTriggerPosPat int NULL)
		go
		
		Insert into [MyDB].[MySchema].Lung_Sta3n528_4_01_Count (    --altered (ORD_...Dflt)
			Sta6a
			,[run_dt]
			,[sp_start]
			,[sp_end]
			,NumOfTotalChestXRayCT
			,NumOfTotalPatWithChestXRayCT
			,NumOfRedFlaggedChestXRayCT
			,NumOfPatWithRedFlaggedChestXRayCT
			,NumOfTriggerPosChestXRayC
			,NumOfTriggerPosPat)
		values (
		(select  Sta6a from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
		,(select  run_dt from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
		,(select  sp_start from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
		,(select  sp_end from [MyDB].[MySchema].Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
		-- number of Chest XRay/CT performed
		,(select  count(distinct  RadiologyExamSID ) from [MyDB].[MySchema].Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a)    --altered (ORD_...Dflt)
		-- number of patients with Chest XRay/CT performed
		,(select count(distinct  patientssn ) from [MyDB].[MySchema].Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a)    --altered (ORD_...Dflt)
		-- number of Chest XRay/CT which are red-flageed
		,(select count(distinct  RadiologyExamSID ) from [MyDB].[MySchema].Lung_Sta3n528_1_In_3_RedFlagXRayCT)    --altered (ORD_...Dflt)
		-- number of patients with red-flagged Chest XRay/CT
		,(select count(distinct  patientssn ) from [MyDB].[MySchema].Lung_Sta3n528_1_In_3_RedFlagXRayCT)     --altered (ORD_...Dflt)
		-- number of Chest XRay/CT which come out trigger positive
		,(select count(distinct  RadiologyExamSID ) from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_U_TriggerPos)    --altered (ORD_...Dflt)
		-- number of patients with trigger positive Chest XRay/CT
		,(select count(distinct  patientssn ) from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_U_TriggerPos)    --altered (ORD_...Dflt)
		)
go

select * from [MyDB].[MySchema].Lung_Sta3n528_4_01_Count    --altered (ORD_...Dflt)

---- data set:  Chest XRay/CT performed
--select * from [MyDB].[MySchema].Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a    --altered (ORD_...Dflt)
---- data set:  patients with Chest XRay/CT performed
--select * from [MyDB].[MySchema].Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a    --altered (ORD_...Dflt)
---- data set:  Chest XRay/CT which are red-flaged
--select * from [MyDB].[MySchema].Lung_Sta3n528_1_In_3_RedFlagXRayCT    --altered (ORD_...Dflt)
---- data set:  patients with red-flagged Chest XRay/CT
--select * from [MyDB].[MySchema].Lung_Sta3n528_1_In_3_RedFlagXRayCT    --altered (ORD_...Dflt)
---- data set:  Chest XRay/CT which come out trigger positive
--select * from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_U_TriggerPos    --altered (ORD_...Dflt)
---- data set:  patients with trigger positive Chest XRay/CT
--select * from [MyDB].[MySchema].Lung_Sta3n528_3_Ins_U_TriggerPos    --altered (ORD_...Dflt)


---- Delete intermediate tables
--drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_Sta6a    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_6_IncIns    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_1_In_8_IncPat    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_1_SurgDx_ICD10    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_1_SurgDx_ICD10_Hlp1    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_1_SurgDx_ICD9    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_1_SurgDx_ICD9_Hlp1    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_2_OutPatDx_ICD10    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD10    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD10    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD10    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_4_AllDx_ICD10    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_4_AllDx_ICD9    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD10    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9ICD10    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD10Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD10Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD10Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg_Hlp1    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_E_PrevProc_AllNonDxProcICD9ICD10Proc_XRay    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_F_PrevProc_AllNonDxProcICD9ICD10Proc_CT    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Exc_NonDx_G_PrevProc_AllNonDxProcICD9ICD10Proc_PET    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_0_1_In_4_Age    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_0_2_In_5_Alive    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_1_Ex_LungCancer    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_2_Ex_Termi_Major    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_ByPTF    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_4_Ex_Tuber    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_A_XRay    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_B_CT    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_C_PET    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID    --altered (ORD_...Dflt)
--drop table [MyDB].[MySchema].Lung_Sta3n528_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID    --altered (ORD_...Dflt)

 
