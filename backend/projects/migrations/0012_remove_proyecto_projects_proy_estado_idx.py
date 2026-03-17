from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("projects", "0011_proyecto_compound_indexes"),
    ]

    operations = [
        migrations.RemoveIndex(
            model_name="proyecto",
            name="projects_proy_estado_idx",
        ),
    ]
