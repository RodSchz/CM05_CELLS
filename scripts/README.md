# Scripts del repositorio

| Carpeta | Ámbito | Propósito |
|---|---|---|
| `drc/` | común | Verificación geométrica. `check_site.py` valida el contrato de fila contra `digital/site.yaml`. |
| `lvs/` | común | Comparación esquemático contra layout. |
| `verify/digital/` | digital | Verificación **funcional**: tabla de verdad y niveles lógicos. Pasa o no pasa. |
| `verify/analog/` | analógico | Verificación por **especificación**: corre el testbench de la celda y compara contra los objetivos de `cell.yaml`. |
| `characterize/` | digital | Caracterización en lote: barrido de carga × pendiente de entrada × corner para generar los `.lib`. No es verificación. |

## La distinción que importa

`verify/` responde *¿la celda hace lo que debe?* — resultado booleano.
`characterize/` responde *¿con qué retardo y consumo lo hace?* — resultado numérico.

En ambas ramas de `verify/` el trabajo es el mismo: correr la simulación, leer
las mediciones y compararlas contra lo que declara `cell.yaml`. Solo cambian el
testbench y el criterio, así que la parte común no debe duplicarse.

> `characterize/` permanecerá vacía mientras el PDK no defina los corners `ff` y
> `ss`. Con el bloqueo del TOX abierto, cualquier `.lib` generado hoy saldría
> mal calibrado.
