from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("projects", "0010_proyecto_estado_index"),
    ]

    operations = [
        migrations.AddIndex(
            model_name="proyecto",
            index=models.Index(fields=["estado", "fecha_fin_estimada"], name="proy_estado_fin_idx"),
        ),
        migrations.AddIndex(
            model_name="proyecto",
            index=models.Index(fields=["area", "estado"], name="proy_area_estado_idx"),
        ),
        migrations.AddIndex(
            model_name="proyecto",
            index=models.Index(fields=["secretaria", "estado"], name="proy_sec_estado_idx"),
        ),
    ]
