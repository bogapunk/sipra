# Generated manually - Hashea contraseñas en texto plano existentes

from django.db import migrations
from django.contrib.auth.hashers import make_password, is_password_usable


def hash_plain_passwords(apps, schema_editor):
    """Convierte contraseñas en texto plano a hash. No modifica las ya hasheadas."""
    Usuario = apps.get_model('users', 'Usuario')
    for u in Usuario.objects.all():
        pwd = u.password or ''
        if pwd and not is_password_usable(pwd):
            u.password = make_password(pwd)
            u.save(update_fields=['password'])


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0005_area_secretaria_tarea_usuario'),
    ]

    operations = [
        migrations.RunPython(hash_plain_passwords, noop),
    ]
