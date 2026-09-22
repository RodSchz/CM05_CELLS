# Guía de creación de celdas — CM05_CELLS

Cómo atender un issue de celda, de principio a fin.

**Requisito previo:** haber completado `docs/guia-inicio.md`. Esta guía da por
hecho que ya tienes fork, clon, y que abriste al menos un pull request.

Aquí no se explica git: se explica **cómo se construye una celda** y qué tiene
que entregarse para que el pull request se acepte.

---

## 1. Antes de dibujar nada

### Lee el issue completo

El criterio de aceptación no es una formalidad: es literalmente la lista contra
la que se va a revisar tu trabajo. Si algo no se entiende, **pregúntalo en el
issue antes de empezar**, no después de tres días de layout.

### Abre la rama

```bash
git fetch upstream
git checkout -b cell/<nombre> upstream/main
```

### Copia la plantilla

```bash
# celda digital
cp -r digital/_template digital/cells/<nombre>

# celda analógica
cp -r analog/_template analog/cells/<nombre>
```

Renombra los archivos de la plantilla al nombre de tu celda. **El nombre debe
ser idéntico** en la carpeta, el esquemático, el símbolo, el GDS y el
subcircuito SPICE — viaja por todo el flujo y es donde más se rompen las cosas.

---

## 2. Referencia del proceso

### Capas de CIDESI_CM05

| Capa | Nombre | Para qué |
|---|---|---|
| `42/0` | Nwell | Pozo n |
| `43/0` | Active | Región activa |
| `44/0` | Pselect | Implantación p+ |
| `45/0` | Nselect | Implantación n+ |
| `46/0` | Poly | Polisilicio |
| `46/1` | Poly.text | Etiquetas sobre poly |
| `47/0` | ContactPoly | Contacto a poly |
| `48/0` | ContactActive | Contacto a activo |
| `49/0` | Metal1 | Primer metal |
| `49/1` | Metal1.text | **Etiquetas de VDD y GND** |
| `50/0` | Via | Vía Metal1–Metal2 |
| `51/0` | Metal2 | Segundo metal |
| `51/1` | Metal2.text | **Etiquetas de señales** |

### Dimensiones mínimas

- λ = 2.5 µm
- Largo mínimo de canal, contacto y vía: 5.0 µm (2λ)

### Dónde van las etiquetas

Es una convención, no una sugerencia:

- `VDD` y `GND` → **Metal1.text (49/1)**
- Señales (`A`, `B`, `Out`, `P1`, `P2`…) → **Metal2.text (51/1)**

Si las pones en la capa equivocada, el LVS no encuentra los puertos.

---

## 3. Las PCells del PDK

El PDK trae celdas paramétricas que te ahorran dibujar transistores a mano y
garantizan que estén bien construidos. Están en la biblioteca **CM05_PCells**,
que aparece en el panel de bibliotecas de KLayout.

| PCell | Para qué |
|---|---|
| `Mosfet` | Transistor NMOS o PMOS |
| `GuardRing` | Anillo de guarda |
| `BulkTap` | Contacto de sustrato o pozo |
| `ResistorHiRes` | Resistor de poly |
| `CapacitorMIM` / `CapacitorMIP` | Capacitores |
| `CutArray` | Arreglo de contactos o vías |

### Parámetros de `Mosfet`

Los que vas a usar:

| Parámetro | Qué es | Por omisión |
|---|---|---|
| `mos_type` | NMOS o PMOS | NMOS |
| `w_um` | **W por dedo**, no W total | 100.0 |
| `l_um` | Largo de canal | 10.0 |
| `nfing` | Número de dedos | 1 |
| `connect_sd` | Une fuentes y drenajes con rieles M1 | true |
| `draw_guard` | Dibuja anillo de guarda alrededor | false |
| `label_d/s/g/b` | Etiquetas de terminales | D, S, G, B |

> **Cuidado con `w_um` y `nfing`.** `w_um` es el ancho **por dedo**. Un
> dispositivo con `w_um=100, nfing=2` tiene W total de 200 µm. Si el issue
> pide W=30, pones `w_um=30`, no `w_um=15, nfing=2`.

Para colocar una: panel *Libraries* → `CM05_PCells` → arrastra `Mosfet` al
layout. Para editar sus parámetros: selecciónala y presiona **Q**, o menú
*Edit → Selection → Properties*.

