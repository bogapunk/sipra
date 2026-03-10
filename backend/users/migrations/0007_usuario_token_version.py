from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0006_hash_passwords'),
    ]

    operations = [
        migrations.AddField(
            model_name='usuario',
            name='token_version',
            field=models.PositiveIntegerField(default=1),
        ),
    ]
