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
gl PROJ_PATH  = "Documents/Projects"

if "`c(os)'" == "Windows" {
    * define cloud parent folder location
    gl PROJ_DIR  = "C:/Users/`c(username)'"

    if ${WORK_LOCAL} == 1 {
        * just in desperate low connection cases
        gl VIR_DRIVE = "${PROJ_DIR}/Documents"
    }

    else {
        * define virtual drive pathname (depending on network)
        gl VIR_DRIVE = "M:"
    }

}

else if "`c(os)'" == "MacOSX" {
	* define cloud parent folder location
	gl PROJ_DIR = "/Users/`c(username)'"
	
    if ${WORK_LOCAL} == 1 {
        * just in desperate low connection cases
        gl VIR_DRIVE = "${PROJ_DIR}/Documents"
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
gl BASE_PATH = "${PROJ_DIR}/${PROJ_PATH}/${DIR_NAME}"

* check pathname
capture cd "${BASE_PATH}"

if _rc {
    di "Pathnames are not defined properly. Exit."
    exit, clear
}

* create workspace directories and pathnames
qui do "${BASE_PATH}/src/util/workdir.do"

* define dataset pathnames
gl SOEP_PATH     = "${VIR_DRIVE}/soep"
gl SOEP_PATH_RAW = "${VIR_DRIVE}/soep/raw"

* add local source directory to adopath (in case of ad-hoc .ado)
adopath + "${SRC_PATH}/ado"

********************************************************************************
* Dependencies                                                                 *
********************************************************************************

* graph dependencies
capture ssc install grstyle
capture ssc install palettes
capture ssc install colrspace

* occupation classes (eventually)
capture ssc install iscogen

********************************************************************************
* Log Opening and Settings                                                     *
********************************************************************************

* generate pseudo timestamp (TODO: .ado file for that, this is ugly)
gl T_STRING = subinstr("`c(current_date)'"+"_"+"`c(current_time)'", ":", "_", .)
gl T_STRING = subinstr("${T_STRING}", " ", "_", .)

* open log file
capture log using "${LOG_PATH}/${DIR_NAME}_`filename'_${T_STRING}", text replace

* run the graph utility .do file to set up the graph styles
qui do "${SRC_PATH}/util/gconfig.do"

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

* create the panel of second-generation individuals with country of ancestry
qui do "${SRC_PATH}/2ndgen/2ndgen.do"

* create the households in analysis through household head

********************************************************************************
* Closing Commands                                                             *
********************************************************************************

capture log close
exit
