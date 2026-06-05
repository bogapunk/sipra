from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('projects', '0016_proyectoobjetivo'),
    ]

    operations = [
        migrations.AddField(
            model_name='eje',
            name='anio',
            field=models.PositiveSmallIntegerField(db_index=True, default=2026),
        ),
        migrations.AlterModelOptions(
            name='eje',
            options={'ordering': ['anio', 'id_eje'], 'verbose_name': 'Eje', 'verbose_name_plural': 'Ejes'},
        ),
    ]
