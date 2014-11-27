

# define necessary variables
set projName	mmc_core
set projDir	./proj

set srcDir	./src
set constrDir	./constr
set scriptDir	./scripts

set vhdlDir	$srcDir/vhdl
set veriDir	$srcDir/verilog


# Create project and load all necessary files 
create_project $projName $projDir
set_property part xc7a200tfbg484-1 [current_project]

# Add VHDL and verilog design files
add_files [glob $vhdlDir/*.vhd]
# add_files [glob $veriDir/*.v]

# Add constraints
add_files -fileset constrs_1 [glob $constrDir/*.xdc]

