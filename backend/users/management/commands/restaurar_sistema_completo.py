"""
Restaura todos los datos del sistema a su estado inicial completo:
- Roles, áreas, secretarías
- Usuarios bootstrap configurados por entorno
- Planificación 2026 (ejes, planes, programas, objetivos)
- Proyectos de ejemplo con tareas e historial
- Reactiva usuarios desactivados
"""
import os
from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.utils import timezone
from datetime import timedelta
from users.models import Rol, Usuario
from areas.models import Area
from projects.models import Proyecto, Etapa
from tasks.models import Tarea, HistorialTarea


class Command(BaseCommand):
    help = 'Restaura el sistema completo: roles, áreas, secretarías, usuarios, planificación 2026, proyectos y tareas'

    def _env(self, name, default=''):
        return (os.environ.get(name, default) or default).strip()

    def add_arguments(self, parser):
        parser.add_argument(
            '--forzar',
            action='store_true',
            help='Recrear datos incluso si ya existen (puede duplicar)',
        )

    def handle(self, *args, **options):
        forzar = options.get('forzar', False)

        self.stdout.write('Iniciando restauración completa del sistema...')

        # 1. Reactivar usuarios desactivados
        reactivados = Usuario.objects.filter(estado=False).update(estado=True)
        if reactivados:
            self.stdout.write(self.style.SUCCESS(f'  [OK] Reactivados {reactivados} usuario(s)'))

        # 2. Cargar planificación 2026 (ejes, planes, programas, objetivos)
        call_command('cargar_planificacion_2026')
        self.stdout.write(self.style.SUCCESS('  [OK] Planificacion 2026 cargada'))

        # 3. Cargar secretarías
        call_command('cargar_secretarias')
        self.stdout.write(self.style.SUCCESS('  [OK] Secretarias cargadas'))

        # 4. Crear roles
        roles_data = [
            ('Administrador', 'Acceso total al sistema'),
            ('Carga', 'Puede crear y editar proyectos y tareas'),
            ('Visualización', 'Solo lectura'),
        ]
        for nombre, desc in roles_data:
            Rol.objects.get_or_create(nombre=nombre, defaults={'descripcion': desc})
        admin_rol = Rol.objects.get(nombre='Administrador')
        carga_rol = Rol.objects.get(nombre='Carga')
        vis_rol = Rol.objects.get(nombre='Visualización')
        self.stdout.write(self.style.SUCCESS('  [OK] Roles creados'))

        # 5. Crear áreas
        areas_data = ['Presidencia', 'Desarrollo', 'Infraestructura', 'Comunicación', 'Recursos Humanos']
        areas_objs = []
        for nombre in areas_data:
            a, _ = Area.objects.get_or_create(nombre=nombre, defaults={'estado': True})
            areas_objs.append(a)
        area_presidencia = areas_objs[0] if areas_objs else None
        area_desarrollo = areas_objs[1] if len(areas_objs) > 1 else None
        self.stdout.write(self.style.SUCCESS('  [OK] Areas creadas'))

        # 6. Crear usuarios bootstrap configurados en .env
        call_command('crear_datos_iniciales')
        admin_email = self._env('BOOTSTRAP_ADMIN_EMAIL', 'admin@sipra.local').lower()
        carga_email = self._env('BOOTSTRAP_CARGA_EMAIL', 'gestion.proyectos@sipra.local').lower()
        self.stdout.write(self.style.SUCCESS('  [OK] Usuarios creados'))

        # 7. Crear proyectos y tareas
        admin_user = Usuario.objects.filter(email=admin_email).first()
        carga_user = Usuario.objects.filter(email=carga_email).first()
        creador = admin_user or Usuario.objects.first()
        responsable = carga_user or Usuario.objects.first()

        if creador:
            hoy = timezone.now().date()
            proyectos_ejemplo = [
                ('Sistema de Planificación', 'Sistema de seguimiento de proyectos y tareas'),
                ('Portal Web Corporativo', 'Desarrollo del portal web institucional'),
                ('Modernización de Infraestructura', 'Actualización de servidores y redes'),
            ]
            for nombre_proy, desc in proyectos_ejemplo:
                proy, created = Proyecto.objects.get_or_create(
                    nombre=nombre_proy,
                    defaults={
                        'descripcion': desc,
                        'fecha_inicio': hoy - timedelta(days=60),
                        'fecha_fin_estimada': hoy + timedelta(days=90),
                        'estado': 'Activo',
                        'creado_por': creador,
                        'area': area_desarrollo,
                    }
                )
                if created:
                    etapa, _ = Etapa.objects.get_or_create(
                        proyecto=proy,
                        nombre='Etapa principal',
                        defaults={'orden': 1}
                    )
                    for i, (titulo, area) in enumerate([
                        ('Análisis de requisitos', areas_objs[0]),
                        ('Diseño técnico', areas_objs[0]),
                        ('Implementación', areas_objs[0]),
                        ('Integración', areas_objs[1]),
                    ]):
                        tarea, _ = Tarea.objects.get_or_create(
                            proyecto=proy,
                            titulo=f'{titulo} - {proy.nombre[:20]}',
                            defaults={
                                'area': area,
                                'etapa': etapa,
                                'responsable': responsable,
                                'fecha_inicio': hoy - timedelta(days=30),
                                'fecha_vencimiento': hoy + timedelta(days=30),
                                'estado': 'En proceso' if i < 2 else 'Pendiente',
                                'porcentaje_avance': (i + 1) * 20,
                            }
                        )
                        HistorialTarea.objects.get_or_create(
                            tarea=tarea,
                            porcentaje_avance=tarea.porcentaje_avance,
                            defaults={
                                'usuario': tarea.responsable,
                                'comentario': 'Avance inicial',
                            }
                        )

            # Tarea particular (sin proyecto) para pruebas
            Tarea.objects.get_or_create(
                titulo='Tarea particular de seguimiento',
                proyecto=None,
                defaults={
                    'area': area_desarrollo,
                    'responsable': responsable,
                    'fecha_inicio': hoy,
                    'fecha_vencimiento': hoy + timedelta(days=30),
                    'estado': 'Pendiente',
                    'porcentaje_avance': 0,
                }
            )

            self.stdout.write(self.style.SUCCESS('  [OK] Proyectos y tareas creados'))

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=== Restauracion completada ==='))
        self.stdout.write('')
        self.stdout.write('Usuarios disponibles:')
        self.stdout.write(f'  - Admin: {self._env("BOOTSTRAP_ADMIN_EMAIL", "admin@sipra.local")}')
        self.stdout.write(f'  - Visualización: {self._env("BOOTSTRAP_VISUALIZADOR_EMAIL", "visualizacion@sipra.local")}')
        self.stdout.write(f'  - Carga: {self._env("BOOTSTRAP_CARGA_EMAIL", "gestion.proyectos@sipra.local")}')
        self.stdout.write('  - Las contraseñas se toman desde el archivo .env o variables de entorno.')
        self.stdout.write('')
        self.stdout.write('Reinicie el servidor si está en ejecución.')
