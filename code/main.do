/* main.do */
/* Author: Lars Vilhuber */
/* NOTE: this is a VERY simple example file
         it does NOT fully comply with best practices
*/

// in case we need it
local tmp : pwd
// find out where the main.do is
capture confirm file  "code/main.do"
if _rc != 0 {
   display as text "We may be in the code directory"
   capture confirm file "main.do"
   if _rc != 0 {
      display as text "not sure how to run"
      exit
   }
   // if yes, we go up
   cd ".."
}

global BASEDIR : pwd 

global DATADIR "${BASEDIR}/data"
global CODEDIR "${BASEDIR}/code"
global RESULTS "${BASEDIR}/results"

sysuse auto
desc

/* we list the ado files - by default, it should list 'estout' 
   that we installed via the setup.do during the build phase
   of the Docker image */

ado



