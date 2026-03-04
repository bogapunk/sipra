"""Carga inicial de secretarías."""
from django.core.management.base import BaseCommand
from secretarias.models import Secretaria


DATOS = [
    ('EC', 'Economía del Conocimiento', 'Secretaría orientada al desarrollo del sector tecnológico y economía basada en conocimiento'),
    ('CYT', 'Ciencia y Tecnología', 'Secretaría orientada a la investigación científica y desarrollo tecnológico'),
    ('TEC', 'Tecnología', 'Secretaría de innovación y transformación digital'),
    ('CUL', 'Cultura', 'Secretaría de promoción cultural y desarrollo creativo'),
    ('GOB', 'Gobierno Abierto', 'Secretaría de modernización y transparencia'),
    ('ADM', 'Administración y Gestión', 'Secretaría de gestión institucional'),
]


class Command(BaseCommand):
    help = 'Carga las secretarías iniciales'

    def handle(self, *args, **options):
        for codigo, nombre, descripcion in DATOS:
            Secretaria.objects.update_or_create(
                codigo=codigo,
                defaults={'nombre': nombre, 'descripcion': descripcion, 'activa': True}
            )
        self.stdout.write(self.style.SUCCESS(
            f'Secretarías cargadas: {Secretaria.objects.count()} registros.'
        ))
