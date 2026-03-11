# Optimización: índice compuesto para consultas de "último historial por tarea"
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('tasks', '0009_tarea_orden'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='historialtarea',
            index=models.Index(fields=['tarea', '-fecha'], name='tasks_hist_tarea_fecha_idx'),
        ),
        migrations.AddIndex(
            model_name='tarea',
            index=models.Index(fields=['fecha_vencimiento'], name='tasks_tarea_fecha_venc_idx'),
        ),
    ]
