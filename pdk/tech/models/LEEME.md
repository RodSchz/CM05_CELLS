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

| Modelo | Tipo | Nivel | VTO | TOX | KP |
|---|---|---|---|---|---|
| `CIDNMOS` | NMOS | 3 | +0.584 V | 50.2 nm | 21.0 µA/V² |
| `CIDPMOS` | PMOS | 3 | −0.981 V | 25.0 nm | 19.2 µA/V² |

Además incluye modelos pasivos con coeficientes térmicos: `R_METAL1`,
`R_POLY`, `R_NDIFF`, `R_PDIFF`, `C_MIP`, `C_MIM`. Están marcados como
preliminares en el propio archivo — los valores de TC1 hay que ajustarlos tras
medir.

## Uso desde LTspice

Con rutas relativas desde una celda en `analog/cells/<nombre>/sim/`:

```
.inc ../../../../pdk/tech/models/CM05_models.lib
```

## Pendientes

- **Solo existe un corner.** No hay variantes `ff` ni `ss`, así que hoy es
  imposible simular esquinas de proceso. Definirlas es requisito para poder
  marcar cualquier celda como `verified`.
- **Falta el modelo de Monte Carlo** (dispersión de VTO, TOX, W/L), necesario
  para estimar el error de apareamiento en celdas analógicas.
- Los modelos pasivos están declarados como preliminares.
