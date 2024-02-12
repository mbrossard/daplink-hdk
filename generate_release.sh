#!/bin/sh

PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project_name>"
    exit 1
fi

# Create an output directory and subdirectories for the release
mkdir -p output
mkdir -p output/gerber

# Generate a project netlist
kicad-cli sch export netlist --format kicadxml $PROJECT_NAME/$PROJECT_NAME.kicad_sch

# Retrive the project revision
python3 util/getRevision.py $PROJECT_NAME.xml ./revision.txt
REVISION="$(cat ./revision.txt)"

# Generate the schematic
kicad-cli sch export pdf $PROJECT_NAME/$PROJECT_NAME.kicad_sch -o output/${PROJECT_NAME}_schematic_${REVISION}.pdf

# Generate BOM
python3 util/bom_csv_grouped_by_mpn.py $PROJECT_NAME.xml ./output/${PROJECT_NAME}_BOM_${REVISION}.csv

# Generate Gerber files
kicad-cli pcb export gerbers --no-x2 --no-protel-ext $PROJECT_NAME/$PROJECT_NAME.kicad_pcb -o ./output/gerber/

# Generate the Drill file
kicad-cli pcb export drill --excellon-zeros-format suppressleading --excellon-min-header $PROJECT_NAME/$PROJECT_NAME.kicad_pcb -o ./output/gerber/

# Zip up the gerbers
cd output/gerber
zip -r ../../output/${PROJECT_NAME}_gerbers_${REVISION}.zip *
cd ../..

# Delete the gerber directory
rm -rf ./output/gerber