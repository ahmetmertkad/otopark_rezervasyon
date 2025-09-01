from rest_framework import viewsets, permissions
from .models import ParkingLot
from .serializers import ParkingLotSerializer

class ParkingLotViewSet(viewsets.ModelViewSet):
    queryset = ParkingLot.objects.all()
    serializer_class = ParkingLotSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = super().get_queryset()
        params = self.request.query_params

        # 1) aktif filtresi
        aktif = params.get('aktif')
        if aktif is not None:
            if aktif.lower() in ('1','true','yes','y'):
                qs = qs.filter(aktif=True)
            elif aktif.lower() in ('0','false','no','n'):
                qs = qs.filter(aktif=False)

        # 2) tip filtresi
        tip = params.get('tip')
        if tip:
            qs = qs.filter(tip=tip)

        # 3) ad veya konum arama
        search = params.get('search')
        if search:
            qs = qs.filter(ad__icontains=search) | qs.filter(konum__icontains=search)

        # 4) sıralama
        ordering = params.get('ordering')
        if ordering in ['ad','-ad','kapasite','-kapasite']:
            qs = qs.order_by(ordering)

        return qs





# reservations/views.py
from rest_framework import viewsets, permissions
from .models import RatePlan
from .serializers import RatePlanSerializer

class RatePlanViewSet(viewsets.ModelViewSet):
    # 🔹 Tüm RatePlan kayıtlarını getir ama lot (ParkingLot) bilgisini de JOIN ile çek
    queryset = RatePlan.objects.select_related('lot').all()
    
    # 🔹 JSON dönüşümü için kullanılacak serializer
    serializer_class = RatePlanSerializer
    
    # 🔹 Sadece admin kullanıcılar POST/PUT/PATCH/DELETE yapabilir
    # normal kullanıcılar GET (liste/detay) görebilir
    permission_classes = []

    def get_queryset(self):
        """
        Eğer URL'de ?lot_id=... parametresi verilirse,
        sadece o otoparka ait tarifeleri döndür.
        Yoksa tüm RatePlan'leri döndür.
        """
        qs = super().get_queryset()
        lot_id = self.request.query_params.get('lot_id')
        if lot_id:
            qs = qs.filter(lot_id=lot_id)
        return qs
