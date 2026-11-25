# Plantilla de celda digital

Esta carpeta **no es una celda que se copie entera**: git no versiona
directorios vacíos, así que aquí solo vive `cell.yaml`. Los directorios se
crean a mano.

## Estructura que debe tener una celda terminada

```
digital/cells/<CELDA>/
├── cell.yaml                   # metadatos; copiar de esta plantilla
├── layout/
│   ├── <CELDA>.gds             # el layout
│   ├── <CELDA>.cir             # netlist extraído por KLayout (EXT)
│   └── <CELDA>_PEX.cir         # netlist con parásitos (opcional)
├── ltspice/
│   ├── <CELDA>.asc             # esquemático
│   └── <CELDA>.asy             # símbolo
└── sim/
    └── tabla_verdad.sp         # copia del testbench, con la cabecera editada
```

## Cómo empezar

```bash
C=NOMBRE_CELDA
mkdir -p digital/cells/$C/layout digital/cells/$C/ltspice digital/cells/$C/sim
cp digital/_template/cell.yaml digital/cells/$C/cell.yaml
```

Luego, según el número de entradas de tu celda:

```bash
cp scripts/verify/digital/tabla_verdad_3in.sp digital/cells/$C/sim/tabla_verdad.sp
```

Hay testbenches para 1, 2, 3 y 4 entradas (`tabla_verdad_1in.sp` …
`tabla_verdad_4in.sp`), más `tabla_tristate.sp`, `FFD_tb.sp` y `Latch_tb.sp`.
Las rutas `.include` de todos son relativas a `digital/cells/<CELDA>/sim/`: el
testbench **se copia**, no se corre en su lugar.

## El nombre viaja por todo el flujo

Debe ser idéntico en la carpeta, el `cell.yaml`, el esquemático, el símbolo, el
GDS y el `.subckt` SPICE. Es donde más se rompen las cosas: el LVS empareja por
nombre.

La salida se llama **`Out`** en toda la biblioteca, no `Y`.

## Qué sigue

`docs/guia-celdas.md` explica la ruta completa: esquemático, símbolo,
simulación, layout, contrato de fila, DRC, extracción y LVS.
