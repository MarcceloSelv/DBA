
--http://www.sqlservercentral.com/scripts/Test+Data/128795/

SET NOCOUNT ON;
USE PATIENT_WAREHOUSE_PROD;

DECLARE @parmRealOrAnonimized CHAR(1) = 'A';

-- STEP 1: Populate anonymous first names with first 200 patients at Mayo Clinic starting with E) ...
;WITH AnonFN (Anon_Row, Anon_FirstName) AS	
	(
		SELECT	TOP 200 RANK() OVER(ORDER BY P.pat_first_name), P.pat_first_name
		FROM	Patient_Table P
		WHERE	P.pat_location = 'MAYO CLINIC' AND 
			P.pat_first_name LIKE '[E-Z]%'
		GROUP BY P.pat_first_name
	)

-- STEP 2: Populate anonymous middle names with first 200 patients at Johns Hopkins starting with K) ...
,AnonMN (Anon_Row, Anon_MiddleName) AS														(
		SELECT	TOP 200 RANK() OVER(ORDER BY P.pat_middle_name), P.pat_middle_name
		FROM	Patient_Table P
		WHERE	P.pat_location = 'JOHNS HOPKINS' AND
			P.pat_middle_name LIKE '[K-Z]%' 
		GROUP BY P.pat_middle_name
	)

-- STEP 3: Populate anonymous last names with first 200 patients at Mass General starting with A) ...
,AnonLN (Anon_Row, Anon_LastName) AS														(
		SELECT	TOP 200 RANK() OVER(ORDER BY P.pat_last_name), P.pat_last_name
		FROM	Patient_Table P
		WHERE	P.pat_location = 'MASS GENERAL' AND
			P.pat_last_name LIKE '[A-Z]%'
		GROUP BY P.pat_last_name
	)

-- STEP 4: Populate anonymous addresses with first 200 patients at Duke University Hospital) ...
,AnonA1 (Anon_Row, Anon_Address1) AS														(
		SELECT	TOP 200 RANK() OVER(ORDER BY P.pat_address_1), P.pat_address_1
		FROM	Patient_Table P
		WHERE	P.pat_location = 'DUKE UNIVERSITY HOSPITAL' AND
			P.pat_address_1 IS NOT NULL
		GROUP BY P.pat_address_1
	)

-- STEP 5: Populate anonymous addresses with first 200 patients at Brigham and Women’s Hospital) ...
,AnonCSZ (Anon_Row, Anon_City, Anon_State, Anon_Zip) AS										--	(
		SELECT	TOP 200 RANK() OVER(ORDER BY P.pat_address_1, P.pat_city, P.pat_state, P.pat_zip), P.pat_city, P.pat_state, P.pat_zip
		FROM	Patient_Table P
		WHERE	P.pat_location = 'BRIGHAM AND WOMENS' AND
			P.pat_address_1 IS NOT NULL		
GROUP BY P.pat_address_1, P.pat_city, P.pat_state, P.pat_zip	
	)

-- STEP 6: Populate anonymous DOBs with first 200 patients at Cedars-Sinai) ...
,AnonDOB (Anon_Row, Anon_DOB) AS	
	(
		SELECT	TOP 200 RANK() OVER(ORDER BY P.pat_date_of_birth), FORMAT(P.pat_date_of_birth, 'yyyyMMdd', 'en-US')
		FROM	Patient_Table P
		WHERE	P.pat_location = 'CEDARS-SINAI' AND
			P.pat_date_of_birth > '19600101' 
		GROUP BY P.pat_date_of_birth
	)

-- STEP 7: Consolidate all anonymous tables …
,AnonCombined (	Anon_Row, Anon_FirstName, Anon_MiddleName, Anon_LastName, Anon_Address1, Anon_City, 
Anon_State, Anon_Zip, Anon_DOB, Anon_AttendingMD, ReferringMD, AdmittingMD) AS
	(
		SELECT	FN.Anon_Row,	FN.Anon_FirstName, MN.Anon_MiddleName, LN.Anon_LastName, A1.Anon_Address1, CSZ.Anon_City,
			CSZ.Anon_State, CSZ.Anon_Zip, D.Anon_DOB
		FROM	AnonFN FN
			JOIN AnonMN MN   ON MN.Anon_Row = FN.Anon_Row
			JOIN AnonLN LN   ON LN.Anon_Row = FN.Anon_Row
			JOIN AnonA1 A1   ON A1.Anon_Row = FN.Anon_Row
			JOIN AnonCSZ CSZ ON CSZ.Anon_Row = FN.Anon_Row
			JOIN AnonDOB D   ON D.Anon_Row = FN.Anon_Row
	)

-- STEP 8: Pull the real data...
,RealData (	RowNumber, PatientId, FacilityName, PatientLastName, PatientFirstName, PatientMiddleName, PatientStreetAddress, PatientCity,
		PatientState, PatientZipCode, PatientPrimaryPhone, PatientSSN, PatientDOB, PatientGender) AS
	(
	SELECT	ROW_NUMBER() OVER(ORDER BY P.patient_id)				AS RowNumber,
	        P.pat_id			AS PatientId,	
		P.pat_location		        AS FacilityName,
		P.pat_last_name			AS PatientLastName, 
		P.pat_first_name		AS PatientFirstName,
		COALESCE(REPLACE(P.pat_middle_name, ',', ' '), '')	AS PatientMiddleName,
		P.pat_address_1			AS PatientStreetAddress,
		P.pat_city			AS PatientCity,
		P.pat_state			AS PatientState,
	        P.pat_zip			AS PatientZipCode,
		P.pat_phone_1			AS PatientPrimaryPhone,
		COALESCE(REPLACE(P.pat_ssn, '-', ''), '') AS PatientSSN, 
                FORMAT(P.pat_date_of_birth, 'yyyyMMdd', 'en-US')		                                        AS PatientDOB,
		P.pat_sex			AS PatientGender,
	FROM	Patient_Table P
	)

-- STEP 9: Select either the real or anon data, depending on the runtime parm...
SELECT	R.FacilityName,
	PatientId = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientId ELSE (ABS(CHECKSUM(NewId())) % 7500) END,
	PatientLastName = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientLastName ELSE A.Anon_LastName END,
	PatientFirstName = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientFirstName ELSE A.Anon_FirstName END,
	PatientMiddleName = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientMiddleName ELSE A.Anon_MiddleName END,
	PatientStreetAddress = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientStreetAddress ELSE A.Anon_Address1 END,
	PatientCity = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientCity ELSE A.Anon_City END,
	PatientState = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientState ELSE A.Anon_State END,
	PatientZipCode = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientZipCode ELSE A.Anon_Zip END,
	PatientPrimaryPhone = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientPrimaryPhone ELSE RIGHT((ABS(CHECKSUM(NewId())) % 11002001000), 10) END,
	PatientSSN = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientSSN ELSE RIGHT((ABS(CHECKSUM(NewId())) % 2350000000), 9) END,
	PatientDOB = CASE @parmRealOrAnonimized 
WHEN 'R' THEN R.PatientDOB ELSE A.Anon_DOB END,
FROM	RealData R
		LEFT OUTER JOIN AnonCombined A ON A.Anon_Row = R.RowNumber
