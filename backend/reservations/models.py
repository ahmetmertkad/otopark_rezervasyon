import uuid
from decimal import Decimal
from django.db import models
from django.core.validators import MinValueValidator
from django.conf import settings


class ParkingLot(models.Model):
    TIP = (('acik', 'Açık'), ('kapali', 'Kapalı'), ('vip', 'VIP'))

    ad       = models.CharField(max_length=100)
    tip      = models.CharField(max_length=10, choices=TIP)
    konum    = models.CharField(max_length=200, blank=True)
    kapasite = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    aktif    = models.BooleanField(default=True)

    class Meta:
        indexes = [
            models.Index(fields=['aktif', 'tip']),
        ]
        verbose_name = "Otopark"
        verbose_name_plural = "Otoparklar"

    def __str__(self):
        return f"{self.ad} ({self.get_tip_display()})"


class RatePlan(models.Model):
    lot           = models.ForeignKey(ParkingLot, on_delete=models.CASCADE, related_name='rateplans')
    ad            = models.CharField(max_length=50, default='Standart')
    saatlik_ucret = models.DecimalField(max_digits=8, decimal_places=2, validators=[MinValueValidator(Decimal('0'))])
    gunluk_tavan  = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)

    class Meta:
        unique_together = ('lot', 'ad')
        verbose_name = "Tarife"
        verbose_name_plural = "Tarifeler"

    def __str__(self):
        return f"{self.lot.ad} / {self.ad}"


class Reservation(models.Model):
    DURUM = (
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('checked_in', 'CheckedIn'),
        ('checked_out', 'CheckedOut'),
        ('canceled', 'Canceled'),
    )

    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    # Rezervasyonu oluşturan kullanıcı (default User ya da CustomUser ile uyumlu)
    user        = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reservations',
        null=True, blank=True,   # MVP’de opsiyonel; auth ekleyince zorunlu yapabilirsin
    )

    lot         = models.ForeignKey(ParkingLot, on_delete=models.PROTECT, related_name='reservations')
    plaka       = models.CharField(max_length=15, db_index=True)
    baslangic   = models.DateTimeField(db_index=True)
    bitis       = models.DateTimeField(db_index=True)
    durum       = models.CharField(max_length=20, choices=DURUM, default='pending', db_index=True)

    # Girişte/çıkışta doğrulama için tekil token
    qr_token    = models.CharField(max_length=64, unique=True, blank=True)

    # Ön-ücret (quote) veya hesaplanmış ücret
    ucret_hesap = models.DecimalField(max_digits=8, decimal_places=2, default=Decimal('0.00'))

    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['lot', 'baslangic', 'bitis']),
            models.Index(fields=['durum']),
            models.Index(fields=['qr_token']),
        ]
        ordering = ['-created_at']
        verbose_name = "Rezervasyon"
        verbose_name_plural = "Rezervasyonlar"

    def clean(self):
        # basit zaman doğrulaması
        if self.baslangic and self.bitis and self.baslangic >= self.bitis:
            from django.core.exceptions import ValidationError
            raise ValidationError("Bitiş tarihi başlangıçtan sonra olmalı.")

    def __str__(self):
        owner = getattr(self.user, "username", None) or "anon"
        return f"{self.plaka} @ {self.lot.ad} [{self.durum}] by {owner}"


class CheckEvent(models.Model):
    TIP = (('check_in', 'IN'), ('check_out', 'OUT'))

    reservation = models.ForeignKey(Reservation, on_delete=models.CASCADE, related_name='checks')
    tip         = models.CharField(max_length=10, choices=TIP)

    # İşlemi yapan görevli (User FK)
    gorevli     = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='check_events'
    )

    zaman       = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Giriş/Çıkış Kaydı"
        verbose_name_plural = "Giriş/Çıkış Kayıtları"

    def __str__(self):
        return f"{self.reservation.plaka} - {self.tip} - {self.zaman:%Y-%m-%d %H:%M}"


class Payment(models.Model):
    SAGLAYICI = (('mock', 'Mock'), ('iyzico', 'iyzico'), ('stripe', 'Stripe'))
    DURUM     = (('pending', 'Pending'), ('paid', 'Paid'), ('failed', 'Failed'))

    reservation = models.OneToOneField(Reservation, on_delete=models.CASCADE, related_name='payment', null=True, blank=True)
    tutar       = models.DecimalField(max_digits=8, decimal_places=2, validators=[MinValueValidator(Decimal('0'))])
    saglayici   = models.CharField(max_length=10, choices=SAGLAYICI, default='mock')
    durum       = models.CharField(max_length=10, choices=DURUM, default='pending')
    odeme_ref   = models.CharField(max_length=100, blank=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Ödeme"
        verbose_name_plural = "Ödemeler"

    def __str__(self):
        return f"{self.reservation_id} - {self.durum} {self.tutar}₺"
