# Guía de contribución — CM05_CELLS

## Modelo de colaboración

El repositorio canónico vive en la cuenta `RodSchz`. Los diseñadores **no
escriben directamente en él**: trabajan sobre un *fork* propio y proponen
cambios mediante *pull request*.

```
repo canónico (RodSchz)  <--- PR ---  fork del diseñador  <--- push ---  rama local
```

### Alta de un colaborador

1. El diseñador hace **Fork** del repositorio desde GitHub.
2. Clona su fork y agrega el canónico como remoto de solo lectura:

```bash
git clone https://github.com/<usuario>/CM05_CELLS.git
cd CM05_CELLS
git remote add upstream https://github.com/RodSchz/CM05_CELLS.git
git lfs install
```

3. Antes de empezar cada celda, sincroniza:

```bash
git fetch upstream
git checkout -b cell/<nombre> upstream/main
```

## Reparto del trabajo

| Subárbol | Responsable |
|---|---|
| `digital/` | Diseñador asignado a celdas estándar |
| `analog/` | Diseñador asignado a celdas analógicas |
| `pdk/`, `blocks/` | Coordinación (solo por PR revisado) |

**Regla de oro: una celda, un dueño.** Los archivos GDS son binarios y Git no
puede fusionarlos. Si dos personas editan el mismo layout, el conflicto se
resuelve descartando el trabajo de alguien. No compartas celdas.

## Nomenclatura

- **Digital**: `<función>_<drive>` — `inv_x1`, `nand2_x2`, `dff_x1`.
- **Analógico**: descriptiva — `ota_5t_1v8`, `bandgap_ref`, `comp_hyst`.
- Solo minúsculas, dígitos y guion bajo. Sin espacios ni acentos.
- El nombre de la carpeta, el de la celda en el esquemático, el de la celda en
  el GDS y el del subcircuito SPICE **deben ser idénticos**. El nombre viaja
  del esquemático al netlist, al layout y al LVS.

## Ramas

- `main` — estado validado. Nunca se hace push directo.
- `cell/<nombre>` — trabajo sobre una celda.
- `fix/<descripción>` — corrección puntual.
- `pdk/<descripción>` — cambio en tecnología (requiere revisión reforzada).

## Commits

Formato: `<ámbito>: <qué cambió>`

```
inv_x1: layout inicial, DRC limpio
ota_5t_1v8: corrige espejo de corriente, mejora PSRR 8 dB
pdk: agrega corner ss a los modelos
```

## Qué se versiona

**Sí:** `.asc`, `.asy`, `.cir`, `.spice`, `.cdl`, `.v`, `.gds`, `.oas`,
`.lyp`, `.lym`, `.xs`, `.lydrc`, `cell.yaml`, documentación.

**No:** `.raw`, `.log`, `.fft`, netlists generados, archivos de bloqueo,
resultados intermedios de simulación. Ver `.gitignore`.

Los binarios (`.gds`, `.oas`, `.png`) pasan por **Git LFS**. Instálalo antes
del primer commit: `git lfs install`.

> El plan gratuito de GitHub incluye 1 GB de LFS. Sube solo layouts liberados,
> no versiones intermedias.

## Antes de abrir un pull request

### Celda digital

- [ ] DRC limpio contra `pdk/tech/drc/`
- [ ] LVS esquemático vs layout sin discrepancias
- [ ] Cumple el contrato geométrico de `digital/docs/site_rules.md`
- [ ] `cell.yaml` completo
- [ ] `.cdl` y `.v` presentes y consistentes

### Celda analógica

- [ ] DRC limpio y LVS sin discrepancias
- [ ] Tabla de specs medidas vs objetivo en `cell.yaml`
- [ ] Simulación en corners tt / ff / ss
- [ ] Gráficas en `results/`
- [ ] `docs/design.md` con el razonamiento de diseño

## Revisión y merge

El propietario revisa. Para layout, adjunta captura del `XOR` de KLayout
contra la versión anterior. El merge se hace con *squash* para mantener el
historial legible.

## Liberación

```bash
git tag inv_x1-v1.0          # celda validada
git tag mpw-2026-11          # congelamiento de biblioteca para tape-out
git push upstream --tags
```
