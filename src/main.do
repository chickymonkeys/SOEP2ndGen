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

* for Stata in Linux
set max_memory 6g

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
gl DIR_NAME = "DebtCulture"
gl MEGA_DIR =  "Documents/Datasets/projects"

if "`c(os)'" == "Windows" {
    * define project parent folder location (common drive)
    gl HOME_DIR = "D:/Projects"
    
    * define cloud folder location
    gl MEGA_PATH = "E:/MEGA/${MEGA_DIR}"

    if ${WORK_LOCAL} == 1 {
        * just in desperate low connection cases
        gl V_DRIVE = "E:/Data"
    }
.\s13903
    else {
        * define virtual drive pathname (depending on network)
        gl V_DRIVE = "M:/Data"
    }

}

else if "`c(os)'" == "MacOSX" {
    * define project parent folder location
    gl HOME_DIR = "/Users/`c(username)'/Documents/Projects"

    * define cloud folder location
    gl MEGA_PATH = "/Users/`c(username)'/MEGA/${MEGA_DIR}"

    if ${WORK_LOCAL} == 1 {
        * just in desperate low connection cases
        gl V_DRIVE = "/Users/`c(username)'/Documents/Data"
    }

    else {
        * connect to VALUTA network drive through VPN
        gl V_DRIVE = "/Volumes/s13903/Data"
    }
}

else if "`c(os)'" == "Unix" {
    * define project parent folder location
    gl HOME_DIR = "/home/`c(username)'/Documents/Projects"

    * define cloud folder location
    gl MEGA_PATH = "/run/media/stargate/MEGA/${MEGA_DIR}"

    if ${WORK_LOCAL} == 1 {
        * just in desperate low connection cases
        gl V_DRIVE = "/run/media/stargate/Data"
    }

    else {
        * connect to VALUTA network drive through VPN
        * TODO: when I manage to connect Manjaro 
    }

}

else {
    di "OS Not Identified."
    exit, clear
}

* define base directory pathname
gl BASE_PATH = "${HOME_DIR}/${DIR_NAME}"

* check pathname
capture cd "${BASE_PATH}"

if _rc {
    di "Pathnames are not defined properly. Exit."
    exit, clear
}

* create workspace directories and pathnames
qui do "${BASE_PATH}/src/util/workdir.do"

* create utility directory path
gl UTIL_PATH = "${SRC_PATH}/util" 

* define dataset pathnames
gl SOEP_PATH     = "${V_DRIVE}/SOEP"
gl SOEP_PATH_RAW = "${V_DRIVE}/SOEP/raw"

* create data directory path (outside git repository in the cloud)
gl DATA_PATH = "${MEGA_PATH}/`=lower("${DIR_NAME}")'"
if ${MAKE_DIR} {
    !mkdir "${DATA_PATH}"
}

* add local source directory to adopath (in case of ad-hoc .ado)
adopath + "${SRC_PATH}/ado"

********************************************************************************
* Dependencies                                                                 *
********************************************************************************

* graph dependencies
capture ssc install grstyle
capture ssc install palettes
capture ssc install colrspace

********************************************************************************
* Log Opening and Settings                                                     *
********************************************************************************

* generate pseudo timestamp (TODO: .ado file for that, this is ugly)
gl T_STRING = subinstr("`c(current_date)'"+"_"+"`c(current_time)'", ":", "_", .)
gl T_STRING = subinstr("${T_STRING}", " ", "_", .)

* open log file
capture log using "${LOG_PATH}/${DIR_NAME}_`filename'_${T_STRING}", text replace

* run the graph utility .do file to set up the graph styles
qui do "${UTIL_PATH}/gconfig.do"

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
do "${SRC_PATH}/2ndgen/2ndgen.do"

* create the households in analysis through household head

********************************************************************************
* Closing Commands                                                             *
********************************************************************************

capture log close
exit
