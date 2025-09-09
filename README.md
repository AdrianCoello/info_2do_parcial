# Match-3 Game - Segundo Parcial Infografia 

## Desarrolladores
- **Adrian Coello**
- **Diego Orellana**

## Descripción del Juego

Este es un juego Match-3 desarrollado en **Godot Engine** como proyecto del segundo parcial de Infografia. El objetivo es formar líneas de 3 o más piezas del mismo color para eliminarlas del tablero y obtener puntos.

## Mecánicas del Juego

### Jugabilidad Básica
- **Objetivo**: Formar líneas de 3 o más piezas del mismo color
- **Controles**: Click y arrastra para intercambiar piezas adyacentes
- **Límite de movimientos**: Cada nivel tiene un número limitado de movimientos
- **Sistema de puntuación**: Cada pieza eliminada otorga 10 puntos

### Piezas Especiales

El juego incluye un sistema avanzado de piezas especiales que se crean automáticamente:

#### **Dulce Multicolor (Rainbow)**
- **Se crea**: Al formar una línea de 5 piezas del mismo color
- **Efecto**: Elimina TODAS las piezas del mismo color del tablero
- **Activación**: Se activa automáticamente al moverlo con cualquier pieza

####  **Dulce de Fila (Row)**
- **Se crea**: Al formar una línea horizontal de 4 piezas
- **Efecto**: Elimina toda la fila horizontal donde se encuentra

####  **Dulce de Columna (Column)**
- **Se crea**: Al formar una línea vertical de 4 piezas
- **Efecto**: Elimina toda la columna vertical donde se encuentra

#### **Dulce Adyacente (Adjacent)**
- **Se crea**: Al formar una combinación en T (líneas horizontal y vertical que se cruzan)
- **Efecto**: Elimina todas las piezas adyacentes (8 direcciones) en un patrón de cruz

### Sistema de Prioridades

El juego implementa un sistema inteligente de detección de matches con las siguientes prioridades:

1. **Match horizontal de 5** → Dulce Multicolor
2. **Match vertical de 5** → Dulce Multicolor
3. **Combinación en T** → Dulce Adyacente
4. **Match horizontal de 4** → Dulce de Fila
5. **Match vertical de 4** → Dulce de Columna
6. **Matches de 3** → Eliminación normal

## Características Técnicas

### Arquitectura del Código
- **Engine**: Godot 4.x
- **Lenguaje**: GDScript
- **Estructura modular**: Scripts separados para cada componente

### Archivos Principales
- `grid.gd`: Lógica principal del tablero y detección de matches
- `piece.gd`: Comportamiento individual de las piezas
- `top_ui.gd`: Interfaz de usuario (puntuación, movimientos)

### Funcionalidades Implementadas
-  Sistema de intercambio de piezas con validación
-  Detección automática de matches múltiples
-  Creación automática de piezas especiales
-  Sistema anti-duplicados para matches
-  Animaciones fluidas de movimiento
-  Colapso automático de piezas tras eliminación
-  Sistema de puntuación y conteo de movimientos
-  Detección de fin de juego

## Instalación y Ejecución

1. Clona o descarga el repositorio
2. Abre el proyecto en Godot Engine 4.x
3. Ejecuta la escena principal `game.tscn`

## Assets Utilizados

El juego utiliza assets gráficos y de audio especializados para Match-3:
- Sprites de piezas de colores (azul, verde, amarillo, naranja, rosa, verde claro)
- Efectos especiales para cada tipo de dulce
- Interfaz de usuario personalizada
- Fuentes tipográficas de Kenney

## Estado del Proyecto

**Versión actual**: Implementación completa con todas las mecánicas funcionales
**Branch**: `main`

### Últimas mejoras implementadas:
-  Corrección de detección de matches de 5 para dulce arcoíris
-  Activación automática del dulce multicolor al moverlo
-  Sistema de prioridades optimizado para evitar conflictos
-  Logs de debug para seguimiento de matches

---

*Proyecto desarrollado como parte del curso de Infografia - Universidad Privada Boliviana*
