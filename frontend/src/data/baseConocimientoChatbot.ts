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
      'El Dashboard muestra una vista general del sistema con: tarjetas de métricas (total proyectos, activos, tareas, finalizadas, bloqueadas, avance global), lista de proyectos con avance y barra de progreso, y acceso rápido al detalle y reasignación.',
      [
        'Las tarjetas superiores muestran el estado global del sistema.',
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
      'El Dashboard muestra todos los proyectos visibles según su rol. Los administradores ven todo. Los visualizadores ven según restricciones. Use el buscador si está disponible para filtrar por nombre.',
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
    keywords: ['crear plan', 'crear programa', 'crear objetivo', 'vincular planificación'],
    respuesta: r(
      'Crear elementos de planificación',
      'Desde la pestaña correspondiente (Planes, Programas, Objetivos), use el botón de crear. Complete los campos obligatorios. Los elementos se vinculan en cascada: Eje → Plan → Programa → Objetivo. Los proyectos se asocian a un objetivo estratégico al crearlos o editarlos.',
      [
        'Respetar la jerarquía: no puede crear un programa sin plan.',
        'La planificación impacta en la trazabilidad estratégica de los proyectos.',
        'Los indicadores se asocian a cada proyecto.',
      ],
      undefined,
      'Planificación'
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
      'Activo: en ejecución. En pausa: temporalmente detenido. Finalizado: completado (se marca automáticamente cuando todas las tareas llegan al 100%). Puede actualizar el estado manualmente al editar el proyecto.',
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
      'Administrador: ABM completo en todos los módulos. Visualizador: solo lectura en Dashboard, Avances por área, Planificación, Proyectos, Tareas; no ve Áreas, Secretarías, Usuarios, Roles ni Cargar Avances. Carga: solo Cargar Avances y Dashboard (sus proyectos); no ve el resto.',
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
      'Solo lectura. Ve: Dashboard, Avances por área, Planificación, Proyectos, Tareas. No ve: Secretarías, Áreas, Usuarios, Roles, Cargar Avances, Avances por secretaría. No puede crear, editar ni eliminar. Ideal para consulta y reportes.',
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
      'Descargar Excel',
      'Exporta la lista visible (o filtrada) a un archivo CSV/Excel. Incluye las columnas principales del módulo. Útil para reportes externos o análisis en hoja de cálculo.',
      undefined,
      undefined,
      undefined
    ),
  },
  {
    keywords: ['buscar', 'buscador', 'filtrar'],
    respuesta: r(
      'Buscadores y filtros',
      'La mayoría de módulos tienen buscador por nombre o filtros por estado. Escriba en el campo de búsqueda para filtrar en tiempo real. En Cargar Avances hay buscador por proyecto.',
      undefined,
      undefined,
      undefined
    ),
  },

  // ========== GENÉRICOS ==========
  {
    keywords: ['ayuda', 'cómo funciona', 'qué es esto', 'no entiendo'],
    respuesta: r(
      'Asistente del sistema',
      'Soy el asistente del Sistema de Seguimiento de Proyectos. Puede preguntarme sobre cualquier módulo: Dashboard, Proyectos, Tareas, Áreas, Secretarías, Usuarios, Roles, Avances, Planificación. Escriba su pregunta en lenguaje natural, por ejemplo: "¿Cómo reasigno un proyecto?" o "¿Qué hace el rol Carga?"',
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
      'Las secretarías son unidades organizativas. Se gestionan en el módulo Secretarías. Los proyectos pueden asignarse a una secretaría. Las tareas pueden tener área o secretaría. Los usuarios Carga con secretaría asignada solo ven proyectos/tareas de su secretaría. En Avances por Secretaría se agrupan las tareas por secretaría.',
      undefined,
      undefined,
      'Secretarías'
    ),
  },
]

/** Obtener sugerencias de preguntas según la ruta actual */
export function obtenerSugerenciasPorRuta(ruta: string): string[] {
  const sugerencias: Record<string, string[]> = {
    '/dashboard': [
      '¿Qué información muestra el Dashboard?',
      '¿Cómo se interpretan los indicadores?',
      '¿Qué significan los estados?',
    ],
    '/avances-por-area': [
      '¿Cómo se visualizan los proyectos por área?',
      '¿Qué pasa cuando un proyecto llega al 100%?',
      '¿Cómo se interpreta el historial de avances?',
    ],
    '/avances-por-secretaria': [
      '¿Cómo se agrupan los proyectos por secretaría?',
      '¿Cómo funcionan los filtros?',
    ],
    '/planificacion': [
      '¿Cómo se crean Planes y Programas?',
      '¿Cómo se vinculan los objetivos a proyectos?',
    ],
    '/proyectos': [
      '¿Cómo crear un proyecto?',
      '¿Cómo reasignar un proyecto?',
      '¿Qué significa cada estado?',
    ],
    '/tareas': [
      '¿Cómo crear una tarea?',
      '¿Cómo se actualiza el avance?',
      '¿Cómo se cierra una tarea?',
    ],
    '/areas': [
      '¿Cómo crear o editar un área?',
      '¿Cómo impactan las áreas en el sistema?',
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
    ],
  }
  for (const [path, preguntas] of Object.entries(sugerencias)) {
    if (ruta.startsWith(path)) return preguntas
  }
  return [
    '¿Qué hace el Dashboard?',
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
