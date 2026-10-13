
drc off
locking disable
crashbackups stop
box 0 0 0 0

puts "PEX STEP 1: leyendo GDS"
gds read {/mnt/c/Users/Alexa/CIDESI/CM05_CELLS/digital/cells/NAND3X1/layout/NAND3X1.gds}

puts "PEX STEP 2: cargando NAND3X1"
load {NAND3X1}
select top cell

puts "PEX STEP 3: flatten -> NAND3X1-pex"
flatten {NAND3X1-pex}
load {NAND3X1-pex}

# El flujo RCX oficial recomienda que la celda plana tenga el nombre
# de la celda original durante la extracción.
cellname delete {NAND3X1}
cellname rename {NAND3X1-pex} {NAND3X1}
load {NAND3X1}
select top cell

extract path .
extract do unique

# Configuración del full-RC .
extresist threshold 1
extresist minres 1000
extresist mindelay 0
extresist simplify on
extresist extout on
extresist silent off

puts "PEX threshold=[extresist threshold] mOhm"
puts "PEX minres=[extresist minres] mOhm"
puts "PEX mindelay=[extresist mindelay] ps"

# Desde Magic 8.3.597: full-RC integrado al extractor.
extract do resistance

puts "PEX STEP 4: extract all + full resistance"
extract all

puts "PEX STEP 5: extracción RC terminada"

ext2spice lvs
ext2spice format spice3
ext2spice cthresh 0
ext2spice extresist on
ext2spice merge none

puts "PEX STEP 6: escribiendo SPICE"
ext2spice -p . -o {/mnt/c/Users/Alexa/CIDESI/CM05_CELLS/digital/cells/NAND3X1/layout/NAND3X1_pex.spice}

puts "PEX completado"
quit -noprompt
