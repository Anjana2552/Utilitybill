from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ('bills', '0008_payment'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='otp_code',
            field=models.CharField(max_length=6, blank=True),
        ),
        migrations.AddField(
            model_name='userprofile',
            name='otp_expires_at',
            field=models.DateTimeField(null=True, blank=True),
        ),
        migrations.AddField(
            model_name='userprofile',
            name='otp_verified',
            field=models.BooleanField(default=False),
        ),
    ]
