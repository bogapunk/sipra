"""Asigna el área Presidencia a todos los usuarios con rol Visualizador que no tienen área.
También crea el área Presidencia si no existe."""
from django.core.management.base import BaseCommand
from areas.models import Area
from users.models import Usuario


class Command(BaseCommand):
    help = 'Crea área Presidencia si no existe y la asigna a usuarios Visualizador sin área'

    def handle(self, *args, **options):
        area, created = Area.objects.get_or_create(
            nombre='Presidencia',
            defaults={'estado': True}
        )
        if created:
            self.stdout.write(self.style.SUCCESS('Área Presidencia creada.'))

        from users.models import Rol
        if not Rol.objects.filter(nombre='Visualización').exists():
            self.stdout.write(self.style.WARNING('No existe rol Visualización.'))
            return

        actualizados = Usuario.objects.filter(
            rol__nombre='Visualización',
            area__isnull=True
        ).update(area=area)

        if actualizados:
            self.stdout.write(self.style.SUCCESS(f'Se asignó Presidencia a {actualizados} usuario(s) Visualizador.'))
        else:
            self.stdout.write('Todos los Visualizadores ya tienen área asignada.')
