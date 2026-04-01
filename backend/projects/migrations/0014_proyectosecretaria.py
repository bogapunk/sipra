# Generated manually for ProyectoSecretaria

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('secretarias', '0001_inicial'),
        ('projects', '0013_proyectopresupuestoitem_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='ProyectoSecretaria',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('proyecto', models.ForeignKey(db_constraint=False, on_delete=django.db.models.deletion.CASCADE, related_name='proyectosecretaria_set', to='projects.proyecto')),
                ('secretaria', models.ForeignKey(db_constraint=False, on_delete=django.db.models.deletion.CASCADE, related_name='proyectos_vinculados', to='secretarias.secretaria')),
            ],
            options={
                'unique_together': {('proyecto', 'secretaria')},
            },
        ),
    ]
