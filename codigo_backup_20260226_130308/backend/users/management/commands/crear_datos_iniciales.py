from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from users.models import Rol, Usuario
from areas.models import Area
from projects.models import Proyecto, Etapa
from tasks.models import Tarea, HistorialTarea


class Command(BaseCommand):
    help = 'Crea roles, usuario admin y áreas iniciales'

    def handle(self, *args, **options):
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

        Usuario.objects.get_or_create(
            email='admin@admin.com',
            defaults={
                'nombre': 'Admin',
                'apellido': 'Sistema',
                'password': 'admin123',
                'rol': admin_rol,
                'estado': True,
            }
        )
        areas_data = ['Presidencia', 'Desarrollo', 'Infraestructura', 'Comunicación', 'Recursos Humanos']
        areas_objs = []
        for nombre in areas_data:
            a, _ = Area.objects.get_or_create(nombre=nombre, defaults={'estado': True})
            areas_objs.append(a)

        area_presidencia = areas_objs[0] if areas_objs else None  # Presidencia es primera
        area_desarrollo = areas_objs[1] if len(areas_objs) > 1 else None

        vis_user, vis_created = Usuario.objects.get_or_create(
            email='visualizador@test.com',
            defaults={
                'nombre': 'Usuario',
                'apellido': 'Visualizador',
                'password': 'vis123',
                'rol': vis_rol,
                'area': area_presidencia,
                'estado': True,
            }
        )
        if not vis_created and area_presidencia:
            vis_user.area = area_presidencia
            vis_user.save(update_fields=['area'])

        Usuario.objects.get_or_create(
            email='carga@test.com',
            defaults={
                'nombre': 'Usuario',
                'apellido': 'Carga',
                'password': 'carga123',
                'rol': carga_rol,
                'area': area_desarrollo,
                'estado': True,
            }
        )

        # Crear proyectos de ejemplo si no existen
        admin_user = Usuario.objects.filter(email='admin@admin.com').first()
        carga_user = Usuario.objects.filter(email='carga@test.com').first()
        creador = admin_user or Usuario.objects.first()
        responsable = carga_user or Usuario.objects.first()
        if not creador:
            self.stdout.write(self.style.WARNING('No hay usuarios. Saltando creación de proyectos.'))
        else:
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

        self.stdout.write(self.style.SUCCESS('Datos iniciales creados correctamente.'))
