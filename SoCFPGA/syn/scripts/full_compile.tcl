# Script de Synthèse en langage Tcl.
set project $env(PROJECT)

load_package flow
load_package incremental_compilation
load_package project
project_open $project


# Run initial compilation
#export_assignments
execute_flow -compile

project_close

