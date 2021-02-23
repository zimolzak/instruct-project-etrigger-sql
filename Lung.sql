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
--			them with your corresponding database name, data schema and table names:
--			database name: MyDB 
--			data schema:   MySchema 
--			Table names:   We have mapped table names from Research data to Operational. But we currently do not have live access to Operational data to test the mappings. 

--      TobeAltered:
--		4. Table MyDB.[MySchema].Lung_Sta3n528_0_xxx has the input parameters, including study period, standard codes( CPT, ICD, ICDproc etc.).
--		  Although these codes are standardized, if your local site uses them in different flavors, consider customization. Also exam these tables after being populated to make sure codes
--		  used in your site are all included.
--							set @sp_start='2017-01-01 00:00:00'
--							set @sp_end='2017-01-31 23:59:59' 
--
--      TobeAltered:
--		5. Set site(s) code. Table Lung_Sta3n528_0_0_1_Sta3nSta6a has the site(s) whose data the trigger runs against. The site can be CBOC as well as Hospital.
--		  Search for string "--Set site(s) codes here. Keep only your site(s) uncommented". Here you input the site(s) you are interested in running and comment out the others.
--                       Example:
--                       ( 528,'528A8') -- (528) Upstate New York HCS; ALBANY, NY VAMC 
--                      ,(642,'642GA') --  (642) Philadelphia, PA; FORT DIX OUTPATIENT CLINIC/CBC
--
--      TobeAltered:
--		6. Red-flagged chest image Diagnostic Codes
--		   Table MyDB.[MySchema].[Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode] will have the list of red-flagged chest image Diagnostic Codes.
--		   Add any additional codes that your site might use, or remove any that your site does not use by setting isRedFlag=0.
--							select * from #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode  --altered (temp table)
--							where sta3n=@yourSta3n
--						 
--		7. Other possible changes
--		   Standard codes ( CPT,ICD, ICDProcedure, LOINC etc.) might change every year, with addition of new codes and removal of old ones. These changes require corresponding updates of this script. 
--		   Always add new codes to parameter tables. Do NOT remove old codes because script still checks back for clinical history.		  
--
--
--      8. Data Set		    
--			--#Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a		-- 	All chest images from sta6a in the study period --altered (temp table)
--			--#Lung_Sta3n528_1_In_3_RedFlagXRayCT				--  Abnormal (red_flagged) chest images from sta6a in the study period --altered (temp table)
--			--#Lung_Sta3n528_3_Ins_U_TriggerPos				--  Chest images from sta6a in the study period which come out trigger positive --altered (temp table)
--
--		9. If you want to delete the intermediate table generated during execution. uncomment the block at the end of the script.
--
--		10. Numerator and denumerators: select * from #Lung_Sta3n528_4_01_Count --altered (temp table)




--------------------------------------------------------------------------------------------------------------------------------
-----  1. Initial set up: Input parameters, CPT and ICD diagnosis code, and ICDProcedure code lists used in the trigger measurement
--------------------------------------------------------------------------------------------------------------------------------

use master
go

set lock_timeout -1

declare @trigger varchar(20)		--Name of the trigger
declare @isVISN bit 				--Trigger runs on VISN levle
declare @VISN smallint				
declare @isSta3n bit				--Trigger runs on Sta3n levle
declare @run_date datetime2(0)			--Date time of trigger run
declare @sp_start datetime2(0)			--Study starting date time
declare @sp_end datetime2(0)			--Study ending date time
declare @fu_period as smallint		--follow-up window for red-flagged patients  
declare @age as smallint			--patient age upper limit
declare @ICD9Needed bit				--ICD9 and ICD9Proc are not searched if run trigger in year 2017 and beyond, set to 0

-- Set study parameters
set @trigger='LungCancer'
set @isVISN=0						--Disabled. Trigger runs against data of sta3n level 
set @VISN=12
set @isSta3n=1
set @VISN=12
set @sp_start='2020-01-01 00:00:00'
set @sp_end='2020-05-31 23:59:59' 

set @run_date=getdate()
set @fu_period=30
set @age=18
set @ICD9Needed=1

if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_0_1_Sta3nSta6a') is not null)	    --altered (ORD_...Dflt) --altered (object_id temp table)
		drop table #Lung_Sta3n528_0_0_1_Sta3nSta6a    --altered (ORD_...Dflt) --altered (temp table)
	CREATE TABLE #Lung_Sta3n528_0_0_1_Sta3nSta6a (    --altered (ORD_...Dflt) --altered (temp table)
	Sta3n smallint null,
	Sta6a [varchar](10) NULL
	) 


insert into  #Lung_Sta3n528_0_0_1_Sta3nSta6a (Sta3n,Sta6a)     --altered (ORD_...Dflt) --altered (temp table)
values 
 (
 --Set site(s) codes here. Keep only your site(s) uncommented.
 -- Cohort 1
 528,'528A8') --	(528A8) ALBANY,NY [7/1/00]
--,(642,'642') --	(642) Philadelphia, PA, CorporalMichael K.Crescenz VA Medical center
--,(644,'644') --	(644) Phoenix, AZ, Phoenix VA Health Care System
--,(671,'671')	--	(671) South Texas HCS (San Antonio TX)-Audie
-- -- Cohort 2
--,(537,'537') --	(537) JESSE BROWN VAMC
--,(549,'549') --	(549) North Texas HCS (Dallas TX)
--,(589,'589A5') --	(589) VA Heartland West (Kansas City MO)- Colmery-O'Neil VA Medical CENTER - TOPEKA VAMC DIVISION
--,(589,'589A6') --	(589) VA Heartland West (Kansas City MO)- Dwight D. Eisenhower VA Medical Center- LEAVENWORTH VAMC DIVISION
--,(691,'691') --	(691)VA GREATER LOS ANGELES (691)
-- -- Cohort 3
--,(635,'635') --	(635) Oklahoma City, OK
----Another 528 site:
--,(528,'528A7') --	 (528A7) (Syracuse, NY)
--,(540,'540') --	(540) Clarksburg, WV
--,(523,'523') --	(523)BOSTON HCS VAMC

---- Discovery
---- Baltimore is special,does not fill in diagnosticcode, has to go with Note Title
--,(512,'512') --	(512) Maryland HCS (Baltimore MD)
--,(580,'580') --	(580) Houston, TX
--,(541,'541') --(541) Cleveland, OH


if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_1_inputP') is not null)	    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_0_1_inputP    --altered (ORD_...Dflt) --altered (temp table)
	
		CREATE TABLE #Lung_Sta3n528_0_1_inputP(    --altered (ORD_...Dflt) --altered (temp table)
		[trigger] [varchar](20) NULL,
		isVISN bit null,
		isSta3n bit null,
		[VISN] [smallint] NULL,		 
		--Sta3n smallint null,
		ICD9Needed bit null,
		--Sta6a [varchar](10) NULL,
		[run_dt] datetime2(0) NULL,
		[sp_start] datetime2(0) NULL,
		[sp_end] datetime2(0) NULL,
		[fu_period] [smallint] NULL,
		[age] [smallint] NULL)
	

INSERT INTO #Lung_Sta3n528_0_1_inputP    --altered (ORD_...Dflt) --altered (temp table)
           ([trigger]
		   ,isVISN
		   ,isSta3n
		   ,[VISN]
		   --,Sta3n
		   ,ICD9Needed
		   --,Sta6a
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
		   --,@Sta3n
		   ,@ICD9Needed
		   --,@Sta6a           
		   ,@run_date
           ,@sp_start
           ,@sp_end
           ,@fu_period
           ,@age)


go

select [trigger],ICD9Needed,run_dt,sp_start,sp_end,fu_period,age
 from #Lung_Sta3n528_0_1_inputP    --altered (ORD_...Dflt) --altered (temp table)

select * from #Lung_Sta3n528_0_0_1_Sta3nSta6a     --altered (ORD_...Dflt) --altered (temp table)


-- CPT Code lists for Lung images
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_2_0_LungImg') is not null) 		    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_0_2_0_LungImg    --altered (ORD_...Dflt) --altered (temp table)

	CREATE TABLE #Lung_Sta3n528_0_2_0_LungImg (    --altered (ORD_...Dflt) --altered (temp table)
	UniqueID int Identity(1,1) not null,
	[img_code_type] [varchar](50) NULL,
	[img_code_name] [varchar](50) NULL,
	[ImgCode] [varchar](10) NULL
	) 
go

insert into  #Lung_Sta3n528_0_2_0_LungImg ([img_code_type],[img_code_name],[ImgCode])     --altered (ORD_...Dflt) --altered (temp table)
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
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_2_DxICD10CodeExc') is not null) 		    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_0_2_DxICD10CodeExc    --altered (ORD_...Dflt) --altered (temp table)

	CREATE TABLE #Lung_Sta3n528_0_2_DxICD10CodeExc (    --altered (ORD_...Dflt) --altered (temp table)
	--UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.00'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.40'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.50'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.01'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.41'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.51'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.02'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.42'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.52'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.60'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.A0'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C93.00'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C93.01'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C93.02'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C94.00'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C94.01'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C94.02'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C94.20'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C94.21'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C94.22'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C95.00'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C95.01'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C95.02'
--added 20200617 was overlooked from Umair's new codes
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.61'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.62'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.A1'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Leukemia (Acute Only)','C92.A2'



insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Hepatocelllular Cancer','C22.0'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Hepatocelllular Cancer','C22.2'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Hepatocelllular Cancer','C22.3'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Hepatocelllular Cancer','C22.4'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Hepatocelllular Cancer','C22.7'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Hepatocelllular Cancer','C22.8'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Hepatocelllular Cancer','C22.1'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Hepatocelllular Cancer','C22.9'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Hepatocelllular Cancer','C78.7'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Biliary Cancer','C23.'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Biliary Cancer','C24.0'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Biliary Cancer','C24.1'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Biliary Cancer','C24.8'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Biliary Cancer','C24.9'


insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Esophageal Cancer','C15.3'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Esophageal Cancer','C15.4'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Esophageal Cancer','C15.5'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Esophageal Cancer','C15.8'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Esophageal Cancer','C15.9'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Gastric Cancer','C16.0'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Gastric Cancer','C16.4'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Gastric Cancer','C16.3'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Gastric Cancer','C16.1'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Gastric Cancer','C16.2'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Gastric Cancer','C16.5'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Gastric Cancer','C16.6'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Gastric Cancer','C16.8'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Gastric Cancer','C16.9'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C71.0'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C71.1'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C71.2'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C71.3'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C71.4'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C71.5'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C71.6'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C71.7'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C71.8'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C71.9'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C79.31'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C79.32'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer','C79.49'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Brain Cancer', 'C79.40'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Ovarian Cancer','C56.9'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Ovarian Cancer','C56.1'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Ovarian Cancer','C56.2'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Pancreatic Cancer','C25.0'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Pancreatic Cancer','C25.1'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Pancreatic Cancer','C25.2'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Pancreatic Cancer','C25.3'
--added 20200617 which were missing
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Pancreatic Cancer','C25.4'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Pancreatic Cancer','C25.7'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Pancreatic Cancer','C25.8'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Pancreatic Cancer','C25.9'

--'Pleural Cancer & Mesothelioma' is kind of Lung Cancer itself. Should not be in the exclusion 
--insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
--select 	'Terminal','Pleural Cancer & Mesothelioma','C38.4'
--insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
--select 	'Terminal','Pleural Cancer & Mesothelioma','C45.0'
--insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
--select 	'Terminal','Pleural Cancer & Mesothelioma','C78.2'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Uterine Cancer','C55.'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C45.1'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.1'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.8'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.2'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C78.6'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Myeloma','C90.00'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Myeloma','C90.01'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Myeloma','C90.02'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Myeloma','D47.Z9'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Terminal','Tracheal Cancer','C33.'

--insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
--select 	'Terminal','Tracheal Cancer','C78.39'
--insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
--select 	'Terminal','Tracheal Cancer','C78.30'


insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Hospice','','Z51.5'

insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Tuberculosis','','A15.0'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Tuberculosis','','A15.5'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Tuberculosis','','A15.6'
insert into #Lung_Sta3n528_0_2_DxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Tuberculosis','','A15.7'


-- ICD10Proc Code lists
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_3_PreProcICD10ProcExc') is not null) 		    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_0_3_PreProcICD10ProcExc    --altered (ORD_...Dflt) --altered (temp table)


	CREATE TABLE #Lung_Sta3n528_0_3_PreProcICD10ProcExc (    --altered (ORD_...Dflt) --altered (temp table)
	UniqueID int Identity(1,1) not null,
	[ICD10Proc_code_type] [varchar](50) NULL,
	[ICD10Proc_code_Name] [varchar](50) NULL,
	[ICD10ProcCode] [varchar](10) NULL
	) 
go

insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B933ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B934ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B937ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B938ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B943ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B944ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B947ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B948ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B953ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B954ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B957ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B958ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B963ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B964ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B967ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B968ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B973ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B974ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B977ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B978ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B983ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B984ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B987ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B988ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B993ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B994ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B997ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B998ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B3ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B7ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0B9B8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB33ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB34ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB37ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB38ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB43ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB44ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB47ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB48ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB53ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB54ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB57ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB58ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB63ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB64ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB67ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB68ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB73ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB74ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB77ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB78ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB83ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB84ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB87ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB88ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB93ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB94ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB97ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BB98ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB3ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB7ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BBB8ZX'
--20200522
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD34ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD38ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD44ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD48ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD54ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD58ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD64ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD68ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD74ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD78ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD84ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD88ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD94ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BD98ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BDB4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedBiopsyBronchus','0BDB8ZX'

insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0B930ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0B940ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0B950ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0B960ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0B970ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0B980ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0B990ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0B9B0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB30ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB40ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB50ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB60ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB70ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB80ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0BB90ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyBronchus','0BBB0ZX'

insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9C3ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9C4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9C7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9D3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9D4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9D7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9F3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9F4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9F7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9G3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9G4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9G7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9H3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9H4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9H7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9J3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9J4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9J7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9K3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9K4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9K7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9L3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9L4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9L7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9M3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9M4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0B9M7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBC3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBD3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBF3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBG3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBH3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBJ3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBK3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBL3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BBM3ZX'
--20200522
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BDC8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BDD8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BDF8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BDG8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BDH8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BDJ8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BDK8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BDL8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNneedleBiopsyLung','0BDM8ZX'

insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0B9K8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0B9L8ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0B9M8ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBK7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBK8ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBL7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBL8ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBM4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBM7ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedEndoscopicBiopsyLung','0BBM8ZX'



insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyLung','0B9K0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyLung','0B9L0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyLung','0B9M0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyLung','0BBK0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyLung','0BBL0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','OpenBiopsyLung','0BBM0ZX'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBC4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBD4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBF4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBG4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBH4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBJ4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBK4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBL4ZX'
--20200522
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBN4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ThoracoscopicPleuralBiopsy','0BBP4ZX'

insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','BiopsyChestWall','0W980ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','BiopsyChestWall','0W983ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','BiopsyChestWall','0W984ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','BiopsyChestWall','0WB80ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','BiopsyChestWall','0WB83ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','BiopsyChestWall','0WB84ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','BiopsyChestWall','0WB8XZX'

insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0B9N0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0B9N3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0B9N4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0B9P0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0B9P3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0B9P4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0BBN0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0BBN3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0BBP0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0BBP3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0W990ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0W993ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0W994ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0W9B0ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0W9B3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0W9B4ZX'
--20200522
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0B9N8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0B9P8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0BBN8ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','PleuraBiopsy','0BBP8ZX'



insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0W9C3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0W9C4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0WBC3ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungBiopsy','ClosedNeedleBiopsyMediastinum','0WBC4ZX'



insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBN4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBP4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BJ08ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0WJQ4ZZ'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0WJC4ZZ'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BJ08ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BJK8ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BJL8ZZ'
--20200522
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBC4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBD4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBF4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBG4ZX' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBH4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBJ4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBK4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBL4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BBM4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BDC4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BDD4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BDF4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BDG4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BDH4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BDJ4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','',''
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BDL4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BDM4ZX'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BJ08ZZ'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BJK8ZZ'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'Bronchoscopy','','0BJL8ZZ'

-- Lung surgery
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B534ZZ'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B538ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B544ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B548ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B554ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B558ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B564ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B568ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B574ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B578ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B584ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B588ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B594ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B598ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5B4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5B8ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB34ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB38ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB44ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB48ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB54ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB58ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB64ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB68ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB74ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB78ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB84ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB88ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB94ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB98ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBB4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBB8ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B530ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B533ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B537ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B540ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B543ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B547ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B550ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B553ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B557ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B560ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B563ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B567ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B570ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B573ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B577ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B580ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B583ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B587ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B590ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B593ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B597ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5B0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5B3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5B7ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB30ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB33ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB37ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB40ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB43ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB47ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB50ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB53ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB57ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB60ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB63ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB67ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB70ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB73ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB77ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB80ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB83ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB87ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB90ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB93ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BB97ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBB0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBB3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBB7ZZ'

insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT30ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT34ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT40ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT44ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT50ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT54ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT60ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT64ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT70ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT74ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT80ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT84ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT90ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BT94ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTB0ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBK4ZZ'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBL4ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5K0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5L0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5M0ZZ'

insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5K3ZZ'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5L3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5M3ZZ'



insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5K4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5L4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5M4ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5K7ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5K8ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5L7ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5L8ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5M7ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5M8ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5K8ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5L8ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5M8ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBK8ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBL8ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBM4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBM8ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5K0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5K3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5K7ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5L0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5L3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5L7ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5M0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5M3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0B5M7ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBK0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBK3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBK7ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBL0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBL3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBL7ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBM0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBM3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBM7ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBC4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBD4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBF4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBG4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBH4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBJ4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBK4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBL4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTH4ZZ'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)

select 	'LungSurgery','','0BBK0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBK3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBK7ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBL0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBL3ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BBL7ZZ'

insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTC4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTD4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTF4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTG4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTJ4ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTC0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTD0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTF0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTG0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTJ0ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','02JA0ZZ'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0WJC0ZZ'



insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BJ04ZZ'
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0WJQ4ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTK4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTL4ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTM4ZZ'


insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTK0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTL0ZZ' 
insert into #Lung_Sta3n528_0_3_PreProcICD10ProcExc ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt) --altered (temp table)
select 	'LungSurgery','','0BTM0ZZ'

-- ICD9 Diagnostic Code list
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_4_DxICD9CodeExc') is not null) 		    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_0_4_DxICD9CodeExc    --altered (ORD_...Dflt) --altered (temp table)

	CREATE TABLE #Lung_Sta3n528_0_4_DxICD9CodeExc (    --altered (ORD_...Dflt) --altered (temp table)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go


insert into  #Lung_Sta3n528_0_4_DxICD9CodeExc (    --altered (ORD_...Dflt) --altered (temp table)
	[ICD9Code]
	) 
select distinct ICD9Code from CDWWork.dim.ICD9 as dimICD9
where (select ICD9Needed from #Lung_Sta3n528_0_1_inputP)=1    --altered (ORD_...Dflt) --altered (temp table)
	and (dimICD9.ICD9Code like '157.%'
	 -- Leukemia (Acute Only)
		or dimICD9.ICD9Code like
			'207.2%'
			or dimICD9.ICD9Code like
				'207.0%'
			or dimICD9.ICD9Code like
				'205.0%'
			or dimICD9.ICD9Code like
				'206.0%'
			or dimICD9.ICD9Code like
				'208.0%'
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

update  #Lung_Sta3n528_0_4_DxICD9CodeExc     --altered (ORD_...Dflt) --altered (temp table)
 set dx_code_type = case
		when  	-- Pancreatic Cancer 
			ICD9Code like '157.%'
			 -- Leukemia (Acute Only)
				or ICD9Code like
					'207.2%'
					or ICD9Code like
						'207.0%'
					or ICD9Code like
						'205.0%'
					or ICD9Code like
						'206.0%'
					or ICD9Code like
						'208.0%'
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
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_5_PreProcICD9ProcExc') is not null) 		    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_0_5_PreProcICD9ProcExc    --altered (ORD_...Dflt) --altered (temp table)

	CREATE TABLE #Lung_Sta3n528_0_5_PreProcICD9ProcExc (    --altered (ORD_...Dflt) --altered (temp table)
	UniqueID int Identity(1,1) not null,
	[ICD9Proc_code_type] [varchar](50) NULL,
	[ICD9Proc_code_Name] [varchar](50) NULL,
	[ICD9ProcCode] [varchar](10) NULL
	) 
go

If Exists (select ICD9Needed from #Lung_Sta3n528_0_1_inputP where ICD9Needed=1)    --altered (ORD_...Dflt) --altered (temp table)
	insert into  #Lung_Sta3n528_0_5_PreProcICD9ProcExc ([ICD9Proc_code_type],[ICD9Proc_code_Name],[ICD9ProcCode])     --altered (ORD_...Dflt) --altered (temp table)
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
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc') is not null) 		    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc    --altered (ORD_...Dflt) --altered (temp table)

	CREATE TABLE #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc (    --altered (ORD_...Dflt) --altered (temp table)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go


insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.00'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.01'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.02'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.10'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.11'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.12'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.2'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.30'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.31'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.32'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.80'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.81'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.82'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.90'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.91'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C34.92'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C78.00'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C78.01'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C78.02'

--'Pleural Cancer & Mesothelioma' cancer is kind of lung cancer
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C38.4'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C45.0'
insert into #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt) --altered (temp table)
select 	'RecentActiveLungC','Lung Cancer','C78.2'

-- ICD9 diagnostic code list for lung cancer
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc') is not null) 		    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc    --altered (ORD_...Dflt) --altered (temp table)

	CREATE TABLE #Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc (    --altered (ORD_...Dflt) --altered (temp table)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go

insert into  #Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc (    --altered (ORD_...Dflt) --altered (temp table)
[dx_code_type],
	[dx_code_name],
	[ICD9Code]
	) 
select distinct 'RecentActiveLungC','', ICD9Code from CDWWork.dim.ICD9 as dimICD9
where	(select ICD9Needed from #Lung_Sta3n528_0_1_inputP)=1    --altered (ORD_...Dflt) --altered (temp table)
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
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_8_PrevProcCPTCodeExc') is not null) 		    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
go

	CREATE TABLE #Lung_Sta3n528_0_8_PrevProcCPTCodeExc (    --altered (ORD_...Dflt) --altered (temp table)
	UniqueID int Identity(1,1) not null,
	[CPT_code_type] [varchar](50) NULL,
	[CPT_code_name] [varchar](50) NULL,
	[CPTCode] [varchar](10) NULL
	) 
go

insert into  #Lung_Sta3n528_0_8_PrevProcCPTCodeExc (    --altered (ORD_...Dflt) --altered (temp table)
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
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode') is not null) 		    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode    --altered (ORD_...Dflt) --altered (temp table)
go

	CREATE TABLE #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode (    --altered (ORD_...Dflt) --altered (temp table)
	UniqueID int Identity(1,1) not null,
	Sta3n smallint null,
	RadiologyDiagnosticCode [varchar](100) NULL,
	[IsRedFlag] [bit] NULL,
	RadiologyDiagnosticCodeSID int null
)
go


-- Add red-flagged RadiologyDiagnosticCode. Check if all the codes used in your site are included

INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'POSSIBLE MALIGNANCY', 1, 800001068)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 800001096)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 800001097)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 800001098)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 800001113)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'HIGHLY SUGGESTIVE OF MALIGNANCY', 1, 800001142)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 800001146)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'POSSIBLE MALIGNANCY', 1, 800001883)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 800001904)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 800001905)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 800001906)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 800001921)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'LESION SUSPICIOUS FOR LUNG CA', 1, 800001925)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'ABNORMALITY: POSSIBLE MALIGNANCY, ATTN. NEEDED', 1, 800001928)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (691, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 800001933)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (644, N'PULMONARY NODULE PRESENT', 1, 800002109)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'HIGHLY SUG OF MALIG, TK ACTION', 1, 1000000002)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'SUSPICIOUS ABNORM, CONSIDER BX', 1, 1000000003)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'POSSIBLE MALIGNANCY', 1, 1000000340)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000000361)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000000362)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000000363)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000000378)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (537, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1000000416)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'POSSIBLE MALIGNANCY', 1, 1000000423)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000000446)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000000447)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000000448)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'IMPORTANT REPORT/POSSIBLE MALIGNANCY', 1, 1000000462)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000000463)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (580, N'POSSIBLE MALIGNANCY', 1, 1000000782)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (580, N'NEW UNSUSPECTED MALIGNANCY F/U ACTION NEEDED', 1, 1000000785)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (580, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000000815)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (580, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000000816)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (580, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000000817)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (580, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000000831)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (580, N'Suspicious for New Malignancy Need FU', 1, 1000000835)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (580, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1000000854)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'POSSIBLE MALIGNANCY', 1, 1000001015)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000001036)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000001037)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000001038)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000001053)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'CLINICAL ALERT-POSS. MALIGNANCY-E-MAIL', 1, 1000001064)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'CLINICAL ALERT-POSSIBLE MALIGNANCY', 1, 1000001069)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (589, N'POSSIBLE MALIGNACY, FOLLOW-UP NEEDED', 1, 1000001073)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'POSSIBLE MALIGNANCY', 1, 1000001552)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'SUSPICIOUS FOR MALIGNANCY-CLINICAL FOLLOW-UP ACTION NEEDED', 1, 1000001555)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000001583)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000001584)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000001585)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000001600)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'Suspicious for New Malignancy Need FU ', 1, 1000001605)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'PULMONARY EMBOLISM, IMMEDIATE ATTN NEEDED', 1, 1000001615)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'PULMONARY EMBOLISM, IMMEDIATE ATTN NEEDED', 1, 1000001617)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'NODULES 4mm TO LESS THAN 2cm', 1, 1000001619)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'NODULES/MASSES GREATER THAN 2cm', 1, 1000001620)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1000001628)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'POSSIBLE MALIGNANCY', 1, 1000002243)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1000002263)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1000002264)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1000002265)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1000002279)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (671, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1000002307)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'NODULES LESS THAN 6 MM', 1, 1000002593)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (635, N'NODULES 6MM TO LESS THEN 2CM', 1, 1000002594)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (541, N'POSSIBLE MALIGNANCY', 1, 1200000692)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (541, N'MASS LESION', 1, 1200000694)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (541, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1200000698)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (541, N'LUNG - SUSPICION FOR CANCER', 1, 1200000722)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (541, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1200000727)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (541, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1200000728)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (541, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1200000729)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (541, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1200000745)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (541, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1200000747)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (541, N'LUNG MASS-IMMEDIATE ATTENTION NEEDED.', 1, 1200000753)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (512, N'POSSIBLE MALIGNANCY', 1, 1400000304)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (512, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1400000317)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (512, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1400000325)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (512, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1400000326)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (512, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1400000327)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (512, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1400000342)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'POSSIBLE MALIGNANCY', 1, 1400000451)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1400000472)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1400000473)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1400000474)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1400000489)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'POSSIBLE MALIGNANCY, FOLLOW-UP NEEDED', 1, 1400000495)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'Possible Malignancy', 1, 1400000529)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'Lung Lesion for follow-up team', 1, 1400000530)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'Possible Malignancy ', 1, 1400000537)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'Lung lesion for follow up team', 1, 1400000538)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (523, N'LUNG NODULE FOLLOW UP', 1, 1400000540)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'POSSIBLE MALIGNANCY', 1, 1400000629)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1400000650)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1400000651)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1400000652)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1400000667)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'SUSPICIOUS FINDINGS,FU STUDY RECOM', 1, 1400000669)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'POSS PROBABLE TUMOR, PROVIDER NOTIFIED', 1, 1400000672)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'CATEGORY 5 HIGHLY SUGG MALIGNANCY', 1, 1400000688)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (528, N'POSSIBLE MALIGNANCY, FOLLOWUP NEEDED', 1, 1400000716)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'POSSIBLE MALIGNANCY', 1, 1400000805)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1400000824)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1400000825)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1400000826)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1400000840)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (540, N'POSS MALIGN, F/U NEEDED, ALERT SENT    ', 1, 1400000843)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'POSSIBLE MALIGNANCY', 1, 1400001450)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'LUNGRADS 4A: SUSPICIOUS NODULE', 1, 1400001471)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'LUNGRADS 4B: SUSPICIOUS NODULE', 1, 1400001472)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'LUNGRADS 4X: SUSPICIOUS NODULE WITH ADDITIONAL FEATURES', 1, 1400001473)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'INCIDENTAL LUNG NODULE(NONSCREENING)', 1, 1400001488)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (642, N'MAJOR ABNORMALITY/POSSIBLE MALIGNANCY', 1, 1400002196)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'SOLID MASS, IRREGULAR MARGINS', 1, 1000000476)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (549, N'NEW LESIONS, ATTN. NEEDED', 1, 1000000466)    --altered (ORD_...Dflt) --altered (temp table)
GO
INSERT #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode ([sta3n], [RadiologyDiagnosticCode], [isRedFlag], [RadiologyDiagnosticCodeSID]) VALUES (580, N'POSSIBLE NEW LUNG CANCER', 1, 1000002624)    --altered (ORD_...Dflt) --altered (temp table)
GO