---

## 4. Ruta de una celda digital

Ejemplo de referencia: el issue de `NAND3X1`.

### 4.1 Esquemático en LTspice

Todos los archivos de LTspice de la celda van juntos en
`digital/cells/<nombre>/ltspice/`.

1. Abre LTspice, nuevo esquemático, guárdalo como `<nombre>.asc` en esa
   carpeta.
2. Coloca los transistores con `nmos4` y `pmos4`.
3. Por cada uno, clic derecho y llena:
   - **Value:** `CIDNMOS` o `CIDPMOS`
   - **Value2:** `l=5u w=30u` (las dimensiones que pida el issue)
4. Marca los puertos con **Label Net** (`F4`), y en el diálogo elige
   *Port Type* distinto de `None`: `In`, `Out` o `BiDir` según corresponda.
   Eso es lo que convierte una etiqueta en puerto del subcircuito.
5. Incluye los modelos con una directiva de texto (`S` y luego el texto,
   empezando con `!`):

   ```
   .inc ../../../../pdk/tech/models/CM05_models.lib
   ```

   Son cuatro niveles porque estás en `digital/cells/<nombre>/ltspice/`.
   **Nunca pongas una ruta absoluta** tipo `C:\Users\...` — rompe el
   repositorio para todos los demás.

### 4.2 Símbolo

1. Con el esquemático abierto: menú *Hierarchy → Create New Symbol*, o crea
   uno nuevo y dibújalo.
2. Guárdalo como `<nombre>.asy`, **en la misma carpeta** que el `.asc`.
3. Ordena los pines con `SpiceOrder` según diga el issue. El orden del resto
   de la biblioteca para compuertas es `A, B, Out, V+, V-`.

> LTspice busca el esquemático de un símbolo jerárquico en la carpeta del
> esquemático que lo instancia. Por eso todo vive junto y por eso los bloques
> en `blocks/` todavía no abren.

### 4.3 Simulación funcional

Un testbench en la misma carpeta, `<nombre>_sim.asc`, que instancie tu celda y
recorra las combinaciones de entrada.

Para una NAND de 3 entradas son 8 combinaciones. La forma práctica es tres
fuentes `PULSE` con periodos en relación 1:2:4, para que en un solo transitorio
pasen todas:

```
VA A 0 PULSE(0 5 0 10n 10n {Tp/2} {Tp})
VB B 0 PULSE(0 5 0 10n 10n {Tp} {2*Tp})
VC C 0 PULSE(0 5 0 10n 10n {2*Tp} {4*Tp})
.param fo=1MEG Tp=1/fo
.param CL=1p
.tran {8*Tp}
```

Verifica que `Out` sea 0 únicamente cuando las tres entradas están en alto.

### 4.4 Layout en KLayout

1. Abre KLayout y selecciona la tecnología **CIDESI_CM05** — si no lo haces,
   las capas salen sin nombre y el DRC no corre.
2. Nueva vista, guarda como `<nombre>.gds` en
   `digital/cells/<nombre>/layout/`.
3. Coloca los transistores con la PCell `Mosfet`.
4. Rutea, y **respeta el contrato de fila**:

| | |
|---|---|
| Altura | exactamente 222.5 µm |
| Ancho | múltiplo de 2.5 µm |
| Origen | esquina inferior izquierda en (0.0, 0.0) |
| Riel GND | Metal1, de y = 5.0 a y = 15.0 |
| Riel VDD | Metal1, de y = 197.5 a y = 207.5 |
| Rieles en X | empiezan 7.5 µm después del borde izquierdo y terminan 7.5 µm antes del derecho |
| Pozo n | debe llegar al borde superior (y = 222.5) |

5. Etiqueta los pines en las capas correctas (sección 2).

Todo esto está detallado en `digital/docs/site_rules.md`.

### 4.5 Verificar el contrato

```bash
python scripts/drc/check_site.py --config digital/site.yaml \
  digital/cells/<nombre>/layout/<nombre>.gds
```

Es el mismo verificador que corre en el CI, así que si pasa aquí, pasa allá.
Debe decir `cumple`.

### 4.6 DRC

