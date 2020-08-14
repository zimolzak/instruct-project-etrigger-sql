--------------------------------------------
--- FOBT Cancer Trigger 
--------------------------------------------

--		1. What this SQL script does: Extract FOBT tests which are diagnosed as positive. Among these positive (red-flagged) tests, exclude those from patients who have clinical explanations or have 
--			completed timely follow up. The rest of red-flagged tests are considered potentially missed followed up, and we call them "trigger positive".
--          This script runs across sta3n level data. ALBANY,NY(528A8) was coded as an example.
--
--		2. Give 60 days followup window: A red-flagged FOBT test needs 60 days to follow up. Always make sure, when setting up the study period, that the clinical data within 60 days after the FOBT test date is available.
--
--      TobeAltered:
--		3. This SQL script is written for CDW Research Data Warehouse, so it needs corresponding changes if run in Operational Data Warehouse. Search for the following string and replace
--			them with your corresponding database name, data schema and table names:
--			database name: MyDB 
--			data schema:   MySchema 
--			Table names:   We have mapped table names from Research data to Operational. But we currently do not have live access to Operational data to test the mappings. 

--      TobeAltered:
--		4. FOBT_Sta3n528_0_xxx has the input parameters, including site(s) info, study period, standard codes( CPT, ICD, ICDproc etc.).
--		  Although these codes are standardized, if your local site(s) uses them in different flavors, consider customization. Also exam these tables after being populated to make sure codes
--		  used in your site(s) are all included.
--							--Set your study period.
--							set @sp_start='2017-01-01 00:00:00'
--							set @sp_end='2017-01-31 23:59:59' 
--
--		5. Set your site(s) code in table FOBT_Sta3n528_0_0_1_Sta3nSta6a. This table has the sites(s) that trigger whose data trigger will run against. The site can be CBOC as well as Hospital.
--		   Search for string "--Set site(s) codes here. Keep only your site(s) uncommented.". Here you input the site(s) you are interested in running and comment out the others.
--                       Example:
--                       ( 528,'528A8') -- (528) Upstate New York HCS; ALBANY, NY VAMC 
--                      ,(642,'642GA') --  (642) Philadelphia, PA; FORT DIX OUTPATIENT CLINIC/CBC
			
--      TobeAltered:
--		6. FOBT test names
--		   5.1 Table FOBT_Sta3n528_0_7_FOBTLabTestName will have the list of FOBT tests your sta3n uses
--			  select * from MyDB.MySchema.FOBT_Sta3n528_0_7_FOBTLabTestName
--			  where sta3n= @Sta3n
--			  Exam the FOBT tests that your site(s) uses. If your site(s) uses other FOBT tests, insert them to this table as well.
--
--      TobeAltered:
--		7. Red-flagged FOBT test values
--		   7.1 Table FOBT_Sta3n528_0_A_RedFlagFOBTTestResult will have the list of FOBT test values which will be marked as positive.
--			   Add any additional codes that your site(s) might use, or remove any that your site do(es) not use by setting isRedFlag=0.
--		   7.2 Search for string "-- Using Abnormal Flag". Trigger will consider FOBT value which is marked as 'Hxxx' as positive. Make corresponsing change here if it does not apply to your site(s).
--
--		8. Other possible changes
--		   Standard codes ( CPT,ICD, ICDProcedure, LOINC etc.) might change every year, with addition of new codes and removal of old ones. These changes require corresponding updates of this script. 
--		   Always add new codes to parameter tables. Do NOT remove old codes because script still checks back for clinical history.		  
--
--      9. Data Set		    
			--FOBT_Sta3n528_1_Inc_1_AllFOBTSta6a		-- 	All FOBT tests from sta6a in the study period
			--FOBT_Sta3n528_1_Inc_8_IncIns				--  Positive ( red_flagged) FOBT tests  from sta6a in the study period
			--FOBT_Sta3n528_5_Ins_U_TriggerPos			--  FOBT tests from sta6a in the study period, which come out trigger positive
			
--		10. If you want to delete the intermediate table generated during execution. uncomment the block at the end of the script.
--
--		11. Numerator and denumerators table: FOBT_Sta3n528_5_Ins_X_count







--------------------------------------------------------------------------------------------------------------------------------
-----  1. Initial set up: Input parameters, CPT and ICD diagnosis code, and ICDProcedure code lists used in the trigger measurement
--------------------------------------------------------------------------------------------------------------------------------

use master	
go

set lock_timeout -1

-- Set study parameters.
-----------------------

declare @trigger varchar(20)		
declare @isVISN bit 				--Trigger runs on VISN data levle
declare @VISN smallint				
declare @isSta3n bit				--Trigger runs on Sta3n data levle
declare @Sta3n smallint				
--declare @Sta6a varchar(10)			--Site Code
declare @run_date datetime2(0)			--Date time of trigger run
declare @sp_start datetime2(0)			
declare @sp_end datetime2(0)            
declare @fu_period as smallint		--follow-up window for red-flagged patients  
declare @age_lower as smallint
declare @age_upper as smallint

declare @ICD9Needed bit				--ICD9 and ICD9Proc are not searched if run trigger in year 2017 and beyond, set to 0


-- Set study parameters
set @trigger='FOBT'					--Name of the trigger
set @isVISN=0						--Disabled. Trigger runs against data of sta3n level 
set @VISN=-1
set @isSta3n=0						--Enabled. Trigger runs against data of sta3n level 
set @Sta3n=-1


set @run_date=getdate()
set @sp_start='2020-01-01 00:00:00' --Study starting date time
set @sp_end='2020-05-31 23:59:59'	--Study starting end time
--  Follow-up period
set @fu_period=60
set @age_lower=40
set @age_upper=75
set @ICD9Needed=1 					


-- set your site code
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_0_0_1_Sta3nSta6a]') is not null)	    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_0_0_1_Sta3nSta6a    --altered (ORD_...Dflt)
	CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_0_1_Sta3nSta6a (    --altered (ORD_...Dflt)
	Sta3n smallint null,
	Sta6a [varchar](10) NULL
	) 




insert into  [MyDB].[MySchema].FOBT_Sta3n528_0_0_1_Sta3nSta6a (Sta3n,Sta6a)     --altered (ORD_...Dflt)
values 
 (
 --Set site(s) codes here. Keep only your site(s) uncommented. Comment out all the other sites.
  -- Cohort 1
 528,'528A8') --	(528A8) ALBANY,NY
--,(642,'642') --	(642) Philadelphia, PA, CorporalMichael K.Crescenz VA Medical center
--,(644,'644') --	(644) Phoenix, AZ, Phoenix VA Health Care System
--,(671,'671')	--	(671) South Texas HCS (San Antonio TX)-Audie

 -- Cohort 2
--,(537,'537') --	(537) JESSE BROWN VAMC
--,(549,'549') --	(549) North Texas HCS (Dallas TX)
--,(589,'589') --	(589) VA Heartland West (Kansas City MO)
--,(691,'691') --	(691)VA GREATER LOS ANGELES (691)

 -- Cohort 3
--,(635,'635') --	(635) Oklahoma City, OK
--Another 528 site:
--,(528,'528A7') --	 (528A7) (Syracuse, NY)
--,(540,'540') --	(540) Clarksburg, WV
--,(523,'523') --	(523)BOSTON HCS VAMC

-- Discovery
-- Baltimore missing diagnosticcode, go with Note Title
--,(512,'512') --	(512) Maryland HCS (Baltimore MD)
--,(580,'580') --	(580) Houston, TX
--,(541,'541') --(541) Cleveland, OH

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_0_1_inputP]') is not null)	    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP    --altered (ORD_...Dflt)

		CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP(    --altered (ORD_...Dflt)
		[trigger] [varchar](20) NULL,
		[VISN] [smallint] NULL,		 
		--Sta3n smallint null,
		--Sta6a varchar(10) null,
		[run_dt] datetime2(0) NULL,
		[sp_start] datetime2(0) NULL,
		[sp_end] datetime2(0) NULL,
		[fu_period] [smallint] NULL,
		[age_Lower] [smallint] NULL,
		[age_upper] [smallint] NULL,
		[ICD9Needed] bit)
--go

INSERT INTO [MyDB].[MySchema].[FOBT_Sta3n528_0_1_inputP]    --altered (ORD_...Dflt)
           ([trigger]
		   ,[VISN]
		   --,Sta3n
		   --,Sta6a
           ,[run_dt]
           ,[sp_start]
           ,[sp_end]
		   ,[ICD9Needed]
           ,[fu_period]
           ,[age_lower]
		   ,[age_upper]
           )
     VALUES
           (
           @trigger
		   ,@VISN
		   --,@Sta3n
		   --,@sta6a
		   ,@run_date
           ,@sp_start
           ,@sp_end
		   ,@ICD9Needed
           ,@fu_period
           ,@age_lower
		   ,@age_upper
           )


go

select * from [MyDB].[MySchema].[FOBT_Sta3n528_0_0_1_Sta3nSta6a]    --altered (ORD_...Dflt)
select * from [MyDB].[MySchema].[FOBT_Sta3n528_0_1_inputP]    --altered (ORD_...Dflt)
go
-- Colon Cancer ICD9 Dx code list
if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_0_8_ColonCancerDxICD9Code') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_0_8_ColonCancerDxICD9Code    --altered (ORD_...Dflt)
go


	CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_8_ColonCancerDxICD9Code (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go

If Exists (select ICD9Needed from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP where ICD9Needed=1)    --altered (ORD_...Dflt)
begin
	insert into [MyDB].[MySchema].FOBT_Sta3n528_0_8_ColonCancerDxICD9Code ([dx_code_type],	[dx_code_name] ,[ICD9Code])    --altered (ORD_...Dflt)
	select 	'PrevColonCancer','ColonCancer','154.0'
	insert into [MyDB].[MySchema].FOBT_Sta3n528_0_8_ColonCancerDxICD9Code ([dx_code_type],	[dx_code_name] ,[ICD9Code])    --altered (ORD_...Dflt)
	select 	'PrevColonCancer','ColonCancer','154.1'
	insert into [MyDB].[MySchema].FOBT_Sta3n528_0_8_ColonCancerDxICD9Code ([dx_code_type],	[dx_code_name] ,[ICD9Code])    --altered (ORD_...Dflt)
	select 	'PrevColonCancer','ColonCancer','154.2'
	insert into [MyDB].[MySchema].FOBT_Sta3n528_0_8_ColonCancerDxICD9Code ([dx_code_type],	[dx_code_name] ,[ICD9Code])    --altered (ORD_...Dflt)
	select 	'PrevColonCancer','ColonCancer','154.3'
	insert into [MyDB].[MySchema].FOBT_Sta3n528_0_8_ColonCancerDxICD9Code ([dx_code_type],	[dx_code_name] ,[ICD9Code])    --altered (ORD_...Dflt)
	select 	'PrevColonCancer','ColonCancer','154.8'
	insert into [MyDB].[MySchema].FOBT_Sta3n528_0_8_ColonCancerDxICD9Code ([dx_code_type],	[dx_code_name] ,[ICD9Code])    --altered (ORD_...Dflt)
	select distinct	'PrevColonCancer','ColonCancer',
			ICD9Code from CDWWork.dim.icd9
			where icd9code like '153%'--'%153.[^0]%'	
end

-- Colon Cancer ICD10 Dx code list
if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_0_9_ColonCancerDxICD10Code') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_0_9_ColonCancerDxICD10Code    --altered (ORD_...Dflt)
go


	CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_9_ColonCancerDxICD10Code (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go




insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.6'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.7'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.5'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.8'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C18.9'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C19.'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C20.'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C21.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C21.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'PrevColonCancer','ColonCancer','C21.8'


-- Clinical Exclusion ICD10 Dx code list 

if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc    --altered (ORD_...Dflt)
go


	CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc (    --altered (ORD_...Dflt)
--	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD10Code] [varchar](10) NULL
	) 
go


insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.00'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.40'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.50'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.01'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.41'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.51'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.02'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.42'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.52'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.60'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.A0'
-- added 20200617
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.61'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.62'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.A1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C92.A2'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C93.00'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C93.01'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C93.02'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.00'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.01'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.02'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.20'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.21'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C94.22'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C95.00'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C95.01'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Terminal','Leukemia (Acute Only)','C95.02'


insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.3'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.7'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.8'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C22.9'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Hepatocelllular Cancer','C78.7'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C23.'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.8'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Biliary Cancer','C24.9'


insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.3'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.5'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.8'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Esophageal Cancer','C15.9'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.3'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.5'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.6'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.8'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Gastric Cancer','C16.9'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.3'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.5'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.6'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.7'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.8'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C71.9'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C79.31'
--added 20200617
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C79.40'
--missing
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C79.32'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Brain Cancer','C79.49'


insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Ovarian Cancer','C56.9'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Ovarian Cancer','C56.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Ovarian Cancer','C56.2'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.3'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.7'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.8'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pancreatic Cancer','C25.9'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.00'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.01'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.02'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.10'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.11'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.12'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.30'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.31'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.32'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.80'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.81'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.82'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.90'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.91'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C34.92'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C78.00'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C78.01'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Lung Cancer','C78.02'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pleural Cancer & Mesothelioma','C38.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pleural Cancer & Mesothelioma','C45.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Pleural Cancer & Mesothelioma','C78.2'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Uterine Cancer','C55.'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C45.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.8'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C48.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Peritonel, Omental & Mesenteric Cancer','C78.6'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','C90.00'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','C90.01'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','C90.02'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Myeloma','D47.Z9'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Tracheal Cancer','C33.'
--added 20200617
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Tracheal Cancer','C78.39'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Terminal','Tracheal Cancer','C78.30'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 	'Hospice','','Z51.5'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K92.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K22.11'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K25.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K25.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K25.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K25.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K25.6'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K26.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K26.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K26.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K26.6'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K27.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K27.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K27.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K27.6'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K28.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K28.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K28.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'K28.6'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'I85.01'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'UpperGIBleeding','', 'I85.11'


insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N92.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N92.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N92.4'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N95.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R31.9'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R31.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R31.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R31.2'
--added 20200617
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R31.21'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R31.29'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R04.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N89.8'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N92.5'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N93.8'
--20200617
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','N93.1'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R04.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R04.9'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','R04.89'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'OtherBleeding','','T79.2XXA'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','Z34.00'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','Z34.80'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','Z34.90'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','Z33.1'
--added 20200617
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','Z33.3'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.00'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.10'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.291'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.40'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.211'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.291'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.291'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.30'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.511'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.521'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.611'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.621'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.891'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.892'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.893'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.899'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.90'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.91'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.92'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.93'
--added 20200617
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O09.A0'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.8'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.9'
--added 20200617
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.101'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.102'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.109'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.201'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.202'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.209'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.211'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.212'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.219'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.80'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.81'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Pregnancy','','O00.90'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemia','','D56.9'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemia','','D57.40'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemia','','D57.419'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemia','','D56.0'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemia','','D56.1'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemia','','D56.2'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemia','','D56.3'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemia','','D56.5'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_2_DxICD10CodeExc] ([dx_code_type],	[dx_code_name] ,[ICD10Code])    --altered (ORD_...Dflt)
select 'Thalassemia','','D56.8'


