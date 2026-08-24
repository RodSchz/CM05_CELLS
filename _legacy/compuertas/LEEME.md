# compuertas — material no migrado

Contenido de `compuertas.rar` que **no** se incorporó a la estructura. Nada se
descartó; esto es lo que quedó fuera y por qué.

| Archivo | Qué es | Por qué está aquí |
|---|---|---|
| `GATE2X1_sim.asc` | Testbench que ejercita las 8 compuertas a la vez | Cruza celdas. Se prefirió un testbench por celda: cuando algo falla, el CI dice **cuál** compuerta falló, no que "algo" falló. |
| `CHIP01.asc` / `.asy` | Esquemático vacío | 28 bytes, solo el encabezado. Existe el símbolo pero no hay contenido. |

## Lo que sí se migró

**A `digital/cells/<nombre>/ltspice/`:** los esquemáticos y símbolos de
`NOT` (→ `Inverter`), `Buffer`, `NAND2X1`, `NOR2X1`, `AND2X1`, `OR2X1`,
`XOR2X1`, `XNOR2x1` (→ `XNOR2X1`), más los testbenches propios de `NAND2X1`.

**A `blocks/`:** `HA`, `Full_adder`, `NOT_CHAIN` y `MUX2X1`.

**Excluidos por `.gitignore`:** los `.raw`, `.log`, `.op.raw` y `.plt`, que son
salidas regenerables de LTspice.

## Rutas corregidas

Todos los testbenches incluían los modelos desde una tercera ubicación:

```
C:\Users\Lenovo\OneDrive\Documentos\LTspice_LNunT\Ejemplos\CM05_models.lib
```

Era la tercera copia del archivo, además del PDK y de la que estaba en
`_legacy`. Ya están apuntando a `pdk/tech/models/CM05_models.lib` con ruta
relativa. La copia del repositorio está sincronizada con el PDK, que es la
fuente de verdad — ver `pdk/tech/models/LEEME.md`.
