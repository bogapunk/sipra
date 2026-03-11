# Optimización: índice en estado para filtros frecuentes
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('projects', '0009_adjuntoauditlog'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='proyecto',
            index=models.Index(fields=['estado'], name='projects_proy_estado_idx'),
        ),
    ]
