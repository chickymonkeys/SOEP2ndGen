********************************************************************************
*                                                                              *
* Filename: gconfig.do                                                         *
* Description: .do file to configure the external package grstyle for the      *
*   graph settings of the project. 
*                                                                              *
********************************************************************************

capture ssc install grstyle, replace
capture ssc install palettes, replace
capture ssc install colrspace, replace
* grstyle initialisation
grstyle init

* program to set the number of ticks in the graph
capture program drop grstyle_set_nticks
program grstyle_set_nticks
    syntax [, n(int 5) mticks(int 0) ]
    file write $GRSTYLE_FH "numticks_g horizontal_major `n'" _n
    file write $GRSTYLE_FH "numticks_g vertical_major   `n'" _n
    file write $GRSTYLE_FH "anglestyle vertical_tick horizontal" _n
    file write $GRSTYLE_FH "numticks_g horizontal_tminor `mticks'" _n
    file write $GRSTYLE_FH "numticks_g vertical_tminor   `mticks'" _n
end

* basic scheme
grstyle set plain, grid horizontal compact

* general color set set as 538
grstyle set color lean

* axis options
grstyle set size small: tick_label
grstyle set nticks, n(10)
grstyle set size small: axis_title

* line options
grstyle set linewidth thin: plineplot

* markers options
grstyle set color lean, opacity(80): p#markfill
grstyle set color lean, opacity(0):  p#markline
grstyle set symbol d
grstyle set size vsmall: p#markfill
grstyle set size vsmall: p#markline

* histogram options
grstyle set color, opacity(80): histogram
grstyle set color, opacity(50): histogram_line
grstyle set size vsmall: histogram

* graph bar opsions
grstyle set color 538, opacity(80): p#bar
grstyle set color 538, opacity(50): p#barline
grstyle set size small: p#bar

* transparent CIs
grstyle set ci

* legend settings
grstyle set legend 12, klength(large) nobox
grstyle set size small: legend
