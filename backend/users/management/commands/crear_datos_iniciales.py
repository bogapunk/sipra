import os
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.contrib.auth.hashers import make_password, identify_hasher
from datetime import timedelta
from users.models import Rol, Usuario
from areas.models import Area
from projects.models import Proyecto, Etapa
from tasks.models import Tarea, HistorialTarea


class Command(BaseCommand):
    help = 'Crea roles, usuario admin y áreas iniciales'

    def _env(self, name, default=''):
        return (os.environ.get(name, default) or default).strip()

    def _password_is_hashed(self, value):
        try:
            identify_hasher(value)
            return True
        except Exception:
            return False

    def _ensure_bootstrap_user(
        self,
        *,
        email,
        password,
        nombre,
        apellido,
        rol,
        area=None,
        secretaria=None,
    ):
        user, created = Usuario.objects.get_or_create(
            email=email,
            defaults={
                'nombre': nombre,
                'apellido': apellido,
                'password': make_password(password),
                'rol': rol,
                'area': area,
                'secretaria': secretaria,
                'estado': True,
            }
        )
        fields_to_update = []
        if user.nombre != nombre:
            user.nombre = nombre
            fields_to_update.append('nombre')
        if (user.apellido or '') != (apellido or ''):
            user.apellido = apellido
            fields_to_update.append('apellido')
        if user.rol_id != rol.id:
            user.rol = rol
            fields_to_update.append('rol')
        if user.area_id != getattr(area, 'id', None):
            user.area = area
            fields_to_update.append('area')
        if user.secretaria_id != getattr(secretaria, 'id', None):
            user.secretaria = secretaria
            fields_to_update.append('secretaria')
        if not user.estado:
            user.estado = True
            fields_to_update.append('estado')
        if not self._password_is_hashed(user.password):
            user.password = make_password(password)
            fields_to_update.append('password')
        if fields_to_update:
            user.save(update_fields=fields_to_update)
        return user, created

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

        admin_user, _ = self._ensure_bootstrap_user(
            email=self._env('BOOTSTRAP_ADMIN_EMAIL', 'admin@sipra.local').lower(),
            password=self._env('BOOTSTRAP_ADMIN_PASSWORD', 'AdminSipra2026!'),
            nombre=self._env('BOOTSTRAP_ADMIN_NOMBRE', 'Administrador'),
            apellido=self._env('BOOTSTRAP_ADMIN_APELLIDO', 'SIPRA'),
            rol=admin_rol,
        )
        vis_user, _ = self._ensure_bootstrap_user(
            email=self._env('BOOTSTRAP_VISUALIZADOR_EMAIL', 'visualizacion@sipra.local').lower(),
            password=self._env('BOOTSTRAP_VISUALIZADOR_PASSWORD', 'VisualSipra2026!'),
            nombre=self._env('BOOTSTRAP_VISUALIZADOR_NOMBRE', 'Consulta'),
            apellido=self._env('BOOTSTRAP_VISUALIZADOR_APELLIDO', 'General'),
            rol=vis_rol,
            area=area_presidencia,
        )
        carga_user, _ = self._ensure_bootstrap_user(
            email=self._env('BOOTSTRAP_CARGA_EMAIL', 'gestion.proyectos@sipra.local').lower(),
            password=self._env('BOOTSTRAP_CARGA_PASSWORD', 'GestionSipra2026!'),
            nombre=self._env('BOOTSTRAP_CARGA_NOMBRE', 'Gestion'),
            apellido=self._env('BOOTSTRAP_CARGA_APELLIDO', 'Proyectos'),
            rol=carga_rol,
            area=area_desarrollo,
        )

        # Usuario bogarin1983: siempre con contraseña Sipra2026 para desarrollo
        bogarin = Usuario.objects.filter(email='bogarin1983@gmail.com').first()
        if bogarin:
            bogarin.password = make_password('Sipra2026')
            bogarin.estado = True
            bogarin.rol = admin_rol
            bogarin.save(update_fields=['password', 'estado', 'rol'])
        else:
            Usuario.objects.create(
                email='bogarin1983@gmail.com',
                nombre='Horacio David',
                apellido='Bogarin',
                password=make_password('Sipra2026'),
                rol=admin_rol,
                estado=True,
            )

        # Crear proyectos de ejemplo si no existen
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