--------------------------------------------------------------------------------------------------------------------------------
-----  2. Extract red-flagged chest images
--------------------------------------------------------------------------------------------------------------------------------
	
-- Extract of all chest XRay/CT during study period + follow-up days
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET    --altered (ORD_...Dflt) --altered (temp table)


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
into #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET     --altered (ORD_...Dflt) --altered (temp table)
FROM [CDWWork].[Rad].[RadiologyExam] as Rad    --altered (ORD_...Src)
--NeedToSwitch
inner join #Lung_Sta3n528_0_0_1_Sta3nSta6a as s    --altered (ORD_...Dflt) --altered (temp table)
on Rad.Sta3n=s.sta3n
left join CDWWork.Dim.location as b
		on Rad.RequestingLocationSID=b.LocationSID
left join CDWWork.dim.Division as d
		on b.DivisionSID=d.DivisionSID
left join cdwwork.dim.[RadiologyProcedure] as prc
on rad.sta3n=prc.sta3n and rad.[RadiologyProcedureSID]=prc.[RadiologyProcedureSID]
left join cdwwork.dim.CPT as code
on prc.CPTSID=code.CPTSID and prc.sta3n=code.sta3n 
inner join  #Lung_Sta3n528_0_2_0_LungImg as TargetImg    --altered (ORD_...Dflt) --altered (temp table)
on TargetImg.ImgCode=code.CPTCode
left join cdwwork.dim.[RadiologyExamStatus] as sta
on Rad.sta3n=sta.sta3n and Rad.[RadiologyExamStatusSID]=sta.[RadiologyExamStatusSID]
left join cdwwork.dim.[RadiologyDiagnosticCode] as diag
on Rad.sta3n=diag.sta3n and Rad.[RadiologyDiagnosticCodeSID]=diag.[RadiologyDiagnosticCodeSID]
  inner join cdwwork.dim.VistaSite as VistaSite
		on Rad.sta3n=VistaSite.Sta3n  
  where --Rad.CohortName='Cohort20180712' and
	 Rad.ExamDateTime
	  between (select sp_start from #Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt) --altered (temp table)
	  and DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP)) --Clue Date Range+followup    --altered (ORD_...Dflt) --altered (temp table)
	and sta.[RadiologyExamStatus] like'%COMPLETE%'


go


if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN    --altered (ORD_...Dflt) --altered (temp table)

	select distinct b.patientSSN,convert(varchar(10),b.BirthDateTime,120) as DOB,convert(varchar(10),b.DeathDateTime,120) as DOD,b.Gender as Sex
				,a.* 	
	into #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN    --altered (ORD_...Dflt) --altered (temp table)
	from #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET as a    --altered (ORD_...Dflt) --altered (temp table)
	left join [CDWWork].[SPatient].[SPatient] as b    --altered (ORD_...Src)
	on a.sta3n=b.sta3n and a.[PatientSID]=b.patientsid
	--where CohortName='Cohort20180712' 

	


-- All Chest_XRay/CT images during study period from local site sta6a
  if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a    --altered (ORD_...Dflt) --altered (temp table)

	select Rad.* into #Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a    --altered (ORD_...Dflt) --altered (temp table)
	from #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN as Rad    --altered (ORD_...Dflt) --altered (temp table)
	--NeedToSwitch
	inner join #Lung_Sta3n528_0_0_1_Sta3nSta6a as s    --altered (ORD_...Dflt) --altered (temp table)
	on Rad.Sta6a=s.sta6a
    where [img_code_type] in ('CT','XRay')
	and ExamDateTime
	  between (select sp_start from #Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt) --altered (temp table)
	  and (select sp_end from #Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt) --altered (temp table)

go


-- Chest_XRay/CT images that are flagged during study period from your site 
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_1_In_3_RedFlagXRayCT') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_1_In_3_RedFlagXRayCT    --altered (ORD_...Dflt) --altered (temp table)

select  Rad.* into #Lung_Sta3n528_1_In_3_RedFlagXRayCT    --altered (ORD_...Dflt) --altered (temp table)
from #Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a as Rad    --altered (ORD_...Dflt) --altered (temp table)
--NeedToSwitch
inner join #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode as code    --altered (ORD_...Dflt) --altered (temp table)
on rad.[RadiologyDiagnosticCode]=code.[RadiologyDiagnosticCode] and rad.Sta3n=code.Sta3n and code.isRedFlag=1
go




-- Red-flagged instances in study period
 if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_1_In_6_IncIns') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_1_In_6_IncIns    --altered (ORD_...Dflt) --altered (temp table)

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
into #Lung_Sta3n528_1_In_6_IncIns    --altered (ORD_...Dflt) --altered (temp table)
from #Lung_Sta3n528_1_In_3_RedFlagXRayCT as Rad    --altered (ORD_...Dflt) --altered (temp table)
where ExamDateTime between (select sp_start from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
				and (select sp_end from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)

go


-- Get other possible patientSID outside your sta3n
 if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_1_In_8_IncPat') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_1_In_8_IncPat    --altered (ORD_...Dflt) --altered (temp table)

	select distinct VStatus.Sta3n,VStatus.PatientSID,VStatus.patientSSN, VStatus.ScrSSN,VStatus.PatientICN
	into #Lung_Sta3n528_1_In_8_IncPat    --altered (ORD_...Dflt) --altered (temp table)
	from #Lung_Sta3n528_1_In_6_IncIns as a    --altered (ORD_...Dflt) --altered (temp table)
	left join [CDWWork].[SPatient].[SPatient]  as VStatus    --altered (ORD_...Src)
	on a.patientSSN=VStatus.PatientSSN
	--where CohortName='Cohort20180712'
	order by patientssn

	go




--------------------------------------------------------------------------------------------------------------------------------
-----  3. Extract red-flagged patients' clinical diagnosis, procedures and consults etc
--------------------------------------------------------------------------------------------------------------------------------

-- Extract of all DX Codes for all potential patients from surgical files
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_1_SurgDx_ICD9ICD10') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_1_SurgDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
											 

SELECT distinct
		surgPre.[SurgerySID] as SurgPre_SurgerySID
	  ,surgDx.SurgeryProcedureDiagnosisCodeSID
	  ,SurgeryOtherPostOpDiagnosisSID
	  ,SurgeryPrincipalAssociatedDiagnosisSID
      ,surgPre.[Sta3n]
      ,[VisitSID]
      ,SurgPre.[PatientSID]
      ,[CancelDateTime]
      ,surgPre.[SurgeryDateTime]  as dx_dt
	  , PreICD9.ICD9Code as PreICD9Diagnosis
	  ,PrincipalPostOpICD9.ICD9Code as PrincipalPostOpICD9Diagnosis
	  ,OtherPostICD9.ICD9Code as OtherPostICD9Diagnosis
	  ,assocDxICD9.ICD9Code as assocDxICD9Diagnosis
	  , PreICD10.ICD10Code as PreICD10Diagnosis
	  ,PrincipalPostOpICD10.ICD10Code as PrincipalPostOpICD10Diagnosis
	  ,OtherPostICD10.ICD10Code as OtherPostICD10Diagnosis
	  ,assocDxICD10.ICD10Code as assocDxICD10Diagnosis
	  ,p.patientSSN
  into #Lung_Sta3n528_2_Ex_1_SurgDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Surg].[SurgeryPre] as surgPre    --altered (ORD_...Src)
  inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
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

  left join CDWWork.dim.ICD10 as PreICD10
  on SurgPre.PrincipalPreOpICD10SID=PreICD10.ICD10SID and SurgPre.Sta3n=PreICD10.Sta3n
  left join CDWWork.dim.ICD10 as PrincipalPostOpICD10
  on SurgDx.[PrincipalPostOpICD10SID]=PrincipalPostOpICD10.ICD10SID and SurgDx.Sta3n=PrincipalPostOpICD10.Sta3n
  left join CDWWork.dim.ICD10 as OtherPostICD10
  on otherPostDx.OtherPostopICD10SID=OtherPostICD10.ICD10SID and otherPostDx.Sta3n=OtherPostICD10.Sta3n
  left join CDWWork.dim.ICD10 as assocDxICD10
  on assocDx.[SurgeryPrincipalAssociatedDiagnosisICD10SID]=assocDxICD10.ICD10SID and assocDx.sta3n=assocDxICD10.sta3n
   where  
  SurgPre.[SurgeryDateTime]>= DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))  and    --altered (ORD_...Dflt) --altered (temp table)
  SurgPre.[SurgeryDateTime]<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  --and  SurgPre.CohortName='Cohort20180712'
  --and  surgDx.CohortName='Cohort20180712'
  --and  otherPostDx.CohortName='Cohort20180712'
  --and  assocDx.CohortName='Cohort20180712'
  and (
  	--PreICD9.ICD9Code in (select ICD9Code from #Lung_Sta3n528_0_4_DxICD9CodeExc)    --altered (ORD_...Dflt) --altered (temp table)
	PrincipalPostOpICD9.ICD9Code in (select ICD9Code from #Lung_Sta3n528_0_4_DxICD9CodeExc)    --altered (ORD_...Dflt) --altered (temp table)
	or 	OtherPostICD9.ICD9Code in (select ICD9Code from #Lung_Sta3n528_0_4_DxICD9CodeExc)    --altered (ORD_...Dflt) --altered (temp table)
	or 	assocDxICD9.ICD9Code in (select ICD9Code from #Lung_Sta3n528_0_4_DxICD9CodeExc)    --altered (ORD_...Dflt) --altered (temp table)

	or PrincipalPostOpICD10.ICD10Code in (select ICD10Code from #Lung_Sta3n528_0_2_DxICD10CodeExc)    --altered (ORD_...Dflt) --altered (temp table)
	or 	OtherPostICD10.ICD10Code in (select ICD10Code from #Lung_Sta3n528_0_2_DxICD10CodeExc)    --altered (ORD_...Dflt) --altered (temp table)
	or 	assocDxICD10.ICD10Code in (select ICD10Code from #Lung_Sta3n528_0_2_DxICD10CodeExc)    --altered (ORD_...Dflt) --altered (temp table)

	) 
  
	go


--  Extract of all DX codes from outpatient table for all potential patients
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9ICD10') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)

SELECT 
	 [VDiagnosisSID]
      ,Diag.[Sta3n]
      ,Diag.[PatientSID]
	  ,targetCode.ICD9Code as ICD9Code
	  ,targetCode.dx_code_type as ICD9dx_code_type
	   ,ICD10CodeList.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type as ICD10dx_code_type
      ,[VisitSID]
      ,[VisitDateTime]
      ,[VDiagnosisDateTime] as dx_dt 	
	  ,p.patientSSN 
into #Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[outpat].[WorkLoadVDiagnosis] as Diag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on Diag.ICD9SID=DimICD9.ICD9SID
left join #Lung_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt) --altered (temp table)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on Diag.ICD10SID=DimICD10.ICD10SID
left join #Lung_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt) --altered (temp table)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and
[VDiagnosisDateTime]> DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and [VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),    --altered (ORD_...Dflt) --altered (temp table)
										(select sp_end from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)		

go



--  Extract of all DX codes from inpatient tables for all potential patients
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
SELECT 
	  [InpatientDiagnosisSID] 
      ,InPatDiag.[Sta3n]
      ,[InpatientSID]  
      ,InPatDiag.[PatientSID]
      ,[DischargeDateTime]
      ,[DischargeDateTime] as dx_dt
	  ,targetCode.ICD9Code as ICD9Code
	  ,targetCode.dx_code_type as ICD9dx_code_type
	   ,ICD10CodeList.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type as ICD10dx_code_type
	  ,p.patientSSN
	into  #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Inpat].[InpatientDiagnosis] as InPatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InPatDiag.ICD9SID=DimICD9.ICD9SID
left join #Lung_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt) --altered (temp table)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InPatDiag.ICD10SID=DimICD10.ICD10SID
left join #Lung_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt) --altered (temp table)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
  where --CohortName='Cohort20180712' and

  [DischargeDateTime]> DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and [DischargeDateTime]<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)
	go


if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Census501Diagnosis') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Census501Diagnosis    --altered (ORD_...Dflt) --altered (temp table)

SELECT 
	  Census501DiagnosisSID 
      ,InPatDiag.[Sta3n]      
      ,InPatDiag.[PatientSID]
      ,CensusDateTime as dx_dt
	  ,AdmitDateTime
	  ,targetCode.ICD9Code as ICD9Code
	  ,targetCode.dx_code_type as ICD9dx_code_type
	   ,ICD10CodeList.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type as ICD10dx_code_type
	  ,p.patientSSN	  
	into  #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Census501Diagnosis    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Inpat].[Census501Diagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join #Lung_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt) --altered (temp table)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join #Lung_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt) --altered (temp table)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and
	CensusDateTime>= DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt) --altered (temp table)
	and CensusDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go

if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis    --altered (ORD_...Dflt) --altered (temp table)

SELECT 
	  CensusDiagnosisSID 
      ,InPatDiag.[Sta3n]
      ,InPatDiag.[PatientSID]
      ,CensusDateTime as dx_dt
	  ,AdmitDateTime
	  ,targetCode.ICD9Code as ICD9Code
	  ,targetCode.dx_code_type as ICD9dx_code_type
	   ,ICD10CodeList.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type as ICD10dx_code_type
	  ,p.patientSSN	  
	into  #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Inpat].[CensusDiagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join #Lung_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt) --altered (temp table)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join #Lung_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt) --altered (temp table)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and
	CensusDateTime>= DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt) --altered (temp table)
	and CensusDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go


if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis    --altered (ORD_...Dflt) --altered (temp table)

SELECT 
	  Inpatient501TransactionDiagnosisSID 
      ,InPatDiag.[Sta3n] 
      ,InPatDiag.[PatientSID]
      ,SpecialtyTransferDateTime as dx_dt
	  ,MovementDateTime      
	  ,targetCode.ICD9Code as ICD9Code
	  ,targetCode.dx_code_type as ICD9dx_code_type
	   ,ICD10CodeList.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type as ICD10dx_code_type
	  ,p.patientSSN	  
	into  #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Inpat].[Inpatient501TransactionDiagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join #Lung_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt) --altered (temp table)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join #Lung_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt) --altered (temp table)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and
	SpecialtyTransferDateTime>= DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt) --altered (temp table)
	and SpecialtyTransferDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go


if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis    --altered (ORD_...Dflt) --altered (temp table)

SELECT 
	  InpatientDischargeDiagnosisSID ,
      InPatDiag.[Sta3n]
      ,InpatDiag.[InpatientSID]  
      ,InPatDiag.[PatientSID]
      ,[DischargeDateTime] as dx_dt
	  ,targetCode.ICD9Code as ICD9Code
	  ,targetCode.dx_code_type as ICD9dx_code_type
	   ,ICD10CodeList.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type as ICD10dx_code_type
	  ,p.patientSSN	  
	into  #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Inpat].[InpatientDischargeDiagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join #Lung_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt) --altered (temp table)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join #Lung_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt) --altered (temp table)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --inpatDiag.CohortName='Cohort20180712' and  
	DischargeDateTime>= DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt) --altered (temp table)
	and DischargeDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go


if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
SELECT 
	  PatientTransferDiagnosisSID ,
      InPatDiag.[Sta3n] 
      ,InPatDiag.[PatientSID]
      ,MovementDateTime
	  ,PatientTransferDateTime as dx_dt
	  ,targetCode.ICD9Code as ICD9Code
	  ,targetCode.dx_code_type as ICD9dx_code_type
	   ,ICD10CodeList.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type as ICD10dx_code_type
	  ,p.patientSSN	  
	into  #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Inpat].[PatientTransferDiagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join #Lung_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt) --altered (temp table)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join #Lung_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt) --altered (temp table)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and  
	PatientTransferDateTime>= DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt) --altered (temp table)
	and PatientTransferDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go

if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
SELECT 
	  SpecialtyTransferDiagnosisSID ,
      InPatDiag.[Sta3n]
      ,InpatDiag.[InpatientSID]  
      ,InPatDiag.[PatientSID]
,MovementDateTime
,SpecialtyTransferDateTime as dx_dt
	  ,targetCode.ICD9Code as ICD9Code
	  ,targetCode.dx_code_type as ICD9dx_code_type
	   ,ICD10CodeList.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type as ICD10dx_code_type
	  ,p.patientSSN	  
	into  #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Inpat].[SpecialtyTransferDiagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join #Lung_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt) --altered (temp table)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join #Lung_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt) --altered (temp table)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --inpatDiag.CohortName='Cohort20180712' and
	SpecialtyTransferDateTime>= DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt) --altered (temp table)
	and SpecialtyTransferDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go

-- Extract of all DX Codes for all potential patients from Purchased Care

if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9ICD10') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)

SELECT 
       Diag.[Sta3n]
      ,Diag.[PatientSID]
	  ,[InpatientFeeDiagnosisSID]
      ,[InpatientFeeBasisSID]      
      ,[AdmitDateTime] 
      ,[DischargeDateTime] as dx_dt
	  ,targetCode.ICD9Code as ICD9Code
	  ,targetCode.dx_code_type as ICD9dx_code_type
	   ,ICD10CodeList.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type as ICD10dx_code_type	  
	  ,p.patientSSN
into #Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
FROM [CDWWork].[Inpat].[InpatientFeeDiagnosis] as Diag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on Diag.ICD9SID=DimICD9.ICD9SID
left join #Lung_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt) --altered (temp table)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on Diag.ICD10SID=DimICD10.ICD10SID
left join #Lung_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt) --altered (temp table)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and
 DischargeDateTime> DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and DischargeDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go



-- Extract of all DX Codes for all potential patients from Purchased Care 
  		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
		drop table #Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)


SELECT  
	  c.patientssn
	,d.InitialTreatmentDateTime as dx_dt
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,FeeServiceProvidedSID
	  ,a.FeeInitialTreatmentSID
	  ,targetCode.ICD9Code as ICD9Code
	  ,targetCode.dx_code_type as ICD9dx_code_type
	   ,ICD10CodeList.ICD10Code as ICD10Code
	  ,ICD10CodeList.dx_code_type as ICD10dx_code_type
into #Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
  inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
   left join CDWWork.Dim.ICD9 as DimICD9
  on a.ICD9SID=DimICD9.ICD9SID
left join #Lung_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt) --altered (temp table)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on a.ICD10SID=DimICD10.ICD10SID
left join #Lung_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt) --altered (temp table)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join #Lung_Sta3n528_1_In_8_IncPat as c    --altered (ORD_...Dflt) --altered (temp table)
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where --a.CohortName='Cohort20180712'  and d.CohortName='Cohort20180712' and
 
 InitialTreatmentDateTime> DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and d.InitialTreatmentDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)
