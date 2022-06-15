clear
capture set more off

global database "Aurum"
global version "2021_02"

if "$database" == "Aurum" {
	global Dictionarydir "J:\EHR Share\3 Database guidelines and info\CPRD Aurum\Code browsers\\${version}"
	global Productdic "$Dictionarydir\CPRDAurumProduct"
	global Medicaldic "$Dictionarydir\CPRDAurumMedical"
	}

global Projectdir "J:\EHR-Working\QRISK\qrisk_bundle_aurum\codelists\v2"

global Dodir "$Projectdir\dofiles"
global Logdir "$Projectdir\logfiles\\${version}"
global Datadir "$Projectdir\datafiles\\${version}"
global Textdir "$Projectdir\textfiles\\${version}"
global Sourcedir "$Projectdir\sourcefiles"

