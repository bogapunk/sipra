/** Ayuda contextual por ruta para el asistente del sistema */
export interface AyudaSeccion {
  titulo: string
  descripcion: string
  pasos?: string[]
  consejos?: string[]
}

export const ayudaPorRuta: Record<string, AyudaSeccion> = {
  '/dashboard': {
    titulo: 'Dashboard',
    descripcion: 'Vista general del sistema con resumen de proyectos y avances. Muestra tarjetas con métricas clave y lista de proyectos.',
    pasos: [
      'Revise las tarjetas superiores para el estado global.',
      'Haga clic en un proyecto para ver su detalle.',
      'Use "Reasignar" para cambiar áreas o responsables del proyecto.',
    ],
    consejos: ['El avance por proyecto se calcula automáticamente desde las tareas asociadas.'],
  },
  '/proyectos': {
    titulo: 'Proyectos',
    descripcion: 'Gestión de proyectos. Cree proyectos asignándolos a un Área o Secretaría. La columna "Dependencia organizacional" muestra si cada proyecto pertenece a un Área o Secretaría.',
    pasos: [
      'Use "Nuevo proyecto". Elija tipo de dependencia (Área o Secretaría) y seleccione del listado.',
      'Complete nombre, fechas, descripción y responsable.',
      'Use "Reasignar" desde el detalle para cambiar la asignación.',
    ],
    consejos: ['Solo puede elegir Área o Secretaría, no ambos. La dependencia define la estructura organizativa.'],
  },
  '/tareas': {
    titulo: 'Tareas',
    descripcion: 'Administración de tareas. Pueden vincularse a un proyecto (estratégicas) o ser independientes (administrativas). Vinculación organizacional: Área, Secretaría o ninguna.',
    pasos: [
      'Seleccione "Área" o "Secretaría" al crear una tarea. Solo una opción.',
      'Elija el proyecto, responsable y fechas de inicio y vencimiento.',
      'El avance se actualiza desde "Cargar Avances" (rol Carga).',
    ],
    consejos: ['El responsable de la tarea puede cargar avances desde su panel.'],
  },
  '/areas': {
    titulo: 'Áreas',
    descripcion: 'Catálogo de áreas organizacionales. Las áreas se usan para vincular tareas y usuarios.',
    pasos: [
      'Cree áreas con "Nueva área". Use nombres descriptivos.',
      'Las áreas inactivas no aparecen en selectores de nuevas tareas.',
      'Use "Editar" para modificar o desactivar.',
    ],
    consejos: ['Mantenga solo las áreas activas que se utilizan actualmente.'],
  },
  '/secretarias': {
    titulo: 'Secretarías',
    descripcion: 'Catálogo de secretarías. Las secretarías organizan proyectos y tareas por dependencia.',
    pasos: [
      'Revise las secretarías cargadas inicialmente.',
      'Use "Nueva Secretaría" para agregar. Código y nombre son obligatorios.',
      'Desactive en lugar de eliminar para mantener historial.',
    ],
    consejos: ['Use "Ver proyectos" para listar proyectos vinculados a cada secretaría.'],
  },
  '/usuarios': {
    titulo: 'Usuarios',
    descripcion: 'Gestión de usuarios del sistema. Asigne roles y, para Carga, un Área o Secretaría obligatoria.',
    pasos: [
      'Rol Administrador: acceso completo, sin restricción de área.',
      'Rol Carga: debe asignar Área o Secretaría. El usuario solo verá información de su asignación.',
      'Rol Visualización: solo lectura en Dashboard, Avances, Proyectos y Tareas.',
    ],
    consejos: ['Para Carga, la asignación Área/Secretaría determina qué proyectos y tareas puede ver.'],
  },
  '/roles': {
    titulo: 'Roles',
    descripcion: 'Definición de roles del sistema. Los roles controlan permisos y acceso a cada módulo.',
    pasos: [
      'Administrador: ABM completo en todos los módulos.',
      'Visualización: solo lectura en Dashboard, Avances, Proyectos, Tareas.',
      'Carga: carga de avances y vista de proyectos asignados.',
    ],
    consejos: ['No modifique los roles si ya hay usuarios asignados sin verificar impacto.'],
  },
  '/avances-por-area': {
    titulo: 'Avances por área',
    descripcion: 'Vista ejecutiva de avances agrupados por área. Muestra el avance actual y el último incremento de cada tarea.',
    pasos: [
      'Las tareas se agrupan por área. Haga clic en una tarjeta para ver el historial.',
      'El "último incremento" indica cuánto se avanzó en la última actualización.',
      'La barra de progreso refleja el porcentaje actual de avance.',
    ],
    consejos: ['Ideal para seguimiento por área organizacional.'],
  },
  '/avances-por-secretaria': {
    titulo: 'Avances por secretaría',
    descripcion: 'Vista ejecutiva de avances agrupados por secretaría. Solo incluye tareas vinculadas a una secretaría.',
    pasos: [
      'Las tareas se agrupan por secretaría. Haga clic en una tarjeta para ver el historial.',
      'Solo aparecen tareas que tienen secretaría asignada.',
      'Mismo formato visual que Avances por área para coherencia.',
    ],
    consejos: ['Asigne secretaría a las tareas desde el módulo Tareas para que aparezcan aquí.'],
  },
  '/planificacion': {
    titulo: 'Planificación',
    descripcion: 'Estructura jerárquica: Ejes → Planes → Programas → Objetivos → Proyectos → Indicadores.',
    pasos: [
      'Navegue por las pestañas (Ejes, Planes, Programas, Objetivos, Indicadores).',
      'Cree y edite elementos según la jerarquía.',
      'Vincule proyectos a objetivos estratégicos.',
    ],
    consejos: ['La estructura define la alineación estratégica de los proyectos.'],
  },
  '/cargar': {
    titulo: 'Cargar Avances',
    descripcion: 'Módulo para usuarios con rol Carga. Actualice el porcentaje de avance de tareas. Use el buscador por proyecto para filtrar. Al cargar 100%, la tarea se marca como Finalizada.',
    pasos: [
      'Use el buscador para filtrar por nombre de proyecto.',
      'Seleccione una tarea y haga clic en "Actualizar avance".',
      'Ingrese el porcentaje (0-100) y opcionalmente un comentario.',
      'Al guardar 100%, la tarea se marca Finalizada. Si todas las tareas del proyecto llegan al 100%, el proyecto se marca Finalizado.',
    ],
    consejos: ['El historial registra cada actualización. Los registros de cierre (100%) se destacan en verde.'],
  },
}

