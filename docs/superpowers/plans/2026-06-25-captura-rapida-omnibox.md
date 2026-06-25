# Plan de Implementación: Captura Rápida Asistida (Omnibox) - Zen OS

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rediseñar el modal de captura rápida (Omnibox) y la interacción táctil directa en el timeline para lograr fricción cero, procesando la IA de forma asíncrona tras el guardado local inmediato.

**Architecture:** MVVM con Clean Architecture. Guardado local instantáneo con estado `pendingAi`, seguido de una llamada en segundo plano al resolvedor de IA (`TriggerAiRefinementUseCase`) si está configurado; control de concurrencia mediante estados de sincronización (`userModified`) para evitar sobreescrituras.

**Tech Stack:** Flutter, Dart, Supabase, Provider.

## Global Constraints
- Estética Apple Industrial: Sin negro puro (#000000). Fondos en `#1C1C1E` y superficies en `#2C2C2E`.
- Tipografía exclusiva Inter.
- Translucidez mediante `BackdropFilter` (blur sigma 15) y bordes de `0.5px` con gradiente de opacidad blanco (`0.1` a `0.02`).
- Color de acento Sage Green (`#8FBC8F`) únicamente para estados activos y progreso.
- Asincronía estricta: Las operaciones de red de la IA no deben bloquear el hilo principal ni la recarga de datos locales en la UI.

---

### Task 1: Capa de Dominio y ViewModel (Asincronía e IA)

**Files:**
- Modify: `lib/domain/entities/transaction_entity.dart` (añadir campo `syncStatus`)
- Modify: `lib/domain/entities/task_entity.dart` (añadir campo `syncStatus`)
- Modify: `lib/presentation/viewmodels/quick_capture_viewmodel.dart` (refactorizar flujo de guardado y asincronía)
- Test: `test/presentation/viewmodels/quick_capture_viewmodel_test.dart`

**Interfaces:**
- Consumes: `AiService` y repositorios (`TaskRepository`, `FinanceRepository`, `NoteRepository`).
- Produces: `QuickCaptureViewModel.captureTransaction`, `QuickCaptureViewModel.captureTask`, `QuickCaptureViewModel.captureNote`.

- [ ] **Step 1: Añadir enum SyncStatus y actualizar Entidades**
  Modificar las entidades de Transacción y Tarea para admitir el control de sincronización de la IA.
  ```dart
  // En lib/domain/entities/transaction_entity.dart
  enum SyncStatus { pendingAi, completed, userModified }
  
  // Agregar campo a TransactionEntity:
  // final SyncStatus syncStatus;
  // default: SyncStatus.completed
  ```

- [ ] **Step 2: Refactorizar QuickCaptureViewModel para guardado local asíncrono**
  Implementar métodos específicos de guardado inmediato que desencadenen la llamada asíncrona de IA en segundo plano.
  ```dart
  // En lib/presentation/viewmodels/quick_capture_viewmodel.dart
  Future<void> saveTransactionImmediate({
    required double amount,
    required String concept,
    required String accountId,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'dev-user';
    
    final txn = TransactionEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // ID temporal
      userId: userId,
      accountId: accountId,
      amount: amount,
      category: 'Sin Categoría',
      note: concept,
      date: DateTime.now(),
      syncStatus: SyncStatus.pendingAi,
    );

    // 1. Guardar en repositorio local/Supabase inmediatamente
    await _financeRepo.createTransaction(txn);
    notifyListeners();

    // 2. Ejecutar procesamiento IA en segundo plano sin esperar el resultado en UI
    _runAiTransactionRefinement(txn);
  }

  Future<void> _runAiTransactionRefinement(TransactionEntity txn) async {
    if (!_aiService.isConfigured) return;
    
    try {
      final result = await _aiService.classify(txn.note ?? '');
      
      // Verificar si el usuario ya la modificó manualmente en la UI
      final currentTxn = await _financeRepo.getTransactionById(txn.id);
      if (currentTxn.syncStatus == SyncStatus.userModified) {
        return; // Detener para evitar race condition
      }

      await _financeRepo.updateTransactionCategory(txn.id, result.category);
    } catch (e) {
      // Ignorar error de red silenciosamente, dejando estado sin categoría
    }
  }
  ```

- [ ] **Step 3: Crear test unitario para verificar asincronía**
  Escribir pruebas que garanticen que la UI se libera inmediatamente tras guardar localmente y que la IA no sobreescribe si el estado cambia a `userModified`.

- [ ] **Step 4: Ejecutar pruebas unitarias**
  Run: `flutter test test/presentation/viewmodels/quick_capture_viewmodel_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add lib/domain/entities/transaction_entity.dart lib/presentation/viewmodels/quick_capture_viewmodel.dart
  git commit -m "feat: implement non-blocking asynchronous capture with syncStatus check"
  ```

---

### Task 2: UI de Captura Rápida (Modal de 3 Botones y Transición)

**Files:**
- Modify: `lib/presentation/screens/global_add_screen.dart`
- Create: `lib/presentation/widgets/glass_action_button.dart`

**Interfaces:**
- Consumes: `QuickCaptureViewModel`
- Produces: `GlobalAddScreen` (Widget interactivo tipo BottomSheet)

- [ ] **Step 1: Crear botón de acción con estética de cristal ahumado**
  Crear un botón táctil minimalista.
  ```dart
  // En lib/presentation/widgets/glass_action_button.dart
  class GlassActionButton extends StatelessWidget {
    final String label;
    final VoidCallback onTap;
    final String icon;

    const GlassActionButton({required this.label, required this.onTap, required this.icon, super.key});

    @override
    Widget build(BuildContext context) {
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xff2c2c2e).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 2: Refactorizar GlobalAddScreen con modal inicial y mini-formularios**
  Reemplazar el textfield único por una interfaz en 2 fases:
  1. **Fase 1:** Contenedor compacto con 3 opciones: `Nueva Misión`, `Registrar Gasto`, `Apunte Rápido`.
  2. **Fase 2:** Al pulsar una opción, el modal transiciona su altura (`AnimatedContainer`) y despliega los campos específicos. El primer campo de texto adquiere el foco mediante un `FocusNode` y el teclado del móvil se despliega inmediatamente.

- [ ] **Step 3: Añadir BackdropFilter y estilos visuales**
  Asegurar que el fondo del BottomSheet tenga el difuminado característico.
  ```dart
  BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      decoration: BoxDecoration(
        color: const Color(0xff1c1c1e).withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      child: ...
    )
  )
  ```

- [ ] **Step 4: Probar la integración visual del modal**
  Comprobar de forma manual y mediante pruebas de Widget que al pulsar "+" se muestra el selector, y al pulsar "Registrar Gasto" cambia de tamaño y enfoca el input de cantidad.

- [ ] **Step 5: Commit**
  ```bash
  git add lib/presentation/screens/global_add_screen.dart lib/presentation/widgets/glass_action_button.dart
  git commit -m "ui: implement translucent fast transitions and inputs focused on select"
  ```

---

### Task 3: Interacciones Directas en Timeline (Categoría y Energía)

**Files:**
- Modify: `lib/presentation/widgets/transaction_tile.dart` (o similar widget de transacciones)
- Modify: `lib/presentation/widgets/task_tile.dart` (o similar widget de tareas)
- Create: `lib/presentation/widgets/category_popover.dart`

**Interfaces:**
- Consumes: `FinanceViewModel` y `TasksViewModel`
- Produces: Popover de cambio de categoría táctil e interacción directa de energía en Tareas.

- [ ] **Step 1: Crear CategoryPopover flotante**
  Diseñar un overlay flotante translúcido que aparezca justo debajo o encima del badge de categoría al ser pulsado.
  ```dart
  // En lib/presentation/widgets/category_popover.dart
  void showCategoryPopover(BuildContext context, Offset targetOffset, Function(String) onSelected) {
    // Usar OverlayEntry de Flutter para posicionar un contenedor de cristal ahumado
    // con una rejilla de categorías de 2 filas y 4 columnas.
  }
  ```

- [ ] **Step 2: Integrar el Popover en la celda de Transacción**
  Hacer que el toque en la categoría en `transaction_tile.dart` calcule la posición en pantalla (`findRenderObject`) y dispare `showCategoryPopover`. Al seleccionar, actualizar el registro local en base de datos y cambiar el estado a `SyncStatus.userModified` para bloquear escrituras tardías de la IA.

- [ ] **Step 3: Agregar cambio cíclico de Energía en Tasks**
  En `task_tile.dart`, mapear el botón o indicador de barritas de energía. Al pulsarlo:
  ```dart
  onTap: () {
    final nextEnergy = task.energy == Energy.low 
        ? Energy.medium 
        : task.energy == Energy.medium 
            ? Energy.high 
            : Energy.low;
    tasksViewModel.updateTaskEnergy(task.id, nextEnergy);
    HapticFeedback.lightImpact();
  }
  ```

- [ ] **Step 4: Probar cambios en el timeline**
  Verificar que los cambios de categoría y energía se aplican inmediatamente en la pantalla principal sin abrir modales a pantalla completa.

- [ ] **Step 5: Commit**
  ```bash
  git add lib/presentation/widgets/category_popover.dart lib/presentation/widgets/transaction_tile.dart lib/presentation/widgets/task_tile.dart
  git commit -m "ui: add direct visual popover for categories and quick cycle toggle for task energy"
  ```