go



	--  Extract of all exclusion diagnoses from surgical, inpatient, and outpatient tables
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_4_AllDx_ICD9') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_4_AllDx_ICD9    --altered (ORD_...Dflt) --altered (temp table)
go


select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'DX-OutPat' as dataSource
into #Lung_Sta3n528_2_Ex_4_AllDx_ICD9    --altered (ORD_...Dflt) --altered (temp table)
 from #Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-InPat' as dataSource
 from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code,ICD9dx_code_type as dx_code_type,'Dx-InPatFee' as dataSource
 from #Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code,ICD9dx_code_type as dx_code_type,'Dx-InPatFeeService' as dataSource
 from #Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
where ICD9dx_code_type is not null
--
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-Census501Diagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Census501Diagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-CensusDiagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-501TransactionDiagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-InpatientDischargeDiagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-PatientTransferDiagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-SpecialtyTransferDiagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD9dx_code_type is not null
----------------
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,PrincipalPostOpICD9Diagnosis as ICD9
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from #Lung_Sta3n528_2_Ex_1_SurgDx_ICD9ICD10 as a    --altered (ORD_...Dflt) --altered (temp table)
 inner join #Lung_Sta3n528_0_4_DxICD9CodeExc  as b    --altered (ORD_...Dflt) --altered (temp table)
 on a.PrincipalPostOpICD9Diagnosis=b.ICD9Code
 where  isnull(PrincipalPostOpICD9Diagnosis,'') in (select ICD9Code from #Lung_Sta3n528_0_4_DxICD9CodeExc )    --altered (ORD_...Dflt) --altered (temp table)
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,OtherPostICD9Diagnosis as ICD9
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from #Lung_Sta3n528_2_Ex_1_SurgDx_ICD9ICD10 as a    --altered (ORD_...Dflt) --altered (temp table)
 inner join #Lung_Sta3n528_0_4_DxICD9CodeExc  as b    --altered (ORD_...Dflt) --altered (temp table)
 on a.OtherPostICD9Diagnosis=b.ICD9Code
 where  isnull(OtherPostICD9Diagnosis,'') in (select ICD9Code from #Lung_Sta3n528_0_4_DxICD9CodeExc )    --altered (ORD_...Dflt) --altered (temp table)
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,assocDxICD9Diagnosis as ICD9
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from #Lung_Sta3n528_2_Ex_1_SurgDx_ICD9ICD10 as a    --altered (ORD_...Dflt) --altered (temp table)
 inner join #Lung_Sta3n528_0_4_DxICD9CodeExc  as b    --altered (ORD_...Dflt) --altered (temp table)
 on a.assocDxICD9Diagnosis=b.ICD9Code
 where  isnull(assocDxICD9Diagnosis,'') in (select ICD9Code from #Lung_Sta3n528_0_4_DxICD9CodeExc )    --altered (ORD_...Dflt) --altered (temp table)
 go


if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_4_AllDx_ICD10') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_4_AllDx_ICD10    --altered (ORD_...Dflt) --altered (temp table)
go


select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'DX-OutPat' as dataSource
into #Lung_Sta3n528_2_Ex_4_AllDx_ICD10    --altered (ORD_...Dflt) --altered (temp table)
 from #Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-InPat' as dataSource
 from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code,ICD10dx_code_type as dx_code_type,'Dx-InPatFee' as dataSource
 from #Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code,ICD10dx_code_type as dx_code_type,'Dx-InPatFeeService' as dataSource
 from #Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
where ICD10dx_code_type is not null
--
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-Census501Diagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Census501Diagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-CensusDiagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-501TransactionDiagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-InpatientDischargeDiagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-PatientTransferDiagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-SpecialtyTransferDiagnosis' as dataSource
from #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
where ICD10dx_code_type is not null
----------------
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,PrincipalPostOpICD10Diagnosis as ICD10
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from #Lung_Sta3n528_2_Ex_1_SurgDx_ICD9ICD10 as a    --altered (ORD_...Dflt) --altered (temp table)
 inner join #Lung_Sta3n528_0_2_DxICD10CodeExc  as b    --altered (ORD_...Dflt) --altered (temp table)
 on a.PrincipalPostOpICD10Diagnosis=b.ICD10Code
 where  isnull(PrincipalPostOpICD10Diagnosis,'') in (select ICD10Code from #Lung_Sta3n528_0_2_DxICD10CodeExc )    --altered (ORD_...Dflt) --altered (temp table)
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,OtherPostICD10Diagnosis as ICD10
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from #Lung_Sta3n528_2_Ex_1_SurgDx_ICD9ICD10 as a    --altered (ORD_...Dflt) --altered (temp table)
 inner join #Lung_Sta3n528_0_2_DxICD10CodeExc  as b    --altered (ORD_...Dflt) --altered (temp table)
 on a.OtherPostICD10Diagnosis=b.ICD10Code
 where  isnull(OtherPostICD10Diagnosis,'') in (select ICD10Code from #Lung_Sta3n528_0_2_DxICD10CodeExc )    --altered (ORD_...Dflt) --altered (temp table)
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,assocDxICD10Diagnosis as ICD10
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from #Lung_Sta3n528_2_Ex_1_SurgDx_ICD9ICD10 as a    --altered (ORD_...Dflt) --altered (temp table)
 inner join #Lung_Sta3n528_0_2_DxICD10CodeExc  as b    --altered (ORD_...Dflt) --altered (temp table)
 on a.assocDxICD10Diagnosis=b.ICD10Code
 where  isnull(assocDxICD10Diagnosis,'') in (select ICD10Code from #Lung_Sta3n528_0_2_DxICD10CodeExc )    --altered (ORD_...Dflt) --altered (temp table)
 go



if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
go

select patientSSN,Sta3n,PatientSID,dx_dt,ICD9 as ICDCode,dataSource,dx_code_type
into #Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
from #Lung_Sta3n528_2_Ex_4_AllDx_ICD9    --altered (ORD_...Dflt) --altered (temp table)
Union ALL
select patientSSN,Sta3n,PatientSID,dx_dt,ICD10,dataSource,dx_code_type
from #Lung_Sta3n528_2_Ex_4_AllDx_ICD10    --altered (ORD_...Dflt) --altered (temp table)
go


--  Look into ProblemList for Previous ACTIVE lung canccer 
-- ProblemList data is very spotty
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9ICD10') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
go

select
			  p.patientssn,Plist.sta3n,Plist.patientsid	,Plist.EnteredDateTime,Plist.RecordedDateTime
			  ,ICD9.ICD9Code
			  ,CancerICD9CodeList.ICD9Code as TargetICD9Code
			  ,CancerICD9CodeList.dx_code_type as Icd9dx_code_type
    			,ICD10.ICD10Code,CancerICD10CodeList.ICD10Code as TargetICD10Code				
			  ,CancerICD10CodeList.dx_code_type as Icd10dx_code_type
into #Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
 FROM [CDWWork].[Outpat].[ProblemList] as Plist    --altered (ORD_...Src)
left join CDWWork.Dim.ICD9 as ICD9
  on Plist.ICD9SID=ICD9.ICD9SID
left join #Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc as CancerICD9CodeList    --altered (ORD_...Dflt) --altered (temp table)
on ICD9.ICD9Code=CancerICD9CodeList.ICD9Code
left join CDWWork.Dim.ICD10 as ICD10
  on Plist.ICD10SID=ICD10.ICD10SID
left join #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc as CancerICD10CodeList    --altered (ORD_...Dflt) --altered (temp table)
on ICD10.ICD10Code=CancerICD10CodeList.ICD10Code
inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
  on Plist.sta3n=p.sta3n and Plist.patientsid=p.patientsid
where --CohortName='Cohort20180712' and 
plist.RecordedDateTime >= DATEADD(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt) --altered (temp table)
and plist.RecordedDateTime <= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),    --altered (ORD_...Dflt) --altered (temp table)
										(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
and
(
CancerICD9CodeList.dx_code_type is not null
or CancerICD10CodeList.dx_code_type is not null
)
go



--Inpatient Procedure from all potential patients
-- Previous ICD procedures from inpatient tables 

				if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc			    --altered (ORD_...Dflt) --altered (temp table)

			 select pat.patientssn,ICDProc.sta3n,ICDProc.patientsid	,ICDProc.[ICDProcedureDateTime]
			  ,DimICD9Proc.[ICD9ProcedureCode],TargetCode.ICD9ProcCode,TargetCode.ICD9Proc_Code_Type
    			,DimICD10Proc.ICD10ProcedureCode,ICD10CodeList.ICD10ProcCode,ICD10CodeList.ICD10Proc_Code_Type
into #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[inpat].[InpatientICDProcedure] as ICDProc    --altered (ORD_...Src)
 			  left join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on ICDProc.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  left join #Lung_Sta3n528_0_5_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt) --altered (temp table)
			  on DimICD9Proc.[ICD9ProcedureCode]=TargetCode.ICD9ProcCode

			  left join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			    left join #Lung_Sta3n528_0_3_PreProcICD10ProcExc as ICD10CodeList    --altered (ORD_...Dflt) --altered (temp table)
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from #Lung_Sta3n528_1_In_8_IncPat) as pat    --altered (ORD_...Dflt) --altered (temp table)
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where --CohortName='Cohort20180712' and
  ([ICDProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  and [ICDProcedureDateTime]<= DateAdd(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  )
 and (TargetCode.ICD9Proc_code_type is not null or ICD10CodeList.ICD10Proc_code_type is not null)	
 go


			if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)

			 select pat.patientssn,ICDProc.sta3n,ICDProc.patientsid	,ICDProc.ICDProcedureDateTime
			  ,DimICD9Proc.[ICD9ProcedureCode],TargetCode.ICD9ProcCode,TargetCode.ICD9Proc_Code_Type
    			,DimICD10Proc.ICD10ProcedureCode,ICD10CodeList.ICD10ProcCode,ICD10CodeList.ICD10Proc_Code_Type
into #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Inpat].[CensusICDProcedure] as ICDProc    --altered (ORD_...Src)
 			  left join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on ICDProc.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  left join #Lung_Sta3n528_0_5_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt) --altered (temp table)
			  on DimICD9Proc.[ICD9ProcedureCode]=TargetCode.ICD9ProcCode

			  left join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			    left join #Lung_Sta3n528_0_3_PreProcICD10ProcExc as ICD10CodeList    --altered (ORD_...Dflt) --altered (temp table)
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode  
   inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from #Lung_Sta3n528_1_In_8_IncPat) as pat    --altered (ORD_...Dflt) --altered (temp table)
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where --CohortName='Cohort20180712' and
  ([ICDProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  and [ICDProcedureDateTime]<= DateAdd(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  )  
 and (TargetCode.ICD9Proc_code_type is not null or ICD10CodeList.ICD10Proc_code_type is not null)	
go



if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)

			select pat.patientssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
			,DimICD9Proc.[ICD9ProcedureCode],TargetCode.ICD9Proc_Code_Type
	      ,TargetCode.ICD9ProcCode,ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],ICD10CodeList.ICD10ProcCode
into #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[inpat].[InpatientSurgicalProcedure] as a    --altered (ORD_...Src)
 			  left join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  left join #Lung_Sta3n528_0_5_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt) --altered (temp table)
			  on DimICD9Proc.[ICD9ProcedureCode]=TargetCode.ICD9ProcCode

			  left join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			    left join #Lung_Sta3n528_0_3_PreProcICD10ProcExc as ICD10CodeList    --altered (ORD_...Dflt) --altered (temp table)
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from #Lung_Sta3n528_1_In_8_IncPat) as pat    --altered (ORD_...Dflt) --altered (temp table)
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where --CohortName='Cohort20180712' and
  ([SurgicalProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  and [SurgicalProcedureDateTime]<= DateAdd(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  )
  and (TargetCode.ICD9Proc_code_type is not null or ICD10CodeList.ICD10Proc_code_type is not null)
go



if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)

			 select pat.patientssn,a.sta3n,a.patientsid	,a.SurgicalProcedureDateTime
			  ,DimICD9Proc.[ICD9ProcedureCode],TargetCode.ICD9ProcCode,TargetCode.ICD9Proc_Code_Type
    			,DimICD10Proc.ICD10ProcedureCode,ICD10CodeList.ICD10ProcCode,ICD10CodeList.ICD10Proc_Code_Type
into #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
  FROM [CDWWork].[Inpat].[CensusSurgicalProcedure] as a    --altered (ORD_...Src)
 			  left join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  left join #Lung_Sta3n528_0_5_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt) --altered (temp table)
			  on DimICD9Proc.[ICD9ProcedureCode]=TargetCode.ICD9ProcCode

			  left join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			    left join #Lung_Sta3n528_0_3_PreProcICD10ProcExc as ICD10CodeList    --altered (ORD_...Dflt) --altered (temp table)
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from #Lung_Sta3n528_1_In_8_IncPat) as pat    --altered (ORD_...Dflt) --altered (temp table)
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where --CohortName='Cohort20180712' and
  ([SurgicalProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  and [SurgicalProcedureDateTime]<= DateAdd(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  )
  and (TargetCode.ICD9Proc_code_type is not null or ICD10CodeList.ICD10Proc_code_type is not null)
go



	if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc	    --altered (ORD_...Dflt) --altered (temp table)

			 select pat.patientssn,a.sta3n,b.patientsid	,b.[TreatmentFromDateTime]
			  ,DimICD9Proc.[ICD9ProcedureCode],TargetCode.ICD9ProcCode,TargetCode.ICD9Proc_Code_Type
    			,DimICD10Proc.ICD10ProcedureCode,ICD10CodeList.ICD10ProcCode,ICD10CodeList.ICD10Proc_Code_Type
	into #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	from [CDWWork].[Fee].[FeeInpatInvoiceICDProcedure] as a    --altered (ORD_...Src)
	inner join[CDWWork].[Fee].[FeeInpatInvoice] as b    --altered (ORD_...Src)
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
			  left join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  left join #Lung_Sta3n528_0_5_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt) --altered (temp table)
			  on DimICD9Proc.[ICD9ProcedureCode]=TargetCode.ICD9ProcCode

			  left join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			    left join #Lung_Sta3n528_0_3_PreProcICD10ProcExc as ICD10CodeList    --altered (ORD_...Dflt) --altered (temp table)
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode 
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from #Lung_Sta3n528_1_In_8_IncPat) as pat    --altered (ORD_...Dflt) --altered (temp table)
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where --a.CohortName='Cohort20180712' and b.CohortName='Cohort20180712' and
  ([TreatmentFromDateTime] >= DateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  and [TreatmentFromDateTime]<= DateAdd(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  )
   and (TargetCode.ICD9Proc_code_type is not null or ICD10CodeList.ICD10Proc_code_type is not null)
 go


 -- combine all Icd9Procedure from inpatient tables
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc    --altered (ORD_...Dflt) --altered (temp table)
	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9Proc_Code_Type
	  ,'Inp-InpICD'	  as datasource	  
    into #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc	    --altered (ORD_...Dflt) --altered (temp table)
	from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	where ICD9Proc_code_type is not null
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9Proc_Code_Type
	  ,'Inp-CensusICD'	  as datasource
	from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	where ICD9Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9Proc_Code_Type
	 ,'Inp-InpSurg'	  as datasource	 
	from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	where ICD9Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
	  ,ICD9Proc_Code_Type
      ,[ICD9ProcedureCode]      
	 ,'Inp-CensusSurg'	  as datasource
	from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	where ICD9Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9Proc_Code_Type
	 ,'Inp-FeeICDProc'	  as datasource
	 from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	where ICD9Proc_code_type is not null
	
go

-- combine all Icd10Procedure from inpatient tables

if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	

	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10Proc_Code_Type
	  ,'Inp-InpICD'	  as datasource
    into  #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	where ICD10Proc_code_type is not null
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10Proc_Code_Type
	  ,'Inp-CensusICD'	  as datasource
	from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	where ICD10Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10Proc_Code_Type
	 ,'Inp-InpSurg'	  as datasource	 
	from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	where ICD10Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
	  ,ICD10Proc_Code_Type
      ,[ICD10ProcedureCode]      
	 ,'Inp-CensusSurg'	  as datasource
	from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	where ICD10Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10Proc_Code_Type
	 ,'Inp-FeeICDProc'	  as datasource
	 from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
	where ICD10Proc_code_type is not null

	
go




-- Inpatien CPT procedure
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt) --altered (temp table)

select pat.patientssn,pat.scrssn,CPTProc.sta3n,CPTProc.patientsid,CPTProc.[CPTProcedureDateTime]
	,DimCPT.[CPTCode],DimCPT.CPTName,DimCPT.CPTDescription ,CPT_code_type, patientICN
into  #Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt) --altered (temp table)
FROM [CDWWork].[Inpat].[InpatientCPTProcedure] as CPTProc    --altered (ORD_...Src)
inner join cdwwork.dim.CPT as DimCPT
	on CPTProc.[CPTSID]=DimCPT.CPTSID  
inner join 
	(select CPT_code_type,CPTCode from  #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
	union
	select img_code_type,ImgCode as CPTCode from  #Lung_Sta3n528_0_2_0_LungImg    --altered (ORD_...Dflt) --altered (temp table)
	) as TargetCode
	on DimCPT.CPTCode=TargetCode.CPTCode
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from #Lung_Sta3n528_1_In_8_IncPat) as pat    --altered (ORD_...Dflt) --altered (temp table)
	on CPTProc.patientsid=pat.patientsid and CPTProc.sta3n=pat.sta3n
where  --CPTProc.CohortName='Cohort20180712' and
	 CPTProc.[CPTProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
	and CPTProc.[CPTProcedureDateTime] <= DateAdd(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
go



-- Outpatient CPT procedure
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt) --altered (temp table)
		
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
into #Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt) --altered (temp table)
FROM [CDWWork].[Outpat].[WorkloadVProcedure] as VProc    --altered (ORD_...Src)
inner join CDWWork.[Dim].[CPT] as DimCPT 
	on  VProc.[CPTSID]=DimCPT.CPTSID
inner join 
	(select CPT_code_type,CPTCode from  #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
	union
	select img_code_type,ImgCode as CPTCode from  #Lung_Sta3n528_0_2_0_LungImg    --altered (ORD_...Dflt) --altered (temp table)
	) as TargetCode
	on DimCPT.CPTCode=TargetCode.CPTCode
inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
	on VProc.sta3n=p.sta3n and VProc.patientsid=p.patientsid
where 
	--VProc.CohortName='Cohort20180712' and
	 [VProcedureDateTime] >= DateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
	and [VProcedureDateTime] <= DateAdd(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
go

-- Surgical CPT procedures
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg    --altered (ORD_...Dflt) --altered (temp table)
	

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
	  --,assocCPT.CPTCode as assocProcedureCode
	  --,assocCPT.CPTDescription as assocProcedureDescription
	  ,OtherCPT.CPTCode as OtherProcedureCode
	  ,OtherCPT.CPTDescription as OtherProcedureDescription
	  ,p.patientSSN
into #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg    --altered (ORD_...Dflt) --altered (temp table)
FROM [CDWWork].[Surg].[SurgeryPre] as surgPre    --altered (ORD_...Src)
  inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
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
    SurgPre.[SurgeryDateTime] >= DateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  and SurgPre.[SurgeryDateTime] <= DateAdd(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)

  --and  SurgPre.CohortName='Cohort20180712'
  --and  surgDx.CohortName='Cohort20180712'
  --and  assocProc.CohortName='Cohort20180712'
  and (
		  PrincipalCPT.CPTCode in 
		  (select CPTCode from  #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
			union
			select ImgCode as CPTCode from  #Lung_Sta3n528_0_2_0_LungImg)					     --altered (ORD_...Dflt) --altered (temp table)
		  or OtherCPT.CPTCode in
		  (select CPTCode from  #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
			union
			select ImgCode as CPTCode from  #Lung_Sta3n528_0_2_0_LungImg)					     --altered (ORD_...Dflt) --altered (temp table)
		)
go


 --Fee CPT procedure
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
		drop table #Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt) --altered (temp table)
							 
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
into #Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt) --altered (temp table)
FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
	on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
inner join cdwwork.dim.CPT as DimCPT
	on a.[ServiceProvidedCPTSID]=DimCPT.[CPTSID]  
inner join 
(select CPT_code_type,CPTCode from  #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
union
select img_code_type,ImgCode as CPTCode from  #Lung_Sta3n528_0_2_0_LungImg    --altered (ORD_...Dflt) --altered (temp table)
) as TargetCode
	on DimCPT.CPTCode=TargetCode.CPTCode
inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from #Lung_Sta3n528_1_In_8_IncPat) as pat    --altered (ORD_...Dflt) --altered (temp table)
	on a.sta3n=pat.sta3n and a.patientsid=pat.patientsid
where --a.CohortName='Cohort20180712'  and d.CohortName='Cohort20180712' and
     InitialTreatmentDateTime >= DateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
  and InitialTreatmentDateTime <= DateAdd(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
go	
											
	
-- LungBiopsy procedure
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy    --altered (ORD_...Dflt) --altered (temp table)


select patientSSN,sta3n,patientSID,[Proc_dt] as LungBiopsy_dt,'LungBiopsy-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD','LungBiopsy' as code_type
into  #Lung_Sta3n528_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy    --altered (ORD_...Dflt) --altered (temp table)
from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc    --altered (ORD_...Dflt) --altered (temp table)
		where [Proc_dt] is not null 
		and ICD9Proc_code_type='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[Proc_dt] as LungBiopsy_dt,'LungBiopsy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD','LungBiopsy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as LungBiopsy_dt,'LungBiopsy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','LungBiopsy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt) --altered (temp table)
		where [CPTProcedureDateTime] is not null 
		and CPT_code_type='LungBiopsy'
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as LungBiopsy_dt ,'LungBiopsy-OutPat' as datasource,[CPTCode] as 'CPTOrICD','LungBiopsy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt) --altered (temp table)
		where [VProcedureDateTime] is not null
		and CPT_code_type='LungBiopsy'
	UNION 
select patientSSN,sta3n,patientSID,[DateOfOperation] as LungBiopsy_dt,'LungBiopsy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','LungBiopsy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
		where isnull([PrincipalProcedureCode],'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
													  where cpt_code_type='LungBiopsy')
	UNION 
select patientSSN,sta3n,patientSID,[DateOfOperation] as LungBiopsy_dt,'LungBiopsy-Surg' as datasource, OtherProcedureCode as 'CPTOrICD','LungBiopsy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
		where isnull(OtherProcedureCode,'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc     --altered (ORD_...Dflt) --altered (temp table)
													  where cpt_code_type='LungBiopsy')
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as LungBiopsy_dt,'LungBiopsy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','LungBiopsy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt) --altered (temp table)
		where InitialTreatmentDateTime is not null
		and CPT_code_type='LungBiopsy'
go


-- Bronchoscopy procedure
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy    --altered (ORD_...Dflt) --altered (temp table)

select patientSSN,sta3n,patientSID,[Proc_dt] as Bronchoscopy_dt,'Bronchoscopy-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD','Bronchoscopy' as code_type
into  #Lung_Sta3n528_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy    --altered (ORD_...Dflt) --altered (temp table)
from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc    --altered (ORD_...Dflt) --altered (temp table)
		where [Proc_dt] is not null
		and ICD9Proc_code_type='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[Proc_dt] as Bronchoscopy_dt,'Bronchoscopy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD','Bronchoscopy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as Bronchoscopy_dt,'Bronchoscopy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','Bronchoscopy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt) --altered (temp table)
		where [CPTProcedureDateTime] is not null
		and CPT_code_type='Bronchoscopy'
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as Bronchoscopy_dt ,'Bronchoscopy-OutPat' as datasource,[CPTCode] as 'CPTOrICD','Bronchoscopy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt) --altered (temp table)
		where [VProcedureDateTime] is not null
		and CPT_code_type='Bronchoscopy'
	UNION 
select patientSSN,sta3n,patientSID,[DateOfOperation] as Bronchoscopy_dt,'Bronchoscopy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','Bronchoscopy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
		where isnull([PrincipalProcedureCode],'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
													  where cpt_code_type='Bronchoscopy')
	UNION 
select patientSSN,sta3n,patientSID,[DateOfOperation] as Bronchoscopy_dt,'Bronchoscopy-Surg' as datasource, OtherProcedureCode as 'CPTOrICD','Bronchoscopy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
		where isnull(OtherProcedureCode,'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc     --altered (ORD_...Dflt) --altered (temp table)
													  where cpt_code_type='Bronchoscopy')
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as Bronchoscopy_dt,'Bronchoscopy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','Bronchoscopy' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt) --altered (temp table)
		where InitialTreatmentDateTime is not null
		and CPT_code_type='Bronchoscopy'
go


--Lung Surgery
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery    --altered (ORD_...Dflt) --altered (temp table)


select patientSSN,sta3n,patientSID,[Proc_dt] as LungSurgery_dt,'LungSurgery-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD','LungSurgery' as code_type
into  #Lung_Sta3n528_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery    --altered (ORD_...Dflt) --altered (temp table)
from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc    --altered (ORD_...Dflt) --altered (temp table)
		where [Proc_dt] is not null
		and ICD9Proc_code_type='LungSurgery'   
union
select patientSSN,sta3n,patientSID,[Proc_dt] as LungSurgery_dt,'LungSurgery-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD','LungSurgery' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
		where [Proc_dt] is not null		
		and [ICD10Proc_code_type]='LungSurgery'
union
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as LungSurgery_dt,'LungSurgery-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','LungSurgery' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt) --altered (temp table)
		where [CPTProcedureDateTime] is not null
		and CPT_code_type='LungSurgery'   								 			
union
select patientSSN,sta3n,patientSID,[VProcedureDateTime] as LungSurgery_dt ,'LungSurgery-OutPat' as datasource,[CPTCode] as 'CPTOrICD','LungSurgery' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt) --altered (temp table)
		where [VProcedureDateTime] is not null
		and CPT_code_type='LungSurgery'
	UNION 
select patientSSN,sta3n,patientSID,[DateOfOperation] as LungSurgery_dt,'LungSurgery-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','LungSurgery' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
		where isnull([PrincipalProcedureCode],'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
													  where cpt_code_type='LungSurgery')
	UNION 
select patientSSN,sta3n,patientSID,[DateOfOperation] as LungSurgery_dt,'LungSurgery-Surg' as datasource, OtherProcedureCode as 'CPTOrICD','LungSurgery' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
		where isnull(OtherProcedureCode,'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc     --altered (ORD_...Dflt) --altered (temp table)
													  where cpt_code_type='LungSurgery')
union
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as LungSurgery_dt,'LungSurgery-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','LungSurgery' as code_type
from #Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt) --altered (temp table)
		where InitialTreatmentDateTime is not null
		and CPT_code_type='LungSurgery'
go


-- Chest XRay
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_E_PrevProc_AllNonDxProcICD9ICD10Proc_XRay') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
		drop table #Lung_Sta3n528_3_Exc_NonDx_E_PrevProc_AllNonDxProcICD9ICD10Proc_XRay    --altered (ORD_...Dflt) --altered (temp table)

select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as Img_dt,'XRAY-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','XRay' as code_type
into  #Lung_Sta3n528_3_Exc_NonDx_E_PrevProc_AllNonDxProcICD9ICD10Proc_XRay    --altered (ORD_...Dflt) --altered (temp table)
--union
--from #Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt) --altered (temp table)
--		where [CPTProcedureDateTime] is not null
--		and CPT_code_type ='XRay'
--union
--select patientSSN,sta3n,patientSID,[VProcedureDateTime] as Img_dt ,'XRAY-OutPat' as datasource,[CPTCode] as 'CPTOrICD','XRay' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt) --altered (temp table)
--		where [VProcedureDateTime] is not null
--		and CPT_code_type ='XRay'
--	UNION 
--select patientSSN,sta3n,patientSID,[DateOfOperation] as Img_dt,'XRAY-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','XRay' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
--		where isnull([PrincipalProcedureCode],'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
--													  where cpt_code_type='XRay')
--	UNION 
--select patientSSN,sta3n,patientSID,[DateOfOperation] as Img_dt,'XRAY-Surg' as datasource, OtherProcedureCode as 'CPTOrICD','XRay' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
--		where isnull(OtherProcedureCode,'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc     --altered (ORD_...Dflt) --altered (temp table)
--													  where cpt_code_type='XRay')
from #Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt) --altered (temp table)
		where InitialTreatmentDateTime is not null
		and CPT_code_type ='XRay'

go

--Chest CT
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_F_PrevProc_AllNonDxProcICD9ICD10Proc_CT') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Exc_NonDx_F_PrevProc_AllNonDxProcICD9ICD10Proc_CT    --altered (ORD_...Dflt) --altered (temp table)

select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as Img_dt,'CT-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','CT' as code_type
into  #Lung_Sta3n528_3_Exc_NonDx_F_PrevProc_AllNonDxProcICD9ICD10Proc_CT    --altered (ORD_...Dflt) --altered (temp table)
--union
--select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as img_dt,'CT-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','CT' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt) --altered (temp table)
--		where [CPTProcedureDateTime] is not null
--		and CPT_code_type ='CT'
--union
--select patientSSN,sta3n,patientSID,[VProcedureDateTime] as Img_dt ,'CT-OutPat' as datasource,[CPTCode] as 'CPTOrICD','CT' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt) --altered (temp table)
--		where [VProcedureDateTime] is not null
--		and CPT_code_type ='CT'
--	UNION 
--select patientSSN,sta3n,patientSID,[DateOfOperation] as Img_dt,'CT-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','CT' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
--		where isnull([PrincipalProcedureCode],'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
--													  where cpt_code_type='CT')
--	UNION 
--select patientSSN,sta3n,patientSID,[DateOfOperation] as Img_dt,'CT-Surg' as datasource, OtherProcedureCode as 'CPTOrICD','CT' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
--		where isnull(OtherProcedureCode,'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc     --altered (ORD_...Dflt) --altered (temp table)
--													  where cpt_code_type='CT')
from #Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt) --altered (temp table)
		where InitialTreatmentDateTime is not null
		and CPT_code_type ='CT'
go

--Chest PET
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Exc_NonDx_G_PrevProc_AllNonDxProcICD9ICD10Proc_PET') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Exc_NonDx_G_PrevProc_AllNonDxProcICD9ICD10Proc_PET    --altered (ORD_...Dflt) --altered (temp table)


select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as Img_dt,'PET-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD','PET' as code_type
into  #Lung_Sta3n528_3_Exc_NonDx_G_PrevProc_AllNonDxProcICD9ICD10Proc_PET    --altered (ORD_...Dflt) --altered (temp table)
--union
--select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as img_dt,'PET-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD','PET' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt) --altered (temp table)
--		where [CPTProcedureDateTime] is not null
--		and CPT_code_type ='PET'
--union
--select patientSSN,sta3n,patientSID,[VProcedureDateTime] as Img_dt ,'PET-OutPat' as datasource,[CPTCode] as 'CPTOrICD','PET' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt) --altered (temp table)
--		where [VProcedureDateTime] is not null
--		and CPT_code_type ='PET'
--	UNION 
--select patientSSN,sta3n,patientSID,[DateOfOperation] as Img_dt,'PET-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD','PET' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
--		where isnull([PrincipalProcedureCode],'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
--													  where cpt_code_type='PET')
--	UNION 
--select patientSSN,sta3n,patientSID,[DateOfOperation] as Img_dt,'PET-Surg' as datasource, OtherProcedureCode as 'CPTOrICD','PET' as code_type
--from #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg     --altered (ORD_...Dflt) --altered (temp table)
--		where isnull(OtherProcedureCode,'') in (select cptcode from #Lung_Sta3n528_0_8_PrevProcCPTCodeExc     --altered (ORD_...Dflt) --altered (temp table)
--													  where cpt_code_type='PET')
from #Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt) --altered (temp table)
		where InitialTreatmentDateTime is not null
		and CPT_code_type ='PET'
go


-- Visit,referral and physician's note from potential patient

if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
		drop table #Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1    --altered (ORD_...Dflt) --altered (temp table)
					
select p.patientSSN
	,V.Sta3n,V.PatientSID,V.Visitsid,V.VisitDatetime,V.primaryStopcodeSID,V.SecondaryStopcodeSID					
into #Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1					    --altered (ORD_...Dflt) --altered (temp table)
from [CDWWork].[Outpat].[Visit] as V    --altered (ORD_...Src)
inner join 
	(select distinct pat.*,ins.ExamDateTime 
		from #Lung_Sta3n528_1_In_8_IncPat as pat    --altered (ORD_...Dflt) --altered (temp table)
		left join #Lung_Sta3n528_1_In_6_IncIns as ins    --altered (ORD_...Dflt) --altered (temp table)
		on pat.patientSSN=ins.PatientSSN 
	) as p 
	on v.sta3n=p.sta3n and v.patientsid=p.patientsid 
	and v.VisitDateTime between dateAdd(yy,-1,p.ExamDateTime)
					and DateAdd(dd,30+(select fu_period from #Lung_Sta3n528_0_1_inputP),p.ExamDateTime)    --altered (ORD_...Dflt) --altered (temp table)
where 	--CohortName='Cohort20180712'	and	
	V.VisitDateTime between dateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
						and DateAdd(dd,30+(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))						      --altered (ORD_...Dflt) --altered (temp table)
go


if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
					drop table #Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits    --altered (ORD_...Dflt) --altered (temp table)

   select PatientSSN,VisitSID,VisitDateTime,PrimaryStopCodeSID,SecondaryStopCodeSID
   into #Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits    --altered (ORD_...Dflt) --altered (temp table)
   from #Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1    --altered (ORD_...Dflt) --altered (temp table)
   union
   select PatientSSN,VisitSID,VisitDateTime,PrimaryStopCodeSID,SecondaryStopCodeSID
   from #Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1    --altered (ORD_...Dflt) --altered (temp table)
go


if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits_StopCode') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits_StopCode    --altered (ORD_...Dflt) --altered (temp table)
					
	select v.*,code1.stopcode as PrimaryStopCode,code1.stopcodename as PrimaryStopCodeName
			,code2.stopcode as SecondaryStopCode,code2.stopcodename as SecondaryStopCodeName
	into #Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits_StopCode    --altered (ORD_...Dflt) --altered (temp table)
	from #Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits as V    --altered (ORD_...Dflt) --altered (temp table)
	left join [CDWWork].[Dim].[StopCode] as code1
	on V.PrimaryStopCodeSID=code1.StopCodeSID		
	left join [CDWWork].[Dim].[StopCode] as code2
	on V.SecondaryStopCodeSID=code2.StopCodeSID

go

--Physician's notes from the visit
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_9_Ex_2_VisitTIU') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Ins_9_Ex_2_VisitTIU    --altered (ORD_...Dflt) --altered (temp table)


	select v.*
	,T.[TIUDocumentSID],T.[EntryDateTime],T.[ReferenceDateTime]
	,e.tiustandardtitle,T.ConsultSID
	into #Lung_Sta3n528_3_Ins_9_Ex_2_VisitTIU				    --altered (ORD_...Dflt) --altered (temp table)
	from #Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits_StopCode as V    --altered (ORD_...Dflt) --altered (temp table)
	left join [CDWWork].[TIU].[TIUDocument] as T    --altered (ORD_...Src)
	on T.VisitSID=V.Visitsid --and T.CohortName='Cohort20180712'
					--more filter
					--and T.[EntryDateTime] between dateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
					--	and DateAdd(dd,30+(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))						      --altered (ORD_...Dflt) --altered (temp table)
	left join cdwwork.dim.[TIUDocumentDefinition] as d                                         
	on t.[TIUDocumentDefinitionSID]=d.[TIUDocumentDefinitionSID]
	left join cdwwork.dim.TIUStandardTitle as e
	on d.TIUStandardTitleSID=e.TIUStandardTitleSID
	--where isnull(T.OpCode,'')<>'D'

				
go

-- Referrals
-- E-Consult shares the same stop code as the physical location
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)

			select v.*
			,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
			c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName,
			c.placeofconsultation,	  
			c.requestType, -- weather the request is a consult or procedure
			c.[InpatOutpat], -- the ordering person to indicate if the service is to be rendered on an outpatient or Inpatients basis.
			c.[RemoteService],
			d.StopCode as ConStopCode
			into #Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID				    --altered (ORD_...Dflt) --altered (temp table)
            from #Lung_Sta3n528_3_Ins_9_Ex_2_VisitTIU as V    --altered (ORD_...Dflt) --altered (temp table)
			left join [CDWWork].[Con].[Consult] as C										                        --altered (ORD_...Src)
			on C.ConsultSID=V.ConsultSID --and CohortName='Cohort20180712'		
					--more filter
					--and C.[requestDateTime] between dateAdd(yy,-1,(select sp_start from #Lung_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt) --altered (temp table)
					--	and DateAdd(dd,30+(select fu_period from #Lung_Sta3n528_0_1_inputP),(select sp_end from #Lung_Sta3n528_0_1_inputP))						      --altered (ORD_...Dflt) --altered (temp table)
			left join CDWWork.dim.AssociatedStopCode as d
			on c.ToRequestserviceSID=d.RequestServiceSID
				
go

--------------------------------------------------------------------------------------------------------------------------------
-----  4. Exclude red-flagged patients with certain clinical diagnosis and other 
--------------------------------------------------------------------------------------------------------------------------------

--  Red-flagged instances: Exclude patients <18 years old 
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_0_1_In_4_Age') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Ins_0_1_In_4_Age    --altered (ORD_...Dflt) --altered (temp table)
select Rad.* 
into #Lung_Sta3n528_3_Ins_0_1_In_4_Age    --altered (ORD_...Dflt) --altered (temp table)
from #Lung_Sta3n528_1_In_6_IncIns as Rad    --altered (ORD_...Dflt) --altered (temp table)
where (DATEDIFF(yy,DOB,Rad.[ExamDateTime]) >= (select age from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
		 or patientssn is null 
         )  

go

--  Red-flagged instances: Exclude deseased patients
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_0_2_In_5_Alive') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Ins_0_2_In_5_Alive    --altered (ORD_...Dflt) --altered (temp table)

select age.* into #Lung_Sta3n528_3_Ins_0_2_In_5_Alive    --altered (ORD_...Dflt) --altered (temp table)
 from #Lung_Sta3n528_3_Ins_0_1_In_4_Age as age      --altered (ORD_...Dflt) --altered (temp table)
 where 
        [DOD] is null 		
		or (DOD is not null 
				and ( 
					DATEADD(dd,-(select fu_period from #Lung_Sta3n528_0_1_inputP),dod)>age.ExamDateTime    --altered (ORD_...Dflt) --altered (temp table)
					)
				)	   	     
go
	
--  Red-flagged instances: Exclude patients with previous lung cancer
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_1_Ex_LungCancer') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
	drop table #Lung_Sta3n528_3_Ins_1_Ex_LungCancer    --altered (ORD_...Dflt) --altered (temp table)
go

select a.*
into #Lung_Sta3n528_3_Ins_1_Ex_LungCancer    --altered (ORD_...Dflt) --altered (temp table)
from #Lung_Sta3n528_3_Ins_0_2_In_5_Alive as a    --altered (ORD_...Dflt) --altered (temp table)
where not exists
	(select * from #Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9ICD10 as b    --altered (ORD_...Dflt) --altered (temp table)
		where a.[PatientSSN] = b.[PatientSSN]
		and (b.RecordedDateTime between DATEADD(yy,-1,a.[ExamDateTime]) and a.[ExamDateTime]))			 
go
			 
	
--  Red-flagged instances: Exclude patients with terminal/major DX		
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_2_Ex_Termi_Major') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_2_Ex_Termi_Major    --altered (ORD_...Dflt) --altered (temp table)
		go

		select *
		into #Lung_Sta3n528_3_Ins_2_Ex_Termi_Major    --altered (ORD_...Dflt) --altered (temp table)
		from #Lung_Sta3n528_3_Ins_1_Ex_LungCancer as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select * from #Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10 as b    --altered (ORD_...Dflt) --altered (temp table)
				where a.[PatientSSN] = b.[PatientSSN] and b.dx_code_type='Terminal' and 
			 (b.dx_dt between DATEADD(yy,-1,a.[ExamDateTime]) and DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),a.[ExamDateTime])))    --altered (ORD_...Dflt) --altered (temp table)
		go
		

 --  Red-flagged instances: Exclude patients with hospice/palliative diagnosis
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx    --altered (ORD_...Dflt) --altered (temp table)
		go

		select *
		into #Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx    --altered (ORD_...Dflt) --altered (temp table)
		from #Lung_Sta3n528_3_Ins_2_Ex_Termi_Major as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select * from #Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10 as b    --altered (ORD_...Dflt) --altered (temp table)
			 where a.[PatientSSN] = b.[PatientSSN] and b.dx_code_type='Hospice'  and 
			 b.dx_dt between DATEADD(yy,-1,a.[ExamDateTime] ) and 
			 DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),a.[ExamDateTime]))		    --altered (ORD_...Dflt) --altered (temp table)
		go

--  Red-flagged instances: Exclude patients with hospice/palliative care
				if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee    --altered (ORD_...Dflt) --altered (temp table)
		go


	select * 
	into #Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee    --altered (ORD_...Dflt) --altered (temp table)
	from #Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx    --altered (ORD_...Dflt) --altered (temp table)
	except
	SELECT x.*
	 from #Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx as x    --altered (ORD_...Dflt) --altered (temp table)
	 inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
	 on  x.PatientSSN=p.PatientSSN
	 inner join [CDWWork].[Fee].[FeeInpatInvoice] as a    --altered (ORD_...Src)
	 on a.Sta3n=p.sta3n and a.PatientSID=p.patientsid
		inner join cdwwork.dim.FeePurposeOfVisit as b
		on a.FeePurposeOfVisitSID=b.FeePurposeOfVisitSID
	  where ltrim(rtrim(b.AustinCode)) in ('43','37','38','77','78')   and
	   a.TreatmentFromDateTime 		between DATEADD(yy,-1,x.ExamDateTime) and 
					  DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),x.ExamDateTime)    --altered (ORD_...Dflt) --altered (temp table)
go


--  Red-flagged instances: Exclude patients with Inpatient hospice/palliative care

				if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_ByPTF') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_ByPTF    --altered (ORD_...Dflt) --altered (temp table)

	select * 
	into #Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_ByPTF    --altered (ORD_...Dflt) --altered (temp table)
	from #Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee    --altered (ORD_...Dflt) --altered (temp table)
	except
	SELECT x.*
	 from #Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee as x    --altered (ORD_...Dflt) --altered (temp table)
	 inner join #Lung_Sta3n528_1_In_8_IncPat as p    --altered (ORD_...Dflt) --altered (temp table)
	 on  x.PatientSSN=p.PatientSSN
	 inner join [CDWWork].[Inpat].[Inpatient] as a    --altered (ORD_...Src)
	 on a.Sta3n=p.sta3n and a.PatientSID=p.patientsid
	 inner join CDWWork.Dim.Specialty as s
	 on a.DischargeFromSpecialtySID=s.SpecialtySID and a.sta3n=s.sta3n
	  where ltrim(rtrim(s.PTFCode)) in ('96','1F') and
	   a.[DischargeDateTime] between DATEADD(yy,-1,x.ExamDateTime) and 
					  DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),x.ExamDateTime)    --altered (ORD_...Dflt) --altered (temp table)
go		

		
--  Red-flagged instances: Exclude patients with hospice/palliative referral
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
													 
				
		select *
		into #Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
        from #Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_ByPTF as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(	select * from #Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID as b    --altered (ORD_...Dflt) --altered (temp table)
				 where (
						 --With Stopcode
						   b.[primaryStopcode] in (351,353) or b.[secondaryStopcode] in (351,353) or b.ConStopCode in (351,353)   --Hospice
						 -- There is a visit, but the StopCode is missing
							or (
							b.[ConsultToRequestserviceName] like '%Hospice%' or b.[ConsultToRequestserviceName] like '%palliative%'
							or b.TIUStandardTitle like '%Hospice%' or b.TIUStandardTitle like '%palliative%'
							))				
				 and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				 and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
				 and a.patientSSN = b.patientSSN
				 and (coalesce(b.ReferenceDateTime,b.visitdatetime) between DATEADD(yy,-1, convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP), convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))    --altered (ORD_...Dflt) --altered (temp table)
				 and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
					  ) 
			)

go

--  Red-flagged instances: Exclude patients with tuberculosis diagnosis
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_4_Ex_Tuber') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_4_Ex_Tuber    --altered (ORD_...Dflt) --altered (temp table)
		go

				select *
		into #Lung_Sta3n528_3_Ins_4_Ex_Tuber    --altered (ORD_...Dflt) --altered (temp table)
		from #Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select * from #Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10 as b    --altered (ORD_...Dflt) --altered (temp table)
			 where a.[PatientSSN] = b.[PatientSSN] and b.dx_code_type='Tuberculosis' and
			 			 (b.dx_dt between DATEADD(yy,-1,a.[ExamDateTime]) and
			  DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP),a.[ExamDateTime]))    --altered (ORD_...Dflt) --altered (temp table)
			 )
		
		go
	