export function obtenerAyuda(ruta: string): AyudaSeccion | null {
  const rutaBase = ruta.split('/').filter(Boolean)[0] ? `/${ruta.split('/').filter(Boolean)[0]}` : '/'
  if (ruta.startsWith('/proyectos/') && !ruta.includes('/reasignar')) {
    return {
      titulo: 'Detalle de proyecto',
      descripcion: 'Vista detallada del proyecto con etapas, avance y gráfica de evolución.',
      pasos: [
        'Agregue etapas para desglosar el proyecto.',
        'El avance se calcula desde las tareas asociadas.',
        'Use "Reasignar" para cambiar áreas o responsables.',
      ],
    }
  }
  if (ruta.includes('/reasignar')) {
    return {
      titulo: 'Reasignar proyecto',
      descripcion: 'Asigne el proyecto a un Área o una Secretaría. Elija el tipo de destino y seleccione del listado correspondiente. Indique el motivo (opcional).',
      pasos: [
        'Seleccione "Área" o "Secretaría" como tipo de destino.',
        'Si Área: marque las áreas que participan (puede ser más de una).',
        'Si Secretaría: elija una secretaría del selector.',
        'Indique el motivo y guarde. La reasignación queda registrada.',
      ],
    }
  }
  return ayudaPorRuta[ruta] || ayudaPorRuta[rutaBase] || null
}
