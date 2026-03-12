from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("tasks", "0010_historial_fecha_index"),
    ]

    operations = [
        migrations.AddIndex(
            model_name="tarea",
            index=models.Index(fields=["estado", "fecha_vencimiento"], name="tarea_estado_venc_idx"),
        ),
        migrations.AddIndex(
            model_name="tarea",
            index=models.Index(fields=["responsable", "estado"], name="tarea_resp_estado_idx"),
        ),
        migrations.AddIndex(
            model_name="tarea",
            index=models.Index(fields=["proyecto", "tarea_padre", "orden"], name="tarea_proj_padre_ord_idx"),
        ),
    ]
