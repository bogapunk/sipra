/**
 * Base de conocimiento del chatbot asistente.
 * Permite responder preguntas sobre módulos, botones, procesos, permisos e impacto.
 */

export interface RespuestaChatbot {
  titulo?: string
  contenido: string
  pasos?: string[]
  ejemplo?: string
  modulo?: string
}

/** Palabras clave (normalizadas) que activan cada respuesta */
export interface EntradaConocimiento {
  keywords: string[]
  respuesta: RespuestaChatbot
}

const normalizar = (s: string) =>
  s
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim()

function r(titulo: string, contenido: string, pasos?: string[], ejemplo?: string, modulo?: string): RespuestaChatbot {
  return { titulo, contenido, pasos, ejemplo, modulo }
}

export const entradasConocimiento: EntradaConocimiento[] = [
  // ========== DASHBOARD ==========
  {
    keywords: ['dashboard', 'inicio', 'principal', 'resumen', 'indicadores', 'métricas', 'tarjetas'],
    respuesta: r(
      'Dashboard',
      'El Dashboard muestra una vista general del sistema con: tarjetas de métricas (total proyectos, activos, tareas, finalizadas, bloqueadas, avance global), gráficos de proyectos por estado y por dependencia, proyectos en riesgo, tendencia de avance, carga por responsable, lista de proyectos con avance y barra de progreso, y acceso rápido al detalle y reasignación. Los Administradores ven el Dashboard ejecutivo completo; Visualizadores y Carga ven según su rol.',
      [
        'Las tarjetas superiores muestran el estado global del sistema.',
        'Gráficos: proyectos por estado, por dependencia, tendencia temporal.',
        'Proyectos en riesgo: atrasados o con tareas bloqueadas.',
        'Cada proyecto muestra su avance calculado desde las tareas.',
        'Haga clic en un proyecto para ver detalle, comentarios y reasignar.',
      ],
      'Ejemplo: "Proyecto X - 75%" indica que las tareas del proyecto promedian 75% de avance.',
      'Dashboard'
    ),
  },
  {
    keywords: ['interpretar indicadores dashboard', 'qué significan', 'avance global'],
    respuesta: r(
      'Interpretación de indicadores',
      'Total proyectos: cantidad de proyectos en el sistema. Proyectos activos: en curso. Tareas finalizadas: completadas al 100%. Tareas bloqueadas: requieren atención. Avance global: porcentaje de tareas finalizadas sobre el total.',
      undefined,
      'Si hay 10 tareas y 7 finalizadas, avance global = 70%.',
      'Dashboard'
    ),
  },
  {
    keywords: ['filtrar dashboard', 'filtrar datos dashboard'],
    respuesta: r(
      'Filtros en Dashboard',
      'El Dashboard muestra todos los proyectos visibles según su rol. Los Administradores ven todo el sistema. Los Visualizadores ven Dashboard, Avances por área, Avances por secretaría, Planificación, Proyectos, Tareas y Calendario (solo lectura). Los Carga ven solo sus proyectos asignados. Use el buscador para filtrar por nombre de proyecto.',
      undefined,
      undefined,
      'Dashboard'
    ),
  },

  // ========== AVANCES POR ÁREA ==========
  {
    keywords: ['avances área', 'avances por área', 'visualizar proyectos área'],
    respuesta: r(
      'Avances por Área',
      'Muestra las tareas agrupadas por área organizacional. Cada tarjeta representa un área con sus tareas, porcentaje de avance, barra de progreso y último incremento. Haga clic en una tarjeta para ver el historial de actualizaciones.',
      [
        'Las tareas se agrupan por el área asignada.',
        'Use el buscador para filtrar por nombre de tarea o proyecto.',
        'El historial muestra fecha, usuario y valor anterior → nuevo.',
      ],
      undefined,
      'Avances por Área'
    ),
  },
  {
    keywords: ['porcentaje avance área', 'interpretar porcentaje', 'barra progreso'],
    respuesta: r(
      'Porcentajes de avance',
      'El porcentaje indica cuánto se ha completado la tarea (0-100%). La barra de progreso lo representa visualmente. El "último incremento" muestra cuánto se avanzó en la última actualización (ej: de 50% a 70% = +20%).',
      undefined,
      '100% = tarea finalizada. Se marca automáticamente como "Finalizada".',
      'Avances por Área'
    ),
  },
  {
    keywords: ['proyecto 100%', 'llegar 100', 'cierre proyecto', 'finalizar proyecto'],
    respuesta: r(
      'Cuando un proyecto llega al 100%',
      'Cuando una tarea alcanza 100% de avance, se marca automáticamente como "Finalizada". Si todas las tareas del proyecto están al 100%, el proyecto se marca como "Finalizado". En el historial, el registro de cierre se destaca con etiqueta "Tarea Finalizada" y color verde.',
      [
        'El usuario que cargó el 100% queda registrado en el historial.',
        'La fecha y hora del cierre se guardan.',
        'El proyecto pasa a estado "Finalizado" cuando todas sus tareas están al 100%.',
      ],
      undefined,
      'Avances por Área'
    ),
  },
  {
    keywords: ['historial avances', 'ver historial', 'historial tarea'],
    respuesta: r(
      'Historial de avances',
      'Cada actualización de avance queda registrada con: fecha, usuario que actualizó, valor anterior, nuevo valor y comentario opcional. Los registros de cierre (100%) se destacan con etiqueta "Tarea Finalizada" y fondo verde para identificar el momento de cierre.',
      undefined,
      undefined,
      'Avances por Área'
    ),
  },

  // ========== AVANCES POR SECRETARÍA ==========
  {
    keywords: ['avances secretaría', 'avances por secretaría', 'agrupar secretaría'],
    respuesta: r(
      'Avances por Secretaría',
      'Similar a Avances por Área, pero agrupa las tareas por Secretaría. Solo aparecen tareas que tienen secretaría asignada. Use los filtros para ver una secretaría específica.',
      [
        'Las tareas sin secretaría no aparecen aquí.',
        'Asigne secretaría a las tareas desde el módulo Tareas.',
        'Indicadores: avance actual, último incremento, fecha de actualización.',
      ],
      undefined,
      'Avances por Secretaría'
    ),
  },
  {
    keywords: ['filtrar secretaría', 'filtro secretaría'],
    respuesta: r(
      'Filtros por Secretaría',
      'Use el selector o buscador para filtrar por secretaría. Solo se mostrarán las tareas de la secretaría seleccionada. Los indicadores se analizan por grupo de secretaría.',
      undefined,
      undefined,
      'Avances por Secretaría'
    ),
  },

  // ========== PLANIFICACIÓN ==========
  {
    keywords: ['planificación', 'planes', 'programas', 'objetivos', 'ejes'],
    respuesta: r(
      'Planificación',
      'Estructura jerárquica: Ejes → Planes → Programas → Objetivos Estratégicos → Proyectos → Indicadores. La planificación define la alineación estratégica. Los proyectos se vinculan a objetivos estratégicos.',
      [
        'Ejes: nivel superior de la planificación.',
        'Planes: asociados a cada eje.',
        'Programas: asociados a cada plan.',
        'Objetivos: vinculan a proyectos concretos.',
      ],
      undefined,
      'Planificación'
    ),
  },
  {
    keywords: ['crear plan', 'crear programa', 'crear objetivo', 'crear eje', 'vincular planificación'],
    respuesta: r(
      'Crear elementos de planificación',
      'Desde la pestaña correspondiente (Ejes, Planes, Programas, Objetivos, Indicadores), use el botón de crear. Complete los campos obligatorios. Jerarquía: Eje → Plan → Programa → Objetivo Estratégico → Proyecto → Indicadores. Cada nivel tiene filtros para buscar en el nivel superior. Los proyectos se asocian a un objetivo estratégico al crearlos o editarlos.',
      [
        'Ejes: nivel superior, sin dependencia.',
        'Planes: asociados a un Eje.',
        'Programas: asociados a un Plan.',
        'Objetivos: asociados a un Programa.',
        'Indicadores: asociados a Proyectos vinculados a objetivos.',
      ],
      undefined,
      'Planificación'
    ),
  },
  {
    keywords: ['crear secretaría', 'nueva secretaría', 'editar secretaría'],
    respuesta: r(
      'Gestión de Secretarías',
      'En el módulo Secretarías (solo Administrador) puede crear, editar y desactivar secretarías. Cada secretaría tiene código, nombre y descripción. Las secretarías inactivas no aparecen en selectores. Los proyectos pueden asignarse a una secretaría. Las tareas y usuarios pueden vincularse a secretarías. Use "Ver proyectos" para ver los proyectos de una secretaría.',
      [
        'Las secretarías son unidades organizativas alternativas a las Áreas.',
        'Un proyecto tiene Área o Secretaría, no ambas.',
        'Los usuarios Carga con secretaría ven solo sus proyectos.',
      ],
      undefined,
      'Secretarías'
    ),
  },
  {
    keywords: ['desactivar usuario', 'eliminar usuario', 'usuario inactivo'],
    respuesta: r(
      'Desactivar usuarios',
      'El sistema usa eliminación lógica: al "eliminar" un usuario, se desactiva pero no se borra de la base de datos. Los usuarios desactivados no pueden iniciar sesión. El comando restaurar_datos reactiva usuarios previamente desactivados. Para desactivar: edite el usuario y cambie el estado a inactivo (si está disponible) o use la opción de eliminación del módulo.',
      undefined,
      undefined,
      'Usuarios'
    ),
  },

  // ========== PROYECTOS ==========
  {
    keywords: ['crear proyecto', 'nuevo proyecto', 'cómo crear proyecto'],
    respuesta: r(
      'Crear un proyecto',
      'Use el botón "Nuevo proyecto". Complete: nombre, descripción, fechas de inicio y fin, estado. Seleccione el tipo de dependencia (Área o Secretaría) y elija una. Asigne el responsable (creado por). Guarde.',
      [
        'Elija Área o Secretaría según la estructura organizativa.',
        'Solo puede seleccionar una opción (Área o Secretaría).',
        'El proyecto quedará vinculado a la dependencia elegida.',
      ],
      'Ejemplo: Proyecto "Sistema X" → Área "Tecnología" → Responsable Juan Pérez.',
      'Proyectos'
    ),
  },
  {
    keywords: ['asignar proyecto', 'asignar área', 'asignar secretaría proyecto'],
    respuesta: r(
      'Asignar proyecto a Área o Secretaría',
      'Al crear o editar un proyecto, seleccione "Área" o "Secretaría" en dependencia organizacional. Luego elija la opción correspondiente del listado. Solo una de las dos. Esto define a qué estructura pertenece el proyecto.',
      undefined,
      undefined,
      'Proyectos'
    ),
  },
  {
    keywords: ['reasignar', 'reasignar proyecto', 'cómo reasigno'],
    respuesta: r(
      'Reasignar proyecto',
      'Desde el detalle del proyecto, use "Reasignar Proyecto" o acceda a Proyectos → clic en proyecto → Reasignar. Seleccione el tipo (Área o Secretaría). Si Área: marque las áreas. Si Secretaría: elija una. Indique el motivo. Guarde. La reasignación queda registrada en comentarios.',
      [
        'Puede reasignar a múltiples áreas (si elige tipo Área).',
        'Solo una secretaría por proyecto.',
        'El motivo es opcional pero recomendado para trazabilidad.',
      ],
      undefined,
      'Proyectos'
    ),
  },
  {
    keywords: ['estado proyecto', 'activo', 'finalizado', 'en pausa', 'en curso'],
    respuesta: r(
      'Estados de proyecto',
      'Activo: en ejecución. En pausa: temporalmente detenido. Finalizado: completado (se marca automáticamente cuando todas las tareas llegan al 100%). Puede actualizar el estado manualmente al editar el proyecto. En Tareas también puede filtrar por estado: Activa, Finalizada, Bloqueada.',
      undefined,
      undefined,
      'Proyectos'
    ),
  },
  {
    keywords: ['dependencia organizacional', 'área o secretaría', 'tipo dependencia'],
    respuesta: r(
      'Dependencia organizacional',
      'Proyectos y tareas tienen una dependencia organizacional: Área o Secretaría. Solo puede elegir una de las dos. Si elige Área, selecciona una o más áreas. Si elige Secretaría, selecciona una secretaría. Esto define la estructura y quién puede ver/cargar: los usuarios Carga con área ven proyectos de su área; con secretaría ven proyectos de su secretaría.',
      undefined,
      undefined,
      'Proyectos'
    ),
  },

  // ========== TAREAS ==========
  {
    keywords: ['crear tarea', 'nueva tarea', 'cómo crear tarea'],
    respuesta: r(
      'Crear una tarea',
      'En Tareas, use "Nueva tarea". Seleccione Área o Secretaría (solo una). Elija proyecto, responsable, fechas. Complete título y descripción. El avance inicial es 0%. Las tareas se actualizan desde "Cargar Avances" (rol Carga) o editando en Tareas.',
      [
        'Cada tarea debe tener Área o Secretaría.',
        'El responsable puede cargar avances si tiene rol Carga.',
        'Las tareas determinan el avance del proyecto.',
      ],
      undefined,
      'Tareas'
    ),
  },
  {
    keywords: ['asignar tarea', 'asignar usuario tarea', 'responsable tarea'],
    respuesta: r(
      'Asignar tarea a usuario',
      'Al crear o editar una tarea, seleccione el "Responsable" en el campo correspondiente. El responsable podrá cargar avances si tiene rol Carga y el proyecto está asignado a su área o secretaría.',
      undefined,
      undefined,
      'Tareas'
    ),
  },
  {
    keywords: ['actualizar avance', 'cargar avance', 'porcentaje tarea'],
    respuesta: r(
      'Actualizar avance de tarea',
      'Los usuarios con rol Carga acceden a "Cargar Avances". Ahí ven solo sus tareas. Seleccionan una, ingresan el porcentaje (0-100) y opcionalmente un comentario. Al guardar 100%, la tarea se marca como Finalizada. Si todas las tareas del proyecto llegan al 100%, el proyecto se marca Finalizado.',
      [
        'El historial registra cada actualización.',
        'Use el buscador por proyecto para filtrar rápidamente.',
        'Comente cuando sea posible para documentar.',
      ],
      undefined,
      'Tareas'
    ),
  },
  {
    keywords: ['cerrar tarea', 'finalizar tarea'],
    respuesta: r(
      'Cerrar una tarea',
      'Al cargar 100% de avance, la tarea se marca automáticamente como "Finalizada". No hay un botón separado de cierre. El registro en el historial se destaca como "Tarea Finalizada" con fecha y usuario.',
      undefined,
      undefined,
      'Tareas'
    ),
  },
  {
    keywords: ['prioridad tarea', 'prioridad alta', 'prioridad media', 'prioridad baja'],
    respuesta: r(
      'Prioridad de tareas',
      'Cada tarea tiene una prioridad: Alta, Media o Baja. Se asigna al crear o editar la tarea. La prioridad ayuda a ordenar y priorizar el trabajo. En Tareas puede filtrar por estado (Activa, Finalizada, Bloqueada) y ver la prioridad en la tabla. Las tareas de alta prioridad suelen mostrarse con color rojo, media con amarillo y baja con verde.',
      [
        'Seleccione la prioridad en el formulario de tarea.',
        'Use el filtro por estado para ver solo tareas activas o bloqueadas.',
        'La prioridad no afecta el cálculo de avance del proyecto.',
      ],
      undefined,
      'Tareas'
    ),
  },
  {
    keywords: ['tarea padre', 'subtarea', 'tarea hija', 'jerarquía tareas'],
    respuesta: r(
      'Tareas padre e hijas',
      'Las tareas pueden tener una tarea padre, formando una jerarquía. Una tarea sin padre es de nivel superior. Las subtareas se vinculan seleccionando "Tarea padre" al crearlas o editarlas. El avance del proyecto se calcula considerando todas las tareas (padre e hijas).',
      [
        'Cree primero la tarea padre, luego las hijas.',
        'Las subtareas pueden tener su propio responsable y fechas.',
        'Útil para desglosar trabajo en fases o sub-actividades.',
      ],
      undefined,
      'Tareas'
    ),
  },
  {
    keywords: ['paginación', 'páginas', 'paginado', 'siguiente página'],
    respuesta: r(
      'Paginación',
      'Los módulos Proyectos y Tareas usan paginación para mostrar los resultados. Puede navegar entre páginas con los botones "Anterior" y "Siguiente", o ir a una página específica. El tamaño de página es configurable. Los filtros y búsqueda se aplican al conjunto total antes de paginar.',
      [
        'Proyectos: paginación por defecto.',
        'Tareas: filtros por estado y búsqueda por título.',
        'Exportar Excel respeta los filtros aplicados.',
      ],
      undefined,
      undefined
    ),
  },

  // ========== ÁREAS ==========
  {
    keywords: ['crear área', 'nueva área', 'editar área', 'desactivar área'],
    respuesta: r(
      'Gestión de Áreas',
      'En Áreas, use "Nueva área" para crear. "Editar" para modificar o desactivar. Las áreas inactivas no aparecen en selectores de nuevas tareas. Las áreas impactan en la estructura: usuarios con área ven solo proyectos/tareas de su área; las tareas se agrupan por área en Avances.',
      [
        'Desactive en lugar de eliminar para mantener historial.',
        'Las áreas se vinculan a usuarios (rol Carga) y tareas.',
        'Los proyectos pueden asignarse a áreas vía reasignación.',
      ],
      undefined,
      'Áreas'
    ),
  },
  {
    keywords: ['impacto área', 'área proyectos', 'área usuarios'],
    respuesta: r(
      'Impacto de las Áreas',
      'Áreas definen la estructura organizativa. Usuarios Carga con área asignada solo ven proyectos/tareas de su área. Las tareas pueden vincularse a un Área, una Secretaría o ninguna. Pueden asociarse a un proyecto (estratégicas) o ser independientes (administrativas). En Avances por Área, las tareas se agrupan por área. Los proyectos se reasignan desde el módulo Reasignar.',
      undefined,
      undefined,
      'Áreas'
    ),
  },

  // ========== USUARIOS ==========
  {
    keywords: ['crear usuario', 'nuevo usuario', 'cómo crear usuario'],
    respuesta: r(
      'Crear usuario',
      'En Usuarios, "Nuevo usuario". Complete nombre, apellido, email, contraseña. Asigne rol (Administrador, Visualizador o Carga). Si es Carga, asigne Área o Secretaría obligatoriamente. El usuario solo verá información según su asignación.',
      [
        'Administrador: sin restricción de área.',
        'Carga: debe tener Área o Secretaría.',
        'Visualizador: solo lectura, sin Área/Secretaría.',
      ],
      undefined,
      'Usuarios'
    ),
  },
  {
    keywords: ['asignar rol', 'rol usuario', 'cambiar rol'],
    respuesta: r(
      'Asignar rol a usuario',
      'Al crear o editar usuario, seleccione el rol en el campo correspondiente. Administrador: acceso completo. Visualizador: solo lectura en Dashboard, Avances, Proyectos, Tareas. Carga: carga de avances y vista de proyectos asignados a su área/secretaría.',
      undefined,
      undefined,
      'Usuarios'
    ),
  },
  {
    keywords: ['vincular área usuario', 'vincular secretaría usuario'],
    respuesta: r(
      'Vincular usuario a Área o Secretaría',
      'Solo aplica al rol Carga. En el formulario de usuario, seleccione Área o Secretaría. El usuario solo verá proyectos y tareas de su asignación. No puede tener ambas; elija una.',
      undefined,
      undefined,
      'Usuarios'
    ),
  },
  {
    keywords: ['permisos usuario', 'qué puede hacer'],
    respuesta: r(
      'Permisos por rol',
      'Administrador: ABM completo en todos los módulos (Dashboard, Avances, Planificación, Proyectos, Tareas, Calendario, Áreas, Secretarías, Usuarios, Roles, Backup, Auditoría). Visualizador: solo lectura en Dashboard, Avances por área/secretaría, Planificación, Proyectos, Tareas, Calendario; no ve Áreas, Secretarías, Usuarios, Roles, Cargar Avances, Backup ni Auditoría. Carga: solo Cargar Avances, Dashboard y Calendario (sus proyectos); no ve Proyectos, Tareas, Planificación ni configuración.',
      undefined,
      undefined,
      'Usuarios'
    ),
  },
  {
    keywords: ['contraseña', 'gestionar contraseña', 'cambiar contraseña'],
    respuesta: r(
      'Gestión de contraseñas',
      'Al crear usuario, se define la contraseña inicial. El sistema valida que cumpla requisitos de seguridad. Al editar, puede cambiar la contraseña. Se recomienda que el usuario la cambie en su primer acceso.',
      undefined,
      undefined,
      'Usuarios'
    ),
  },

  // ========== ROLES ==========
  {
    keywords: ['administrador', 'rol administrador', 'qué hace administrador'],
    respuesta: r(
      'Rol Administrador',
      'Acceso completo a todos los módulos: Dashboard, Avances por área, Avances por secretaría, Planificación, Proyectos, Tareas, Áreas, Secretarías, Usuarios, Roles. Puede crear, editar y eliminar. Sin restricciones de visualización.',
      undefined,
      undefined,
      'Roles'
    ),
  },
  {
    keywords: ['visualizador', 'rol visualizador', 'qué puede visualizador'],
    respuesta: r(
      'Rol Visualizador',
      'Solo lectura. Ve: Dashboard, Avances por área, Avances por secretaría, Planificación, Proyectos, Tareas y Calendario. No ve: Áreas, Secretarías, Usuarios, Roles, Cargar Avances, Backup & Restore, Auditoría. No puede crear, editar ni eliminar. Puede exportar a Excel en los módulos permitidos. Ideal para consulta y reportes.',
      undefined,
      undefined,
      'Roles'
    ),
  },
  {
    keywords: ['carga', 'rol carga', 'qué puede carga'],
    respuesta: r(
      'Rol Carga',
      'Solo ve "Cargar Avances" y "Dashboard" (sus proyectos). Debe tener Área o Secretaría asignada. Solo actualiza avances de tareas de proyectos asignados a su área/secretaría. No ve Proyectos, Tareas, Áreas, Usuarios, etc. Ideal para operadores que cargan avances.',
      undefined,
      undefined,
      'Roles'
    ),
  },
  {
    keywords: ['diferencias roles', 'alcance rol', 'restricciones rol'],
    respuesta: r(
      'Diferencias entre roles',
      'Administrador: todo. Visualizador: solo lectura en módulos de consulta, sin acceso a configuración. Carga: solo carga de avances en sus proyectos. Las restricciones evitan que usuarios vean o modifiquen datos fuera de su alcance.',
      undefined,
      undefined,
      'Roles'
    ),
  },

  // ========== BOTONES Y ACCIONES ==========
  {
    keywords: ['botón nuevo', 'botón crear', 'botón guardar', 'botón editar', 'botón eliminar'],
    respuesta: r(
      'Botones principales',
      'Nuevo/Crear: abre formulario para agregar registro. Guardar: persiste los datos. Editar: abre formulario con datos existentes. Eliminar: borra el registro (suele pedir confirmación). Descargar Excel: exporta la lista actual a CSV/Excel.',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['descargar excel', 'exportar', 'excel'],
    respuesta: r(
      'Descargar Excel y exportar',
      'Varios módulos permiten exportar datos: Proyectos (lista con filtros), Tareas (lista con filtros), Proyecto detalle (detalle completo con etapas, tareas e indicadores), Avances por área (reporte por área con búsqueda aplicada), Avances por secretaría (reporte por secretaría). El botón "Descargar Excel" o "Exportar" genera archivos CSV/Excel. Los Visualizadores pueden exportar en los módulos que tienen acceso.',
      [
        'Proyectos: exporta la lista filtrada o paginada.',
        'Proyecto detalle: exporta a Excel con toda la información del proyecto.',
        'Avances: exporta el reporte con el filtro de búsqueda aplicado.',
      ],
      undefined,
      undefined
    ),
  },
  {
    keywords: ['buscar', 'buscador', 'filtrar'],
    respuesta: r(
      'Buscadores y filtros',
      'La mayoría de módulos tienen buscador o filtros: Proyectos (por nombre, área, secretaría), Tareas (por título, estado Activa/Finalizada/Bloqueada), Avances por área (por tarea o proyecto), Avances por secretaría (por secretaría), Planificación (filtros por eje, plan, programa), Backup (por fecha y texto), Auditoría (por proyecto, tarea, usuario, tipo, fechas). En Cargar Avances hay buscador por proyecto. Los filtros se aplican antes de paginar y exportar.',
      undefined,
      undefined,
      undefined
    ),
  },

  // ========== GENÉRICOS ==========
  {
    keywords: ['ayuda', 'cómo funciona', 'qué es esto', 'no entiendo'],
    respuesta: r(
      'Asistente del sistema SIP-AIF',
      'Soy el asistente de SIP-AIF. Puede preguntarme sobre: módulos (Dashboard, Avances por área/secretaría, Planificación, Proyectos, Tareas, Calendario, Áreas, Secretarías, Usuarios, Roles, Backup, Auditoría), procesos (crear, reasignar, cargar avances, exportar), prioridad de tareas, tareas padre/hijas, paginación, equipo, etapas, indicadores, comentarios, adjuntos, auditoría, credenciales, ejecutar sistema, producción y más. Escriba en lenguaje natural, ej: "¿Cómo exportar un proyecto?" o "¿Qué es la prioridad de una tarea?"',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['menú', 'navegación', 'sidebar', 'menú lateral'],
    respuesta: r(
      'Menú de navegación',
      'El menú lateral aparece a la izquierda (desktop) o como menú hamburguesa en móvil. Muestra: Dashboard, Avances por área, Avances por secretaría, Planificación, Proyectos, Tareas, Calendario, Áreas, Secretarías, Usuarios, Roles, Backup & Restore, Auditoría. Los ítems visibles dependen del rol. Administrador ve todo; Visualizador no ve Áreas, Secretarías, Usuarios, Roles, Cargar Avances, Backup ni Auditoría; Carga solo ve Dashboard, Cargar Avances y Calendario.',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['asistente', 'chatbot', 'botón ayuda', 'dónde está el asistente'],
    respuesta: r(
      'Asistente del sistema',
      'El asistente es el botón con "?" en la esquina inferior derecha de la pantalla. Al hacer clic se abre un panel con sugerencias contextuales según la ruta actual y un campo para escribir preguntas. Escriba en lenguaje natural y obtendrá respuestas sobre el módulo, procesos o permisos. Use "Limpiar conversación" para reiniciar. El panel se adapta a móviles.',
      [
        'Botón visible en todas las pantallas (excepto login).',
        'Sugerencias cambian según la página actual.',
        'Puede preguntar sobre cualquier funcionalidad.',
      ],
      undefined,
      undefined
    ),
  },
  {
    keywords: ['breadcrumbs', 'migas de pan', 'navegación ruta'],
    respuesta: r(
      'Breadcrumbs (migas de pan)',
      'Cuando navega en rutas anidadas (ej: Proyecto X → Reasignar), aparece una barra de breadcrumbs arriba del contenido: "Inicio › Proyectos › Nombre Proyecto › Reasignar". Cada ítem es clicable para volver atrás. Solo se muestra cuando hay al menos 3 niveles.',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['responsive', 'móvil', 'tablet', 'celular'],
    respuesta: r(
      'Sistema responsive',
      'SIP-AIF es completamente responsive. En móvil: el menú lateral se convierte en menú hamburguesa (botón superior izquierdo), las tablas tienen scroll horizontal, los formularios se apilan, los botones de acción se adaptan. En tablet y desktop: layout completo. Los touch targets mínimos son 44px para usabilidad táctil. Soporta safe-area para dispositivos con notch.',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['permisos', 'qué permisos', 'quién puede'],
    respuesta: r(
      'Permisos del sistema',
      'Los permisos dependen del rol. Administrador: todo. Visualizador: solo lectura en módulos de consulta. Carga: solo Cargar Avances en sus proyectos. Cada funcionalidad está restringida según el rol asignado al usuario.',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['impacto', 'qué impacto', 'qué pasa si'],
    respuesta: r(
      'Impacto de las operaciones',
      'Cada operación tiene consecuencias: crear/editar registros los persiste en la base de datos. Reasignar un proyecto cambia su dependencia organizativa. Cargar 100% marca la tarea como Finalizada y puede marcar el proyecto como Finalizado. Los cambios quedan registrados en historiales para auditoría.',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['proceso', 'flujo', 'pasos'],
    respuesta: r(
      'Flujos de proceso',
      'Los procesos típicos: 1) Crear proyecto → asignar Área/Secretaría. 2) Crear tareas → asignar responsable y área/secretaría. 3) Usuario Carga actualiza avances. 4) Al 100% se cierra tarea y posiblemente proyecto. La planificación (Ejes, Planes, Programas, Objetivos) define la estructura estratégica que vincula a los proyectos.',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['secretaría', 'secretarias'],
    respuesta: r(
      'Secretarías',
      'Las secretarías son unidades organizativas alternativas a las Áreas. Se gestionan en el módulo Secretarías (solo Administrador). Los proyectos pueden asignarse a una secretaría (o a áreas, pero no ambas). Las tareas pueden tener área o secretaría. Los usuarios Carga con secretaría asignada solo ven proyectos/tareas de su secretaría. En Avances por Secretaría se agrupan las tareas por secretaría. Puede exportar el reporte con el botón "Exportar reporte".',
      undefined,
      undefined,
      'Secretarías'
    ),
  },
  {
    keywords: ['diferencia área secretaría', 'área vs secretaría', 'cuándo usar área'],
    respuesta: r(
      'Área vs Secretaría',
      'Ambas son unidades organizativas. Un proyecto o tarea tiene una u otra, no ambas. Use Área cuando la estructura se organice por áreas funcionales. Use Secretaría cuando se organice por secretarías. Los usuarios Carga se asignan a un Área o una Secretaría; ven solo los proyectos/tareas de su asignación. En Avances por Área las tareas se agrupan por área; en Avances por Secretaría por secretaría.',
      undefined,
      undefined,
      undefined
    ),
  },

  // ========== ARQUITECTURA Y TECNOLOGÍA ==========
  {
    keywords: ['tecnología', 'stack', 'arquitectura', 'cómo está hecho', 'backend', 'frontend', 'django', 'vue'],
    respuesta: r(
      'Arquitectura del sistema SIP-AIF',
      'SIP-AIF es un sistema full-stack: Backend en Django REST Framework (Python) con PostgreSQL. Frontend en Vue 3 + Vite + TypeScript. Autenticación JWT. API REST en /api/. El frontend usa proxy hacia el backend en desarrollo. Puerto backend: 8001, frontend: 5173.',
      [
        'Backend: Django 4.x, DRF, PostgreSQL, JWT.',
        'Frontend: Vue 3, Vue Router, Axios, Vite.',
        'Base de datos: PostgreSQL (obligatoria).',
      ],
      'URLs: Backend http://127.0.0.1:8001, Frontend http://localhost:5173',
      undefined
    ),
  },
  {
    keywords: ['ejecutar sistema', 'iniciar', 'levantar', 'arrancar', 'ejecutar-sistema-completo', 'bat'],
    respuesta: r(
      'Cómo ejecutar el sistema',
      'Use el archivo ejecutar-sistema-completo.bat en la raíz del proyecto. Este script: 1) Verifica conexión a PostgreSQL y ejecuta migraciones. 2) Carga datos iniciales (roles, usuarios, áreas). 3) Inicia el backend en puerto 8001. 4) Inicia el frontend en puerto 5173. Requiere PostgreSQL corriendo con base "sipra".',
      [
        'PostgreSQL debe estar activo en localhost:5432.',
        'Base de datos: sipra. Usuario: postgres.',
        'No cierre las ventanas de backend y frontend.',
      ],
      'Alternativa: diagnostico-db.bat para verificar la conexión a la BD.',
      undefined
    ),
  },
  {
    keywords: ['credenciales', 'contraseña', 'usuario admin', 'login', 'iniciar sesión', 'acceso'],
    respuesta: r(
      'Credenciales de acceso',
      'Usuarios por defecto: admin@admin.com / admin123, admin@sipra.local / AdminSipra2026!, bogarin1983@gmail.com / Sipra2026. Si no puede ingresar: verifique que el backend esté corriendo (puerto 8001), que PostgreSQL esté activo, y que use la URL correcta del frontend (localhost:5173).',
      [
        'Token inválido o expirado: cierre sesión, borre localStorage o use ventana de incógnito.',
        'Error de conexión: el backend no está corriendo o hay problema de red.',
        'Credenciales incorrectas: verifique email y contraseña (mayúsculas/minúsculas).',
      ],
      undefined,
      undefined
    ),
  },
  {
    keywords: ['token expirado', 'sesión caducada', 'cerrar sesión', 'logout'],
    respuesta: r(
      'Token y sesión',
      'El sistema usa JWT con expiración configurable (por defecto 8 horas). Si aparece "Token inválido o expirado": cierre sesión desde el menú, borre el localStorage del sitio, o abra en ventana de incógnito. El heartbeat de sesión mantiene la sesión activa mientras navega.',
      undefined,
      undefined,
      undefined
    ),
  },

  // ========== BACKUP Y RESTORE ==========
  {
    keywords: ['backup', 'respaldo', 'guardar copia', 'exportar datos'],
    respuesta: r(
      'Backup del sistema',
      'En el módulo Backup y Restore (solo Administrador) puede crear backups de la base de datos PostgreSQL y del código. Hay dos tipos: backup de datos (pg_dump, archivo .sql) y backup de código (copia de archivos del proyecto). Los backups se listan con fecha y puede filtrar por rango de fechas o texto. Use "Crear backup" para generar una copia. Los backups permiten restaurar en caso de fallo.',
      [
        'Backup de datos: exporta la base PostgreSQL completa.',
        'Backup de código: copia los archivos del proyecto.',
        'Puede filtrar la lista por fecha y descargar backups previos.',
      ],
      undefined,
      'Backup y Restore'
    ),
  },
  {
    keywords: ['restore', 'restaurar', 'recuperar', 'restaurar-datos', 'restaurar_sistema_completo'],
    respuesta: r(
      'Restaurar datos',
      'Restaurar sistema completo: ejecute restaurar-datos.bat o el comando "python manage.py restaurar_sistema_completo" desde la carpeta backend. Restaura roles, áreas, secretarías, usuarios bootstrap, planificación 2026, proyectos de ejemplo y tareas. Los usuarios existentes se reactivan. Luego ejecute ejecutar-sistema-completo.bat para iniciar.',
      undefined,
      undefined,
      'Backup y Restore'
    ),
  },

  // ========== COMENTARIOS Y ADJUNTOS ==========
  {
    keywords: ['comentario proyecto', 'comentar proyecto', 'comentarios'],
    respuesta: r(
      'Comentarios en proyectos',
      'En el detalle del proyecto puede agregar comentarios. Los Administradores pueden editar/eliminar cualquier comentario. Los usuarios normales solo pueden editar o eliminar sus propios comentarios dentro de los primeros 15 minutos. Los comentarios quedan registrados para trazabilidad.',
      [
        'Los comentarios son visibles para quienes tienen acceso al proyecto.',
        'Hay auditoría de ediciones y eliminaciones (solo Admin).',
        'Use comentarios para documentar decisiones o avances.',
      ],
      undefined,
      'Proyectos'
    ),
  },
  {
    keywords: ['adjunto', 'archivo', 'subir archivo', 'documento', 'pdf', 'excel'],
    respuesta: r(
      'Adjuntos y archivos',
      'Puede subir archivos a proyectos y tareas. Formatos permitidos: PDF, Word, Excel, PowerPoint, CSV, TXT, imágenes (PNG, JPG, JPEG, WebP). Tamaño máximo configurable (por defecto 10 MB). Los adjuntos se validan por tipo y extensión. Hay auditoría de adjuntos (solo Administrador).',
      [
        'Adjuntos de proyecto: en el detalle del proyecto.',
        'Adjuntos de tarea: en el detalle de la tarea.',
        'Los adjuntos quedan vinculados al proyecto/tarea.',
      ],
      undefined,
      undefined
    ),
  },
  {
    keywords: ['auditoría', 'log', 'historial ediciones', 'quién editó', 'auditoria comentarios'],
    respuesta: r(
      'Auditoría',
      'El sistema registra auditoría de comentarios y adjuntos. Solo el Administrador puede ver el log de auditoría. Muestra: quién editó/eliminó, cuándo, texto anterior y nuevo. Filtros por proyecto, tarea, usuario, tipo y fechas. Acceso desde el menú o módulo correspondiente.',
      undefined,
      undefined,
      'Auditoría'
    ),
  },

  // ========== INDICADORES Y PLANIFICACIÓN ==========
  {
    keywords: ['indicador', 'indicadores proyecto', 'seguimiento indicador'],
    respuesta: r(
      'Indicadores de proyecto',
      'Cada proyecto puede tener indicadores de seguimiento: descripción, unidad de medida y frecuencia. Los indicadores se gestionan en el módulo de Planificación o en el detalle del proyecto. Se vinculan al objetivo estratégico y permiten medir el avance cualitativo del proyecto.',
      [
        'Indicadores: descripción, unidad de medida, frecuencia.',
        'Se asocian a proyectos vinculados a objetivos estratégicos.',
        'Complementan el avance porcentual de las tareas.',
      ],
      undefined,
      'Planificación'
    ),
  },
  {
    keywords: ['objetivo estratégico', 'vincular objetivo', 'objetivo proyecto'],
    respuesta: r(
      'Objetivos estratégicos',
      'Los objetivos estratégicos pertenecen a un programa. Los proyectos se vinculan a un objetivo estratégico al crearlos o editarlos. Esto permite trazabilidad: Eje → Plan → Programa → Objetivo → Proyecto → Indicadores. La planificación 2026 define la estructura completa.',
      undefined,
      undefined,
      'Planificación'
    ),
  },

  // ========== EQUIPO Y ESTRUCTURA ==========
  {
    keywords: ['equipo proyecto', 'miembros equipo', 'asignar equipo', 'proyecto equipo'],
    respuesta: r(
      'Equipo del proyecto',
      'Cada proyecto puede tener un equipo de miembros asignados. Se gestiona en Proyecto Área / Proyecto Equipo o en el formulario del proyecto. Los miembros del equipo participan en el proyecto con permisos limitados. El responsable principal (usuario_responsable) es quien lidera.',
      [
        'Responsable: usuario principal a cargo del proyecto.',
        'Equipo: miembros adicionales que participan.',
        'Áreas asignadas: pueden vincularse varias áreas al proyecto.',
      ],
      undefined,
      'Proyectos'
    ),
  },
  {
    keywords: ['tarea particular', 'tarea sin proyecto', 'tarea administrativa'],
    respuesta: r(
      'Tareas particulares',
      'Las tareas pueden existir sin proyecto (tareas particulares o administrativas). Se asignan a un responsable y área/secretaría. Aparecen en el Dashboard del usuario en la sección "Tareas particulares". Se gestionan igual que las tareas de proyecto pero sin vinculación a un proyecto.',
      [
        'Útiles para tareas administrativas o de soporte.',
        'El avance de tareas particulares no impacta proyectos.',
        'Se cuentan por separado en el Dashboard ejecutivo.',
      ],
      undefined,
      'Tareas'
    ),
  },
  {
    keywords: ['etapa', 'etapas proyecto', 'fases'],
    respuesta: r(
      'Etapas del proyecto',
      'Cada proyecto tiene etapas (fases). Las tareas se asignan a una etapa. Las etapas tienen orden y porcentaje de avance. Al crear un proyecto puede crear etapas. Las tareas se organizan por etapa para estructurar el trabajo.',
      undefined,
      undefined,
      'Proyectos'
    ),
  },

  // ========== DASHBOARD EJECUTIVO Y ALERTAS ==========
  {
    keywords: ['dashboard ejecutivo', 'vista ejecutivo', 'métricas admin'],
    respuesta: r(
      'Dashboard ejecutivo',
      'Solo el Administrador ve el Dashboard ejecutivo completo. Muestra: total proyectos, proyectos activos, total tareas, tareas finalizadas, bloqueadas, tareas particulares, avance global, avance de tareas particulares, gráficos (proyectos por estado, por dependencia, tendencia de avance, vencimientos), proyectos en riesgo y tareas críticas. Los Visualizadores ven un Dashboard de solo lectura. Los Carga ven solo sus proyectos asignados.',
      undefined,
      undefined,
      'Dashboard'
    ),
  },
  {
    keywords: ['proyectos en riesgo', 'proyectos atrasados', 'riesgo'],
    respuesta: r(
      'Proyectos en riesgo',
      'El Dashboard muestra proyectos en riesgo: aquellos atrasados (fecha fin estimada vencida) o con tareas bloqueadas. Incluye: nombre, estado, responsable, secretaría, fecha fin, avance, tareas bloqueadas y días de atraso. Solo el Administrador ve esta sección completa. Útil para priorizar seguimiento.',
      [
        'Proyectos atrasados: fecha_fin_estimada ya pasada.',
        'Tareas bloqueadas: requieren atención.',
        'Clic en "Ver todos" para ir al listado filtrado.',
      ],
      undefined,
      'Dashboard'
    ),
  },
  {
    keywords: ['estado tarea', 'tarea activa', 'tarea bloqueada', 'tarea finalizada'],
    respuesta: r(
      'Estados de tarea',
      'Las tareas tienen estados: Activa (en curso), Finalizada (100% de avance, se marca automáticamente), Bloqueada (requiere atención). En el módulo Tareas puede filtrar por estado con los botones/pills. Las tareas bloqueadas se cuentan en el Dashboard. Al cargar 100% la tarea pasa a Finalizada.',
      undefined,
      undefined,
      'Tareas'
    ),
  },
  {
    keywords: ['alerta vencimiento', 'vencimiento', 'tarea vencida', 'próxima a vencer'],
    respuesta: r(
      'Alertas de vencimiento',
      'El sistema puede mostrar alertas de tareas y proyectos próximos a vencer o vencidos. Las tareas tienen fecha_vencimiento y los proyectos fecha_fin_estimada. Las alertas excluyen tareas Finalizadas y proyectos Finalizados. Solo Administrador y Visualizador ven las alertas.',
      [
        'Tareas: por fecha_vencimiento.',
        'Proyectos: por fecha_fin_estimada.',
        'Use el calendario para ver fechas de vencimiento.',
      ],
      undefined,
      'Dashboard'
    ),
  },
  {
    keywords: ['calendario', 'fechas', 'ver fechas'],
    respuesta: r(
      'Calendario',
      'El módulo Calendario muestra las tareas y proyectos en vista mensual. Puede alternar entre vista de tareas y vista de proyectos. Cada celda muestra los eventos del día. Al hacer clic en un día se abre un modal con el detalle de tareas o proyectos. Las fechas se toman de inicio y vencimiento. Permite visualizar la carga de trabajo y detectar vencimientos próximos. Todos los roles con acceso (Admin, Visualizador, Carga) ven el calendario según sus permisos.',
      [
        'Vista tareas: muestra tareas por fecha de vencimiento.',
        'Vista proyectos: muestra proyectos por fechas.',
        'Clic en el día: abre modal con detalle.',
      ],
      undefined,
      'Calendario'
    ),
  },

  // ========== EVOLUCIÓN Y GRÁFICAS ==========
  {
    keywords: ['evolución', 'gráfica', 'gráfico avance', 'serie temporal'],
    respuesta: r(
      'Evolución del proyecto',
      'En el detalle del proyecto puede ver la evolución temporal del avance: una serie de puntos (fecha, porcentaje) que muestra cómo ha ido avanzando el proyecto en el tiempo. Se calcula a partir del historial de avances de las tareas.',
      undefined,
      undefined,
      'Proyectos'
    ),
  },

  // ========== PRODUCCIÓN Y DESPLIEGUE ==========
  {
    keywords: ['producción', 'desplegar', 'deploy', 'poner en producción'],
    respuesta: r(
      'Despliegue en producción',
      'Para producción: 1) Use Gunicorn u otro servidor WSGI (no runserver). 2) Configure variables de entorno: SECRET_KEY, ALLOWED_HOSTS, credenciales PostgreSQL. 3) Use HTTPS (Nginx/Caddy con Let\'s Encrypt). 4) No ponga credenciales en archivos .bat. 5) Consulte DEPLOY_DEMO.md para opciones (VPS, Render, Railway).',
      [
        'DEBUG=0 en producción.',
        'SECRET_KEY y ALLOWED_HOSTS obligatorios.',
        'PostgreSQL en servidor dedicado o gestionado.',
      ],
      undefined,
      undefined
    ),
  },
  {
    keywords: ['variables entorno', 'configuración', 'env', 'postgres'],
    respuesta: r(
      'Variables de entorno',
      'Variables clave: SECRET_KEY (obligatoria en prod), DEBUG (0 en prod), ALLOWED_HOSTS (dominios permitidos), POSTGRES_DB_HOST, POSTGRES_DB_PORT, POSTGRES_DB_NAME, POSTGRES_DB_USER, POSTGRES_DB_PASSWORD. Use archivo .env en la raíz (no subir al repositorio).',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['migración', 'migrate', 'migraciones', 'actualizar base datos'],
    respuesta: r(
      'Migraciones de base de datos',
      'Las migraciones se ejecutan con: python manage.py migrate (desde la carpeta backend). El script ejecutar-sistema-completo.bat ya las ejecuta. Si hay cambios en modelos, cree migraciones con: python manage.py makemigrations. Luego migrate para aplicarlas.',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['docker', 'contenedor', 'docker compose'],
    respuesta: r(
      'Ejecutar con Docker',
      'Para producción con Docker: use docker compose up -d --build desde la raíz. Consulte DOCKER.md para la guía completa. El docker-compose.yml define PostgreSQL, backend y frontend. Variables de entorno: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, DATABASE_URL, etc. Para desarrollo local use ejecutar-sistema-completo.bat.',
      [
        'Docker requiere Docker y Docker Compose instalados.',
        'docker-compose.produccion.yml para entorno de producción.',
        'Los backups pueden guardarse en volumen montado.',
      ],
      undefined,
      undefined
    ),
  },
  {
    keywords: ['scroll', 'volver arriba', 'botón inicio'],
    respuesta: r(
      'Botón volver al inicio',
      'Cuando hace scroll hacia abajo, aparece un botón flotante en la esquina inferior derecha (arriba del asistente) para volver al inicio de la página. Al hacer clic, hace scroll suave hacia arriba. Útil en páginas largas como Dashboard o listados.',
      undefined,
      undefined,
      undefined
    ),
  },

  // ========== ERRORES Y SOLUCIÓN ==========
  {
    keywords: ['error', 'no funciona', 'falla', 'problema', 'no puedo'],
    respuesta: r(
      'Solución de problemas',
      'Errores comunes: 1) No puedo ingresar: verifique backend en 8001, PostgreSQL activo, credenciales correctas. 2) Token expirado: cierre sesión, borre localStorage. 3) Error de conexión: backend no está corriendo. 4) Error de BD: ejecute diagnostico-db.bat. 5) Credenciales en .bat: use .env para no exponer contraseñas.',
      [
        'diagnostico-db.bat: verifica conexión a PostgreSQL.',
        'restaurar-datos.bat: restaura datos iniciales.',
        'ejecutar-sistema-completo.bat: inicia todo el sistema.',
      ],
      undefined,
      undefined
    ),
  },
  {
    keywords: ['sip-aif', 'qué es sip-aif', 'sistema integral proyectos', 'sistema planificación'],
    respuesta: r(
      'SIP-AIF',
      'SIP-AIF es el Sistema Integral de Proyectos. Permite gestionar proyectos, tareas, avances, áreas, secretarías, usuarios y roles. Incluye planificación estratégica (ejes, planes, programas, objetivos), dashboards, alertas de vencimiento, backup/restore y auditoría. Desarrollado para la Agencia de Innovación.',
      undefined,
      undefined,
      undefined
    ),
  },
]

/** Obtener sugerencias de preguntas según la ruta actual */
export function obtenerSugerenciasPorRuta(ruta: string): string[] {
  const sugerencias: Record<string, string[]> = {
    '/dashboard': [
      '¿Qué información muestra el Dashboard?',
      '¿Qué son los proyectos en riesgo?',
      '¿Cómo se interpretan los indicadores?',
      '¿Qué es el Dashboard ejecutivo?',
    ],
    '/avances-por-area': [
      '¿Cómo se visualizan los avances por área?',
      '¿Qué pasa cuando un proyecto llega al 100%?',
      '¿Cómo exportar el reporte de avances?',
      '¿Cómo se interpreta el historial de avances?',
    ],
    '/avances-por-secretaria': [
      '¿Cómo se agrupan las tareas por secretaría?',
      '¿Cómo exportar el reporte?',
      '¿Cómo funcionan los filtros?',
    ],
    '/planificacion': [
      '¿Cómo se crean Ejes, Planes y Programas?',
      '¿Cómo se vinculan los objetivos a proyectos?',
      '¿Qué son los indicadores de proyecto?',
    ],
    '/proyectos': [
      '¿Cómo crear un proyecto?',
      '¿Cómo reasignar un proyecto?',
      '¿Cómo exportar a Excel?',
      '¿Qué es la dependencia organizacional?',
    ],
    '/tareas': [
      '¿Cómo crear una tarea?',
      '¿Qué es la prioridad de una tarea?',
      '¿Cómo se actualiza el avance?',
      '¿Qué son las tareas particulares?',
    ],
    '/areas': [
      '¿Cómo crear o editar un área?',
      '¿Cómo impactan las áreas en el sistema?',
    ],
    '/secretarias': [
      '¿Cómo crear una secretaría?',
      '¿Cuál es la diferencia entre Área y Secretaría?',
    ],
    '/usuarios': [
      '¿Cómo crear un usuario?',
      '¿Cómo asignar rol y área?',
      '¿Cómo funcionan los permisos?',
    ],
    '/roles': [
      '¿Cuáles son las diferencias entre los roles?',
      '¿Qué puede hacer cada perfil?',
    ],
    '/cargar': [
      '¿Cómo actualizar el avance de una tarea?',
      '¿Qué pasa al cargar 100%?',
      '¿Dónde veo solo mis tareas?',
    ],
    '/backup-restore': [
      '¿Cómo hacer backup del sistema?',
      '¿Cómo restaurar los datos?',
      '¿Qué tipos de backup hay?',
    ],
    '/calendario': [
      '¿Qué muestra el calendario?',
      '¿Cómo ver tareas y proyectos por fecha?',
      '¿Cómo ver las alertas de vencimiento?',
    ],
    '/auditoria-comentarios': [
      '¿Qué registra la auditoría?',
      '¿Quién puede ver el log de auditoría?',
      '¿Cómo filtrar por proyecto o tarea?',
    ],
  }
  for (const [path, preguntas] of Object.entries(sugerencias)) {
    if (ruta.startsWith(path)) return preguntas
  }
  return [
    '¿Qué es SIP-AIF?',
    '¿Cómo ejecutar el sistema?',
    '¿Cuáles son las credenciales de acceso?',
    '¿Cómo crear un proyecto?',
    '¿Cuáles son las diferencias entre roles?',
  ]
}

/** Buscar respuesta según la pregunta del usuario */
export function buscarRespuesta(pregunta: string): RespuestaChatbot | null {
  const texto = normalizar(pregunta)
  if (!texto || texto.length < 2) return null

  const palabras = texto.split(/\s+/).filter((p) => p.length > 1)
  let mejorMatch: { entrada: EntradaConocimiento; score: number } | null = null

  for (const entrada of entradasConocimiento) {
    let score = 0
    for (const kw of entrada.keywords) {
      const kwNorm = normalizar(kw)
      if (texto.includes(kwNorm)) score += 2
      for (const p of palabras) {
        if (kwNorm.includes(p) || p.includes(kwNorm)) score += 1
      }
    }
    if (score > 0 && (!mejorMatch || score > mejorMatch.score)) {
      mejorMatch = { entrada, score }
    }
  }

  return mejorMatch && mejorMatch.score >= 2 ? mejorMatch.entrada.respuesta : null
}
