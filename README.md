# CM05_CELLS — Biblioteca de celdas del proceso CIDESI_CM05

Biblioteca de celdas analógicas y digitales para el proceso **CIDESI_CM05**
(CMOS ~5 µm, transistores n y p, dos metales, un polisilicio).

Flujo: **LTspice** para esquemático y simulación, **KLayout** para layout y
verificación DRC/LVS.

## Organización

| Carpeta | Contenido |
|---|---|
| `pdk/` | Tecnología compartida: capas, reglas DRC/LVS, modelos SPICE por corner |
| `digital/` | Celdas estándar: contrato geométrico fijo, caracterización en lote |
| `analog/` | Celdas analógicas: regidas por especificaciones, verificación por testbench |
| `blocks/` | Bloques mixtos que componen celdas de ambas bibliotecas |
| `scripts/` | DRC, LVS, caracterización digital y verificación analógica |
| `docs/` | Convenciones, guías y documentación general |
| `_legacy/` | Material previo a la reorganización, sin clasificar |

## Estado

Repositorio en configuración inicial. Ver `CONTRIBUTING.md` antes de contribuir.
Repositorio en operación desde agosto de 2026.

## Contacto

Coordinación de Circuitos Integrados — CIDESI, Querétaro.
