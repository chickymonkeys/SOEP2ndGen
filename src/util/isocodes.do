********************************************************************************
*                                                                              *
* Filename: isocodes.do                                                        *
* Description: a script that uses the command kountry in order to harmonize    *
*   the country names to the one of the SOEP and the country codes to the ISO  *
*   3166 numeric standard. This allows us to merge the SOEP with country       *
*   specific datasets.                                                         *
* P.S.: Before merging, switch the label language to English!                  *
*                                                                              *
********************************************************************************

* use this dataset as reference point for country of origin
use "${SOEP_PATH}/ppathl.dta", clear

lab lang EN
* drop country of non-significant country of origin (keep Ex-Yugoslavia)
drop if corigin == 222 | corigin == 333 | corigin == 444 | corigin == 999 | ///
    corigin == 98 | corigin == 7 | corigin < 0
* decode country of origin to get the strings
decode corigin, g(cnames)
* regular expression to save just the full name of the country
replace cnames = regexs(2) if regexm(cnames,"(\[[0-9]+\] )([-a-zA-Z0-9._ ]*)")

* drop duplicates so it is easier
duplicates drop corigin, force

* add Saint Lucia and Seychelles
set obs `=_N+2'
replace corigin = 72  in `=_N-1'
replace cnames  = "St. Lucia" if corigin == 72
replace corigin = 131  in `=_N'
replace cnames  = "Seychelles" if corigin == 131

* ISO 3166-1 Numeric Code for Countries
kountry cnames, from(other) st

* change Serbia in 688 (old code)
replace _ISO3N_ = 688 if _ISO3N_ == 890

* withdrawn codes for Ex-Yugoslavia and East Germany
replace _ISO3N_ = 890 if corigin == 3
replace _ISO3N_ = 278 if corigin == 7

* name mismatch for Colombia, Cabo Verde, Trinidad
replace _ISO3N_ = 170 if corigin == 48
replace _ISO3N_ = 132 if corigin == 36
replace _ISO3N_ = 780 if corigin == 115

* de facto code for Kurdistan
replace _ISO3N_ = 639 if corigin == 149

* de facto code for Kosovo
replace _ISO3N_ = 383 if corigin == 140

* replace Benelux with Belgium
replace _ISO3N_ = 56 if corigin == 12
replace cnames  = "Belgium" if _ISO3N_ == 56
replace corigin = 117 if corigin == 12

* Congo is not divided in the two countries : we assume Belgian Congo
replace _ISO3N_ = 180 if _ISO3N_ == 178

label drop corigin_EN corigin
rename (_ISO3N_ corigin) (isocodes oldcode)

* to use labmask we need to drop duplicates
duplicates drop isocodes, force
* trim the country names
replace cnames = strtrim(cnames)
* generate label values from the generated isocodes
labmask isocodes, values(cnames)
* non-interesting codes are dropped
drop if missing(isocodes)
* oldcode is for the merging
keep isocodes oldcode


compress
save "${DATA_PATH}/soep_isocodes.dta", replace
