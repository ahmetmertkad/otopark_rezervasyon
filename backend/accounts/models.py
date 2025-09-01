import uuid
from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    ROLE = (
        ('musteri', 'Müşteri'),
        ('gorevli', 'Görevli'),
        ('yonetici', 'Yönetici'),
    )
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    role = models.CharField(max_length=20, choices=ROLE, default='musteri')

    def __str__(self):
        return f"{self.username} ({self.role})"