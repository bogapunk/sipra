"""
Crea o restablece un usuario SIPRA (email + contraseña + rol).
"""
from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand

from areas.models import Area
from users.models import Rol, Usuario


class Command(BaseCommand):
    help = 'Crea o restablece la contraseña de un usuario por email'

    def add_arguments(self, parser):
        parser.add_argument('--email', type=str, required=True)
        parser.add_argument('--password', type=str, required=True)
        parser.add_argument('--nombre', type=str, default='')
        parser.add_argument('--apellido', type=str, default='')
        parser.add_argument('--rol', type=str, default='Administrador')

    def handle(self, *args, **options):
        email = (options['email'] or '').strip().lower()
        password = (options['password'] or '').strip()
        if not email or not password:
            self.stdout.write(self.style.ERROR('Email y contraseña son obligatorios.'))
            return

        rol = Rol.objects.filter(nombre__iexact=options['rol']).first()
        if not rol:
            self.stdout.write(self.style.ERROR(f'No existe el rol "{options["rol"]}".'))
            return

        nombre = (options['nombre'] or email.split('@')[0]).strip() or 'Usuario'
        apellido = (options['apellido'] or '').strip()
        area = Area.objects.filter(estado=True).first()

        usuario = Usuario.objects.filter(email__iexact=email).first()
        if usuario:
            usuario.password = make_password(password)
            usuario.estado = True
            usuario.rol = rol
            usuario.token_version = (usuario.token_version or 1) + 1
            usuario.save(update_fields=['password', 'estado', 'rol', 'token_version'])
            self.stdout.write(self.style.SUCCESS(f'Usuario actualizado: {email}'))
        else:
            Usuario.objects.create(
                nombre=nombre,
                apellido=apellido,
                email=email,
                password=make_password(password),
                rol=rol,
                area=area,
                estado=True,
            )
            self.stdout.write(self.style.SUCCESS(f'Usuario creado: {email}'))

        self.stdout.write(self.style.SUCCESS(f'Rol: {rol.nombre} | Estado: activo'))
