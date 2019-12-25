********************************************************************************
*                                                                              *
* Filename: test.do                                                            *
* Description: .do file to run tests after setting the environment             *
*                                                                              *
********************************************************************************

* check whether the path to the datasets is running properly

capture {
    u "${SOEP_PATH}/abroad.dta", clear
    u "${SOEP_PATH_RAW}/abroad.dta", clear
}

if _rc {
    di "Pathnames not defined (network error?)"
    exit, clear
}