-- Clinical Exclusion ICD10Procedure code list 

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_0_3_PreProcICD10ProcExc]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[FOBT_Sta3n528_0_3_PreProcICD10ProcExc]    --altered (ORD_...Dflt)
go

	CREATE TABLE [MyDB].[MySchema].[FOBT_Sta3n528_0_3_PreProcICD10ProcExc] (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[ICD10Proc_code_type] [varchar](50) NULL,
	[ICD10Proc_code_Name] [varchar](50) NULL,
	[ICD10ProcCode] [varchar](10) NULL
	) 
go


insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','0DTE4ZZ'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','0DTE0ZZ'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','0DTE7ZZ'
insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','0DTE8ZZ'

insert into [MyDB].[MySchema].[FOBT_Sta3n528_0_3_PreProcICD10ProcExc] ([ICD10Proc_code_type],	[ICD10Proc_code_Name] ,[ICD10ProcCode])    --altered (ORD_...Dflt)
select 'Colonoscopy','','0DJD8ZZ'


-- Clinical Exclusion ICD9 Dx code list 

if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc    --altered (ORD_...Dflt)
go


	CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[dx_code_type] [varchar](50) NULL,
	[dx_code_name] [varchar](50) NULL,
	[ICD9Code] [varchar](10) NULL
	) 
go

