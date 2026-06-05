from django.db import migrations, models
import django.db.models.deletion


def migrar_objetivo_fk_a_through(apps, schema_editor):
    Proyecto = apps.get_model('projects', 'Proyecto')
    ProyectoObjetivo = apps.get_model('projects', 'ProyectoObjetivo')
    for proyecto in Proyecto.objects.exclude(objetivo_estrategico_id__isnull=True):
        ProyectoObjetivo.objects.get_or_create(
            proyecto_id=proyecto.id,
            objetivo_id=proyecto.objetivo_estrategico_id,
            defaults={'estado_avance': 'No iniciado'},
        )


class Migration(migrations.Migration):

    dependencies = [
        ('projects', '0015_proyecto_es_transversal'),
    ]

    operations = [
        migrations.CreateModel(
            name='ProyectoObjetivo',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('estado_avance', models.CharField(
                    choices=[
                        ('No iniciado', 'No iniciado'),
                        ('En progreso', 'En progreso'),
                        ('Finalizado', 'Finalizado'),
                    ],
                    default='No iniciado',
                    max_length=20,
                )),
                ('objetivo', models.ForeignKey(
                    db_constraint=False,
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='vinculos_proyecto',
                    to='projects.objetivoestrategico',
                )),
                ('proyecto', models.ForeignKey(
                    db_constraint=False,
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='objetivos_proyecto',
                    to='projects.proyecto',
                )),
            ],
            options={
                'verbose_name': 'Objetivo del proyecto',
                'verbose_name_plural': 'Objetivos del proyecto',
                'ordering': ['id'],
                'unique_together': {('proyecto', 'objetivo')},
            },
        ),
        migrations.RunPython(migrar_objetivo_fk_a_through, migrations.RunPython.noop),
    ]
