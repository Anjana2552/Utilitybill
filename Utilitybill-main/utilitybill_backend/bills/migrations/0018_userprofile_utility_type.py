from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bills', '0017_notification'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='utility_type',
            field=models.CharField(blank=True, max_length=50),
        ),
    ]
