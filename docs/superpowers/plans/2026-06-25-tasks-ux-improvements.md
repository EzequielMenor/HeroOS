# Mejora de UX y Microinteracciones en Misiones

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rediseñar visualmente la pantalla de tareas en la app móvil de Zen OS, introduciendo un checkbox animado, separación visual de tareas por fechas, filtros de energía rápidos y un lienzo a pantalla completa para la creación/edición inmersiva de misiones con vinculación a notas.

**Architecture:** Modificaremos la entidad de dominio `TaskEntity` y el modelo de datos para añadir el Foco diario (`isHighlight`), el bloque de enfoque (`FocusDuration`), y la relación opcional con notas (`noteId`). Actualizaremos la pantalla `TasksScreen` en móvil para utilizar un sistema de listas animadas agrupadas y una interfaz inmersiva a pantalla completa basada en chips flotantes.

**Tech Stack:** Flutter, Dart, Supabase Flutter, Provider, Google Fonts (Inter).

## Global Constraints
- El diseño debe adherirse a la estética "Apple Industrial": fondo `#1C1C1E` (o el fondo del scaffold actual), superficies `#2C2C2E` y acentos en verde salvia (`#8FBC8F`).
- Mantener compatibilidad con el entorno de desarrollo y pruebas locales (`AuthRepository.devQuickAccess`).
- No utilizar librerías externas de interfaz que no estén ya instaladas; trabajar con widgets nativos y animaciones fluidas (`AnimatedContainer`, `TweenAnimationBuilder`, `AnimatedList`).

---

### Task 1: Modificación del Dominio y Modelo de Datos

**Files:**
- Modify: `lib/domain/entities/task_entity.dart`
- Modify: `lib/data/models/task_model.dart`
- Modify: `lib/data/repositories/dev_repository.dart`

**Interfaces:**
- Consumes: `TaskEntity`, `TaskModel`, `DevRepository`
- Produces: Nueva estructura de `TaskEntity` con campos `noteId`, `isHighlight` y `duration` (usando `FocusDuration`).

- [ ] **Step 1: Definir el enum `FocusDuration` y añadir campos en `TaskEntity`**
  Modifica `lib/domain/entities/task_entity.dart` para añadir:
  ```dart
  enum FocusDuration { micro, short, deep }
  ```
  Añade las propiedades `noteId` (String?), `isHighlight` (bool) y `duration` (FocusDuration?) en la clase `TaskEntity`, sus parámetros en el constructor y el método `copyWith`.
  ```dart
  // lib/domain/entities/task_entity.dart
  enum FocusDuration { micro, short, deep }

  class TaskEntity {
    final String id;
    final String userId;
    final String title;
    final bool isDone;
    final DateTime? dueDate;
    final Energy? energy;
    final SyncStatus? syncStatus;
    final String? noteId;
    final bool isHighlight;
    final FocusDuration? duration;

    TaskEntity({
      required this.id,
      required this.userId,
      required this.title,
      this.isDone = false,
      this.dueDate,
      this.energy,
      this.syncStatus,
      this.noteId,
      this.isHighlight = false,
      this.duration,
    });
    
    // Actualizar copyWith con los nuevos campos
  ```

- [ ] **Step 2: Actualizar `TaskModel` para mapear los nuevos campos**
  Modifica `lib/data/models/task_model.dart` para serializar y deserializar `noteId`, `isHighlight` y `duration` a/desde JSON y entidad.
  ```dart
  // En TaskModel.fromJson:
  final durationStr = json['duration'] as String?;
  FocusDuration? duration;
  if (durationStr != null) {
    duration = FocusDuration.values.firstWhere(
      (d) => d.name == durationStr,
      orElse: () => FocusDuration.short,
    );
  }
  
  return TaskModel(
    // ...,
    noteId: json['note_id'] as String?,
    isHighlight: json['is_highlight'] as bool? ?? false,
    duration: duration,
  );
  
  // En toJson:
  'note_id': noteId,
  'is_highlight': isHighlight,
  'duration': duration?.name,
  ```

- [ ] **Step 3: Modificar `DevRepository` para mockear la persistencia de datos**
  Modifica `lib/data/repositories/dev_repository.dart` para que `createTask` y `updateTask` preserven las nuevas propiedades en la base de datos simulada en memoria.
  ```dart
  // En createTask en dev_repository.dart:
  _tasks.add(TaskEntity(
    id: _genId(),
    userId: 'dev-user',
    title: t.title,
    isDone: false,
    dueDate: t.dueDate,
    energy: t.energy,
    noteId: t.noteId,
    isHighlight: t.isHighlight,
    duration: t.duration,
  ));
  ```

