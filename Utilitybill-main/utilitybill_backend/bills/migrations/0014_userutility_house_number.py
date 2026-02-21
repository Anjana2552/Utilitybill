# Generated migration for adding house_number field to UserUtility

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bills', '0013_userprofile_house_number'),
    ]

    operations = [
        migrations.AddField(
            model_name='userutility',
            name='house_number',
            field=models.CharField(blank=True, max_length=50),
        ),
    ]
