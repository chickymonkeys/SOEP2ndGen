********************************************************************************
*                                                                              *
* Title:     SOEP Second-Genration Immigrants Identification Script            *
* Author:    Alessandro Pizzigolotto (NHH)                                     *
* Language:  Stata (sigh)                                                      *
* Version:   0.1 (alpha)                                                       *
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

* for Stata in my poor Linux
set max_memory 6g

********************************************************************************
* Utility Flags Definition                                                     *
********************************************************************************

gl MAKE_DIR   = 1 /* = 1 when need to create workspace folders */
gl ISO_CODES  = 1 /* = 1 when need to generate ISO codes table */

********************************************************************************
* Environment Variables Definition                                             *
********************************************************************************

* define the absolute PATHNAME to the workspace and SOEP Data
gl DIR_NAME      = "SOEP2ndGen"
gl BASE_PATH     = "/home/`c(username)'/Documents/Projects/${DIR_NAME}"
gl SOEP_PATH     = "/run/media/stargate/Data/SOEP"
gl SOEP_PATH_RAW = "${SOEP_PATH}/raw"

local base   = "${BASE_PATH}"
local stubs  = "log src data"
local gnames = "LOG SRC DATA"
local n: word count `gnames'
tokenize "`gnames'"
forvalues i = 1/`n' {
    gl ``i''_PATH = "`base'/`: word `i' of `stubs''"
    * check if directory already exists
    capture confirm file "${``i''_PATH}"
    if _rc {
        mkdir "${``i''_PATH}", pub
    }
}
* create utility directory path
gl UTIL_PATH = "${SRC_PATH}/util" 

********************************************************************************
* Log Opening and Settings                                                     *
********************************************************************************

* generate pseudo timestamp (TODO: .ado program for that, this is ugly)
gl T_STRING = subinstr("`c(current_date)'"+"_"+"`c(current_time)'", ":", "_", .)
gl T_STRING = subinstr("${T_STRING}", " ", "_", .)

* open log file
capture log using "${LOG_PATH}/${DIR_NAME}_`filename'_${T_STRING}", text replace

********************************************************************************
* When the Flag is ON -> Run the Script to create ISO 3166-1 Numeric Table     *
********************************************************************************

if ${ISO_CODES} {
    capture ssc install kountry
    do "${UTIL_PATH}/isocodes.do"
}

********************************************************************************
* SOEP Data Second-Generation Panel Build                                      *
********************************************************************************

* create the panel of second-generation individuals with country of ancestry
do "${SRC_PATH}/2ndgen/2ndgen.do"

********************************************************************************
* Closing Commands                                                             *
********************************************************************************

capture log close
exit