- [ ] **Step 4: Ejecutar la compilación y verificar la ausencia de errores sintácticos**
  Comando: `flutter analyze`
  Esperado: Sin errores en la entidad ni en el modelo.


### Task 2: Actualización de la Lógica de Negocio (ViewModel)

**Files:**
- Modify: `lib/presentation/viewmodels/tasks_viewmodel.dart`

**Interfaces:**
- Consumes: `TasksViewModel`, `TaskEntity`
- Produces: `TasksViewModel` con funciones para gestionar el filtro de energía local, toggle de Highlight y creación con notas.

- [ ] **Step 1: Añadir soporte para creación y edición en `TasksViewModel`**
  Modifica `createTask` en `lib/presentation/viewmodels/tasks_viewmodel.dart` para soportar las nuevas propiedades:
  ```dart
  Future<void> createTask({
    required String title,
    DateTime? dueDate,
    Energy? energy,
    String? noteId,
    bool isHighlight = false,
    FocusDuration? duration,
  }) async {
    // ...
    final task = TaskEntity(
      id: '',
      userId: userId,
      title: title,
      dueDate: dueDate,
      energy: energy,
      noteId: noteId,
      isHighlight: isHighlight,
      duration: duration,
    );
    // ...
  }
  ```

- [ ] **Step 2: Añadir propiedad y métodos para el filtro de energía seleccionado**
  Añade `Energy? _selectedEnergyFilter;` en `TasksViewModel`, junto con su getter y un setter `setEnergyFilter(Energy? filter)`.
  ```dart
  Energy? _selectedEnergyFilter;
  Energy? get selectedEnergyFilter => _selectedEnergyFilter;

  void setEnergyFilter(Energy? filter) {
    _selectedEnergyFilter = filter;
    notifyListeners();
  }
  ```

- [ ] **Step 3: Filtrar tareas activas según el filtro de energía**
  Actualiza los getters `pendingTasks` y `doneTasks` en `TasksViewModel` para filtrar opcionalmente por energía si `_selectedEnergyFilter` no es nulo:
  ```dart
  List<TaskEntity> get pendingTasks {
    var list = _tasks.where((t) => !t.isDone);
    if (_selectedEnergyFilter != null) {
      list = list.where((t) => t.energy == _selectedEnergyFilter);
    }
    return list.toList();
  }
  ```

- [ ] **Step 4: Añadir toggle para el Foco del Día (Highlight)**
  Crea una función en `TasksViewModel` para alternar la propiedad `isHighlight` de una tarea:
  ```dart
  Future<void> toggleTaskHighlight(TaskEntity task) async {
    // Para simplificar, desmarcar otros highlights y marcar este, o simplemente alternarlo.
    // Enfoque Zen: Permitir un solo highlight activo.
    final updatedList = _tasks.map((t) {
      if (t.id == task.id) {
        return t.copyWith(isHighlight: !t.isHighlight);
      } else if (!t.isDone) {
        return t.copyWith(isHighlight: false); // Solo un highlight activo
      }
      return t;
    }).toList();
    
    final updatedTask = task.copyWith(isHighlight: !task.isHighlight);
    await updateTask(updatedTask);
  }
  ```


### Task 3: Checkbox Zen y Agrupación Visual de Tareas

**Files:**
- Modify: `lib/presentation/screens/tasks_screen.dart`

- [ ] **Step 1: Rediseñar el checkbox circular en `_TaskTile`**
  En `_TaskTile`, modifica el checkbox de la línea 764-790. Debe tener un borde ultra-fino de `1.2` de grosor y animación de rellenado:
  ```dart
  GestureDetector(
    onTap: () async {
      HapticFeedback.mediumImpact();
      // Retardo de 400ms para permitir ver la microinteracción de marcado
      await Future.delayed(const Duration(milliseconds: 400));
      if (task.isDone) {
        vm.uncompleteTask(task);
      } else {
        vm.completeTask(task);
      }
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: task.isDone ? _kAccent : _kTextSecondary.withOpacity(0.4),
          width: 1.2,
        ),
        color: task.isDone ? _kAccent.withOpacity(0.15) : Colors.transparent,
      ),
      child: task.isDone
          ? Center(
              child: Icon(Icons.check, size: 10, color: _kAccent),
            )
          : null,
    ),
  )
  ```

