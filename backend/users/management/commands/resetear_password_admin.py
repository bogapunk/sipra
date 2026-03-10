"""
Restablece la contraseña del usuario Administrador bootstrap.
Útil cuando no se puede ingresar al sistema.
"""
import os
from django.core.management.base import BaseCommand
from django.contrib.auth.hashers import make_password
from users.models import Usuario, Rol


class Command(BaseCommand):
    help = 'Restablece la contraseña del usuario administrador bootstrap'

    def add_arguments(self, parser):
        parser.add_argument(
            '--password',
            type=str,
            default='',
            help='Nueva contraseña. Si no se informa, usa BOOTSTRAP_ADMIN_PASSWORD del entorno.',
        )

    def handle(self, *args, **options):
        email = (os.environ.get('BOOTSTRAP_ADMIN_EMAIL', 'admin@sipra.local') or 'admin@sipra.local').strip().lower()
        nueva_password = (options['password'] or os.environ.get('BOOTSTRAP_ADMIN_PASSWORD', '')).strip()
        if not nueva_password:
            self.stdout.write(self.style.ERROR('Debe indicar --password o definir BOOTSTRAP_ADMIN_PASSWORD.'))
            return

        usuario = Usuario.objects.filter(email__iexact=email).first()
        if not usuario:
            # Crear admin si no existe
            admin_rol = Rol.objects.filter(nombre='Administrador').first()
            if not admin_rol:
                self.stdout.write(self.style.ERROR('No existe el rol Administrador. Ejecute: python manage.py crear_datos_iniciales'))
                return
            usuario = Usuario.objects.create(
                nombre=os.environ.get('BOOTSTRAP_ADMIN_NOMBRE', 'Administrador').strip() or 'Administrador',
                apellido=os.environ.get('BOOTSTRAP_ADMIN_APELLIDO', 'SIPRA').strip() or 'SIPRA',
                email=email,
                password=make_password(nueva_password),
                rol=admin_rol,
                estado=True,
            )
            self.stdout.write(self.style.SUCCESS(f'Usuario administrador creado: {email}'))
        else:
            usuario.password = make_password(nueva_password)
            usuario.estado = True
            usuario.token_version = (usuario.token_version or 1) + 1
            usuario.save(update_fields=['password', 'estado', 'token_version'])
            self.stdout.write(self.style.SUCCESS(f'Contraseña restablecida para: {email}'))

        self.stdout.write(self.style.SUCCESS(f'\nCredenciales de acceso:'))
        self.stdout.write(f'  Email: {email}')
        self.stdout.write(f'  Contraseña: {nueva_password}')