--------------------------------------------------------------------------------------------------------------------------------
-----  5. Exclude red-flagged patients with timely follow up
--------------------------------------------------------------------------------------------------------------------------------
		
--  Red-flagged instances: Exclude patients with LungBiopsy completed
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy    --altered (ORD_...Dflt) --altered (temp table)
	
		select *
		into #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy    --altered (ORD_...Dflt) --altered (temp table)
		from #Lung_Sta3n528_3_Ins_4_Ex_Tuber as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select * from #Lung_Sta3n528_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy as b    --altered (ORD_...Dflt) --altered (temp table)
			 where a.patientSSN = b.PatientSSN and
			 b.LungBiopsy_dt between DATEADD(dd,-(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
											,convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00' as datetime)) 
						and DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
											,convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59:997' as datetime)))

go

--  Red-flagged instances: Exclude patients with Bronchoscopy completed
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy    --altered (ORD_...Dflt) --altered (temp table)
	
		select *
		into #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy    --altered (ORD_...Dflt) --altered (temp table)
		from #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select * from #Lung_Sta3n528_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy as b    --altered (ORD_...Dflt) --altered (temp table)
			 where a.patientSSN = b.PatientSSN and
			 b.Bronchoscopy_dt between DATEADD(dd,-(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
											,convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00' as datetime)) 
						and DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
											,convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59:997' as datetime)))
		go
		
--  Red-flagged instances: Exclude patients with Lung Surgery completed
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery    --altered (ORD_...Dflt) --altered (temp table)
	
		select *
		into #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery    --altered (ORD_...Dflt) --altered (temp table)
		from #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select * from #Lung_Sta3n528_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery as b    --altered (ORD_...Dflt) --altered (temp table)
			 where a.patientSSN = b.PatientSSN and
			 b.LungSurgery_dt between DATEADD(dd,-(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
											,convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00' as datetime)) 
						and DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
											,convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59:997' as datetime)))

		go

	

--  Red-flagged instances: Exclude patients with follow up chest XRay completed
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_A_XRay') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_A_XRay    --altered (ORD_...Dflt) --altered (temp table)

					select a.*
		into  #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_A_XRay    --altered (ORD_...Dflt) --altered (temp table)
		from  #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select * from (select PatientSSN,ExamDateTime,img_code_type from #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN     --altered (ORD_...Dflt) --altered (temp table)
						where [img_code_type]='XRay'
					 union  select patientssn, img_dt as ExamDateTime,code_type as img_code_type from  #Lung_Sta3n528_3_Exc_NonDx_E_PrevProc_AllNonDxProcICD9ICD10Proc_XRay    --altered (ORD_...Dflt) --altered (temp table)
						   where code_type='XRAY'
			   ) as b
			 where a.PatientSSN = b.patientSSN and			 
			 (b.ExamDateTime > a.examDateTime
					and	b.ExamDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
														,(convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime))))
			 and b.[img_code_type]='XRay'
			 )			 
go

--  Red-flagged instances: Exclude patients with follow up chest CT completed
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_B_CT') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_B_CT    --altered (ORD_...Dflt) --altered (temp table)

					select a.*
		into  #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_B_CT    --altered (ORD_...Dflt) --altered (temp table)
		from  #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_A_XRay as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
				(select * from (select PatientSSN,ExamDateTime,img_code_type from #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN     --altered (ORD_...Dflt) --altered (temp table)
				       where [img_code_type]='CT'
					 union  select patientssn, img_dt as ExamDateTime,code_type as img_code_type from  #Lung_Sta3n528_3_Exc_NonDx_F_PrevProc_AllNonDxProcICD9ICD10Proc_CT    --altered (ORD_...Dflt) --altered (temp table)
						   where code_type='CT'
			   ) as b
			 where a.PatientSSN = b.patientSSN and			 
			 (b.ExamDateTime > a.ExamDateTime
					and	b.ExamDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
														,(convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime))))
			 and b.[img_code_type]='CT'
			 )			 
