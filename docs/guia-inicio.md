# Guía de inicio — CM05_CELLS

Para quien empieza a contribuir a la biblioteca de celdas y **nunca ha usado
git**. Se lee una vez, de principio a fin.

Al terminar vas a haber corregido un defecto real de la biblioteca y propuesto
el cambio como pull request. Toma entre dos y tres horas la primera vez.

Si ya trabajaste con git y GitHub, salta al [ejercicio guiado](#5-ejercicio-guiado-corregir-buffer_8x).

---

## 1. Qué vas a instalar

Cinco cosas. Todas gratuitas, todas en Windows.

| Herramienta | Para qué | Dónde |
|---|---|---|
| **Git para Windows** | Control de versiones | git-scm.com |
| **Cuenta de GitHub** | Colaborar en el repositorio | github.com |
| **KLayout** | Dibujar y verificar layout | klayout.de |
| **PDK CIDESI_CM05** | Capas, DRC, LVS y modelos del proceso | Repositorio del PDK |
| **LTspice** | Esquemático y simulación | Analog Devices |
| **Python** + módulo klayout | Correr el verificador de contrato | python.org |

### Git para Windows

Descarga de **git-scm.com** e instala con las opciones por defecto. Solo una
importa: cuando pregunte por el editor, si no conoces Vim elige **Notepad** o
**Visual Studio Code**. Quedarse atrapado en Vim es el rito de iniciación más
frustrante de git y es evitable.

Al terminar tendrás **Git Bash**, una terminal donde vas a escribir todos los
comandos de esta guía. Ábrela con clic derecho en cualquier carpeta → *Open Git
Bash here*.

Comprueba que quedó:

```bash
git --version
```

### Cuenta de GitHub

Crea una en **github.com** si no tienes. Usa un nombre de usuario que
reconozcan tus compañeros: va a aparecer en cada cambio que propongas, para
siempre.

**Sobre tu correo:** el repositorio es público, así que el correo que
configures queda visible en el historial. Si prefieres no exponer el personal,
ve a *Settings → Emails* y marca **Keep my email addresses private**. GitHub te
da una dirección tipo `12345678+usuario@users.noreply.github.com` que funciona
igual.

### KLayout

Descarga de **klayout.de**. En Windows elige el instalador de 64 bits.

### El PDK CIDESI_CM05

El PDK es un paquete de tecnología de KLayout. Se instala clonándolo dentro de
la carpeta `salt` de KLayout:

```bash
cd ~/KLayout/salt
git clone https://github.com/RodSchz/CIDESI_CM05.git
```

Si la carpeta `salt` no existe, créala: `mkdir -p ~/KLayout/salt`.

Abre KLayout y verifica: en la barra de herramientas debe aparecer un selector
de tecnología con **CIDESI_CM05** entre las opciones. Si aparece, el PDK está
instalado y ya tienes las capas con nombre, el DRC, el LVS y el XSection.

Ventaja de instalarlo con git: cuando el PDK se actualice, `git pull` dentro de
esa carpeta te trae la versión nueva.

### LTspice

Descarga de **Analog Devices**. Instalación estándar, sin opciones que
importen.

### Python y el módulo de KLayout

Instala Python de **python.org**. En el instalador, marca la casilla
**"Add Python to PATH"** — es fácil de pasar por alto y sin ella nada funciona
desde Git Bash.

Luego, en Git Bash:

```bash
pip install klayout
```

Esto **no** es otra instalación de KLayout: es el mismo motor empaquetado como
módulo de Python, sin interfaz gráfica. Convive sin problema con la aplicación
y es lo que usa el verificador automático.

Comprueba:

```bash
python -c "import klayout.db; print('ok')"
```

---

## 2. Configurar git

Git firma cada cambio con tu nombre y correo. Configúralos una sola vez:

```bash
git config --global user.name "Tu Nombre Completo"
git config --global user.email "tu-correo@ejemplo.com"
```

Usa el correo de GitHub — el real o el de `noreply`, pero **el mismo** que
tenga tu cuenta, o GitHub no relacionará tus cambios con tu perfil.

Y una opción que evita un problema real en Windows:

```bash
git config --global core.autocrlf false
```

Windows y Linux marcan el fin de línea de forma distinta. El repositorio ya
maneja eso por archivo, y esta línea evita que git haga además su propia
conversión y termine reportando cambios en archivos que nadie tocó.

### Autenticación

La primera vez que envíes algo a GitHub te va a pedir identificarte. Git para
Windows incluye un gestor de credenciales que abre el navegador: inicias sesión
ahí, autorizas, y no vuelve a preguntar.

Si en vez de eso te pide usuario y contraseña en la terminal, **tu contraseña
de GitHub no funciona**. Necesitas un token: GitHub → *Settings → Developer
settings → Personal access tokens → Tokens (classic) → Generate new token*, con
el permiso `repo` marcado. Guárdalo: se muestra una sola vez y se usa en lugar
de la contraseña.

---

## 3. Los conceptos de git que necesitas

Son ocho. Con esto basta para trabajar.

**Repositorio** — una carpeta cuyo historial completo git guarda. Cada versión
de cada archivo, para siempre.

**Commit** — una foto del proyecto en un momento, con un mensaje que explica
qué cambió. Es la unidad del historial. Haz commits pequeños: uno por idea, no
uno por día de trabajo.

**Rama (branch)** — una línea de trabajo paralela. Te separas de `main`,
trabajas sin molestar a nadie, y al final propones que se reincorpore. La rama
principal se llama `main`.

**Fork** — tu copia personal del repositorio, bajo tu cuenta de GitHub. Puedes
hacer lo que quieras ahí sin permiso de nadie.

**Clone** — traer un repositorio de GitHub a tu disco duro.

**Remoto** — un repositorio en internet al que tu copia local apunta. Vas a
tener dos:

- `origin` — **tu fork**. Aquí envías tu trabajo.
- `upstream` — **el repositorio canónico** del coordinador. De aquí traes lo
  que hacen los demás. Nunca escribes aquí.

**Pull request (PR)** — la propuesta formal: *"tengo estos cambios, propongo
incorporarlos"*. Abre una página de discusión, dispara las verificaciones
automáticas, y el coordinador revisa ahí.

**CI** — las verificaciones automáticas que corren solas en cada PR. Si salen
en rojo, hay algo mal y te dice qué.

### Los tres lugares

```
   repositorio canónico          tu fork              tu copia local
   (RodSchz/CM05_CELLS)      (tu-usuario/...)         (tu disco duro)
        upstream                  origin

        ├──────── fork ──────────►│
        │                         ├──────── clone ────────►│
        │                         │                        │
        │                         │◄─────── push ──────────┤
        │◄──── pull request ──────┤                        │
        │                         │                        │
        ├─────────────── fetch / rebase ──────────────────►│
```

Solo hay cuatro movimientos: **fork** una vez, **clone** una vez, **push** cada
vez que quieras subir trabajo, y **fetch/rebase** para traer lo que hicieron los
demás.

---

## 4. Tu fork y tu copia local

Una sola vez, y ya quedas listo para siempre.

**1. Haz el fork.** Entra a `https://github.com/RodSchz/CM05_CELLS` y haz clic
en **Fork** (arriba a la derecha) → **Create fork**. Ahora existe
`https://github.com/tu-usuario/CM05_CELLS`.

**2. Clona tu fork.** En Git Bash, en la carpeta donde quieras trabajar:

```bash
cd ~/dev
git clone https://github.com/tu-usuario/CM05_CELLS.git
cd CM05_CELLS
```

> **No lo pongas dentro de OneDrive.** La sincronización de OneDrive corrompe
> la carpeta interna `.git` cuando dos procesos escriben a la vez, y el
> resultado es un repositorio roto difícil de diagnosticar.

**3. Conecta el repositorio canónico.**

```bash
git remote add upstream https://github.com/RodSchz/CM05_CELLS.git
git remote -v
```

Debes ver cuatro líneas: `origin` apuntando a tu fork y `upstream` al de
RodSchz.

---

## 5. Ejercicio guiado: corregir `Buffer_8X`

Vamos a arreglar un defecto real. La celda `Buffer_8X` no cumple el contrato
geométrico de la biblioteca, y el CI lo reporta desde hace tiempo.

### 5.1 Ver el problema

```bash
python scripts/drc/check_site.py --config digital/site.yaml \
  digital/cells/Buffer_8X/layout/Buffer_8X.gds
```

Vas a ver:

```
  X  Buffer_8X        1 violacion(es)
       - riel GND va de x 5.0 a 235.0, se esperaba 7.5..237.5 (retranqueo 7.5 um)
```

**Qué significa.** Todas las celdas de la biblioteca tienen los rieles de
alimentación metidos 7.5 µm desde cada borde. En `Buffer_8X` el riel de GND
está en 5.0, o sea **2.5 µm corrido a la izquierda**. El riel de VDD sí está
bien, en 7.5.

Ambos rieles miden 230 µm de ancho, así que no es un problema de longitud: la
caja completa está desplazada. La corrección es moverla 2.5 µm a la derecha.

### 5.2 Crear tu rama

Primero sincroniza con el canónico, para partir de lo más reciente:

```bash
git fetch upstream
git checkout -b fix/buffer8x-riel-gnd upstream/main
```

El nombre de la rama dice qué vas a hacer. Ahora estás en tu propia línea de
trabajo.

### 5.3 Corregir en KLayout

1. Abre `digital/cells/Buffer_8X/layout/Buffer_8X.gds` en KLayout.
2. Selecciona la tecnología **CIDESI_CM05** para ver las capas con nombre.
3. Localiza el riel de GND: es la caja horizontal de abajo, en **Metal1
   (49/0)**, de 230 × 10 µm, a la altura y = 5.0 … 15.0.
4. Haz clic sobre ella para seleccionarla. Verifica en la barra de estado que
   sea la caja correcta: debe ir de x = 5.0 a x = 235.0.
5. Muévela **+2.5 µm en X, 0 en Y**. En KLayout: menú **Edit → Selection →
   Move**, y en el diálogo escribe `2.5` en X y `0` en Y.
6. Guarda con **File → Save**.

> **Comprobación de seguridad:** los cinco contactos verticales que bajan hasta
> el riel están entre x = 47.5 y x = 217.5. Después de mover, el riel va de 7.5
> a 237.5, así que los sigue cubriendo a todos. Nada se desconecta.

### 5.4 Verificar

El mismo comando de antes:

```bash
python scripts/drc/check_site.py --config digital/site.yaml \
  digital/cells/Buffer_8X/layout/Buffer_8X.gds
```

Ahora debe decir:

```
  OK Buffer_8X        cumple

Resumen: 1/1 celdas cumplen el contrato de fila.
Todas las celdas cumplen.
```

Corre también el DRC en KLayout para confirmar que el movimiento no rompió
ninguna regla del proceso.

### 5.5 Actualizar el `cell.yaml`

Abre `digital/cells/Buffer_8X/cell.yaml` con un editor de texto y cambia:

```yaml
site_contract:
  compliant:  true
  violations: []
```

El `cell.yaml` es la ficha técnica de la celda. Si el layout cambió y la ficha
no, el repositorio empieza a mentir.

### 5.6 Guardar tu trabajo

```bash
git status
```

Te muestra qué cambió. Deben aparecer dos archivos: el `.gds` y el
`cell.yaml`.

```bash
git add digital/cells/Buffer_8X
git commit -m "Buffer_8X: corrige posicion del riel GND, +2.5 um en X"
```

`git add` marca qué entra al commit; `git commit` lo guarda. El mensaje va en
presente y dice **qué** cambió, no "cambios" ni "arreglo".

### 5.7 Subir a tu fork

```bash
git push origin fix/buffer8x-riel-gnd
```

Git te devuelve un enlace para abrir el pull request. Cópialo.

### 5.8 Abrir el pull request

1. Abre ese enlace, o entra a tu fork en GitHub: aparece una barra amarilla con
   el botón **Compare & pull request**.
2. **Título:** `Buffer_8X: corrige posición del riel GND`
3. **Descripción:** llena la plantilla que aparece. Lo esencial:

```
El riel GND estaba en x 5.0..235.0; el contrato pide 7.5..237.5.
La caja completa estaba desplazada 2.5 um a la izquierda.

Corrección: mover el riel +2.5 um en X.

Verificación:
- check_site.py: cumple
- DRC: limpio
- Los cinco contactos verticales siguen cubiertos por el riel
```

4. **Create pull request**.

### 5.9 Esperar el CI

Abajo aparece un recuadro con las verificaciones. Toma un par de minutos.

- **Verde** — tu corrección pasó. Ahora espera la revisión del coordinador.
- **Rojo** — haz clic en **Details** para ver qué falló, corrige, y repite
  `git add`, `git commit`, `git push`. **El pull request se actualiza solo.**

### 5.10 Atender la revisión

El coordinador puede pedir cambios. Cuando lo haga:

```bash
# corriges lo que te pidieron, luego:
git add digital/cells/Buffer_8X
git commit -m "Buffer_8X: ajusta lo solicitado en revision"
git push origin fix/buffer8x-riel-gnd
```

**No abras un pull request nuevo.** Empujar a la misma rama actualiza el que ya
existe y conserva toda la conversación.

Cuando apruebe y fusione, terminaste. Sincroniza tu copia:

```bash
git checkout main
git fetch upstream
git rebase upstream/main
git push origin main
```

---

## 6. Cuando algo falla

Los seis tropiezos que le pasan a todo el mundo la primera semana.

### «! [remote rejected] main -> main (protected branch hook declined)»

Intentaste enviar directo a `main`. No se puede — es a propósito. Todo entra
por pull request.

Si ya hiciste commits sobre `main` por error:

```bash
git checkout -b fix/mi-cambio
git push origin fix/mi-cambio
```

Tus commits se van con la rama nueva y desde ahí abres el PR.

### «Please tell me who you are»

No configuraste tu identidad. Vuelve a la sección 2.

### El CI sale en rojo

Haz clic en **Details** junto al check fallido. La salida dice exactamente qué
celda y qué regla. Casi siempre es una violación real que hay que corregir, no
un problema del CI.

Puedes reproducirlo en tu máquina con el mismo comando que corre el CI — por
eso el verificador está escrito para funcionar igual en los dos lados.

### LTspice: «Can't find symbol»

El símbolo de una celda y su esquemático deben estar en la **misma carpeta**.
Todos los archivos de LTspice de una celda viven juntos en su carpeta
`ltspice/`. Si moviste algo, regrésalo.

Los bloques (`blocks/HA`, `blocks/Full_adder`, `blocks/NOT_CHAIN`) **todavía no
abren** — están esperando que las celdas que instancian se liberen. No es tu
error.

### «Your branch is behind» o conflictos al fusionar

Tu copia se quedó atrás respecto al canónico:

```bash
git fetch upstream
git rebase upstream/main
```

Si git reporta un conflicto en un archivo de texto, ábrelo: verás marcas
`<<<<<<<`, `=======` y `>>>>>>>` delimitando las dos versiones. Deja el
contenido correcto, borra las marcas, y luego:

```bash
git add <archivo>
git rebase --continue
```

**Si el conflicto es en un `.gds`, detente y avisa al coordinador.** Git no
puede fusionar binarios, y resolverlo mal destruye trabajo. Esto no debería
pasar si se respeta la regla de *una celda, un dueño*.

### «error: failed to push some refs»

Alguien más subió algo a esa rama antes que tú. Trae lo suyo primero:

```bash
git pull --rebase origin <tu-rama>
git push origin <tu-rama>
```

---

## 7. Qué sigue

Ya recorriste el ciclo completo. De aquí en adelante, cada celda es el mismo
patrón:

```bash
git fetch upstream
git checkout -b cell/<nombre> upstream/main
# trabajar, verificar, git add, git commit
git push origin cell/<nombre>
# abrir el PR
```

Quedan cuatro defectos más en la biblioteca, en orden de dificultad:

| Celda | Problema |
|---|---|
| `AND2X1` | Origen en y = −2.5 y altura 225.0 en vez de 222.5 |
| `XOR2X1` | Origen en y = +2.5; pozo n hasta 225.0 |
| `Inverter3S` | Altura 215.0 (−7.5); pozo n corto |
| `FILLER` | Origen en x = 7.5; sin etiquetas de VDD/GND |

`AND2X1` además arrastra una discrepancia entre esquemático y layout que hay
que resolver con el coordinador: el esquemático usa PMOS w=25u / NMOS w=10u y
el layout W=50U / W=15U. **La versión correcta es la del layout.**

### Para consultar después

- **`docs/manual.md`** — el manual de operación. Referencia completa de roles,
  convenciones y ciclo de vida.
- **`digital/docs/site_rules.md`** — el contrato geométrico con todos sus
  números y de dónde salieron.
- **`CONTRIBUTING.md`** — nomenclatura, qué se versiona, checklist de PR.
- **`digital/cells/README.md`** — estado actual de las 16 celdas.

### Qué existe y qué todavía no

Para que no busques lo que aún no está construido:

| Paso | Estado |
|---|---|
| Esquemático y simulación en LTspice | Operativo |
| Layout y DRC en KLayout | Operativo |
| Verificación del contrato de fila | Operativo, automático en cada PR |
| Simulación post-layout con ngspice | Solo montado para `cmirror` |
| LVS formal en KLayout | Sin procedimiento documentado |
| Esquinas de proceso `ff` y `ss` | **No existen en el PDK** |
| Caracterización y `.lib` | No existe |

Por eso hoy ninguna celda puede pasar de `drc_clean`: sin esquinas de proceso
no hay forma de declararla verificada. Es una limitación del kit de proceso, no
del flujo.
