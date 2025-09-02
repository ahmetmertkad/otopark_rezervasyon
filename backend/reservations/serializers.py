from rest_framework import serializers
from .models import ParkingLot, RatePlan

class ParkingLotSerializer(serializers.ModelSerializer):
    tip_display = serializers.CharField(source='get_tip_display', read_only=True)

    class Meta:
        model = ParkingLot
        fields = ('id','ad','tip','tip_display','konum','kapasite','aktif')

class RatePlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = RatePlan
        fields = ('id','lot','ad','saatlik_ucret','gunluk_tavan')


from rest_framework import serializers
from .models import Reservation, CheckEvent  # Payment şimdilik yok

class ReservationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reservation
        fields = "__all__"   # veya ['id','user','lot','plaka','baslangic','bitis','durum','qr_token','ucret_hesap']

class CheckEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = CheckEvent
        fields = "__all__"