go

--  Red-flagged instances: Exclude patients with follow up chest PET completed
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_C_PET') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_C_PET    --altered (ORD_...Dflt) --altered (temp table)

					select a.*
		into  #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_C_PET    --altered (ORD_...Dflt) --altered (temp table)
		from  #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_B_CT as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
				(select * from (select PatientSSN,ExamDateTime,img_code_type from #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN     --altered (ORD_...Dflt) --altered (temp table)
				where [img_code_type]='PET'
					 union  select patientssn, img_dt as ExamDateTime,code_type as img_code_type from  #Lung_Sta3n528_3_Exc_NonDx_G_PrevProc_AllNonDxProcICD9ICD10Proc_PET    --altered (ORD_...Dflt) --altered (temp table)
						   where code_type='PET'
			   ) as b
			 where a.PatientSSN = b.patientSSN and			 
			 (b.ExamDateTime > a.ExamDateTime
					and	b.ExamDateTime<= DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
														,(convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime))))
			 and b.[img_code_type]='PET'
			 )			 
go

	
--  Red-flagged instances: Exclude patients with pulm consult completed
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
				
		select *
		into #Lung_Sta3n528_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
        from #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_C_PET as a		    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select * from #Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID as b    --altered (ORD_...Dflt) --altered (temp table)
			 where (
			 --With Stopcode
			 b.PrimaryStopCode in (312,104)   or b.SecondaryStopCode in (312,104)  or b.ConStopCode in (312,104)  
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
					DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
							, convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))
			    and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
					))
						
