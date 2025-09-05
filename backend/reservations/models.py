# reservations/models.py
import uuid, secrets
from decimal import Decimal
from django.db import models, transaction, IntegrityError
from django.core.validators import MinValueValidator
from django.conf import settings


# ----------------------
# ParkingLot
# ----------------------
class ParkingLot(models.Model):
    TIP = (('acik', 'Açık'), ('kapali', 'Kapalı'), ('vip', 'VIP'))

    ad       = models.CharField(max_length=100)
    tip      = models.CharField(max_length=10, choices=TIP)
    konum    = models.CharField(max_length=200, blank=True)
    kapasite = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    aktif    = models.BooleanField(default=True)

    class Meta:
        indexes = [models.Index(fields=['aktif', 'tip'])]
        verbose_name = "Otopark"
        verbose_name_plural = "Otoparklar"

    def __str__(self):
        return f"{self.ad} ({self.get_tip_display()})"


# ----------------------
# RatePlan
# ----------------------
class RatePlan(models.Model):
    lot           = models.ForeignKey('ParkingLot', on_delete=models.CASCADE, related_name='rateplans')
    ad            = models.CharField(max_length=50, default='Standart')
    saatlik_ucret = models.DecimalField(max_digits=8, decimal_places=2, validators=[MinValueValidator(Decimal('0'))])
    gunluk_tavan  = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)

    class Meta:
        unique_together = ('lot', 'ad')
        verbose_name = "Tarife"
        verbose_name_plural = "Tarifeler"

    def __str__(self):
        return f"{self.lot.ad} / {self.ad}"


# ----------------------
# Reservation
# ----------------------
def _gen_token() -> str:
    return secrets.token_urlsafe(32)  # ~43 karakter, URL-safe


class Reservation(models.Model):
    DURUM = (
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('checked_in', 'CheckedIn'),
        ('checked_out', 'CheckedOut'),
        ('canceled', 'Canceled'),
    )

    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user        = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                                    related_name='reservations', null=True, blank=True)
    lot         = models.ForeignKey('ParkingLot', on_delete=models.PROTECT, related_name='reservations')

    # Müşteri tarife seçebilir; seçmezse lot'un ilk tarifesi hesaplamada kullanılır
    rateplan    = models.ForeignKey('RatePlan', on_delete=models.PROTECT,
                                    related_name='reservations', null=True, blank=True)

    plaka       = models.CharField(max_length=15, db_index=True)
    baslangic   = models.DateTimeField(db_index=True)
    bitis       = models.DateTimeField(db_index=True)
    durum       = models.CharField(max_length=20, choices=DURUM, default='pending', db_index=True)

    # Benzersiz giriş/çıkış doğrulama token'ı
    qr_token    = models.CharField(max_length=64, unique=True, blank=True, null=True)

    # Hesaplanan ücret
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

    # ------ helpers ------
    def clean(self):
        if self.baslangic and self.bitis and self.baslangic >= self.bitis:
            from django.core.exceptions import ValidationError
            raise ValidationError("Bitiş tarihi başlangıçtan sonra olmalı.")

    def _ensure_qr(self):
        """qr_token boşsa üret (uniq çakışmayı minimize etmek için önce varlık kontrolü yapar)."""
        if self.qr_token:
            return
        for _ in range(6):
            t = _gen_token()
            if not Reservation.objects.filter(qr_token=t).exists():
                self.qr_token = t
                return
        raise RuntimeError("QR token üretilemedi.")

    def _resolve_rateplan(self):
        """Seçili rateplan yoksa lot'un ilk tarifesini hesaplama için kullan."""
        return self.rateplan or self.lot.rateplans.order_by('id').first()

    def hesapla_ucret(self) -> Decimal:
        """Saatlik ücret ve (varsa) günlük tavan ile basit ücret hesabı."""
        rp = self._resolve_rateplan()
        if not rp:
            return Decimal('0.00')

        # Toplam saat (yukarı yuvarla), min 1 saat
        total_hours = (self.bitis - self.baslangic).total_seconds() / 3600
        hours = Decimal(str(max(1, int(total_hours + 0.999))))
        tutar = rp.saatlik_ucret * hours

        # Günlük tavan (24 saat blok + kalan)
        if rp.gunluk_tavan:
            from math import floor
            full_days = floor(total_hours / 24)
            rem = total_hours - full_days * 24
            rem_hours = Decimal(str(0 if rem <= 0 else max(1, int(rem + 0.999))))
            rem_charge = rp.saatlik_ucret * rem_hours
            tutar = rp.gunluk_tavan * full_days + min(rem_charge, rp.gunluk_tavan)

        return tutar

    def save(self, *args, **kwargs):
        # qr_token garanti et
        if not self.qr_token:
            self._ensure_qr()

        # ücret hesapla (create & update)
        if self.baslangic and self.bitis and self.lot_id:
            self.ucret_hesap = self.hesapla_ucret()

        # uniqueness yarışına karşı küçük retry
        for attempt in range(3):
            try:
                with transaction.atomic():
                    return super().save(*args, **kwargs)
            except IntegrityError as e:
                if 'qr_token' in str(e).lower() and attempt < 2:
                    self.qr_token = None
                    self._ensure_qr()
                    continue
                raise

    def __str__(self):
        owner = getattr(self.user, "username", None) or "anon"
        return f"{self.plaka} @ {self.lot.ad} [{self.durum}] by {owner}"


# ----------------------
# CheckEvent
# ----------------------
class CheckEvent(models.Model):
    TIP = (('check_in', 'IN'), ('check_out', 'OUT'))

    reservation = models.ForeignKey('Reservation', on_delete=models.CASCADE, related_name='checks')
    tip         = models.CharField(max_length=10, choices=TIP)

    gorevli     = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
                                    null=True, blank=True, related_name='check_events')

    zaman       = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Giriş/Çıkış Kaydı"
        verbose_name_plural = "Giriş/Çıkış Kayıtları"

    def __str__(self):
        return f"{self.reservation.plaka} - {self.tip} - {self.zaman:%Y-%m-%d %H:%M}"


# ----------------------
# Payment
# ----------------------
class Payment(models.Model):
    SAGLAYICI = (('mock', 'Mock'), ('iyzico', 'iyzico'), ('stripe', 'Stripe'))
    DURUM     = (('pending', 'Pending'), ('paid', 'Paid'), ('failed', 'Failed'))

    reservation = models.OneToOneField('Reservation', on_delete=models.CASCADE, related_name='payment',
                                       null=True, blank=True)
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
