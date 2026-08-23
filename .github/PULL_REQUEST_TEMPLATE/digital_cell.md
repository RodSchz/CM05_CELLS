## Celda digital: <nombre>

**Issue relacionado:** #

### Descripción
Qué celda es y qué cambió.

### Contrato geométrico
- [ ] Altura de fila correcta
- [ ] Ancho múltiplo del pitch
- [ ] Rieles VDD/GND alineados y extendidos a los bordes
- [ ] n-well continuo entre celdas abutadas
- [ ] Pines en metal 1, alineados a la grilla y etiquetados

### Verificación
- [ ] DRC limpio — adjuntar reporte
- [ ] LVS sin discrepancias — adjuntar reporte
- [ ] `cell.yaml` completo y actualizado
- [ ] `.cdl` y `.v` consistentes con el esquemático

### Caracterización
- [ ] Corners simulados: tt / ff / ss
- [ ] Barrido de carga y slew
- [ ] `.lib` regenerado

### Layout
Captura del XOR de KLayout contra la versión anterior (o del layout completo
si es celda nueva):

<!-- arrastra la imagen aquí -->
