from django.core.management.base import BaseCommand
from users.models import Rol, Usuario
from areas.models import Area


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
        Usuario.objects.get_or_create(
            email='admin@admin.com',
            defaults={
                'nombre': 'Administrador',
                'password': 'admin123',
                'rol': admin_rol,
                'estado': True,
            }
        )

        areas_data = ['Desarrollo', 'Infraestructura', 'Comunicación', 'Recursos Humanos']
        for nombre in areas_data:
            Area.objects.get_or_create(nombre=nombre, defaults={'estado': True})

        self.stdout.write(self.style.SUCCESS('Datos iniciales creados correctamente.'))
