# reservations/serializers.py
from rest_framework import serializers
from .models import ParkingLot, RatePlan, Reservation, CheckEvent


# ---- ParkingLot ----
class ParkingLotSerializer(serializers.ModelSerializer):
    tip_display = serializers.CharField(source='get_tip_display', read_only=True)

    class Meta:
        model = ParkingLot
        fields = ('id','ad','tip','tip_display','konum','kapasite','aktif')


# ---- RatePlan ----
class RatePlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = RatePlan
        fields = ('id','lot','ad','saatlik_ucret','gunluk_tavan')


# ---- Reservation (create: müşteri rateplan seçebilir) ----
class ReservationCreateSerializer(serializers.ModelSerializer):
    rateplan = serializers.PrimaryKeyRelatedField(
        queryset=RatePlan.objects.all(), required=False, allow_null=True
    )

    class Meta:
        model = Reservation
        fields = ['id', 'lot', 'rateplan', 'plaka', 'baslangic', 'bitis']

    def validate(self, attrs):
        bas = attrs.get('baslangic')
        bit = attrs.get('bitis')
        lot = attrs.get('lot')
        rp  = attrs.get('rateplan')

        if bas and bit and bas >= bit:
            raise serializers.ValidationError("Bitiş tarihi başlangıçtan sonra olmalı.")

        if lot and not lot.aktif:
            raise serializers.ValidationError("Seçtiğiniz otopark aktif değil.")

        if rp and lot and rp.lot_id != lot.id:
            raise serializers.ValidationError("Seçilen tarife bu otoparka ait değil.")

        return attrs


# ---- Reservation (detay/liste) ----
class ReservationDetailSerializer(serializers.ModelSerializer):
    lot_ad = serializers.CharField(source='lot.ad', read_only=True)
    rp_ad  = serializers.CharField(source='rateplan.ad', read_only=True)

    class Meta:
        model = Reservation
        fields = [
            'id','lot','lot_ad','rateplan','rp_ad',
            'plaka','baslangic','bitis','durum','qr_token',
            'ucret_hesap','created_at'
        ]
        read_only_fields = ['durum','qr_token','ucret_hesap','created_at','lot_ad','rp_ad']


# (opsiyonel) Genel amaçlı tüm alanlar
class ReservationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reservation
        fields = "__all__"


# ---- CheckEvent ----
class CheckEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = CheckEvent
        fields = "__all__"


from rest_framework import serializers

class CheckByQRSerializer(serializers.Serializer):
    qr_token = serializers.CharField(max_length=64)
    tip = serializers.ChoiceField(choices=['check_in', 'check_out'])