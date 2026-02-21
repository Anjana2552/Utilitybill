# Generated migration for adding house_number field to UserProfile

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bills', '0012_wallet_models'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='house_number',
            field=models.CharField(blank=True, max_length=50),
        ),
    ]
