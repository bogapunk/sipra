from django.db import migrations, models


def forwards_rellenar_es_transversal(apps, schema_editor):
    Proyecto = apps.get_model('projects', 'Proyecto')
    ProyectoArea = apps.get_model('projects', 'ProyectoArea')
    ProyectoSecretaria = apps.get_model('projects', 'ProyectoSecretaria')
    for p in Proyecto.objects.all().iterator():
        ids_a = set()
        if p.area_id:
            ids_a.add(p.area_id)
        ids_a.update(ProyectoArea.objects.filter(proyecto_id=p.pk).values_list('area_id', flat=True))
        ids_s = set()
        if p.secretaria_id:
            ids_s.add(p.secretaria_id)
        ids_s.update(ProyectoSecretaria.objects.filter(proyecto_id=p.pk).values_list('secretaria_id', flat=True))
        flag = len(ids_a) > 1 or len(ids_s) > 1
        if p.es_transversal != flag:
            p.es_transversal = flag
            p.save(update_fields=['es_transversal'])


def backwards_noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('projects', '0014_proyectosecretaria'),
    ]

    operations = [
        migrations.AddField(
            model_name='proyecto',
            name='es_transversal',
            field=models.BooleanField(db_index=True, default=False),
        ),
        migrations.RunPython(forwards_rellenar_es_transversal, backwards_noop),
    ]
