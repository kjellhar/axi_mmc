

# define necessary variables
set projName	mmc_core
set projDir	./proj

set srcDir	./src
set constrDir	./constr
set scriptDir	./scripts
set simDir	./sim

set vhdlDir	$srcDir/vhdl
set veriDir	$srcDir/verilog


# Create project and load all necessary files 
create_project $projName $projDir
set_property target_language VHDL [current_project]
set_property part xc7a200tfbg484-1 [current_project]

set_property -name {xsim.simulate.runtime} -value {0 ns} -objects [current_fileset -simset]


# Add VHDL and verilog design files
add_files [glob $vhdlDir/*.vhd]
# add_files [glob $veriDir/*.v]

# Add constraints
add_files -fileset constrs_1 [glob $constrDir/*.xdc]

# Create simulation sets and add source code
set re {[^\/]*$}

foreach dirName [glob -nocomplain -type {d r} -path $simDir/ *] {
	regexp $re $dirName fileSet
	puts $fileSet
	create_fileset -simset $fileset
	current_fileset -simset $fileset
	add_files [glob $dirName/*.vhd] -fileset $fileset
	add_files [glob $vhdlDir/*.vhd] -fileset $fileset
}
