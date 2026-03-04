# Generated manually for performance optimization

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('tasks', '0004_tarea_proyecto_opcional'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='tarea',
            index=models.Index(fields=['estado'], name='tasks_tarea_estado_idx'),
        ),
        migrations.AddIndex(
            model_name='tarea',
            index=models.Index(fields=['proyecto'], name='tasks_tarea_proyecto_idx'),
        ),
    ]
