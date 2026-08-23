# Modelos SPICE — CIDESI_CM05

`CM05_models.lib` define los dos dispositivos del proceso:

| Modelo | Tipo | Nivel | VTO | TOX | KP |
|---|---|---|---|---|---|
| `CIDNMOS` | NMOS | 3 | +0.584 V | 50.2 nm | 21.0 µA/V² |
| `CIDPMOS` | PMOS | 3 | −0.981 V | 25.0 nm | 19.2 µA/V² |

## Pendientes

- **Solo existe un corner.** No hay variantes `ff` ni `ss`, así que hoy es
  imposible simular esquinas de proceso. Definirlas es requisito para poder
  marcar cualquier celda como `verified`.
- **Falta el modelo de Monte Carlo** (dispersión de VTO, TOX, W/L), necesario
  para estimar el error de apareamiento en celdas analógicas.
- Verificar que este archivo coincide con el que instala el PDK en
  `KLayout/salt/CIDESI_CM05/tech/CIDESI_CM05/models/`. Si difieren, decidir
  cuál es la fuente de verdad.

## Uso desde LTspice

Con rutas relativas desde una celda en `analog/cells/<nombre>/sim/`:

```
.inc ../../../../pdk/tech/models/CM05_models.lib
```
