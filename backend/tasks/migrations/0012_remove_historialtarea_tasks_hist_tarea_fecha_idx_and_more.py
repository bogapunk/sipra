from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("tasks", "0011_tarea_compound_indexes"),
    ]

    operations = [
        migrations.RemoveIndex(
            model_name="historialtarea",
            name="tasks_hist_tarea_fecha_idx",
        ),
        migrations.RemoveIndex(
            model_name="tarea",
            name="tasks_tarea_fecha_venc_idx",
        ),
    ]