go


--  Red-flagged instances: Exclude patients with THORACIC SURGERY consult completed
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
				
		select *
		into #Lung_Sta3n528_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
        from #Lung_Sta3n528_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select * from #Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID as b    --altered (ORD_...Dflt) --altered (temp table)
			 where (
					 --With Stopcode
					b.[primaryStopcode] in (413,64) or b.[SecondaryStopcode] in (413,64) or b.ConStopCode in (413,64)   
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
					DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
									, convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))
					and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
						-- make sure not 2 or 3 years off
			         or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
					  ))						

go


--  Red-flagged instances: Exclude patients with Tumor Board conference completed
		if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
				
		select *
		into #Lung_Sta3n528_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
        from #Lung_Sta3n528_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select * from #Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID as b    --altered (ORD_...Dflt) --altered (temp table)
			 where  (
					((b.[primaryStopcode] in (316) or b.[SecondaryStopcode] in (316) or b.ConStopCode in (316)) --oncology
												--and [tiustandardtitle] like '%Tumor%Board%'
												)
			        or b.TIUStandardTitle like '%tumor%board%'					
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				    and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
					--Tumor, stopcode+title
					and a.patientSSN = b.patientSSN 
					and (coalesce(b.ReferenceDateTime,b.visitdatetime) between (convert(varchar(10),a.ExamDateTime,120)+cast('00:00:00.000' as datetime)) and 
						DATEADD(dd,(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
										, convert(varchar(10),a.ExamDateTime,120)+cast('23:59:59.997' as datetime)))
					and (datediff(dd,b.visitDateTime,isnull(b.ReferenceDateTime,b.visitDateTime))<(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
							or datediff(dd,isnull(b.ReferenceDateTime,b.visitDateTime),b.visitDateTime)<(select fu_period from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
							) )

go


--------------------------------------------------------------------------------------------------------------------------------
-----  6. Trigger positive chest images from potential patients
--------------------------------------------------------------------------------------------------------------------------------

--  Trigger Positive instances
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_U_TriggerPos') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_U_TriggerPos    --altered (ORD_...Dflt) --altered (temp table)

	select distinct * 
	into #Lung_Sta3n528_3_Ins_U_TriggerPos    --altered (ORD_...Dflt) --altered (temp table)
	from #Lung_Sta3n528_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
go
--  First instance in the study period in case of multiple trigger position instances, 
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_3_Ins_V_TriggerPos_FirstOfPat_SP') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_3_Ins_V_TriggerPos_FirstOfPat_SP    --altered (ORD_...Dflt) --altered (temp table)
		go

		select *
		into #Lung_Sta3n528_3_Ins_V_TriggerPos_FirstOfPat_SP    --altered (ORD_...Dflt) --altered (temp table)
		from #Lung_Sta3n528_3_Ins_U_TriggerPos as a    --altered (ORD_...Dflt) --altered (temp table)
		where not exists
			(select *
			 from #Lung_Sta3n528_3_Ins_U_TriggerPos as b    --altered (ORD_...Dflt) --altered (temp table)
			 where a.PatientSSN = b.patientSSN and			 
			 b.ExamDateTime < a.ExamDateTime)
		and a.[ExamDateTime] between (select sp_start from #Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt) --altered (temp table)
							and (select sp_end from #Lung_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt) --altered (temp table)
			 	
go

--------------------------------------------------------------------------------------------------------------------------------
-----  7. counts
--------------------------------------------------------------------------------------------------------------------------------

-- Numerator and Denumerator
if (OBJECT_ID('tempdb.dbo.#Lung_Sta3n528_4_01_Count') is not null)    --altered (ORD_...Dflt) --altered (object_id temp table)
			drop table #Lung_Sta3n528_4_01_Count    --altered (ORD_...Dflt) --altered (temp table)
		go

		With -- number of Chest XRay/CT performed
		NumOfTotalChestXRayCT (sta3n,sta6a,[Year],[Month],NumOfTotalChestXRayCT) as 	 
			(select  sta3n,sta6a,datepart(year,ExamDateTime) as [Year],datepart(MONTH,ExamDateTime) as[Month],count(distinct  RadiologyExamSID ) as NumOfTotalChestXRayCT
				 from #Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a    --altered (ORD_...Dflt) --altered (temp table)
				 where ExamDateTime >=(select sp_start from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
					   and ExamDateTime <=(select sp_end from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
				 group by sta3n,Sta6a,datepart(year,ExamDateTime),datepart(MONTH,ExamDateTime)
			) 
		-- number of patients with Chest XRay/CT performed
		,NumOfTotalPatWithChestXRayCT (sta3n,sta6a,[Year],[Month],NumOfTotalPatWithChestXRayCT) as
			(select sta3n,sta6a, datepart(year,ExamDateTime) as [Year],datepart(MONTH,ExamDateTime) as[Month],count(distinct  patientssn ) as NumOfTotalPatWithChestXRayCT
				 from #Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a    --altered (ORD_...Dflt) --altered (temp table)
				 where ExamDateTime >=(select sp_start from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
					   and ExamDateTime <=(select sp_end from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
				 group by sta3n,Sta6a,datepart(year,ExamDateTime),datepart(MONTH,ExamDateTime)
			) 
		-- number of Chest XRay/CT which are red-flageed
		,NumOfRedFlaggedChestXRayCT(sta3n,sta6a,[Year],[Month],NumOfRedFlaggedChestXRayCT) as 
				(select sta3n,sta6a,datepart(year,ExamDateTime) as [Year],datepart(MONTH,ExamDateTime) as[Month],count(distinct  RadiologyExamSID ) as NumOfRedFlaggedChestXRayCT
				from #Lung_Sta3n528_1_In_3_RedFlagXRayCT    --altered (ORD_...Dflt) --altered (temp table)
					 where ExamDateTime >=(select sp_start from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
						   and ExamDateTime <=(select sp_end from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
				group by sta3n,sta6a,datepart(year,ExamDateTime),datepart(MONTH,ExamDateTime)
			)
		-- number of patients with red-flagged Chest XRay/CT
		,NumOfPatWithRedFlaggedChestXRayCT(sta3n,sta6a,[Year],[Month],NumOfPatWithRedFlaggedChestXRayCT) as 
				(select sta3n,sta6a,datepart(year,ExamDateTime) as [Year],datepart(MONTH,ExamDateTime) as[Month],count(distinct  patientssn ) as NumOfPatWithRedFlaggedChestXRayCT
				from #Lung_Sta3n528_1_In_3_RedFlagXRayCT    --altered (ORD_...Dflt) --altered (temp table)
					 where ExamDateTime >=(select sp_start from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
						   and ExamDateTime <=(select sp_end from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
				group by sta3n,sta6a,datepart(year,ExamDateTime),datepart(MONTH,ExamDateTime)
			)
		-- number of Chest XRay/CT which come out trigger positive
		,NumOfTriggerPosChestXRayCT(sta3n,sta6a,[Year],[Month],NumOfTriggerPosChestXRayCT) as
			(select sta3n,sta6a,datepart(year,ExamDateTime) as [Year],datepart(MONTH,ExamDateTime) as[Month],count(distinct  RadiologyExamSID ) as NumOfTriggerPosChestXRayCT
				from #Lung_Sta3n528_3_Ins_U_TriggerPos    --altered (ORD_...Dflt) --altered (temp table)
					where ExamDateTime >=(select sp_start from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
						 and ExamDateTime <=(select sp_end from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
					group by sta3n,sta6a,datepart(year,ExamDateTime),datepart(MONTH,ExamDateTime)
			)
		-- number of patients with trigger positive Chest XRay/CT
		,NumOfTriggerPosPat(sta3n,sta6a,[Year],[Month],NumOfTriggerPosPat) as 
				(select sta3n,sta6a,datepart(year,ExamDateTime) as [Year],datepart(MONTH,ExamDateTime) as[Month],count(distinct  patientssn ) as NumOfTriggerPosPat
				 from #Lung_Sta3n528_3_Ins_U_TriggerPos    --altered (ORD_...Dflt) --altered (temp table)
							where ExamDateTime >=(select sp_start from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
					and ExamDateTime <=(select sp_end from #Lung_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt) --altered (temp table)
					group by sta3n,sta6a,datepart(year,ExamDateTime),datepart(MONTH,ExamDateTime)
		)

			select 
					(select  run_dt  from #Lung_Sta3n528_0_1_inputP) as run_dt    --altered (ORD_...Dflt) --altered (temp table)
					,(select  sp_start from #Lung_Sta3n528_0_1_inputP) as sp_start    --altered (ORD_...Dflt) --altered (temp table)
					,(select  sp_end from #Lung_Sta3n528_0_1_inputP) as sp_end    --altered (ORD_...Dflt) --altered (temp table)
					,a.sta3n,a.sta6a,a.[Year],a.[month]
					,isnull(NumOfTotalChestXRayCT,0) as NumOfTotalChestXRayCT
					,isnull(NumOfTotalPatWithChestXRayCT,0) as NumOfTotalPatWithChestXRayCT
					,isnull(NumOfRedFlaggedChestXRayCT,0) as NumOfRedFlaggedChestXRayCT
					,isnull(NumOfPatWithRedFlaggedChestXRayCT,0) as NumOfPatWithRedFlaggedChestXRayCT
					,isnull(NumOfTriggerPosChestXRayCT,0) as NumOfTriggerPosChestXRayCT
					,isnull(NumOfTriggerPosPat,0) as NumOfTriggerPosPat
			into #Lung_Sta3n528_4_01_Count    --altered (ORD_...Dflt) --altered (temp table)
			from  NumOfTotalChestXRayCT as a
			left join NumOfTotalPatWithChestXRayCT as b
			on a.sta3n=b.sta3n and a.sta6a=b.sta6a and a.[year]=b.[year] and a.[Month]=b.[Month]
			left join NumOfRedFlaggedChestXRayCT as c
			on a.sta3n=c.sta3n and a.sta6a=c.sta6a and a.[year]=c.[year] and a.[Month]=c.[Month]
			left join NumOfPatWithRedFlaggedChestXRayCT as d
			on a.sta3n=d.sta3n and a.sta6a=d.sta6a and a.[year]=d.[year] and a.[Month]=d.[Month]
			left join NumOfTriggerPosChestXRayCT as e
			on a.sta3n=e.sta3n and a.sta6a=e.sta6a and a.[year]=e.[year] and a.[Month]=e.[Month]
			left join NumOfTriggerPosPat as f
			on a.sta3n=f.sta3n and a.sta6a=f.sta6a and a.[year]=f.[year] and a.[Month]=f.[Month]

go

select * from #Lung_Sta3n528_4_01_Count    --altered (ORD_...Dflt) --altered (temp table)
order by sta3n,sta6a,[year],[month]

---- data set:  Chest XRay/CT performed
--select * from #Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a    --altered (ORD_...Dflt) --altered (temp table)
---- data set:  Chest XRay/CT which are red-flaged
--select * from #Lung_Sta3n528_1_In_3_RedFlagXRayCT    --altered (ORD_...Dflt) --altered (temp table)
---- data set:  Chest XRay/CT which come out trigger positive
--select * from #Lung_Sta3n528_3_Ins_U_TriggerPos    --altered (ORD_...Dflt) --altered (temp table)



---- Delete intermediate tables

--Drop table #Lung_Sta3n528_0_0_1_Sta3nSta6a    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_0_1_inputP    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_0_2_0_LungImg    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_0_2_DxICD10CodeExc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_0_3_PreProcICD10ProcExc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_0_4_DxICD9CodeExc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_0_5_PreProcICD9ProcExc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_0_6_LungCancerDxICD10CodeExc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_0_7_LungCancerDxICD9CodeExc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_0_8_PrevProcCPTCodeExc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_0_A_RedFlagXRayCTDiagnosticCode    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_1_In_1_All_Chest_XRayCTPET_SSN    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_1_In_2_All_Chest_XRayCT_Sta6a    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_1_In_3_RedFlagXRayCT    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_1_In_6_IncIns    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_1_In_8_IncPat    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_1_SurgDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_2_OutPatDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Census501Diagnosis    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_3_B_InpatientFeeDiagnosisDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_4_AllDx_ICD10    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_4_AllDx_ICD9    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_4_UnionAllDx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_2_Ex_7_ProblemListLC_Dx_ICD9ICD10    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD10Proc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_3_PrevProc_Inpat_0_UnionAllInpICD9Proc    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_4_PrevProc_Inpat_1_CPT    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_5_PrevProc_Outpat    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_6_PrevProc_surg    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_7_PrevProc_FeeServiceProvidedCPT    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_8_PrevProc_AllNonDxProcICD9ICD10Proc_LungBiopsy    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_9_PrevProc_AllNonDxProcICD9ICD10Proc_Bronchoscopy    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_A_PrevProc_AllNonDxProcICD9ICD10Proc_LungSurgery    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_E_PrevProc_AllNonDxProcICD9ICD10Proc_XRay    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_F_PrevProc_AllNonDxProcICD9ICD10Proc_CT    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Exc_NonDx_G_PrevProc_AllNonDxProcICD9ICD10Proc_PET    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_0_1_In_4_Age    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_0_2_In_5_Alive    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_1_Ex_LungCancer    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_2_Ex_Termi_Major    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_3_Ex_Hospi_1_ByDx    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_3_Ex_Hospi_2_Fee    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_ByPTF    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_3_Ex_Hospi_3_Refer_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_4_Ex_Tuber    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_A_LungBiopsy    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_B_Bronchoscopy    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_7_OutCome_Lung_Proc_C_LungSurgery    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_A_XRay    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_B_CT    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_8_OutCome_Rep_Img_C_PET    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_9_Ex_0_AllVisits_Hlp1    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_9_Ex_1_AllVisits_StopCode    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_9_Ex_2_VisitTIU    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_9_Ex_3_VisitTIUconsult_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_D_OutCome_refer_1_pulm_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_D_OutCome_refer_3_ThoracicSurgery_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_D_OutCome_refer_4_TumorBoard_joinByConsultSID    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_U_TriggerPos    --altered (ORD_...Dflt) --altered (temp table)
--Drop table #Lung_Sta3n528_3_Ins_V_TriggerPos_FirstOfPat_SP    --altered (ORD_...Dflt) --altered (temp table)

 
