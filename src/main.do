********************************************************************************
*                                                                              *
* Title:     Does Culture Affect Households' Borrowing Choices?                *
* Author:    Alessandro Pizzigolotto (NHH)                                     *
* Language:  Stata (sigh)                                                      *
* Version:   0.1 (alpha)                                                       *
*                                                                              *
********************************************************************************
********************************************************************************
*                                                                              *
* Filename: main.do                                                            *
* Description: Workspace Settings for Stata Project                            *
*                                                                              *
********************************************************************************

loc filename = "main"

********************************************************************************
* Preliminary Commands                                                         *
********************************************************************************
clear all
capture log close
set more off

* for older version of Stata
set matsize 11000

********************************************************************************
* Utility Flags Definition                                                     *
********************************************************************************
gl RUN_TESTS  = 0 /* = 1 when tests are (the only) allowed to be run */
gl MAKE_DIR   = 0 /* = 1 when need to create workspace folders */
gl WORK_LOCAL = 1 /* = 1 when we want to work locally with the dataset */

********************************************************************************
* Environment Variables Definition                                             *
********************************************************************************

* rule-of-thumb : pathnames do not finish with slash
gl DIR_NAME   = "DebtCulture"
gl MEGA_PATH  = "Documents/Research/Projects"

if "`c(os)'" == "Windows" {
    * define cloud parent folder location
    gl MEGA_DIR  = "C:/Users/`c(username)'/Documents"
    * define virtual drive pathname (depending on network)
    gl VIR_DRIVE = "M:"
}

else if "`c(os)'" == "MacOSX" {
	* define cloud parent folder location
	gl MEGA_DIR = "/Users/`c(username)'"
	
    if ${WORK_LOCAL} == 1 {
        gl VIR_DRIVE = "${MEGA_DIR}/Documents"
    }

    else {
        * connect to VALUTA network drive through VPN
        gl VIR_DRIVE = "/Volumes/s13903"
    }
}

else {
    di "OS Not Identified."
    exit, clear
}

* define base directory pathname
gl BASE_PATH = "${MEGA_DIR}/MEGA/${MEGA_PATH}/${DIR_NAME}"

* check pathname
capture cd "${BASE_PATH}"

if _rc {
    di "Pathnames are not defined properly. Exit."
    exit, clear
}

* create workspace directories and pathnames
qui do "${BASE_PATH}/util/workdir.do"

* define dataset pathnames
gl SOEP_PATH     = "${VIR_DRIVE}/soep"
gl SOEP_PATH_RAW = "${VIR_DRIVE}/soep/raw"

* add local source directory to adopath (in case of ad-hoc .ado)
adopath + "${SRC_PATH}/ado"

********************************************************************************
* Log Opening and Settings                                                     *
********************************************************************************

* generate pseudo timestamp (TODO: .ado file for that, this is ugly)
gl T_STRING = subinstr("`c(current_date)'"+"_"+"`c(current_time)'", ":", "_", .)
gl T_STRING = subinstr("${T_STRING}", " ", "_", .)

* open log file
capture log using "${LOG_PATH}/${DIR_NAME}_`filename'_${T_STRING}", text replace

********************************************************************************
* Run Test .do Files                                                           *
********************************************************************************

if ${RUN_TESTS} {
    do "${TEST_PATH}/tests.do"
    exit, clear
}

********************************************************************************
* SOEP Data Second-Generation Panel Build                                      *
********************************************************************************

* create workspace directories and pathnames
qui do "${SRC_PATH}/2ndgen/2ndgen.do"

* for step with single waves use update on a same-named variable

* copy the label of corigin

* we will need to double-check with other info, I don't trust this procedure

* split between direct and indirect background (we can trust migback)
* no problems of consistency with corigin within panel
* need to split Eastern Europe
* corigin for 2nd gen is Germany
* g dancestry = corigin if migback == 2

* then we need parents

* corigin : country of origin
* eastern europe is agglomerated (sigh)
* corigininfo : check inconsistencies 

* arefback : indirect[3]/direct[2]/no[1] refugee experience
* admissible retroactive information (keep arefinfo)

* migback : indirect[3]/direct[2]/no[1] migration background

* immiyear : year moved to Germany

* germborn : born in germany or immigrant < 1950



* from pgen (generated) : pgstatus_refu pgstatus_asyl pgnation 

* from pbrutto : pnat

* from pl : plj0024 (german nationality since when),
*   plj0006 (emigrant of german descent)

* from sp (raw) : sp11702

* from akind (raw) : ak07a (nationality of children)
* from ekind (raw) : ek03a (nationality of children)

* from ap: ap61 (nationality for double check)
* from bp: 

* from bioparen : fnat

********************************************************************************
* Closing Commands                                                             *
********************************************************************************

capture log close
exit