- [ ] **Step 2: Agrupación visual en la lista de misiones (Mobile)**
  En `_buildListView(TasksViewModel vm)`, en lugar de devolver una lista plana directa, agrupa las misiones:
  - Filtra las tareas pendientes (`pendingTasks`) en "Hoy" (con `dueDate` igual a hoy o en el pasado) y "Más adelante" / "Sin fecha" (fecha en el futuro o nula).
  - Pinta secciones separadas usando `_ZenSectionLabel`.
  - Las misiones "Hoy" se pintan con peso de texto `FontWeight.w600` (Inter).
  - Las misiones "Más adelante" se pintan con opacidad de texto al 50% (`Color.withOpacity(0.5)`) y peso `FontWeight.w400`.
  - Si la tarea tiene `isHighlight == true`, destaca sutilmente el tile con un fondo verde salvia translúcido (`_kAccent.withOpacity(0.04)`).

- [ ] **Step 3: Agregar indicador de nota vinculada**
  En el row de metadata de `_TaskTile`, comprueba si `task.noteId != null`. Si es así, muestra un pequeño icono de nota/documento de `11px` (`Icons.article_outlined`) en gris tenue.


### Task 4: Barra de Filtro de Energía Horizontal

**Files:**
- Modify: `lib/presentation/screens/tasks_screen.dart`

- [ ] **Step 1: Agregar el selector de energía horizontal**
  Añade una barra horizontal scrollable debajo del toggle de "LISTA / CALENDARIO" y del filtro de estado "ABIERTAS / HECHAS / TODAS":
  ```dart
  Widget _buildEnergyFilterBar(TasksViewModel vm) {
    final energyOptions = [
      {'label': 'TODA LA ENERGÍA', 'value': null},
      {'label': '🟢 BAJA', 'value': Energy.low},
      {'label': '🟡 MEDIA', 'value': Energy.medium},
      {'label': '🔴 ALTA', 'value': Energy.high},
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: energyOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = energyOptions[index];
          final value = option['value'] as Energy?;
          final label = option['label'] as String;
          final isActive = vm.selectedEnergyFilter == value;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              vm.setEnergyFilter(value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? _kAccent : const Color(0x14FFFFFF),
                  width: 1,
                ),
                color: isActive ? _kAccent.withOpacity(0.12) : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? _kAccent : _kTextSecondary,
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  ```
  Integra este método en `_buildMobileLayout` e insértalo de forma elegante.


### Task 5: Pantalla Completa "Lienzo de Misión"

**Files:**
- Modify: `lib/presentation/screens/tasks_screen.dart`

- [ ] **Step 1: Crear e integrar el Lienzo de Misión a pantalla completa**
  Crea un nuevo widget con estado `MissionCanvasScreen` (o una función que lo retorne) que se presente como un diálogo a pantalla completa (`MaterialPageRoute(builder: ..., fullscreenDialog: true)`):
  - Fondo gris oscuro `#1C1C1E` (o el fondo del scaffold).
  - Título y caja de texto gigante:
    ```dart
    TextField(
      autofocus: true,
      style: GoogleFonts.inter(color: _kTextPrimary, fontSize: 24, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Escribe tu misión...',
        hintStyle: TextStyle(color: _kTextSecondary.withOpacity(0.3)),
        border: InputBorder.none,
      ),
    )
    ```
  - Controles flotantes encima del teclado:
    - Chip de energía: al pulsarlo cicla la energía y cambia el indicador visual.
    - Chip de fecha: abre el selector de fechas.
    - Chip de vincular nota: abre un listado sutil de notas obtenidas del viewmodel o repositorio (usando `DevRepository().getNotes()`) para seleccionarla y asociarla.
    - Un toggle para marcar si es el "Highlight" del día.
  - Botón "Guardar" en la esquina superior derecha, habilitado solo cuando el TextField tenga texto.

- [ ] **Step 2: Conectar la creación y edición a la pantalla completa**
  En `TasksScreen`, modifica la llamada del botón de añadir `+` para que abra el `MissionCanvasScreen` en vez de `showTaskCreateSheet`. Haz lo mismo con el tap largo en `_TaskTile` para la edición de tareas.
