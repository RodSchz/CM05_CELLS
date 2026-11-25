# Modelos SPICE — CIDESI_CM05

`CM05_models.lib` es **una copia sincronizada** del archivo autoritativo del PDK:

```
RodSchz/CIDESI_CM05 : tech/CIDESI_CM05/models/CM05_models.lib
```

El PDK es la fuente de verdad. Esta copia existe solo para que los testbenches
puedan incluir los modelos con una ruta relativa dentro del repositorio, sin
depender de dónde tenga instalado KLayout cada persona.

## Cómo resincronizar cuando el PDK cambie

```bash
cp /ruta/al/clon/CIDESI_CM05/tech/CIDESI_CM05/models/CM05_models.lib \
   pdk/tech/models/CM05_models.lib
git commit -am "pdk: sincroniza modelos con CIDESI_CM05 vX.Y"
```

Anota en el mensaje del commit la versión del PDK de la que proviene.

## Contenido

Revisión actual: **preliminar 3 (2026-11-23), MOS ajustados a TCAD**. Los
transistores se ajustaron por mínimos cuadrados en ngspice contra las curvas de
Victory Device de la corrida TCAD CM05v3, con error rms de 0.6 % en el NMOS y
1.0 % en el PMOS.

| Modelo | Tipo | Nivel | VTO | TOX | KP | RSH |
|---|---|---|---|---|---|---|
| `CIDNMOS` | NMOS | 3 | +0.955 V | 29.4 nm | 82.1 µA/V² | 90 Ω/□ |
| `CIDPMOS` | PMOS | 3 | −1.781 V | 29.4 nm | 15.8 µA/V² | 208 Ω/□ |

El cambio de fondo respecto a la revisión anterior es que **los dos dispositivos
comparten `TOX`**, como corresponde a una sola oxidación de compuerta. Antes el
NMOS declaraba 50.2 nm y el PMOS 25 nm, lo que hacía al PMOS casi tan fuerte
como al NMOS y falseaba todo dimensionamiento. Con estos modelos el PMOS resulta
**≈ 8 veces más débil por micra de ancho**: 5.19× por movilidad y el resto por
penalización de umbral.

Las limitaciones del ajuste están documentadas en la cabecera del propio
archivo. Las dos que más conviene tener presentes:

- **`DELTA = 0`:** la simulación 2D no tiene efecto de ancho angosto.
- **El PMOS no es confiable en subumbral:** su `VTO` de nivel 3 (−1.78 V) es el
  de inversión fuerte, y el modelo queda ~0.25 V desplazado respecto al TCAD.

Además incluye modelos pasivos con coeficientes térmicos: `R_METAL1`,
`R_POLY`, `R_NDIFF`, `R_PDIFF`, `C_MIP`, `C_MIM`. Están marcados como
preliminares en el propio archivo — los valores de TC1 hay que ajustarlos tras
medir. **No son alcanzables desde el flujo KLayout → LTspice**, porque LTspice
no admite un nombre de modelo en la línea de instancia de R o C; el coeficiente
térmico se inyecta como `tc=TC1,TC2` desde `macros/CM05_LVS_common.lym`.

## Uso desde LTspice

Con rutas relativas desde una celda en `analog/cells/<nombre>/sim/`:

```
.inc ../../../../pdk/tech/models/CM05_models.lib
```

## Pendientes

- **`TPG` sale invertido respecto a la auditoría de modelos:** el archivo trae
  `-1` en el NMOS y `+1` en el PMOS. Hay que confirmar la convención correcta
  para compuerta de poli en este proceso, porque `TPG` entra en la tensión de
  banda plana y por tanto en el escalamiento térmico de `VTO`.
- **`RSH` contradice a `CM05_process.lym`**, que usa 25 Ω/□ para la difusión n
  y 30 para la p contra los 90 y 208 de estos modelos. Hay que alinearlos o
  declarar explícitamente cuál es la fuente de verdad.
- **`gox_t` en `CIDESI_CM05.xs` sigue en 0.02 µm**; con estos modelos debe pasar
  a 0.0294.
- **Validación en silicio:** `VTO`, `NSUB` y `RSH` son ajuste a TCAD, no
  medición. Hay que contrastarlos con el primer lote CM05.
- **Solo existe un corner.** No hay variantes `ff` ni `ss`, así que hoy es
  imposible simular esquinas de proceso. Definirlas es requisito para poder
  marcar cualquier celda como `verified`.
- **Falta el modelo de Monte Carlo** (dispersión de VTO, TOX, W/L), necesario
  para estimar el error de apareamiento en celdas analógicas.
