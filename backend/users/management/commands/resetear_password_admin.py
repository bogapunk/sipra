"""
Restablece la contraseña del usuario Administrador (admin@admin.com).
Útil cuando no se puede ingresar al sistema.
"""
from django.core.management.base import BaseCommand
from django.contrib.auth.hashers import make_password
from users.models import Usuario, Rol


class Command(BaseCommand):
    help = 'Restablece la contraseña del usuario admin@admin.com a admin123'

    def add_arguments(self, parser):
        parser.add_argument(
            '--password',
            type=str,
            default='admin123',
            help='Nueva contraseña (default: admin123)',
        )

    def handle(self, *args, **options):
        email = 'admin@admin.com'
        nueva_password = options['password']

        usuario = Usuario.objects.filter(email__iexact=email).first()
        if not usuario:
            # Crear admin si no existe
            admin_rol = Rol.objects.filter(nombre='Administrador').first()
            if not admin_rol:
                self.stdout.write(self.style.ERROR('No existe el rol Administrador. Ejecute: python manage.py crear_datos_iniciales'))
                return
            usuario = Usuario.objects.create(
                nombre='Admin',
                apellido='Sistema',
                email=email,
                password=make_password(nueva_password),
                rol=admin_rol,
                estado=True,
            )
            self.stdout.write(self.style.SUCCESS(f'Usuario administrador creado: {email}'))
        else:
            usuario.password = make_password(nueva_password)
            usuario.estado = True
            usuario.save(update_fields=['password', 'estado'])
            self.stdout.write(self.style.SUCCESS(f'Contraseña restablecida para: {email}'))

        self.stdout.write(self.style.SUCCESS(f'\nCredenciales de acceso:'))
        self.stdout.write(f'  Email: {email}')
        self.stdout.write(f'  Contraseña: {nueva_password}')
