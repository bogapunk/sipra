"""
Restaura los datos del sistema SIPRA:
- Reactiva todos los usuarios (por si fueron desactivados con eliminación lógica)
- Crea datos iniciales (roles, áreas, usuarios, proyectos, tareas) si no existen
"""
from django.core.management.base import BaseCommand
from django.core.management import call_command
from users.models import Usuario


class Command(BaseCommand):
    help = 'Restaura datos del sistema: reactiva usuarios y crea datos iniciales si no existen'

    def handle(self, *args, **options):
        # Reactivar todos los usuarios (por eliminación lógica previa)
        reactivados = Usuario.objects.filter(estado=False).update(estado=True)
        if reactivados:
            self.stdout.write(self.style.SUCCESS(f'Se reactivaron {reactivados} usuario(s).'))

        # Crear datos iniciales (roles, áreas, usuarios, proyectos, tareas)
        call_command('crear_datos_iniciales')

        self.stdout.write(self.style.SUCCESS('Restauración completada. Reinicie el servidor si es necesario.'))
