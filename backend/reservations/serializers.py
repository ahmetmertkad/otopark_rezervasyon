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