En KLayout: menú *Tools → DRC*, elige el runset del PDK (`drc/drc.lydrc`) y
córrelo. El reporte sale en el navegador de marcadores; debe quedar en cero
violaciones.

Guarda el reporte en `digital/cells/<nombre>/results/`.

### 4.7 Extracción y LVS

El PDK v0.9 trae tres scripts en `lvs/`:

| Script | Qué hace |
|---|---|
| `EXT.lylvs` | Extrae el netlist sin parásitos |
| `LVS.lylvs` | Extrae y compara contra el esquemático |
| `PEX.lylvs` | Extrae con capacitancias parásitas |

Para una celda digital usas **LVS**. Córrelo desde *Tools → LVS* en KLayout.

El netlist extraído debe coincidir con el netlist de referencia que viene en el
issue. Guárdalo en `layout/<nombre>.cir`.

### 4.8 Llenar el `cell.yaml`

Completa **todos** los campos que puedas: dimensiones medidas sobre el layout,
pines con su capa y posición, estado de DRC y LVS, archivos.

Los campos vacíos son la causa más común de que un PR se devuelva.

Si algo queda pendiente, regístralo como bloqueo:

```yaml
status: wip

blockers:
  - id: <identificador-corto>
    severity: alta
    summary: >
      Qué falta y por qué.
    owner: "tu-usuario"
    issue: null
```

---

## 5. Ruta de una celda analógica

Ejemplo de referencia: el issue de `cmirror_1aN`.

Los pasos 4.1 a 4.3 son iguales, con dos diferencias importantes.

### 5.1 El layout es el trabajo, no el trámite

En digital el layout tiene que caber en la fila. En analógico el layout
**determina si el circuito funciona**. Un espejo de corriente con un arreglo
mal hecho da una relación equivocada aunque el esquemático sea perfecto.

Para un arreglo apareado:

- **Misma orientación en todas las unidades.** Nunca espejes un dispositivo:
  uno espejado no aparea con su original.
- **Centroide común.** Para 1:2, disposición `A B B A`. Para relaciones
  mayores, interdigitación que reparta las unidades de salida simétricamente
  alrededor de la referencia.
- **Dummies en los extremos**, para que las unidades de las orillas vean el
  mismo entorno que las interiores.
- **Entorno idéntico por unidad**: mismo espaciamiento, mismo número de
  contactos, misma geometría.
- **Guard ring** alrededor del arreglo — usa la PCell `GuardRing`.
- **Ruteo simétrico** de compuerta y fuente.

### 5.2 Relaciones por multiplicación

Cuando el issue pide una relación 1:N, se obtiene **replicando el dispositivo
unitario**, no ensanchándolo.

```
CORRECTO                          INCORRECTO
M2 P2 P1 COM COM w=100u           M2 P2 P1 COM COM w=200u
M3 P2 P1 COM COM w=100u
```

Un dispositivo de W=200 no es dos de W=100: tiene otra razón perímetro/área,
otro efecto de canal angosto y otro redondeo de difusión en los extremos. Esos
errores son sistemáticos y no se promedian.

> **Ojo con `nfing`.** La PCell `Mosfet` con `nfing=2` hace un transistor de dos
> dedos. Antes de usarlo para una relación 1:2, **verifica en el netlist
> extraído** si sale como dos dispositivos separados o como uno solo de W
> doble. Si sale como uno solo, coloca dos instancias de la PCell en vez de
> usar dedos.

### 5.3 Los dummies y el LVS

Los dummies aparecen en el netlist extraído como dispositivos adicionales. Si
el esquemático no los incluye, **el LVS reporta discrepancia**.

Inclúyelos también en el esquemático, con compuerta y ambos terminales atados a
la fuente común para que sean eléctricamente inertes, y documenta la decisión
en `docs/design.md`.

### 5.4 Simulación post-layout con ngspice

Una celda analógica lleva además un banco en
`analog/cells/<nombre>/ngspice/`, que consume el **netlist extraído**, no el
esquemático.

Copia el patrón de `analog/cells/cmirror/ngspice/` — tiene el testbench, el
`run.sh` y un README que explica qué mide cada análisis.

```bash
cd analog/cells/<nombre>/ngspice
./run.sh
```

Requiere `ngspice`. En WSL o Linux: `sudo apt install ngspice`.