--Thalessemia: Any time in patient's clinical history, only apply to IDA
insert into  [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc ([ICD9Code])     --altered (ORD_...Dflt)
select distinct ICD9Code from CDWWork.dim.ICD9 as dimICD9
where dimICD9.ICD9Code like
		-- Thalessemia
			'282.4%'

insert into  [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc (    --altered (ORD_...Dflt)
	[ICD9Code]
	) 
select distinct ICD9Code from CDWWork.dim.ICD9 as dimICD9
where	((select ICD9Needed from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)=1) and    --altered (ORD_...Dflt)
			-------------------------------------------------------- Terminal
		(	dimICD9.ICD9Code in (

			-- Leukemia (Acute Only)
				--'205.0','205.01','205.02',
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
				--'162.1',
				'162.2','162.3','162.4','162.5','162.6','162.7','162.8','162.9','197.0',
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
			---------------------------------------------------------- Only IDA only--------------------------
			-------------------------------------------------------- -Other bleeding 
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
				'629.81','631.0','633.0','633.01','633.10',--'633.2%','633.8%','633.9%',

				'V22.0','V22.1','V22.2','V23.0','V23.1','V23.2',
				'V23.3','V23.41','V23.49','V23.5','V23.7','V23.81',
				'V23.82','V23.83','V23.84','V23.89','V23.9',

				'633.0','633.01','633.10','633.20','633.21','633.80','633.81','633.90','633.91'
		)
			-------------------------------------------------------- Previous Colorectal Cancer
		--or ICD9.ICD9Code like
		---- Colon Cancer Codes
		--	'153.%'			
			-------------------------------------------------------- Terminal				
		or dimICD9.ICD9Code like
		-- Leukemia (Acute Only)
			'207.2%'
			or dimICD9.ICD9Code like
				'207.0%'
			or dimICD9.ICD9Code like
				'205.0%'
			or dimICD9.ICD9Code like
				'206.0%'
			or dimICD9.ICD9Code like
				'208.0%'
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
  --Thalessemia: Any time in patient's history, insert seperately
  --  	or dimICD9.ICD9Code like
		---- Thalessemia
		--	'282.4%'
			----------------------------------------------------------- Pregnancy
		-- Pregnancy
		)


update [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc    --altered (ORD_...Dflt)
set   dx_code_type = case
		when ICD9Code in (
			-- Leukemia (Acute Only)
				--'205.0','206.0','207.0','208.0',
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
				--'162.1',
				'162.2','162.3','162.4','162.5','162.6','162.7','162.8','162.9','197.0',
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
								or ICD9Code like
									'207.0%'
								or ICD9Code like
									'205.0%'
								or ICD9Code like
									'206.0%'
								or ICD9Code like
									'208.0%'
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
			 then 'UpperGIBleeding'
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
			 then 'OtherBleeding'
		when ICD9Code in (
			-- Pregnancy
				'629.81','631.0','633.0','633.01','633.10',--'633.2%','633.8%','633.9%',

				'V22.0','V22.1','V22.2','V23.0','V23.1','V23.2',
				'V23.3','V23.41','V23.49','V23.5','V23.7','V23.81',
				'V23.82','V23.83','V23.84','V23.89','V23.9',
				
				'633.0','633.01','633.10','633.20','633.21','633.80','633.81','633.90','633.91'
			) then 'Pregnancy'
		when ICD9Code like 
				-- Thalassemia
				'282.4%'
			 then 'Thalassemia'
		else NULL
	end
go

-- Clinical Exclusion CPT code list 
	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_0_5_PrevProcCPTCodeExc]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
go

	CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[CPT_code_type] [varchar](50) NULL,
	[CPT_code_name] [varchar](50) NULL,
	[CPTCode] [varchar](10) NULL
	) 
go


insert into  [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc (    --altered (ORD_...Dflt)
	[CPT_code_type],
	[CPT_code_name] ,
	[CPTCode] 
	) 
Values --('colonoscopy','','44387') not exists
('colonoscopy','','44388')
,('colonoscopy','','44389')
,('colonoscopy','','44391')
,('colonoscopy','','44392')
,('colonoscopy','','44394')
,('colonoscopy','','45378')
,('colonoscopy','','45379')
,('colonoscopy','','45380')
,('colonoscopy','','45381')
,('colonoscopy','','45382')
,('colonoscopy','','45383')
,('colonoscopy','','45384')
,('colonoscopy','','45385')
,('colonoscopy','','45386')
,('colonoscopy','','45387')
,('colonoscopy','','45355')
,('colonoscopy','','45391')
,('colonoscopy','','45392')

,('colonoscopy','','45388')
,('colonoscopy','','45389')
,('colonoscopy','','45399')

,('colectomy','','44150')
,('colectomy','','44151')
,('colectomy','','44155')
,('colectomy','','44156')
,('colectomy','','44157')
,('colectomy','','44158')
,('colectomy','','44202')
,('colectomy','','44210')
,('colectomy','','44211')
,('colectomy','','44212')
go

-- Clinical Exclusion ICD9Procedure code list 
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_0_6_PreProcICD9ProcExc]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[FOBT_Sta3n528_0_6_PreProcICD9ProcExc]    --altered (ORD_...Dflt)
go

	CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	[ICD9Proc_code_type] [varchar](50) NULL,
	[ICD9Proc_code_Name] [varchar](50) NULL,
	[ICD9ProcCode] [varchar](9) NULL
	) 
go

-- Colectomy: Any time in patient's clinical history
insert into [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc ([ICD9Proc_code_type],	[ICD9Proc_code_Name] ,[ICD9ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','45.81'
insert into [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc ([ICD9Proc_code_type],	[ICD9Proc_code_Name] ,[ICD9ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','45.82'
insert into [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc ([ICD9Proc_code_type],	[ICD9Proc_code_Name] ,[ICD9ProcCode])    --altered (ORD_...Dflt)
select 	'Colectomy','','45.83'

If Exists (select ICD9Needed from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP where ICD9Needed=1)    --altered (ORD_...Dflt)
begin
insert into [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc ([ICD9Proc_code_type],	[ICD9Proc_code_Name] ,[ICD9ProcCode])    --altered (ORD_...Dflt)
select 	'Colonoscopy','','45.23'
end

go


-- FOBT test  
	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_0_7_FOBTLabTestName    --altered (ORD_...Dflt)
go

	CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_7_FOBTLabTestName (    --altered (ORD_...Dflt)
	           Sta3n smallint NULL
			,LabChemTestSID int NULL 
           ,LOINC_Original varchar(50) NULL
           --,LOINC_Mapped nvarchar(50) NULL
           ,LabChemTestName varchar(50) NULL
		   ,[LabChemPrintTestName] varchar(50) NULL
           --,TopographySID int NULL
           --,Units varchar(50) NULL
           --,Topography varchar(100) NULL
           --,DOMAIN_ID varchar(20) NULL
           --,CONCEPT_ID int NULL
           --,SOURCE_CONCEPT_ID int NULL
           --,CONCEPT_NAME varchar(500) NULL
           --,SOURCE_CONCEPT_NAME varchar(500) NULL
           --,VALUE_CONCEPT_ID int NULL
		    )
go



INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000064483, N'14563-1', N'FOBT#1, 1/2007 thru 12/2009', N'FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000069826, N'14564-9', N'OCCULT BLOOD (FIT) #2 OF 3,12/09-1/16', N'FIT 2/3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000075628, N'2335-8', N'OCCULT BLOOD,SINGLE CARD,1/07 thru 12/09', N'FOBT,R')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000104243, N'14563-1', N'OCCULT BLOOD (FIT-R) #1 OF 1', N'FITrsch 1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000122797, N'57905-2', N'OCCULT BLOOD (FIT) #1 OF 1', N'FIT1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000125995, N'29771-3', N'OCCULT BLOOD FIT RANDOM', N'FIT Ran')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (642, 1400005260, N'14563-1', N'OCCULT BLOOD #1', N'OCC BL1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (642, 1400009511, N'14563-1', N'POCT-OCCULT BLOOD', N'POC OCC')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (642, 1400012497, N'14564-9', N'OCCULT BLOOD #2', N'OCC BL2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (642, 1400012498, N'14565-6', N'OCCULT BLOOD #3', N'OCC BL3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (642, 1400078585, N'14563-1', N'IFOBT #1', N'IFOBT #1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (642, 1400078586, N'14564-9', N'IFOBT #2', N'IFOBT #2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (642, 1400078587, N'14565-6', N'IFOBT #3', N'IFOBT #3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (642, 1400570283, N'29771-3', N'CSP-577 OCCULT BLOOD(FIT)', N'CSP-577 FIT')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (644, 800000675, N'14565-6', N'Occult Blood #3', N'FOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (644, 800036890, N'2335-8', N'OCCULT BLOOD SPOT TEST', N'GUAIAC')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (644, 800074605, N'14563-1', N'Occult Blood #1', N'FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (644, 800075804, N'14564-9', N'Occult Blood #2', N'FOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (644, 800224828, N'2335-8', N'CSP#577 OCCULT BLOOD(FIT)#1OF1', N'FIT1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (644, 800257151, NULL, N'Occult Blood (FIT) #1 of 1', N'FIT')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (671, 1000001444, N'2335-8', N'ZZZOCCULT BLOOD (KERRVILLE ONLY)', N'ZZZOCCULT')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (671, 1000023514, N'2335-8', N'OCCULT BLOOD DAY 1', N'OCC1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (671, 1000028047, N'2335-8', N'POC OCCULT BLOOD ANCILLARY', N'POC OCB')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (671, 1000032176, N'14565-6', N'OCCULT BLOOD DAY 3', N'OCC3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (671, 1000035160, N'14565-6', N'IFOBT3', N'FOBT3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (671, 1000038595, N'2335-8', N'FOBT ACCUCHECK (ED/TRIAGE ONLY)', N'FOBT(TRIAGE ONLY)')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (671, 1000053200, N'14564-9', N'ZZZIFOBT2', N'ZZZFOBT2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (671, 1000097002, N'29771-3', N'IFOBT(SINGLE TEST),SCREEN', N'FOBT1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (671, 1000097003, N'29771-3', N'IFOBT1', N'IFOBT1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (691, 800001613, N'2335-8', N'OCCULT BLOOD, STOOL', N'OCC BLD')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (691, 800001614, N'2335-8', N'FIT', N'FIT')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (691, 800053904, N'2335-8', N'OCCULT BLOOD, STOOL (SPOT)', N'OCCBLDs')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (691, 800061861, N'14565-6', N'Occult Blood, Stool #3 disc 7/12/19', N'zOCCBLD3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (691, 800064262, N'14564-9', N'Occult Blood, Stool #2 disc 7/12/19', N'zOCCBLD2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400000167, NULL, N'ZZOCCULT BLOOD #3', N'FOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400000167, N'14565-6', N'ZZOCCULT BLOOD #3', N'FOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400015216, NULL, N'ZZOCCULT BLOOD #1', N'FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400015216, N'14563-1', N'ZZOCCULT BLOOD #1', N'FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400020074, NULL, N'OCCULT BLOOD CNTRL 1', N'OBC1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400020074, N'2335-8', N'OCCULT BLOOD CNTRL 1', N'OBC1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400020761, NULL, N'OCCULT BLOOD CNTRL 2', N'OCBLDC2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400020761, N'2335-8', N'OCCULT BLOOD CNTRL 2', N'OCBLDC2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400049195, NULL, N'ZZOCCULT BLOOD #2', N'FOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400049195, N'14564-9', N'ZZOCCULT BLOOD #2', N'FOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400049217, NULL, N'OCCULT BLOOD CNTRL 3', N'OCBLDC3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400049217, N'2335-8', N'OCCULT BLOOD CNTRL 3', N'OCBLDC3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400568392, N'14564-9', N'OCCULT BLD FIT #1of1', N'OC-FIT')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (512, 1400575623, N'2335-8', N'OCCULT BLOOD FIT #1 OF 1', N'FIT')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (523, 1400006127, N'14565-6', N'  OCCULT BLOOD (#3)', N'FOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (523, 1400007168, N'2335-8', N'OCCULT BLOOD(RANDOM)', N'FOBT-R')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (523, 1400015832, N'2335-8', N'ZZOCCULT BLOOD (WX-WO)', N'ZOCCBLD')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (523, 1400017856, N'14564-9', N'  OCCULT BLOOD (#2)', N'FOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (523, 1400023083, N'2335-8', N'  OCCULT BLOOD (X3) (THRU 6/01)', N'OB(X3)')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (523, 1400024833, N'2335-8', N'  OCCULT BLOOD(X1)(THRU 7/17/01)', N'OB(X1)')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (523, 1400047002, N'14563-1', N'  OCCULT BLOOD (#1)', N'FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (523, 1400052622, N'2335-8', N'  OCCULT BLOOD (LO)(dc''d)', N'O.B.')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (523, 1400570743, N'29771-3', N'CSP#577 OCCULT BLOOD(FIT)1OF1', N'CSP#577 FIT1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (523, 1400574899, N'14563-1', N'OCCULT BLOOD (FIT)#1 OF 1', N'FIT1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400019763, N'2335-8', N'ZZOCCULT BLOOD (V2<6/28/02)', N'OCCULT ')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400020529, N'14563-1', N'ZZOCCULT BLOOD (Slide 1)', N'OCCUL B')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400020827, N'14564-9', N'ZZOCCULT BLOOD (Slide 2)', N'OCCUL B')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400030173, N'14565-6', N'ZZOCCULT BLOOD (Slide 3)', N'OCCUL B')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400041975, N'14564-9', N'2ND OCCULT BLD (AL/BH/CN/SY)', N'FOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400044644, N'2335-8', N'OCCULT BLOOD SPOT (AL/BH/CN/SY)', N'OB SPOT')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400046138, N'2335-8', N'OCCULT BLOOD SPOT POC (BH/SY)', N'OB POC')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400061146, N'14565-6', N'3RD OCCULT BLD (AL/BH/CN/SY)', N'FOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400063272, N'14563-1', N'1ST OCCULT BLD (AL/BH/CN/SY)', N'FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400073764, N'2335-8', N'ZZOCCULT BLOOD FECES (SY<6/23/00)', N'OCCUL')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400568735, N'2335-8', N'OCCULT BLOOD (FIT) #1 OF 3 (SY/CN/BH/AL)', N'FIT1/3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400568736, N'14565-6', N'OCCULT BLOOD (FIT) #2 OF 3 (SY/CN/BH/AL)', N'FIT2/3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400568737, N'14565-6', N'OCCULT BLOOD (FIT) #3 OF 3 (SY/CN/BH/AL)', N'FIT3/3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400568738, N'29771-3', N'OCCULT BLOOD FIT RANDOM (BU/BH)', N'FIT Ran')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (528, 1400593832, N'57905-2', N'OCCULT BLOOD (FIT) #1 OF 1* (CRS) (BU)', N'FIT1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (537, 1000006096, N'2335-8', N'OP OCCULT BLOOD (dc''d 11/5/07)', N'OP-OCCU')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (537, 1000009685, NULL, N'OCCULT BLOOD #2', N'FOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (537, 1000009685, N'2335-8', N'OCCULT BLOOD #2', N'FOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (537, 1000014516, NULL, N'OCCULT BLOOD #1', N'FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (537, 1000014516, N'2335-8', N'OCCULT BLOOD #1', N'FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (537, 1000061002, NULL, N'OCCULT BLOOD #3', N'FOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (537, 1000061002, N'2335-8', N'OCCULT BLOOD #3', N'FOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (537, 1000103300, N'29771-3', N'OCCULT FIT', N'FIT')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (537, 1000105623, N'57905-2', N'CSP#577 OCCULT BLOOD (FIT) #1 of 1', N'CSP#577')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (540, 1400021875, N'14564-9', N'OB#2', N'OB#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (540, 1400021876, N'14565-6', N'OB#3', N'OB#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (540, 1400029888, N'14563-1', N'OB#1', N'OB#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (540, 1400035778, N'2335-8', N'OCCULT BLOOD//DC''d 11-2016', N'OCCULT ')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (540, 1400568250, N'2335-8', N'CSP#577 OCCULT BLOOD(FIT)#1OF1', N'CSP#577')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (540, 1400571692, N'29771-3', N'OCCULT BLOOD (FIT) #1 OF 1', N'FIT1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (541, 1200028313, N'2335-8', N'OCC.BLD,RANDOM (Pre 4.2.07)', N'.OCCBLD')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (541, 1200090066, N'2335-8', N'OCCBLD#1(Pre 4.2.07', N'.OCC1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (541, 1200091575, N'2335-8', N'OCC.BLD.,SINGLE CARD(Pre to 4.23.12)', N'.FOBT-R')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (541, 1200093683, N'14565-6', N'OCC.BLD.,CARD#3(Pre 4.23.12', N'.OCC#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (541, 1200093759, N'14563-1', N'OCC.BLD.,CARD#1(Pre 4.23.12)', N'.FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (541, 1200095497, N'2335-8', N'OCCBLD#3(Pre 4.2.07', N'.OCC3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (541, 1200096072, N'2335-8', N'OCCBLD#2(Pre 4.2.07', N'.OCC#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (541, 1200098811, N'14564-9', N'OCC.BLD.,CARD#2(Pre 4.23.12', N'.FOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (541, 1200112732, N'57905-2', N'OCCULT BLOOD (FIT) #1 OF 1', N'FIT1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (541, 1200114625, N'29771-3', N'OCCULT BLD (CSP#577) FIT 1/1', N'FITCSP')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000002072, N'29771-3', N'.OCCULT BLOOD (FIT) #1 OF 1', N'FIT 1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000015681, N'14563-1', N'ZZZ.OCCULT BLOOD,FECES 1', N'FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000015681, N'2335-8', N'ZZZ.OCCULT BLOOD,FECES 1', N'FOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000018223, N'14563-1', N'OCCULT BLOOD,GUAIAC CARD,FECESx1', N'FOBT-S')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000019611, N'14564-9', N'ZZZ.OCCULT BLOOD,FECES 2 (iFOBT)', N'ZZZiFOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000029526, N'14565-6', N'ZZZ.OCCULT BLOOD,FECES 3 (iFOBT)', N'ZZZiFOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000033851, N'14564-9', N'ZZZ.OCCULT BLOOD,FECES 2', N'ZFOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000033851, N'2335-8', N'ZZZ.OCCULT BLOOD,FECES 2', N'ZFOBT#2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000038707, N'14563-1', N'ZZZ.OCCULT BLOOD,FECES 1 (iFOBT)', N'ZZZiFOBT#1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000051967, N'14565-6', N'ZZZ.OCCULT BLOOD,FECES 3', N'ZFOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000051967, N'2335-8', N'ZZZ.OCCULT BLOOD,FECES 3', N'ZFOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (549, 1000104251, N'29771-3', N'CSP#577 OCCULT BLOOD(FIT)#1OF1', N'FIT1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000000279, N'2335-8', N'ER FOBT', N'ER FOBT')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000000325, N'2335-8', N'OCCULT BLOOD FIT RANDOM', N'FIT Ran')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000022718, N'14563-1', N'ZZFOBT CARD 1(B)', N'CARD 1(B)')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000025007, N'14564-9', N'ZZFOBT CARD 2(L)', N'CARD 2(L)')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000027283, N'14564-9', N'ZZFOBT #2', N'CARD 2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000027289, N'14564-9', N'ZZFOBT CARD 2(B)', N'CARD 2(B)')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000027355, N'14565-6', N'ZZFOBT CARD 3(L)', N'CARD 3(L)')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000032285, NULL, N'ZZER FOBT #3', N'ER FOBT #3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000034075, N'14565-6', N'ZZFOBT CARD 3(B)', N'CARD3(B)')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000034854, NULL, N'ZZER FOBT #2', N'ER FOBT #2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000035704, N'56491-4', N'OCCULT BLOOD (FIT) #3 OF 3', N'FIT 3/3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000038375, N'14565-6', N'ZZFOBT #3', N'CARD 3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000050178, NULL, N'OCCULT BLOOD-PROV(LUF)dc''d 062420', N'OCC BLD-PV')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000054406, N'57905-2', N'OCCULT BLOOD (FIT) #1 OF 3', N'FIT 1/3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000054407, N'56490-6', N'OCCULT BLOOD (FIT) #2 OF 3', N'FIT 2/3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000056183, N'14563-1', N'ZZFOBT #1', N'CARD 1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000069542, N'14563-1', N'ZZFOBT CARD 1(L)', N'CARD 1(L)')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000076255, NULL, N'ZZER FOBT #1', N'ER FOBT #1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000108791, N'57905-2', N'CSP#577 FIT #1 OF 1', N'CSP#577 FIT')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (580, 1000121175, N'29771-3', N'OCCULT BLOOD (FIT) #1 OF 1', N'FIT1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (589, 1000036925, N'2335-8', N'OCCULT BLOOD RANDOM', N'FOB RAN')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (589, 1000043219, N'2335-8', N'POC OCCULT BLOOD-CO', N'POC_FOB')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (589, 1000043224, N'14565-6', N'OCCULT BLOOD #3', N'FOBT #3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (589, 1000068953, N'2335-8', N'OCCULT BLOOD #1', N'FOBT #1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (589, 1000068956, N'14564-9', N'OCCULT BLOOD #2', N'FOBT #2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (589, 1000068956, N'2335-8', N'OCCULT BLOOD #2', N'FOBT #2')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (589, 1000099307, N'14564-9', N'OCCULT BLOOD (FIT) #1 OF 1', N'FIT1/1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (589, 1000106227, N'57905-2', N'CSP#577 OCCULT BLOOD(FIT)#1of1', N'FIT1/ 1')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000012300, N'2335-8', N'OCCULT BLOOD,SINGLE CARD,1998 to 2/2007', N'Occ.Bl.')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000013003, N'2335-8', N'L-OCCULT BLOOD-MULTIPLE,thru Jan.2007', N'OcBld')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000047039, N'14565-6', N'FOBT#3, 1/2007 thru 12/2009', N'FOBT#3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000050677, N'14563-1', N'OCCULT BLOOD (FIT) #1 OF 3,12/09-1/16', N'FIT 1/3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000053306, N'14565-6', N'OCCULT BLOOD (FIT) #3 OF 3,12/09-1/16', N'FIT 3/3')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000054046, N'2335-8', N'OCCULT BLD FIT RANDOM(1of1),12/09-1/16', N'FITRAN')    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_7_FOBTLabTestName] ([Sta3n], [LabChemTestSID], [LOINC_Original], [LabChemTestName], [LabChemPrintTestName]) VALUES (635, 1000059624, N'14564-9', N'FOBT#2, 1/2007 thru 12/2009', N'FOBT#2')    --altered (ORD_...Dflt)
GO


---- FOBT test LOINC code list 
--	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_0_7_LOINC]') is not null) 		    --altered (ORD_...Dflt)
--	drop table [MyDB].[MySchema].FOBT_Sta3n528_0_7_LOINC    --altered (ORD_...Dflt)
--go

--	CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_7_LOINC (    --altered (ORD_...Dflt)
--	UniqueID int Identity(1,1) not null,
--	[LOINC_code_type] [varchar](50) NULL,
--	[LOINC_code_name] [varchar](50) NULL,
--	[LOINC] [varchar](10) NULL
--	) 
--go


--insert into  [MyDB].[MySchema].FOBT_Sta3n528_0_7_LOINC (    --altered (ORD_...Dflt)
--	[LOINC_code_type],
--	[LOINC_code_name] ,
--	[LOINC] 
--	) 
--	Values
--	 ('FOBT','','2335-8')
--	,('FOBT','','27396-1')
--	,('FOBT','','80372-6')
--	,('FOBT','','29771-3')
--	,('FOBT','','58453-2')
--	,('FOBT','','57905-2')
--	,('FOBT','','56490-6')
--	,('FOBT','','56491-4')
--	,('FOBT','','14563-1')
--	,('FOBT','','14564-9')
--	,('FOBT','','14565-6')
--	,('FOBT','','12503-9')
--	,('FOBT','','12504-7')
--	,('FOBT','','27401-9')
--	,('FOBT','','27925-7')
--	,('FOBT','','27926-5')
--	,('FOBT','','57804-7')
--	,('FOBT','','38527-8')
--	,('FOBT','','38526-0')
--	,('FOBT','','50196-5')
--	,('FOBT','','57803-9')
--	,('FOBT','','59841-7')
--  -- new found from OMOP
--	,('FOBT','','77353-1')
--	,('FOBT','','77354-9')
--	,('FOBT','','LG2754-2')
--	,('FOBT','','LG2755-9')
--	,('FOBT','','LG2756-7')
--	,('FOBT','','LG7849-5')
--	,('FOBT','','LP193109-8')
--	,('FOBT','','LP386738-1')
--	,('FOBT','','LP387006-2')
--	,('FOBT','','LP401871-1')
--	,('FOBT','','LP42052-8')
--go



-- Positive FOBT value list 
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult]') is not null) 		    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_0_A_RedFlagFOBTTestResult    --altered (ORD_...Dflt)
go

	CREATE TABLE [MyDB].[MySchema].FOBT_Sta3n528_0_A_RedFlagFOBTTestResult (    --altered (ORD_...Dflt)
	UniqueID int Identity(1,1) not null,
	Sta3n smallint null,
	FOBTTestResult [varchar](100) NULL,
	[IsRedFlag] [bit] NULL
)
go


-- Add red-flagged FOBT test result. Check if all the codes used in your site are included



INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (512, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (523, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (528, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (537, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (540, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (541, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (549, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (580, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (589, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (635, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (642, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (644, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (671, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (691, N'P', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (512, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (523, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (528, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (537, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (540, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (541, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (549, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (580, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (589, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (635, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (642, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (644, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (671, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (691, N'POS', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (512, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (523, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (528, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (537, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (540, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (541, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (549, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (580, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (589, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (635, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (642, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (644, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (671, N'Positive', 1)    --altered (ORD_...Dflt)
GO
INSERT [MyDB].[MySchema].[FOBT_Sta3n528_0_A_RedFlagFOBTTestResult] ([sta3n], [FOBTTestResult], [IsRedFlag]) VALUES (691, N'Positive', 1)    --altered (ORD_...Dflt)
GO

--------------------------------------------------------------------------------------------------------------------------------
-----  2. Extract positive (red-flagged) FOBT tests from sta6a in the study period
--------------------------------------------------------------------------------------------------------------------------------

-- All FOBT tests
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_1_AllFOBTSta6a]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_1_AllFOBTSta6a]    --altered (ORD_...Dflt)

	SELECT [LabChemSID]
      ,labChem.[Sta3n]
	  ,d.Sta6a
	  ,PatientSSN
      ,labChem.[LabChemTestSID]
      ,labChem.[PatientSID]
      ,[LabChemSpecimenDateTime] as FOBT_dt
      ,[LabChemCompleteDateTime] 
      ,[LabChemResultValue]
	  ,[LabChemResultNumericValue]
      ,[Abnormal]
	  ,[RequestingStaffSID]
	  ,dimTest.[LabChemTestName]
	  ,dimTest.[LabChemPrintTestName]
	  ,labChem.[LOINCSID]
	  ,LOINC.LOINC
 into [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_1_AllFOBTSta6a]    --altered (ORD_...Dflt)
  FROM [CDWWork].[chem].[PatientLabChem] as labChem    --altered (ORD_...Src)
  inner join CDWWork.dim.Location as loc
  on labChem.RequestingLocationSID=loc.LocationSID
  inner join CDWWork.dim.Division as d
  on loc.DivisionSID=d.DivisionSID
  --inner join CDWWork.dim.VistASite as VistaSite
  --on VistaSite.Sta3n=labChem.Sta3n
  inner join cdwwork.dim.labchemtest as dimTest
  on labChem.[LabChemTestSID]=dimTest.LabChemTestSID
  inner join cdwwork.dim.LOINC as LOINC
  on labChem.LOINCSID=LOINC.LOINCSID
  inner join [MyDB].[MySchema].FOBT_Sta3n528_0_7_FOBTLabTestName as n    --altered (ORD_...Dflt)
  on labChem.sta3n=n.sta3n and labchem.LabChemTestSID=n.LabChemTestSID
 -- left join [MyDB].[MySchema].FOBT_Sta3n528_0_7_LOINC as l    --altered (ORD_...Dflt)
 --on LOINC.lOINC=l.LOINC
 inner join [MyDB].[MySchema].FOBT_Sta3n528_0_0_1_Sta3nSta6a as s    --altered (ORD_...Dflt)
  on d.sta3n=s.sta3n and d.Sta6a=s.Sta6a
 inner join [CDWWork].[SPatient].[SPatient] as VStatus    --altered (ORD_...Src)
on labChem.PatientSID=VStatus.PatientSID and labChem.sta3n=VStatus.sta3n
  where --labchem.CohortName='Cohort20180712' and 
    labChem.[LabChemSpecimenDateTime] between (select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
											and(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
go

-- Red flagged FOBT tests
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_8_IncIns]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_8_IncIns    --altered (ORD_...Dflt)

go

select distinct [LabChemSID]
      ,a.[Sta3n]
	  ,a.Sta6a
      ,[LabChemTestSID]
      ,a.[PatientSID]
      ,LabChemCompleteDateTime
      ,[FOBT_dt] as CBC_dt
      ,[LabChemResultValue]      
      ,[LabChemResultNumericValue]
      ,[Abnormal]
      ,[LabChemTestName]
      ,[LOINCSID]
      ,[LOINC]
	    ,VStatus.BirthDateTime as DOB
		,VStatus.DeathDateTime as DOD
		,VStatus.gender as Sex
		,a.PatientSSN
into [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_8_IncIns    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_1_AllFOBTSta6a] as a    --altered (ORD_...Dflt)
inner join [CDWWork].[SPatient].[SPatient] as VStatus    --altered (ORD_...Src)
on a.PatientSID=VStatus.PatientSID and a.sta3n=VStatus.sta3n
----PACTDiscovery
--where
-- [FOBT_dt] between (select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt)
--											and (select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
--and (Abnormal like 'H%'
--	or( [LabChemResultValue] like 'P'
--	 or [LabChemResultValue] like '%PO%'
--	 or [LabChemResultValue] like '%PS%'
--	 or [LabChemResultValue] like '%POS%'
--	 or [LabChemResultValue] like '%Posi%'
--	 or [LabChemResultValue] like '%Positive%'
--	 or [LabChemResultValue] like '1'
--	 )
-- )
----PACTDiscoveryEnd
left join [MyDB].[MySchema].FOBT_Sta3n528_0_A_RedFlagFOBTTestResult as targetTestResult    --altered (ORD_...Dflt)
on  ltrim(rtrim(a.[LabChemResultValue]))=targetTestResult.FOBTTestResult and targetTestResult.IsRedFlag=1 and a.Sta3n=targetTestResult.sta3n
where
 [FOBT_dt] between (select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)     --altered (ORD_...Dflt)
											and (select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
and (
targetTestResult.FOBTTestResult is not null
-- Using Abnormal Flag. Make corresponsing change here if it does not apply to your site.

or Abnormal like 'H%'  
)
go


-- Get other possible patientSIDs
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_9_IncPat    --altered (ORD_...Dflt)
go

	select distinct VStatus.Sta3n,VStatus.PatientSID,VStatus.patientSSN, VStatus.ScrSSN,VStatus.PatientICN
	into [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_9_IncPat    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_8_IncIns as a    --altered (ORD_...Dflt)
    left join  [CDWWork].[SPatient].[SPatient] as VStatus    --altered (ORD_...Src)
    on a.patientSSN=VStatus.PatientSSN	
go


--------------------------------------------------------------------------------------------------------------------------------
-----  3. Extract red-flagged patients' clinical diagnosis, procedures and consults etc
--------------------------------------------------------------------------------------------------------------------------------

--  Extract of previous colon cancer history from patient problemlist

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_0_PrevCLCFromProblemList_ICD9ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_0_PrevCLCFromProblemList_ICD9ICD10    --altered (ORD_...Dflt)
go

select
			  p.patientssn,Plist.sta3n,Plist.patientsid	,Plist.EnteredDateTime
			  ,ICD9.ICD9Code
			  ,ColonCancerICD9CodeList.ICD9Code as TargetICD9Code
			  ,ColonCancerICD9CodeList.dx_code_type as Icd9dx_code_type
    			,ICD10.ICD10Code,ColonCancerICD10CodeList.ICD10Code as TargetICD10Code				
			  ,ColonCancerICD10CodeList.dx_code_type as Icd10dx_code_type
into [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_0_PrevCLCFromProblemList_ICD9ICD10    --altered (ORD_...Dflt)
  FROM [CDWWork].[Outpat].[ProblemList] as Plist    --altered (ORD_...Src)
left join CDWWork.Dim.ICD9 as ICD9
  on Plist.ICD9SID=ICD9.ICD9SID
left join [MyDB].[MySchema].[FOBT_Sta3n528_0_8_ColonCancerDxICD9Code] as ColonCancerICD9CodeList    --altered (ORD_...Dflt)
on ICD9.ICD9Code=ColonCancerICD9CodeList.ICD9Code
left join CDWWork.Dim.ICD10 as ICD10
  on Plist.ICD10SID=ICD10.ICD10SID
left join [MyDB].[MySchema].[FOBT_Sta3n528_0_9_ColonCancerDxICD10Code] as ColonCancerICD10CodeList    --altered (ORD_...Dflt)
on ICD10.ICD10Code=ColonCancerICD10CodeList.ICD10Code
inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Plist.sta3n=p.sta3n and Plist.patientsid=p.patientsid
where --CohortName='Cohort20180712' and 
plist.[EnteredDateTime] >= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].[FOBT_Sta3n528_0_1_inputP]))     --altered (ORD_...Dflt)
and plist.[EnteredDateTime] <= DATEADD(dd,(select fu_period from [MyDB].[MySchema].[FOBT_Sta3n528_0_1_inputP]),    --altered (ORD_...Dflt)
										(select sp_end from [MyDB].[MySchema].[FOBT_Sta3n528_0_1_inputP]))    --altered (ORD_...Dflt)
and
(
ColonCancerICD9CodeList.dx_code_type is not null
or ColonCancerICD10CodeList.dx_code_type is not null
)
go


--  Extract of all DX codes from outpatient table for all potential patients
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_1_OutPatDx_ICD9ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_1_OutPatDx_ICD9ICD10    --altered (ORD_...Dflt)

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
into [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_1_OutPatDx_ICD9ICD10    --altered (ORD_...Dflt)
  FROM [CDWWork].[outpat].[WorkLoadVDiagnosis] as Diag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on Diag.ICD9SID=DimICD9.ICD9SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on Diag.ICD10SID=DimICD10.ICD10SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and
-- Thalassemia any time prior only applies to IDA
[VDiagnosisDateTime]> DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and [VDiagnosisDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),    --altered (ORD_...Dflt)
										(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)		

go


-- Extract of all DX Codes for all potential patients from surgical files
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_2_SurgDx_ICD9ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_2_SurgDx_ICD9ICD10    --altered (ORD_...Dflt)

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
  into [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_2_SurgDx_ICD9ICD10    --altered (ORD_...Dflt)
  FROM [CDWWork].[Surg].[SurgeryPre] as surgPre    --altered (ORD_...Src)
  inner join [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_9_IncPat as p    --altered (ORD_...Dflt)
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
-- Thalassemia any time prior only applies to IDA
  SurgPre.[SurgeryDateTime]>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))  and    --altered (ORD_...Dflt)
  SurgPre.[SurgeryDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
  --and  SurgPre.CohortName='Cohort20180712'
  --and  surgDx.CohortName='Cohort20180712'
  --and  otherPostDx.CohortName='Cohort20180712'
  --and  assocDx.CohortName='Cohort20180712'
  and (
  	--PreICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[FOBT_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)
	PrincipalPostOpICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[FOBT_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)
	or 	OtherPostICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[FOBT_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)
	or 	assocDxICD9.ICD9Code in (select ICD9Code from [MyDB].[MySchema].[FOBT_Sta3n528_0_4_DxICD9CodeExc])    --altered (ORD_...Dflt)

	or PrincipalPostOpICD10.ICD10Code in (select ICD10Code from [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc)    --altered (ORD_...Dflt)
	or 	OtherPostICD10.ICD10Code in (select ICD10Code from [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc)    --altered (ORD_...Dflt)
	or 	assocDxICD10.ICD10Code in (select ICD10Code from [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc)    --altered (ORD_...Dflt)

	) 
  
	go



--  Extract of all DX codes from inpatient tables for all potential patients
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10    --altered (ORD_...Dflt)
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
	into  [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[InpatientDiagnosis] as InPatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InPatDiag.ICD9SID=DimICD9.ICD9SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InPatDiag.ICD10SID=DimICD10.ICD10SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
  where --CohortName='Cohort20180712' and
-- Thalassemia any time prior only applies to IDA
  [DischargeDateTime]> DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and [DischargeDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)
	go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Census501Diagnosis]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Census501Diagnosis    --altered (ORD_...Dflt)

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
	into  [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Census501Diagnosis    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[Census501Diagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and
	CensusDateTime= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt)
	and CensusDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis    --altered (ORD_...Dflt)

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
	into  [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[CensusDiagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and
	CensusDateTime>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt)
	and CensusDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis    --altered (ORD_...Dflt)

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
	into  [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[Inpatient501TransactionDiagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and
	SpecialtyTransferDateTime>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt)
	and SpecialtyTransferDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis    --altered (ORD_...Dflt)

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
	into  [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[InpatientDischargeDiagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --inpatDiag.CohortName='Cohort20180712' and  
	DischargeDateTime>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt)
	and DischargeDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis    --altered (ORD_...Dflt)
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
	into  [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[PatientTransferDiagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and  
	PatientTransferDateTime>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt)
	and PatientTransferDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis    --altered (ORD_...Dflt)
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
	into  [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[SpecialtyTransferDiagnosis] as InpatDiag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on InpatDiag.ICD9SID=DimICD9.ICD9SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on InpatDiag.ICD10SID=DimICD10.ICD10SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on InpatDiag.sta3n=p.sta3n and InpatDiag.patientsid=p.patientsid
where --inpatDiag.CohortName='Cohort20180712' and
	SpecialtyTransferDateTime>= DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))	     --altered (ORD_...Dflt)
	and SpecialtyTransferDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go

-- Extract of all DX Codes for all potential patients from Purchased Care

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9ICD10    --altered (ORD_...Dflt)

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
into [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9ICD10    --altered (ORD_...Dflt)
FROM [CDWWork].[Inpat].[InpatientFeeDiagnosis] as Diag    --altered (ORD_...Src)
   left join CDWWork.Dim.ICD9 as DimICD9
  on Diag.ICD9SID=DimICD9.ICD9SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on Diag.ICD10SID=DimICD10.ICD10SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on Diag.sta3n=p.sta3n and Diag.patientsid=p.patientsid
where --CohortName='Cohort20180712' and
-- Thalassemia any time prior only applies to IDA
 [DischargeDateTime]> DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and [DischargeDateTime]<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)	
go



-- Extract of all DX Codes for all potential patients from Purchased Care 
  		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10    --altered (ORD_...Dflt)


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
into [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10    --altered (ORD_...Dflt)
  FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
  inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
   left join CDWWork.Dim.ICD9 as DimICD9
  on a.ICD9SID=DimICD9.ICD9SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc as targetCode    --altered (ORD_...Dflt)
on targetCode.ICD9Code=DimICD9.ICD9Code
  left join CDWWork.Dim.ICD10 as DimICD10
  on a.ICD10SID=DimICD10.ICD10SID
left join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc as ICD10CodeList										    --altered (ORD_...Dflt)
on ICD10CodeList.ICD10Code=DimICD10.ICD10Code
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as c    --altered (ORD_...Dflt)
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where --a.CohortName='Cohort20180712'  and d.CohortName='Cohort20180712' and
  -- Thalassemia any time prior only applies to IDA
 InitialTreatmentDateTime> DATEADD(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
and d.InitialTreatmentDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
and (TargetCode.dx_code_type is not null or ICD10CodeList.dx_code_type is not null)
go



	-- combine all exclusion diagnoses from surgical, inpatient, and outpatient, and purchased care tables
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD9]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD9    --altered (ORD_...Dflt)
go


select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'DX-OutPat' as dataSource
into [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD9	    --altered (ORD_...Dflt)
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_1_OutPatDx_ICD9ICD10]    --altered (ORD_...Dflt)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-InPat' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10]    --altered (ORD_...Dflt)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code,ICD9dx_code_type as dx_code_type,'Dx-InPatFee' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9ICD10]    --altered (ORD_...Dflt)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code,ICD9dx_code_type as dx_code_type,'Dx-InPatFeeService' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10]    --altered (ORD_...Dflt)
where ICD9dx_code_type is not null
-------
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-Census501Diagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Census501Diagnosis    --altered (ORD_...Dflt)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-CensusDiagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis    --altered (ORD_...Dflt)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-501TransactionDiagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis    --altered (ORD_...Dflt)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-InpatientDischargeDiagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis    --altered (ORD_...Dflt)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-PatientTransferDiagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis    --altered (ORD_...Dflt)
where ICD9dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD9Code as ICD9,ICD9dx_code_type as dx_code_type,'Dx-SpecialtyTransferDiagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis    --altered (ORD_...Dflt)
where ICD9dx_code_type is not null
----------------
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,PrincipalPostOpICD9Diagnosis as ICD9
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_2_SurgDx_ICD9ICD10] as a    --altered (ORD_...Dflt)
 inner join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc  as b    --altered (ORD_...Dflt)
 on a.PrincipalPostOpICD9Diagnosis=b.ICD9Code
 where  isnull(PrincipalPostOpICD9Diagnosis,'') in (select ICD9Code from [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc )    --altered (ORD_...Dflt)
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,OtherPostICD9Diagnosis as ICD9
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_2_SurgDx_ICD9ICD10] as a    --altered (ORD_...Dflt)
 inner join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc  as b    --altered (ORD_...Dflt)
 on a.OtherPostICD9Diagnosis=b.ICD9Code
 where  isnull(OtherPostICD9Diagnosis,'') in (select ICD9Code from [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc )    --altered (ORD_...Dflt)
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,assocDxICD9Diagnosis as ICD9
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_2_SurgDx_ICD9ICD10] as a    --altered (ORD_...Dflt)
 inner join [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc  as b    --altered (ORD_...Dflt)
 on a.assocDxICD9Diagnosis=b.ICD9Code
 where  isnull(assocDxICD9Diagnosis,'') in (select ICD9Code from [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc )    --altered (ORD_...Dflt)
 go

alter table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD9    --altered (ORD_...Dflt)
	add  
	term_dx_dt datetime2(0),
	hospice_dt datetime2(0),
	ugi_bleed_dx_dt datetime2(0)
	--other_bleed_dx_dt datetime2(0),
	--preg_dx_dt datetime2(0),
	--thal_dx_dt datetime2(0),
go

update [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD9    --altered (ORD_...Dflt)
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
	ugi_bleed_dx_dt = case
		when dx_code_type='UpperGIBleeding'
			 then dx_dt
		else NULL
	end

go

-- combine all exclusion diagnoses from surgical, inpatient, and outpatient, and purchased care tables
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD10]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD10    --altered (ORD_...Dflt)
go


select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'DX-OutPat' as dataSource
into [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD10	    --altered (ORD_...Dflt)
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_1_OutPatDx_ICD9ICD10]    --altered (ORD_...Dflt)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-InPat' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10]    --altered (ORD_...Dflt)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code,ICD10dx_code_type as dx_code_type,'Dx-InPatFee' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9ICD10]    --altered (ORD_...Dflt)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code,ICD10dx_code_type as dx_code_type,'Dx-InPatFeeService' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10]    --altered (ORD_...Dflt)
where ICD10dx_code_type is not null
--
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-Census501Diagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Census501Diagnosis    --altered (ORD_...Dflt)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-CensusDiagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis    --altered (ORD_...Dflt)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-501TransactionDiagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis    --altered (ORD_...Dflt)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-InpatientDischargeDiagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis    --altered (ORD_...Dflt)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-PatientTransferDiagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis    --altered (ORD_...Dflt)
where ICD10dx_code_type is not null
	UNION 
select patientSSN,sta3n,PatientSID,dx_dt,ICD10Code as ICD10,ICD10dx_code_type as dx_code_type,'Dx-SpecialtyTransferDiagnosis' as dataSource
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis    --altered (ORD_...Dflt)
where ICD10dx_code_type is not null
--
    Union
 select patientSSN,sta3n, PatientSID,dx_dt,PrincipalPostOpICD10Diagnosis as ICD10
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_2_SurgDx_ICD9ICD10] as a    --altered (ORD_...Dflt)
 inner join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc  as b    --altered (ORD_...Dflt)
 on a.PrincipalPostOpICD10Diagnosis=b.ICD10Code
 where  isnull(PrincipalPostOpICD10Diagnosis,'') in (select ICD10Code from [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc )    --altered (ORD_...Dflt)
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,OtherPostICD10Diagnosis as ICD10
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_2_SurgDx_ICD9ICD10] as a    --altered (ORD_...Dflt)
 inner join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc  as b    --altered (ORD_...Dflt)
 on a.OtherPostICD10Diagnosis=b.ICD10Code
 where  isnull(OtherPostICD10Diagnosis,'') in (select ICD10Code from [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc )    --altered (ORD_...Dflt)
   Union
 select patientSSN,sta3n, PatientSID,dx_dt,assocDxICD10Diagnosis as ICD10
		,b.dx_code_type
		,'Dx-Surg' as dataSource
 from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_2_SurgDx_ICD9ICD10] as a    --altered (ORD_...Dflt)
 inner join [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc  as b    --altered (ORD_...Dflt)
 on a.assocDxICD10Diagnosis=b.ICD10Code
 where  isnull(assocDxICD10Diagnosis,'') in (select ICD10Code from [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc )    --altered (ORD_...Dflt)
 go


Alter table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD10    --altered (ORD_...Dflt)
	add 
	term_dx_dt datetime2(0),
	hospice_dt datetime2(0),
	ugi_bleed_dx_dt datetime2(0)

	--other_bleed_dx_dt datetime2(0),
	--preg_dx_dt datetime2(0),
	--thal_dx_dt datetime2(0)

go


update [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD10    --altered (ORD_...Dflt)
set term_dx_dt= case when dx_code_type='Terminal' then dx_dt else null end,
	hospice_dt= case when dx_code_type='hospice' then dx_dt else null end,
	ugi_bleed_dx_dt= case when dx_code_type='UpperGIBleeding' then dx_dt else null end
	--preg_dx_dt=case when dx_code_type='Pregnancy' then dx_dt else null end,
	--other_bleed_dx_dt=case when dx_code_type='OtherBleeding' then dx_dt else null end,
	--thal_dx_dt=case when dx_code_type='Thalassemia' then dx_dt else null end
go
	
	
-- combine all ICD9 and ICD10 exclusion diagnoses from surgical, inpatient, and outpatient, and purchased care tables
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_4_Union_ALLDx_ICD]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_Union_ALLDx_ICD    --altered (ORD_...Dflt)
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
	  ,ugi_bleed_dx_dt
into [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_Union_ALLDx_ICD    --altered (ORD_...Dflt)
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD9    --altered (ORD_...Dflt)
union
select 
	  [patientSSN]
      ,[sta3n]
      ,[PatientSID]
      ,[dx_dt]
      ,[ICD10] as ICDCode
      ,[dataSource]
      ,[dx_code_type]
      ,[term_dx_dt]
      ,[hospice_dt]
	  ,ugi_bleed_dx_dt
from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD10    --altered (ORD_...Dflt)
go


-- Previous ICD procedures from inpatient tables 

				if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)

			 select pat.patientssn,ICDProc.sta3n,ICDProc.patientsid	,ICDProc.[ICDProcedureDateTime]
			  ,DimICD9Proc.[ICD9ProcedureCode],TargetCode.ICD9ProcCode,TargetCode.ICD9Proc_Code_Type
    			,DimICD10Proc.ICD10ProcedureCode,ICD10CodeList.ICD10ProcCode,ICD10CodeList.ICD10Proc_Code_Type
into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)
  FROM [CDWWork].[inpat].[InpatientICDProcedure] as ICDProc    --altered (ORD_...Src)
 			  left join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on ICDProc.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  left join [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt)
			  on DimICD9Proc.[ICD9ProcedureCode]=TargetCode.ICD9ProcCode

			  left join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			    left join [MyDB].[MySchema].FOBT_Sta3n528_0_3_PreProcICD10ProcExc as ICD10CodeList    --altered (ORD_...Dflt)
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where --CohortName='Cohort20180712' and
-- Total Colectomy any time prior 
-- Colonoscopy 3 years prior
  [ICDProcedureDateTime] < DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
 and (TargetCode.ICD9Proc_code_type is not null or ICD10CodeList.ICD10Proc_code_type is not null)	
 go


			if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)

			 select pat.patientssn,ICDProc.sta3n,ICDProc.patientsid	,ICDProc.ICDProcedureDateTime
			  ,DimICD9Proc.[ICD9ProcedureCode],TargetCode.ICD9ProcCode,TargetCode.ICD9Proc_Code_Type
    			,DimICD10Proc.ICD10ProcedureCode,ICD10CodeList.ICD10ProcCode,ICD10CodeList.ICD10Proc_Code_Type
into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[CensusICDProcedure] as ICDProc    --altered (ORD_...Src)
 			  left join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on ICDProc.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  left join [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt)
			  on DimICD9Proc.[ICD9ProcedureCode]=TargetCode.ICD9ProcCode

			  left join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on ICDProc.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			    left join [MyDB].[MySchema].FOBT_Sta3n528_0_3_PreProcICD10ProcExc as ICD10CodeList    --altered (ORD_...Dflt)
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode  
   inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on ICDProc.patientsid=pat.patientsid and ICDProc.sta3n=pat.sta3n
 where --CohortName='Cohort20180712' and
-- Total Colectomy any time prior 
-- Colonoscopy 3 years prior
  [ICDProcedureDateTime] < DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
 and (TargetCode.ICD9Proc_code_type is not null or ICD10CodeList.ICD10Proc_code_type is not null)	
go



if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)

			select pat.patientssn,a.sta3n,a.patientsid,a.[SurgicalProcedureDateTime]
			,DimICD9Proc.[ICD9ProcedureCode],TargetCode.ICD9Proc_Code_Type
	      ,TargetCode.ICD9ProcCode,ICD10CodeList.ICD10Proc_Code_Type
	      ,DimICD10Proc.[ICD10ProcedureCode],ICD10CodeList.ICD10ProcCode
into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)
  FROM [CDWWork].[inpat].[InpatientSurgicalProcedure] as a    --altered (ORD_...Src)
 			  left join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  left join [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt)
			  on DimICD9Proc.[ICD9ProcedureCode]=TargetCode.ICD9ProcCode

			  left join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			    left join [MyDB].[MySchema].FOBT_Sta3n528_0_3_PreProcICD10ProcExc as ICD10CodeList    --altered (ORD_...Dflt)
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where --CohortName='Cohort20180712' and
-- Total Colectomy any time prior 
-- Colonoscopy 3 years prior
 [SurgicalProcedureDateTime] <dateadd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
  and (TargetCode.ICD9Proc_code_type is not null or ICD10CodeList.ICD10Proc_code_type is not null)
go



if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)

			 select pat.patientssn,a.sta3n,a.patientsid	,a.SurgicalProcedureDateTime
			  ,DimICD9Proc.[ICD9ProcedureCode],TargetCode.ICD9ProcCode,TargetCode.ICD9Proc_Code_Type
    			,DimICD10Proc.ICD10ProcedureCode,ICD10CodeList.ICD10ProcCode,ICD10CodeList.ICD10Proc_Code_Type
into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[CensusSurgicalProcedure] as a    --altered (ORD_...Src)
 			  left join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  left join [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt)
			  on DimICD9Proc.[ICD9ProcedureCode]=TargetCode.ICD9ProcCode

			  left join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			    left join [MyDB].[MySchema].FOBT_Sta3n528_0_3_PreProcICD10ProcExc as ICD10CodeList    --altered (ORD_...Dflt)
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode  
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on a.patientsid=pat.patientsid and a.sta3n=pat.sta3n
 where --CohortName='Cohort20180712' and
-- Total Colectomy any time prior 
-- Colonoscopy 3 years prior
  [SurgicalProcedureDateTime] <DateAdd(dd,120+(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
  and (TargetCode.ICD9Proc_code_type is not null or ICD10CodeList.ICD10Proc_code_type is not null)
go



	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc	    --altered (ORD_...Dflt)

			 select pat.patientssn,a.sta3n,b.patientsid	,b.[TreatmentFromDateTime]
			  ,DimICD9Proc.[ICD9ProcedureCode],TargetCode.ICD9ProcCode,TargetCode.ICD9Proc_Code_Type
    			,DimICD10Proc.ICD10ProcedureCode,ICD10CodeList.ICD10ProcCode,ICD10CodeList.ICD10Proc_Code_Type
	into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)
	from [CDWWork].[Fee].[FeeInpatInvoiceICDProcedure] as a    --altered (ORD_...Src)
	inner join[CDWWork].[Fee].[FeeInpatInvoice] as b    --altered (ORD_...Src)
	on a.FeeInpatInvoiceSID=b.FeeInpatInvoiceSID
			  left join cdwwork.dim.ICD9Procedure as DimICD9Proc
			  on a.[ICD9ProcedureSID]=DimICD9Proc.[ICD9ProcedureSID]  
			  left join [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc as TargetCode    --altered (ORD_...Dflt)
			  on DimICD9Proc.[ICD9ProcedureCode]=TargetCode.ICD9ProcCode

			  left join cdwwork.dim.ICD10Procedure as DimICD10Proc
			  on a.[ICD10ProcedureSID]=DimICD10Proc.[ICD10ProcedureSID]  
			    left join [MyDB].[MySchema].FOBT_Sta3n528_0_3_PreProcICD10ProcExc as ICD10CodeList    --altered (ORD_...Dflt)
			  on DimICD10Proc.ICD10ProcedureCode=ICD10CodeList.ICD10ProcCode 
	  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
	  on b.patientsid=pat.patientsid and b.sta3n=pat.sta3n
	  where --a.CohortName='Cohort20180712' and b.CohortName='Cohort20180712' and
-- Total Colectomy any time prior 
-- Colonoscopy 3 years prior
  [TreatmentFromDateTime] < DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
   and (TargetCode.ICD9Proc_code_type is not null or ICD10CodeList.ICD10Proc_code_type is not null)
 go


 -- combine all Icd9Procedure from inpatient tables
if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc    --altered (ORD_...Dflt)
	
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9Proc_Code_Type
	  ,'Inp-InpICD'	  as datasource	  
    into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc	    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc]    --altered (ORD_...Dflt)
	where ICD9Proc_code_type is not null
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9Proc_Code_Type
	  ,'Inp-CensusICD'	  as datasource
	from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc]    --altered (ORD_...Dflt)
	where ICD9Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9Proc_Code_Type
	 ,'Inp-InpSurg'	  as datasource	 
	from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc]    --altered (ORD_...Dflt)
	where ICD9Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
	  ,ICD9Proc_Code_Type
      ,[ICD9ProcedureCode]      
	 ,'Inp-CensusSurg'	  as datasource
	from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc]    --altered (ORD_...Dflt)
	where ICD9Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICD9ProcedureCode]
      ,ICD9Proc_Code_Type
	 ,'Inp-FeeICDProc'	  as datasource
	 from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc]    --altered (ORD_...Dflt)
	where ICD9Proc_code_type is not null
	
go

-- combine all Icd10Procedure from inpatient tables

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc    --altered (ORD_...Dflt)
	

	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10Proc_Code_Type
	  ,'Inp-InpICD'	  as datasource
    into  [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc]    --altered (ORD_...Dflt)
	where ICD10Proc_code_type is not null
	union 
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[ICDProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10Proc_Code_Type
	  ,'Inp-CensusICD'	  as datasource
	from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc]    --altered (ORD_...Dflt)
	where ICD10Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10Proc_Code_Type
	 ,'Inp-InpSurg'	  as datasource	 
	from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc]    --altered (ORD_...Dflt)
	where ICD10Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[SurgicalProcedureDateTime] as Proc_dt
	  ,ICD10Proc_Code_Type
      ,[ICD10ProcedureCode]      
	 ,'Inp-CensusSurg'	  as datasource
	from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc]    --altered (ORD_...Dflt)
	where ICD10Proc_code_type is not null
	union
	select patientssn
      ,[sta3n]
      ,[patientsid]
      ,[TreatmentFromDateTime] as Proc_dt
      ,[ICD10ProcedureCode]
      ,ICD10Proc_Code_Type
	 ,'Inp-FeeICDProc'	  as datasource
	 from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc]    --altered (ORD_...Dflt)
	where ICD10Proc_code_type is not null

	
go

	-- CPT procedures from outpatient tables

		if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_6_Outpat') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_6_Outpat    --altered (ORD_...Dflt)
		go
		
select 		p.patientSSN,
      VProc.[Sta3n]
      ,VProc.[CPTSID]
	  ,dimCPT.[CPTCode]
	  ,TargetCPT.CPT_code_type
	  ,DimCPT.[CPTName]
      ,VProc.[PatientSID]
      ,VProc.[VisitSID]
      ,VProc.[VisitDateTime]
      ,VProc.[VProcedureDateTime] 
      ,VProc.[CPRSOrderSID]
  into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_6_Outpat    --altered (ORD_...Dflt)
  FROM [CDWWork].[Outpat].[WorkloadVProcedure] as VProc    --altered (ORD_...Src)
  inner join CDWWork.[Dim].[CPT] as DimCPT 
  on  VProc.[CPTSID]=DimCPT.CPTSID
  inner join [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc as TargetCPT    --altered (ORD_...Dflt)
  on DimCPT.CPTCode=TargetCPT.CPTCode
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on VProc.sta3n=p.sta3n and VProc.patientsid=p.patientsid
  where  --VProc.CohortName='Cohort20180712' and
   -- Total Colectomy any time prior 
-- Colonoscopy 3 years prior
  VProc.[VProcedureDateTime] <=DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
											,(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)

go



  	-- CPT procedures from surgical tables

		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_7_surg]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_7_surg    --altered (ORD_...Dflt)

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
  into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_7_surg    --altered (ORD_...Dflt)
  FROM [CDWWork].[Surg].[SurgeryPre] as surgPre    --altered (ORD_...Src)
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
  on SurgPre.sta3n=p.sta3n and SurgPre.patientsid=p.patientsid
  left join[CDWWork].[Surg].[SurgeryProcedureDiagnosisCode]as surgDx    --altered (ORD_...Src)
  on surgPre.SurgerySID=SurgDx.SurgerySID and surgPre.sta3n=SurgDx.sta3n
  left join CDWWork.dim.CPT as PrincipalCPT 
  on SurgDx.PrincipalCPTSID=PrincipalCPT.CPTSID and SurgDx.Sta3n=PrincipalCPT.Sta3n
  left join [CDWWork].[Surg].[SurgeryPrincipalAssociatedProcedure] as assocProc    --altered (ORD_...Src)
  on  surgDx.SurgeryProcedureDiagnosisCodeSID=assocProc.SurgeryProcedureDiagnosisCodeSID and surgDx.sta3n=assocProc.sta3n
  --left join CDWWork.dim.CPT as assocCPT
  --on assocProc.SurgeryPrincipalAssociatedProcedureSID=assocCPT.CPTSID and assocProc.sta3n=assocCPT.sta3n 
  left join CDWWork.dim.CPT as OtherCPT
  on assocProc.OtherProcedureCPTSID=OtherCPT.CPTSID and assocProc.sta3n=OtherCPT.sta3n 
   where  
     -- Total Colectomy any time prior 
-- Colonoscopy 3 years prior    
   SurgPre.[SurgeryDateTime] <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
  --and  SurgPre.CohortName='Cohort20180712'
  --and  surgDx.CohortName='Cohort20180712'
  ----and  otherPostDx.CohortName='Cohort20180712'
  --and  assocProc.CohortName='Cohort20180712'
  and (
		  PrincipalCPT.CPTCode in 
		  (select CPTCode from 	[MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc)    --altered (ORD_...Dflt)
		  --or assocCPT.CPTCode in
		  --(select CPTCode from 	[MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc)					     --altered (ORD_...Dflt)
		  or OtherCPT.CPTCode in
		  (select CPTCode from 	[MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc)					     --altered (ORD_...Dflt)
		)

  go

  
  --  CPT procedures from inpatient

	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT]') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT    --altered (ORD_...Dflt)

select pat.patientssn,CPTProc.sta3n,CPTProc.patientsid,CPTProc.[CPTProcedureDateTime]
	      ,DimCPT.[CPTCode],TargetCPT.CPT_code_type
into  [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT    --altered (ORD_...Dflt)
  FROM [CDWWork].[Inpat].[InpatientCPTProcedure] as CPTProc    --altered (ORD_...Src)
  inner join cdwwork.dim.CPT as DimCPT
  on CPTProc.[CPTSID]=DimCPT.CPTSID 
  inner join [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc as TargetCPT    --altered (ORD_...Dflt)
  on DimCPT.CPTCode=TargetCPT.CPTCode   
  inner join (select distinct ScrSSN,patientSSN,patientICN,sta3n,patientsid from [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat]) as pat    --altered (ORD_...Dflt)
  on CPTProc.patientsid=pat.patientsid and CPTProc.sta3n=pat.sta3n
 where --CohortName='Cohort20180712' and
   -- Total Colectomy any time prior 
-- Colonoscopy 3 years prior							
 CPTProc.[CPTProcedureDateTime] <= DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
go



  --Fee CPT procedures from purchased care
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_9_FeeCPT]') is not null)    --altered (ORD_...Dflt)
drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_9_FeeCPT    --altered (ORD_...Dflt)

SELECT  
	  c.patientssn
	,d.InitialTreatmentDateTime
      ,a.[PatientSID]
      ,a.[Sta3n]
      ,[ServiceProvidedCPTSID]
      ,[AmountClaimed]
      ,[AmountPaid]
,DimCPT.CPTCode,DimCPT.CPTName,
CPT_code_type
into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_9_FeeCPT    --altered (ORD_...Dflt)
  FROM [CDWWork].[Fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
  inner join [CDWWork].[Fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
  on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
  inner join cdwwork.dim.cpt as DimCPT
  on a.[ServiceProvidedCPTSID]=DimCPT.cptsid
  inner join [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc as TargetCPT    --altered (ORD_...Dflt)
  on DimCPT.CPTCode=TargetCPT.CPTCode
  inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as c    --altered (ORD_...Dflt)
  on a.sta3n=c.sta3n and a.patientsid=c.patientsid
  where --a.CohortName='Cohort20180712' and d.CohortName='Cohort20180712' and
   -- Total Colectomy any time prior 
-- Colonoscopy 3 years prior						
  	d.InitialTreatmentDateTime<= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),(select sp_end from [MyDB].[MySchema].[FOBT_Sta3n528_0_1_inputP]))    --altered (ORD_...Dflt)

  go



-- All colonoscopy procedures from surgical, inpatient and outpatient and purchased care tables
	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy    --altered (ORD_...Dflt)


select patientSSN,sta3n,patientSID,[VProcedureDateTime] as colonoscopy_dt ,'PrevColonScpy-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy    --altered (ORD_...Dflt)
from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_6_Outpat     --altered (ORD_...Dflt)
		where cpt_code_Type='colonoscopy'
	UNION 
select patientSSN,sta3n,patientSID,[Proc_dt] as colonoscopy_dt,'PrevColonScpy-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
		where [ICD9Proc_Code_type]='colonoscopy'	
	UNION 
select patientSSN,sta3n,patientSID,[Proc_dt] as colonoscopy_dt,'PrevColonScpy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
		where [ICD10Proc_code_type]='Colonoscopy'
	UNION 	
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as colonoscopy_dt,'PrevColonScpy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT]    --altered (ORD_...Dflt)
		where cpt_code_Type='colonoscopy'
	UNION 
select patientSSN,sta3n,patientSID,[DateOfOperation] as colonoscopy_dt,'PrevColonScpy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_7_surg     --altered (ORD_...Dflt)
		where isnull([PrincipalProcedureCode],'') in (select cptcode from [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
													  where cpt_code_type='colonoscopy')
	UNION 
select patientSSN,sta3n,patientSID,[DateOfOperation] as colonoscopy_dt,'PrevColonScpy-Surg' as datasource, OtherProcedureCode as 'CPTOrICD'
from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_7_surg     --altered (ORD_...Dflt)
		where isnull(OtherProcedureCode,'') in (select cptcode from [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc     --altered (ORD_...Dflt)
													  where cpt_code_type='colonoscopy')
	UNION 
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as colonoscopy_dt,'PrevColonScpy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD'
from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_9_FeeCPT     --altered (ORD_...Dflt)
       where cpt_code_Type='colonoscopy'
	
	go

-- All colectomy procedures from surgical, inpatient and outpatient and purchased care tables
	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_2_Colectomy]') is not null)    --altered (ORD_...Dflt)
		drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_2_Colectomy    --altered (ORD_...Dflt)

select patientSSN,sta3n,patientSID,[VProcedureDateTime] as Colectomy_dt ,'PrevColectomy-OutPat' as datasource,[CPTCode] as 'CPTOrICD'
into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_2_Colectomy    --altered (ORD_...Dflt)
from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_6_Outpat     --altered (ORD_...Dflt)
		where cpt_code_Type='Colectomy'
	UNION 
select patientSSN,sta3n,patientSID,[Proc_dt] as Colectomy_dt,'PrevColectomy-InPatICD' as datasource,ICD9ProcedureCode as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc]    --altered (ORD_...Dflt)
		where [ICD9Proc_Code_type]='Colectomy'	
	UNION 
select patientSSN,sta3n,patientSID,[Proc_dt] as Colectomy_dt,'PrevColectomy-InPatICD' as datasource,ICD10ProcedureCode as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc]    --altered (ORD_...Dflt)
		where [ICD10Proc_code_type]='Colectomy'
	UNION 	
select patientSSN,sta3n,patientSID,[CPTProcedureDateTime] as Colectomy_dt,'PrevColectomy-InPatCPT' as datasource,[CPTCode] as 'CPTOrICD'
from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT]    --altered (ORD_...Dflt)
		where cpt_code_Type='Colectomy'
	UNION 
select patientSSN,sta3n,patientSID,[DateOfOperation] as Colectomy_dt,'PrevColectomy-Surg' as datasource, [PrincipalProcedureCode] as 'CPTOrICD'
from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_7_surg     --altered (ORD_...Dflt)
		where isnull([PrincipalProcedureCode],'') in (select cptcode from [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc     --altered (ORD_...Dflt)
													 where cpt_code_type='Colectomy')
	UNION 
select patientSSN,sta3n,patientSID,[DateOfOperation] as Colectomy_dt,'PrevColectomy-Surg' as datasource, OtherProcedureCode as 'CPTOrICD'
from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_7_surg     --altered (ORD_...Dflt)
		where isnull(OtherProcedureCode,'') in (select cptcode from [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc     --altered (ORD_...Dflt)
												where cpt_code_type='Colectomy')
	UNION 
select patientSSN,sta3n,patientSID,InitialTreatmentDateTime as Colectomy_dt,'PrevColectomy-FeeCPT' as datasource, [CPTCode] as 'CPTOrICD'
from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_9_FeeCPT     --altered (ORD_...Dflt)
       where cpt_code_Type='Colectomy'
	
	go



-- Referrals (consults) from Potential patients

if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit_Hlp1]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit_Hlp1    --altered (ORD_...Dflt)
					
					select p.patientSSN
					,V.Sta3n,V.PatientSID,V.Visitsid,V.VisitDatetime,V.primaryStopcodeSID,V.SecondaryStopcodeSID					
					into [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit_Hlp1					    --altered (ORD_...Dflt)
					from [CDWWork].[Outpat].[Visit] as V    --altered (ORD_...Src)
                   inner join 
						(select distinct pat.*,ins.CBC_dt 
							from [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as pat    --altered (ORD_...Dflt)
							left join [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_8_IncIns as ins    --altered (ORD_...Dflt)
							on pat.patientSSN=ins.PatientSSN  
						) as p  
                    on v.sta3n=p.sta3n and v.patientsid=p.patientsid 
						and v.VisitDateTime between dateAdd(yy,-1,p.CBC_dt)
										and DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),p.CBC_dt)    --altered (ORD_...Dflt)
				where 	--CohortName='Cohort20180712'	and	
				V.VisitDateTime between dateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
										and DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
											,(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))						      --altered (ORD_...Dflt)
		go


if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit    --altered (ORD_...Dflt)

   select PatientSSN,VisitSID,VisitDateTime,PrimaryStopCodeSID,SecondaryStopCodeSID
   into [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit    --altered (ORD_...Dflt)
   from [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit_Hlp1    --altered (ORD_...Dflt)
   union
   select PatientSSN,VisitSID,VisitDateTime,PrimaryStopCodeSID,SecondaryStopCodeSID
   from [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit_Hlp1    --altered (ORD_...Dflt)
go



if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Exc_NonDx_5_AllVisits_StopCode]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_5_AllVisits_StopCode    --altered (ORD_...Dflt)
					
					select v.*,code1.stopcode as PrimaryStopCode,code1.stopcodename as PrimaryStopCodeName,code2.stopcode as SecondaryStopCode,code2.stopcodename as SecondaryStopCodeName
					into [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_5_AllVisits_StopCode    --altered (ORD_...Dflt)
					from [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit as V    --altered (ORD_...Dflt)
					left join [CDWWork].[Dim].[StopCode] as code1
					on V.PrimaryStopCodeSID=code1.StopCodeSID
					left join [CDWWork].[Dim].[StopCode] as code2
					on V.SecondaryStopCodeSID=code2.StopCodeSID

go

--Physician's notes from the visit
if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_7_VisitTIU') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_7_VisitTIU    --altered (ORD_...Dflt)


					select v.*
					,T.[TIUDocumentSID],T.[EntryDateTime],T.[ReferenceDateTime]--,ReportText
					,e.tiustandardtitle,T.ConsultSID
					into [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_7_VisitTIU				    --altered (ORD_...Dflt)
					from [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_5_AllVisits_StopCode as V    --altered (ORD_...Dflt)
					left join [CDWWork].[TIU].[TIUDocument] as T     --altered (ORD_...Src)
					on T.VisitSID=V.Visitsid --and T.CohortName='Cohort20180712'
					--more filter
					--and T.[EntryDateTime] between dateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
					--						  and DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
					--										,(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))	    --altered (ORD_...Dflt)
					--left join [CDW_TIU].[TIU].[TIUDocument_8925_02] as RptText
					--on T.TIUDocumentsid=RptText.TIUDocumentsid
					left join cdwwork.dim.[TIUDocumentDefinition] as d                                         
					on t.[TIUDocumentDefinitionSID]=d.[TIUDocumentDefinitionSID]
					left join cdwwork.dim.TIUStandardTitle as e
					on d.TIUStandardTitleSID=e.TIUStandardTitleSID
				--where isnull(T.OpCode,'')<>'D'

				
		go


--consult requested
-- E-Consult shares the same stop code as the physical location
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Exc_NonDx_9_VisitTIUConsult_joinByConsultSID]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_9_VisitTIUConsult_joinByConsultSID    --altered (ORD_...Dflt)

						select v.*
					,c.requestDateTime as ReferralRequestDateTime,c.OrderStatusSID as ConsultOrderStatusSID,
					c.ToRequestserviceSID as ConsultToRequestserviceSID,c.ToRequestserviceName as ConsultToRequestserviceName,
					c.placeofconsultation,	  
					c.requestType,   -- weather the request is a consult or procedure
					c.[InpatOutpat], -- the ordering person to indicate if the service is to be rendered on an outpatient or Inpatients basis.
					c.[RemoteService],
					d.StopCode as ConStopCode
					into [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_9_VisitTIUConsult_joinByConsultSID				    --altered (ORD_...Dflt)
                    from [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_7_VisitTIU as V    --altered (ORD_...Dflt)
					left join [CDWWork].[Con].[Consult] as C										                        --altered (ORD_...Src)
					on C.ConsultSID=V.ConsultSID --and CohortName='Cohort20180712'
					--more filter
					--and C.[requestDateTime] between dateAdd(yy,-1,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
					--						  and DateAdd(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
					--										,(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))	    --altered (ORD_...Dflt)
					left join CDWWork.dim.AssociatedStopCode as d
					on c.ToRequestserviceSID=d.RequestServiceSID

		go



-- procedures possibly from radiology 
if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_6_AllImgProcFromRad]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_6_AllImgProcFromRad    --altered (ORD_...Dflt)
select [RadiologyExamSID]
		,PatientSSN
      ,Rad.[Sta3n]
      ,rad.[PatientSID]
      ,[ExamDateTime]
      ,Rad.[RadiologyProcedureSID]
	  ,code.CPTCode
	  ,TargetImg.[cpt_code_type]
	  ,[RadiologyExamStatus]
	  ,[RadiologyDiagnosticCode]
into [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_6_AllImgProcFromRad    --altered (ORD_...Dflt)
FROM [CDWWork].[Rad].[RadiologyExam] as Rad    --altered (ORD_...Src)
left join cdwwork.dim.[RadiologyProcedure] as prc
on rad.sta3n=prc.sta3n and rad.[RadiologyProcedureSID]=prc.[RadiologyProcedureSID]
left join cdwwork.dim.CPT as code
on prc.CPTSID=code.CPTSID and prc.sta3n=code.sta3n 
inner join  [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc as TargetImg    --altered (ORD_...Dflt)
on TargetImg.CPTCode=code.CPTCode
left join cdwwork.dim.[RadiologyExamStatus] as sta
on Rad.sta3n=sta.sta3n and Rad.[RadiologyExamStatusSID]=sta.[RadiologyExamStatusSID]
left join cdwwork.dim.[RadiologyDiagnosticCode] as diag
on Rad.sta3n=diag.sta3n and Rad.[RadiologyDiagnosticCodeSID]=diag.[RadiologyDiagnosticCodeSID] 
inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
on p.sta3n=Rad.sta3n and p.patientsid=Rad.PatientSID
 where --Rad.CohortName='Cohort20180712' and	 
	 --colonoscopy performed withn 3 years prior
	 -- Total Colectomy any time prior 
	 -- between dateadd(yy,-3,(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))    --altered (ORD_...Dflt)
	 Rad.ExamDateTime <DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
								,(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP))     --altered (ORD_...Dflt)
	and sta.[RadiologyExamStatus] like'%COMPLETE%'

go


--------------------------------------------------------------------------------------------------------------------------------
-----  4. Exclude red-flagged patients with certain clinical diagnosis and other 
--------------------------------------------------------------------------------------------------------------------------------

--  Red-flagged instances: Exclude patients <40 or >75 years old 
if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_5_Ins_1_Age') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_1_Age    --altered (ORD_...Dflt)
select	a.* 
into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_1_Age    --altered (ORD_...Dflt)
from [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_8_IncIns] as a    --altered (ORD_...Dflt)
  where DATEDIFF(yy,DOB,a.[CBC_dt]) >= (select age_Lower from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
	and DATEDIFF(yy,DOB,a.[CBC_dt]) < (select age_upper from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
	go

--  Red-flagged instances: Exclude deseased patients
if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_5_Ins_2_ALive') is not null)    --altered (ORD_...Dflt)
	drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_2_ALive     --altered (ORD_...Dflt)
select a.*
into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_2_ALive    --altered (ORD_...Dflt)
from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_1_Age as a    --altered (ORD_...Dflt)
 where 
        [DOD] is null 		 
		or (DOD is not null 
				and ( 
					DATEADD(dd,-(select fu_period from [MyDB].[MySchema].[FOBT_Sta3n528_0_1_inputP]),dod)> a.cbc_dt    --altered (ORD_...Dflt)
					)
				)	   	     
go

--  Red-flagged instances: Exclude patients with previous colon cancer		
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_3_PrevCRCCancer]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_3_PrevCRCCancer    --altered (ORD_...Dflt)

        select a.*
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_3_PrevCRCCancer    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_2_ALive as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_0_PrevCLCFromProblemList_ICD9ICD10 as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN]
			 			and b.EnteredDateTime between dateadd(yy,-1,a.CBC_dt) and a.CBC_dt)
			 
		go


--  Red-flagged instances: Exclude patients with colectomy
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_4_colectomy]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_4_colectomy    --altered (ORD_...Dflt)

        select a.*
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_4_colectomy    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_3_PrevCRCCancer as a    --altered (ORD_...Dflt)
		where not exists
			(			
			 select * from (
			 select patientssn, [colectomy_dt] from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_2_Colectomy     --altered (ORD_...Dflt)
			 union
			 select patientssn,ExamdateTime as [colectomy_dt] from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_6_AllImgProcFromRad    --altered (ORD_...Dflt)
			 where cpt_code_type='colectomy' ) as b
			 where a.[PatientSSN] = b.[PatientSSN]
			 and b.[colectomy_dt] <= DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),a.CBC_dt))    --altered (ORD_...Dflt)
			 
		go

--  Red-flagged instances: Exclude patients with terminal/major DX
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_5_Term]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_5_Term    --altered (ORD_...Dflt)

        select a.*
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_5_Term    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_4_colectomy as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_4_Union_ALLDx_ICD] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN] 			 			
			 and b.[term_dx_dt] between DATEADD(yy,-1,a.CBC_dt) and DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),a.CBC_dt))    --altered (ORD_...Dflt)
			 
		go

 --  Red-flagged instances: Exclude patients with hospice/palliative diagnosis
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6_Hospice]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6_Hospice    --altered (ORD_...Dflt)

        select a.*
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6_Hospice    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_5_Term as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_4_Union_ALLDx_ICD] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN] 
			 and b.[hospice_dt] between DATEADD(yy,-1,a.CBC_dt) and DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),a.CBC_dt))    --altered (ORD_...Dflt)
			 
		go


--  Red-flagged instances: Exclude patients with hospice/palliative care		
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B1_Inpat_HospiceSpecialty]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B1_Inpat_HospiceSpecialty]    --altered (ORD_...Dflt)
		go

	select * 
	into [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B1_Inpat_HospiceSpecialty]    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6_Hospice    --altered (ORD_...Dflt)
	except
	SELECT x.*
	 from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6_Hospice as x    --altered (ORD_...Dflt)
	 inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
	 on  x.PatientSSN=p.PatientSSN
	 inner join [CDWWork].[Inpat].[Inpatient] as a    --altered (ORD_...Src)
	 on a.Sta3n=p.sta3n and a.PatientSID=p.patientsid
	 inner join CDWWork.Dim.Specialty as s
	 on a.DischargeFromSpecialtySID=s.SpecialtySID and a.sta3n=s.sta3n
	  where ltrim(rtrim(s.PTFCode)) in ('96','1F') and
	   a.[DischargeDateTime] between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),x.CBC_dt)    --altered (ORD_...Dflt)

--  Red-flagged instances: Exclude patients with VA Paid/Fee Based hospice/palliative care
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B2_Hospice_FeeInpatInvoice_PurposeOfVisit]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B2_Hospice_FeeInpatInvoice_PurposeOfVisit]    --altered (ORD_...Dflt)
		go

	select * 
	into [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B2_Hospice_FeeInpatInvoice_PurposeOfVisit]    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B1_Inpat_HospiceSpecialty]    --altered (ORD_...Dflt)
	except
	SELECT x.*
	 from [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B1_Inpat_HospiceSpecialty] as x    --altered (ORD_...Dflt)
	 inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
	 on  x.PatientSSN=p.PatientSSN
	 inner join [CDWWork].[Fee].[FeeInpatInvoice] as a    --altered (ORD_...Src)
	 on a.Sta3n=p.sta3n and a.PatientSID=p.patientsid
		inner join cdwwork.dim.FeePurposeOfVisit as b
		on a.FeePurposeOfVisitSID=b.FeePurposeOfVisitSID
	  where ltrim(rtrim(b.AustinCode)) in ('43','37','38','77','78')   and
	   a.TreatmentFromDateTime 		between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),x.CBC_dt)    --altered (ORD_...Dflt)
					  

		go

--  Red-flagged instances: Exclude patients with VA Paid/Fee Based hospice/palliative care
				if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B3_Hospice_FeeServiceProvided_HCFAType]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B3_Hospice_FeeServiceProvided_HCFAType]    --altered (ORD_...Dflt)
		go


	select * 	 
	into [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B3_Hospice_FeeServiceProvided_HCFAType]    --altered (ORD_...Dflt)
	from [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B2_Hospice_FeeInpatInvoice_PurposeOfVisit] as x    --altered (ORD_...Dflt)
	except
	SELECT x.*	
	 from [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B2_Hospice_FeeInpatInvoice_PurposeOfVisit] as x    --altered (ORD_...Dflt)
	 inner join [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_9_IncPat] as p    --altered (ORD_...Dflt)
	 on  x.PatientSSN=p.PatientSSN
	 inner join [CDWWork].[fee].[FeeServiceProvided] as a    --altered (ORD_...Src)
	 on a.Sta3n=p.sta3n and a.PatientSID=p.patientsid
		inner join [CDWWork].[fee].[FeeInitialTreatment] as d    --altered (ORD_...Src)
		on a.FeeInitialTreatmentSID=d.FeeInitialTreatmentSID
	 inner join CDWWork.Dim.IBTypeOfService as b
		on a.IBTypeOfServiceSID=b.IBTypeOfServiceSID
--	  where ltrim(rtrim(b.IBTypeOfServiceCode)) in ('34','H','Y') and
	  where ltrim(rtrim(b.IBTypeOfServiceCode)) in ('34','H') and
	   d.[InitialTreatmentDateTime] between DATEADD(yy,-1,x.CBC_dt) and 
					  DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),x.CBC_dt)    --altered (ORD_...Dflt)

go

--  Red-flagged instances: Exclude patients with hospice/palliative referral
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6D1_Hospice_Refer_joinByConsultSID]') is not null)    --altered (ORD_...Dflt)
					drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6D1_Hospice_Refer_joinByConsultSID    --altered (ORD_...Dflt)
				
		select *
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6D1_Hospice_Refer_joinByConsultSID    --altered (ORD_...Dflt)
        from [MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_6B3_Hospice_FeeServiceProvided_HCFAType] as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_9_VisitTIUConsult_joinByConsultSID as b    --altered (ORD_...Dflt)
			 where (
			 b.PrimaryStopCode in (351,353)   or b.SecondaryStopCode in (351,353)  or b.ConStopCode in (351,353) 
					or 	(b.[ConsultToRequestserviceName] like '%Hospice%' or b.[ConsultToRequestserviceName] like '%palliative%'
					or b.TIUStandardTitle like '%Hospice%' or b.TIUStandardTitle like '%palliative%')
					)
			 and a.patientSSN = b.patientSSN and
			 (coalesce(b.ReferenceDateTime,b.visitDateTime) between DATEADD(yy,-1, convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime)) 
								and DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP), convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime)))    --altered (ORD_...Dflt)
			 and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)			       --altered (ORD_...Dflt)
								)
go


--  Red-flagged instances: Exclude patients with UGI Bleeding 
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_7_UGIBleed]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_7_UGIBleed    --altered (ORD_...Dflt)

        select a.*
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_7_UGIBleed    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6D1_Hospice_Refer_joinByConsultSID as a    --altered (ORD_...Dflt)
		where not exists
			(select * from [MyDB].[MySchema].[FOBT_Sta3n528_2_ExcDx_4_Union_ALLDx_ICD] as b    --altered (ORD_...Dflt)
			 where a.[PatientSSN] = b.[PatientSSN] 			 			
			 and b.[ugi_bleed_dx_dt] between DATEADD(mm,-6,a.CBC_dt) and a.CBC_dt)
			 
		go

--  Red-flagged instances: Exclude patients with prior ColonScpy done 
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_8_ColonScpy]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_8_ColonScpy    --altered (ORD_...Dflt)
        select a.*
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_8_ColonScpy    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_7_UGIBleed as a    --altered (ORD_...Dflt)
		where not exists
			(
			 select * from (
			 select patientssn, [colonoscopy_dt] from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy]     --altered (ORD_...Dflt)
			 union
			 select patientssn,ExamdateTime as [colonoscopy_dt] from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_6_AllImgProcFromRad    --altered (ORD_...Dflt)
			 where cpt_code_type='colonoscopy' ) as b			
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[colonoscopy_dt] between DATEADD(yy,-3,a.CBC_dt) and a.CBC_dt)
		go



--------------------------------------------------------------------------------------------------------------------------------
-----  5. Exclude red-flagged patients with timely follow up
--------------------------------------------------------------------------------------------------------------------------------

--  Red-flagged instances: Exclude patients with follow up ColonScpy 
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_9_ColonScpy_60d]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_9_ColonScpy_60d    --altered (ORD_...Dflt)
        select a.*
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_9_ColonScpy_60d    --altered (ORD_...Dflt)
		from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_8_ColonScpy as a    --altered (ORD_...Dflt)
		where not exists
			(			 
			 select * from (
			 select patientssn, [colonoscopy_dt] from [MyDB].[MySchema].[FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy]     --altered (ORD_...Dflt)
			 union
			 select patientssn,ExamdateTime as [colonoscopy_dt] from [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_6_AllImgProcFromRad    --altered (ORD_...Dflt)
			 where cpt_code_type='colonoscopy' ) as b
			 where a.[PatientSSN] = b.[PatientSSN]			 			
			 and b.[colonoscopy_dt] between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))    --altered (ORD_...Dflt)
		go

   --  Red-flagged instances: Exclude patients with follow up GI Referral
		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_A]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_A    --altered (ORD_...Dflt)

        select a.* --
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_A    --altered (ORD_...Dflt)
    	from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_9_ColonScpy_60d as a    --altered (ORD_...Dflt)
		where not exists --
			(select * from [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_9_VisitTIUConsult_joinByConsultSID as b    --altered (ORD_...Dflt)
			 where (
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321) or b.ConStopCode in (33,307,321)
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and			 
			 (b.visitDateTime between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime)))))    --altered (ORD_...Dflt)
go


	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_B1]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_B1    --altered (ORD_...Dflt)

        select a.* --
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_B1    --altered (ORD_...Dflt)
     	from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_A as a    --altered (ORD_...Dflt)
		where not exists --
			(select * from [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_9_VisitTIUConsult_joinByConsultSID as b    --altered (ORD_...Dflt)
			 where (
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321) or b.ConStopCode in (33,307,321)
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and		 
			 (b.ReferenceDateTime between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))    --altered (ORD_...Dflt)
			  and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
			  and b.PrimaryStopCodeSID=-1 
			  )
go


 	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_B2]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_B2    --altered (ORD_...Dflt)

        select a.* --
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_B2    --altered (ORD_...Dflt)
     	from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_B1 as a    --altered (ORD_...Dflt)
		where not exists --
			(select * from [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_9_VisitTIUConsult_joinByConsultSID as b    --altered (ORD_...Dflt)
			 where (
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321) or b.ConStopCode in (33,307,321)
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and	 
			 (b.VisitDatetime between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))    --altered (ORD_...Dflt)
			  and b.PrimaryStopCodeSID<>-1  
			  and isnull( b.PrimaryStopCode,'') not in (33,307,321) and  isnull( b.SecondaryStopCode,'') not in (33,307,321)
											
			  )
go

 	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID    --altered (ORD_...Dflt)

        select a.* --
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID    --altered (ORD_...Dflt)
     	from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_B2 as a    --altered (ORD_...Dflt)
		where not exists --
			(select * from [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_9_VisitTIUConsult_joinByConsultSID as b    --altered (ORD_...Dflt)
			 where (
			 b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321) or b.ConStopCode in (33,307,321)
					or 	b.[ConsultToRequestserviceName] like '%Gastro%' or b.[ConsultToRequestserviceName] like '%GI %' 
					or b.TIUStandardTitle like '%Gastro%' or b.TIUStandardTitle like '%GI %'
					)
				    and isnull(b.PrimaryStopCodeName,'') not like '%telephone%' 
				      and isnull(b.SecondaryStopCodeName,'') not like '%telephone%' 
			 and a.patientSSN = b.patientSSN and
			 (b.ReferenceDateTime between (convert(varchar(10),a.CBC_dt,120)+cast('00:00:00.000' as datetime))
			  and (DATEADD(dd,(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP),convert(varchar(10),a.CBC_dt,120)+cast('23:59:59.997' as datetime))))    --altered (ORD_...Dflt)
			  and datediff(dd,b.visitDateTime,b.ReferenceDateTime)<(select fu_period from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
			  and b.PrimaryStopCodeSID<>-1
			  and ( b.PrimaryStopCode in (33,307,321)   or b.SecondaryStopCode in (33,307,321)) 										
			  )
go

--------------------------------------------------------------------------------------------------------------------------------
-----  6. Trigger positive FOBT tests from potential patients
--------------------------------------------------------------------------------------------------------------------------------

 	if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_U_TriggerPos]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_U_TriggerPos    --altered (ORD_...Dflt)

       select * 
	   into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_U_TriggerPos    --altered (ORD_...Dflt)
	   from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID    --altered (ORD_...Dflt)
	   	where CBC_dt between (select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
		                  and (select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
	   union
	   select *  from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID    --altered (ORD_...Dflt)
		where CBC_dt between (select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
		                  and (select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)


		if (OBJECT_ID('[MyDB].[MySchema].[FOBT_Sta3n528_5_Ins_V_FirstOfPat]') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_V_FirstOfPat    --altered (ORD_...Dflt)

		SELECT a.*
		into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_V_FirstOfPat    --altered (ORD_...Dflt)
				from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_U_TriggerPos as a    --altered (ORD_...Dflt)
				inner join 
				(         select a.patientssn, min(a.CBC_dt) as FirstClueDate		
				from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_U_TriggerPos as a		    --altered (ORD_...Dflt)
				where a.CBC_dt between (select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
								  and (select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)			      --altered (ORD_...Dflt)
				group by a.patientssn
				) as sub
				on a.patientssn=sub.patientssn and a.CBC_dt=sub.FirstClueDate	
		where a.CBC_dt between (select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
		                  and (select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)		    --altered (ORD_...Dflt)
go


--------------------------------------------------------------------------------------------------------------------------------
-----   counts
--------------------------------------------------------------------------------------------------------------------------------

-- Numerator and Denumerator
if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_5_Ins_X_count') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_X_count    --altered (ORD_...Dflt)
		go

-- Numerator and Denumerator
if (OBJECT_ID('[MyDB].[MySchema].FOBT_Sta3n528_5_Ins_X_count') is not null)    --altered (ORD_...Dflt)
			drop table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_X_count    --altered (ORD_...Dflt)
		go

		With -- number of FOBT test performed
		NumOfTotalFOBTTest (sta3n,sta6a,[Year],[Month],NumOfTotalFOBTTest) as 	 
			(select  sta3n,sta6a,datepart(year,FOBT_dt) as [Year],datepart(MONTH,FOBT_dt) as[Month],count(distinct concat( PatientSSN,FOBT_dt )) as NumOfTotalFOBTTest
				 from [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_1_AllFOBTSta6a    --altered (ORD_...Dflt)
				 where FOBT_dt >=(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
					   and FOBT_dt <=(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
				 group by sta3n,Sta6a,datepart(year,FOBT_dt),datepart(MONTH,FOBT_dt)--,PatientSSN,FOBT_dt
			) 
		-- number of patients with FOBT test performed
		,NumOfTotalPatWithFOBTTest (sta3n,sta6a,[Year],[Month],NumOfTotalPatWithFOBTTest) as
			(select sta3n,sta6a, datepart(year,FOBT_dt) as [Year],datepart(MONTH,FOBT_dt) as[Month],count(distinct  patientssn ) as NumOfTotalPatWithFOBTTest
				 from [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_1_AllFOBTSta6a    --altered (ORD_...Dflt)
				 where FOBT_dt >=(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
					   and FOBT_dt <=(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
				 group by sta3n,Sta6a,datepart(year,FOBT_dt),datepart(MONTH,FOBT_dt)
			) 		
		-- number of FOBT test which are red-flageed
		,NumOfRedFlaggedFOBTTest(sta3n,sta6a,[Year],[Month],NumOfRedFlaggedFOBTTest) as 
				(select sta3n,sta6a,datepart(year,CBC_dt) as [Year],datepart(MONTH,CBC_dt) as[Month],count(distinct concat( PatientSSN,CBC_dt ) ) as NumOfRedFlaggedFOBTTest
				from [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_8_IncIns    --altered (ORD_...Dflt)
					 where CBC_dt >=(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
						   and CBC_dt <=(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
				group by sta3n,sta6a,datepart(year,CBC_dt),datepart(MONTH,CBC_dt)
			)
		--  number of patients with red-flagged FOBT test
		,NumOfPatWithRedFlaggedFOBTTest(sta3n,sta6a,[Year],[Month],NumOfPatWithRedFlaggedFOBTTest) as 
				(select sta3n,sta6a,datepart(year,CBC_dt) as [Year],datepart(MONTH,CBC_dt) as[Month],count(distinct  patientssn ) as NumOfPatWithRedFlaggedFOBTTest
				from [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_8_IncIns    --altered (ORD_...Dflt)
					 where CBC_dt >=(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
						   and CBC_dt <=(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
				group by sta3n,sta6a,datepart(year,CBC_dt),datepart(MONTH,CBC_dt)
			)
		-- number of FOBT tests which come out as trigger positive
		,NumOfTriggerPosFOBTTest(sta3n,sta6a,[Year],[Month],NumOfTriggerPosFOBTTest) as
			(select sta3n,sta6a,datepart(year,CBC_dt) as [Year],datepart(MONTH,CBC_dt) as[Month],count(distinct concat( PatientSSN,CBC_dt ) ) as NumOfTriggerPosFOBTTest
				from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_U_TriggerPos    --altered (ORD_...Dflt)
					where CBC_dt >=(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
						 and CBC_dt <=(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
					group by sta3n,sta6a,datepart(year,CBC_dt),datepart(MONTH,CBC_dt)
			)
		--number of patients with trigger positive FOBT test
		,NumOfTriggerPosPat(sta3n,sta6a,[Year],[Month],NumOfTriggerPosPat) as 
				(select sta3n,sta6a,datepart(year,CBC_dt) as [Year],datepart(MONTH,CBC_dt) as[Month],count(distinct  patientssn ) as NumOfTriggerPosPat
				 from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_U_TriggerPos    --altered (ORD_...Dflt)
							where CBC_dt >=(select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
					and CBC_dt <=(select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
					group by sta3n,sta6a,datepart(year,CBC_dt),datepart(MONTH,CBC_dt)
		)

			select 
					(select  run_dt  from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP) as run_dt    --altered (ORD_...Dflt)
					,(select  sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP) as sp_start    --altered (ORD_...Dflt)
					,(select  sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP) as sp_end    --altered (ORD_...Dflt)
					,a.sta3n,a.sta6a,a.[Year],a.[month]
					,isnull(NumOfTotalFOBTTest,0) as NumOfTotalFOBTTest
					,isnull(NumOfTotalPatWithFOBTTest,0) as NumOfTotalPatWithFOBTTest
					,isnull(NumOfRedFlaggedFOBTTest,0) as NumOfRedFlaggedFOBTTest
					,isnull(NumOfPatWithRedFlaggedFOBTTest,0) as NumOfPatWithRedFlaggedFOBTTest
					,isnull(NumOfTriggerPosFOBTTest,0) as NumOfTriggerPosFOBTTest
					,isnull(NumOfTriggerPosPat,0) as NumOfTriggerPosPat
			into [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_X_count    --altered (ORD_...Dflt)
			from  NumOfTotalFOBTTest as a
			left join NumOfTotalPatWithFOBTTest as b
			on a.sta3n=b.sta3n and a.sta6a=b.sta6a and a.[year]=b.[year] and a.[Month]=b.[Month]
			left join NumOfRedFlaggedFOBTTest as c
			on a.sta3n=c.sta3n and a.sta6a=c.sta6a and a.[year]=c.[year] and a.[Month]=c.[Month]
			left join NumOfPatWithRedFlaggedFOBTTest as d
			on a.sta3n=d.sta3n and a.sta6a=d.sta6a and a.[year]=d.[year] and a.[Month]=d.[Month]
			left join NumOfTriggerPosFOBTTest as e
			on a.sta3n=e.sta3n and a.sta6a=e.sta6a and a.[year]=e.[year] and a.[Month]=e.[Month]
			left join NumOfTriggerPosPat as f
			on a.sta3n=f.sta3n and a.sta6a=f.sta6a and a.[year]=f.[year] and a.[Month]=f.[Month]

go

select * from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_X_count    --altered (ORD_...Dflt)
order by sta3n,sta6a,[year],[month]

----data set
---- all fobt tests from sta6a in the study period
--select * from [MyDB].[MySchema].[FOBT_Sta3n528_1_Inc_1_AllFOBTSta6a]    --altered (ORD_...Dflt)
--where  FOBT_dt between (select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
--		and (select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
--		and Sta6a in (select sta6a from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
---- red flagged fobt tests from sta6a in the study period
--select * from [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_8_IncIns    --altered (ORD_...Dflt)
--where  CBC_dt between (select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
--		and (select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
--		and Sta6a in (select sta6a from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
---- trigger positive fobt tests from sta6a in the study period
--select * from [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_U_TriggerPos    --altered (ORD_...Dflt)
--where  CBC_dt between (select sp_start from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
--		and (select sp_end from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)
--		and Sta6a in (select sta6a from [MyDB].[MySchema].FOBT_Sta3n528_0_1_inputP)    --altered (ORD_...Dflt)


---- Uncomment below to delete intermediate tables created during execution
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_0_2_DxICD10CodeExc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_0_3_PreProcICD10ProcExc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_0_4_DxICD9CodeExc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_0_5_PrevProcCPTCodeExc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_0_6_PreProcICD9ProcExc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_0_7_FOBTLabTestName    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_0_8_ColonCancerDxICD9Code    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_0_9_ColonCancerDxICD10Code    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_0_A_RedFlagFOBTTestResult    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_1_Inc_9_IncPat    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_0_PrevCLCFromProblemList_ICD9ICD10    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_1_OutPatDx_ICD9ICD10    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_2_SurgDx_ICD9ICD10    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Census501Diagnosis    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_CensusDiagnosis    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_Inpat_Inpatient501TransactionDiagnosis    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_InpatientDischargeDiagnosis    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_PatientTransferDiagnosis    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_A_InPatDx_ICD9ICD10_SpecialtyTransferDiagnosis    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_B_InpatientFeeDiagnosisDx_ICD9ICD10    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_3_C_FeeICDDxFromFeeServiceProvided_ICD9ICD10    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD10    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_ALLDx_ICD9    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_2_ExcDx_4_Union_ALLDx_ICD    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_0_HLP_InPICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_1_HLP_CensusICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_2_HLP_InPSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_3_HLP_CensusSurgICD_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_4_HLP_FeeICDProc_Inpat_ICD9ProcICD10Proc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD10Proc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_5_Union_Inpat_ICD9Proc    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_6_Outpat    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_7_surg    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_8_Inpat_CPT    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_9_FeeCPT    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_1_ColonScpy    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_3_PrevProc_All_2_Colectomy    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_3_Exc_NonDx_6_AllImgProcFromRad    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_3_AllVisit_Hlp1    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_5_AllVisits_StopCode    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_7_VisitTIU    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Exc_NonDx_9_VisitTIUConsult_joinByConsultSID    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_1_Age    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_2_ALive    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_3_PrevCRCCancer    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_4_colectomy    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_5_Term    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6_Hospice    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6B1_Inpat_HospiceSpecialty    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6B2_Hospice_FeeInpatInvoice_PurposeOfVisit    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6B3_Hospice_FeeServiceProvided_HCFAType    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_6D1_Hospice_Refer_joinByConsultSID    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_7_UGIBleed    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_8_ColonScpy    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_9_ColonScpy_60d    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_A    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_B1    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_A01_GIRefer60d_joinByConsultSID_B2    --altered (ORD_...Dflt)
--Drop Table [MyDB].[MySchema].FOBT_Sta3n528_5_Ins_V_FirstOfPat    --altered (ORD_...Dflt)