### 5.5 Registra de dónde salió cada número

En el `cell.yaml`, cada spec medida declara con qué se obtuvo y en qué etapa:

```yaml
specs:
  - {name: ratio, target: 2.0, measured: 2.003, unit: A/A,
     sim: ngspice, stage: extracted, tb: ngspice/tb.spice}
```

`stage: schematic` es pre-layout; `extracted` es post-LVS; `pex` es con
parásitos. Sin eso, en tres meses nadie sabe si el número es del ideal o del
circuito real.

### 5.6 Qué no se puede verificar todavía

Los modelos del PDK **no traen dispersión de parámetros**, así que no hay Monte
Carlo. El apareamiento no se puede medir por simulación: solo se juzga
**mirando el layout** contra los requisitos de 5.1.

Eso hace que en una celda analógica la revisión del layout sea la parte
crítica, no la simulación. Documenta bien tu arreglo en `docs/design.md`.

---

## 6. Documentar el diseño

`docs/design.md` responde **por qué**, no **qué**. El esquemático ya dice qué
se construyó; nadie puede deducir por qué.

Lo mínimo:

- Topología elegida y qué alternativas se descartaron
- Justificación del dimensionamiento
- Consideraciones de layout: apareamiento, dummies, guard rings
- Resultados medidos y cómo interpretarlos
- **Limitaciones conocidas** — bajo qué condiciones la celda no fue validada

La plantilla `analog/_template/design.md` trae la estructura.

---

## 7. Entregar

```bash
git add digital/cells/<nombre>      # o analog/cells/<nombre>
git status                          # revisa que no se cuele nada más
git commit -m "<nombre>: descripcion de lo que hiciste"
git push origin cell/<nombre>
```

Abre el pull request con el enlace que devuelve el push. En la descripción:

- Llena la plantilla completa
- Escribe `Closes #<numero>` con el número del issue
- Adjunta captura del layout y del reporte de DRC

Espera el CI. Si sale en rojo, entra a **Details**, corrige, y vuelve a
`add` → `commit` → `push`. **No abras un PR nuevo**: el que existe se actualiza
solo y conserva la conversación.

---

## 8. Errores frecuentes

| Síntoma | Causa |
|---|---|
| `check_site.py` reporta altura incorrecta | El pozo n o una figura sobresale del contrato |
| El LVS no encuentra puertos | Etiquetas en la capa equivocada: alimentación va en 49/1, señales en 51/1 |
| LTspice: `Can't find symbol` | El `.asy` y el `.asc` no están en la misma carpeta |
| El PR de otro compañero entra en conflicto con el tuyo | Dos personas tocaron la misma celda. Los GDS son binarios y no se fusionan: **una celda, un dueño** |
| El CI falla pero en tu máquina pasa | Revisa mayúsculas en nombres de archivo: Windows no distingue, el runner de Linux sí |
| Las capas salen sin nombre en KLayout | No seleccionaste la tecnología CIDESI_CM05 |

---

## 9. Estado del flujo

Para que no busques lo que todavía no existe:

| Paso | Estado |
|---|---|
| Esquemático y simulación en LTspice | Operativo |
| Layout, PCells y DRC en KLayout | Operativo |
| Verificación del contrato de fila | Operativo, automático en cada PR |
| Extracción y LVS | Operativo desde el PDK v0.9 |
| Extracción con parásitos (PEX) | Operativo, solo capacitancia |
| Simulación post-layout con ngspice | Montado para `cmirror`; replicable |
| Esquinas de proceso `ff` y `ss` | **No existen en el PDK** |
| Monte Carlo / apareamiento | **No existe** |
| Caracterización y `.lib` | No existe |

Por eso ninguna celda puede declararse `verified` todavía: sin esquinas de
proceso no hay forma de validarla. Es una limitación del kit, no del flujo, y
no te impide entregar tu celda hasta `lvs_clean`.

---

## Documentos relacionados

- `docs/guia-inicio.md` — git, GitHub y primer ejercicio
- `docs/manual.md` — roles, ciclo de vida y flujo completo
- `digital/docs/site_rules.md` — el contrato geométrico con todos sus números
- `CONTRIBUTING.md` — nomenclatura y qué se versiona
- `digital/cells/README.md` — estado de la biblioteca
