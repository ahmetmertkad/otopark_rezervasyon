# reservations/views.py
from django.db.models import Q
from rest_framework import viewsets, permissions, status, filters
from rest_framework.response import Response
from rest_framework.decorators import action
from django_filters.rest_framework import DjangoFilterBackend

from .models import ParkingLot, RatePlan, Reservation, CheckEvent
from .serializers import (
    ParkingLotSerializer,
    RatePlanSerializer,
    ReservationSerializer,
    CheckEventSerializer,
)


# --- İzinler ---------------------------------------------------------------

class IsAdminOrReadOnly(permissions.BasePermission):
    """
    GET/HEAD/OPTIONS serbest, yazma işlemleri (POST/PUT/PATCH/DELETE) sadece admin (is_staff).
    """
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return bool(request.user and request.user.is_staff)


# --- ParkingLot ------------------------------------------------------------

class ParkingLotViewSet(viewsets.ModelViewSet):
    """
    /lots/ CRUD
    Filtreleme: ?aktif=true|false, ?tip=acik|kapali|vip
    Arama:      ?search=izmit
    Sıralama:   ?ordering=ad|-ad|kapasite|-kapasite
    """
    queryset = ParkingLot.objects.all()
    serializer_class = ParkingLotSerializer
    permission_classes = []

    # DRF backends (opsiyonel ama pratik)
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['aktif', 'tip']
    search_fields = ['ad', 'konum']
    ordering_fields = ['ad', 'kapasite']

    def get_queryset(self):
        # Ek manuel filtre/arama desteği istiyorsan burada kalabilir
        qs = super().get_queryset()
        params = self.request.query_params

        aktif = params.get('aktif')
        if aktif is not None:
            if aktif.lower() in ('1', 'true', 'yes', 'y'):
                qs = qs.filter(aktif=True)
            elif aktif.lower() in ('0', 'false', 'no', 'n'):
                qs = qs.filter(aktif=False)

        tip = params.get('tip')
        if tip:
            qs = qs.filter(tip=tip)

        search = params.get('search')
        if search:
            # DÜZELTİLDİ: queryset union yerine Q(...) | Q(...)
            qs = qs.filter(Q(ad__icontains=search) | Q(konum__icontains=search))

        ordering = params.get('ordering')
        if ordering in ['ad', '-ad', 'kapasite', '-kapasite']:
            qs = qs.order_by(ordering)

        return qs

    @action(detail=True, methods=['get', 'post'], url_path='rateplans')
    def rateplans(self, request, pk=None):
        """
        Nested kullanım (opsiyonel ama faydalı):
        GET  /lots/{id}/rateplans/ -> bu lota ait tarifeleri listele
        POST /lots/{id}/rateplans/ -> bu lota yeni tarife ekle (sadece admin)
        """
        lot = self.get_object()

        if request.method.lower() == 'get':
            rp_qs = lot.rateplans.select_related('lot').all().order_by('ad')
            return Response(RatePlanSerializer(rp_qs, many=True).data)

        # POST
        if not (request.user and request.user.is_staff):
            return Response({"detail": "Sadece admin ekleyebilir."},
                            status=status.HTTP_403_FORBIDDEN)

        data = request.data.copy()
        data['lot'] = lot.pk
        ser = RatePlanSerializer(data=data)
        ser.is_valid(raise_exception=True)
        ser.save()
        return Response(ser.data, status=status.HTTP_201_CREATED)


# --- RatePlan --------------------------------------------------------------

class RatePlanViewSet(viewsets.ModelViewSet):
    """
    /rateplans/ CRUD
    Filtre:   ?lot=ID  (django-filter)
              ?lot_id=ID (manuel)
    Arama:    ?search=...
    Sıralama: ?ordering=ad|saatlik_ucret|gunluk_tavan (ve - ile ters)
    """
    queryset = RatePlan.objects.select_related('lot').all()
    serializer_class = RatePlanSerializer
    permission_classes = []

    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['lot']                  # ?lot=3
    search_fields = ['ad', 'lot__ad']           # ?search=standart
    ordering_fields = ['ad', 'saatlik_ucret', 'gunluk_tavan']

    def get_queryset(self):
        qs = super().get_queryset()
        lot_id = self.request.query_params.get('lot_id')
        if lot_id:
            qs = qs.filter(lot_id=lot_id)
        return qs


# --- Reservation -----------------------------------------------------------

from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import Reservation
from .serializers import ReservationCreateSerializer, ReservationDetailSerializer

class IsOwnerOrAdmin(permissions.BasePermission):
    """
    Objeye özel izin: Sahibi veya admin ise izin ver.
    """
    def has_object_permission(self, request, view, obj):
        if request.user and request.user.is_staff:
            return True
        return obj.user_id == getattr(request.user, "id", None)

class ReservationViewSet(viewsets.ModelViewSet):
    """
    Müşteri akışı:
    - GET /reservations/         -> müşteri: kendi rezervasyonları; admin: tümü
    - POST /reservations/        -> müşteri yeni rezervasyon oluşturur
    - GET /reservations/{id}/    -> detail (sahibi veya admin)
    - PATCH /reservations/{id}/  -> sadece bazı alanlar, genelde admin
    - POST /reservations/{id}/cancel/ -> sahibi iptal edebilir (duruma bağlı)
    - GET /reservations/my/      -> kısayol, kullanıcının tüm rezervasyonları
    """
    queryset = Reservation.objects.select_related('lot','user','rateplan').all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        qs = super().get_queryset()
        # admin her şeyi görür, müşteri yalnızca kendini
        if self.request.user and self.request.user.is_staff:
            return qs
        return qs.filter(user=self.request.user)

    def get_permissions(self):
        # retrieve/update/destroy sırasında obje sahipliği kontrolü
        if self.action in ['retrieve', 'update', 'partial_update', 'destroy', 'cancel']:
            return [permissions.IsAuthenticated(), IsOwnerOrAdmin()]
        return [permissions.IsAuthenticated()]

    def get_serializer_class(self):
        if self.action in ['create']:
            return ReservationCreateSerializer
        return ReservationDetailSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user, durum='pending')  # istersen 'pending' de yapabilirsin

    @action(detail=False, methods=['get'], url_path='my')
    def my_reservations(self, request):
        qs = self.get_queryset().order_by('-created_at')
        page = self.paginate_queryset(qs)
        ser = ReservationDetailSerializer(page or qs, many=True)
        if page is not None:
            return self.get_paginated_response(ser.data)
        return Response(ser.data)

    @action(detail=True, methods=['post'], url_path='cancel')
    def cancel(self, request, pk=None):
        """
        Sadece sahibi (veya admin) ve belirli durumlarda iptal edebilir.
        """
        resv = self.get_object()  # IsOwnerOrAdmin devreye girer
        if resv.durum in ['checked_in', 'checked_out', 'canceled']:
            return Response({"detail": "Bu rezervasyon iptal edilemez."},
                            status=status.HTTP_400_BAD_REQUEST)
        resv.durum = 'canceled'
        resv.save(update_fields=['durum'])
        return Response({"detail": "Rezervasyon iptal edildi."}, status=status.HTTP_200_OK)



# --- CheckEvent ------------------------------------------------------------

from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters

class CheckEventViewSet(viewsets.ModelViewSet):
    """
    /check-events/ CRUD
    Sadece admin (veya görevli) yazabilir; listeleme adminlere açık.
    Filtre: ?reservation=<id>  ?tip=check_in|check_out  ?gorevli=<user_id>
            ?lot=<lot_id>  ?plaka=34ABC123
    """
    queryset = CheckEvent.objects.select_related('reservation','gorevli','reservation__lot').all()
    serializer_class = CheckEventSerializer
    permission_classes = [permissions.IsAdminUser]

    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['tip', 'reservation', 'gorevli']
    search_fields = ['reservation__plaka']

    def get_queryset(self):
        qs = super().get_queryset()
        lot_id = self.request.query_params.get('lot')
        if lot_id:
            qs = qs.filter(reservation__lot_id=lot_id)
        plaka = self.request.query_params.get('plaka')
        if plaka:
            qs = qs.filter(reservation__plaka__iexact=plaka)
        # Bugün filtrelemesi için ?today=1
        today = self.request.query_params.get('today')
        if today in ('1','true','yes'):
            from django.utils.timezone import now
            d = now().date()
            qs = qs.filter(zaman__date=d)
        return qs.order_by('-zaman')


from rest_framework.views import APIView
from rest_framework.permissions import IsAdminUser
from django.utils import timezone

from .models import Reservation, CheckEvent
from .serializers import CheckByQRSerializer, ReservationDetailSerializer, CheckEventSerializer

class CheckByQRView(APIView):
    """
    POST /reservation/check-by-qr/
    Body: { "qr_token": "...", "tip": "check_in" | "check_out" }
    Only staff (görevli/admin).
    """
    permission_classes = []

    def post(self, request, *args, **kwargs):
        ser = CheckByQRSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        token = ser.validated_data['qr_token']
        tip   = ser.validated_data['tip']

        try:
            resv = Reservation.objects.select_related('lot', 'user', 'rateplan').get(qr_token=token)
        except Reservation.DoesNotExist:
            return Response({"detail": "Rezervasyon bulunamadı."}, status=status.HTTP_404_NOT_FOUND)

        # İş kuralları
        if tip == 'check_in':
            if resv.durum in ['checked_in', 'checked_out', 'canceled']:
                return Response({"detail": f"Bu rezervasyon için check-in yapılamaz (durum: {resv.durum})."}, status=status.HTTP_400_BAD_REQUEST)
            # İstersen pending -> confirmed yap
            if resv.durum == 'pending':
                resv.durum = 'confirmed'
            resv.durum = 'checked_in'
            resv.save(update_fields=['durum'])

        elif tip == 'check_out':
            if resv.durum != 'checked_in':
                return Response({"detail": "Check-out yalnızca 'checked_in' durumunda yapılabilir."}, status=status.HTTP_400_BAD_REQUEST)

            # Gerçek çıkış saatini şimdi olarak alıp ücreti yeniden hesaplamak istersen:
            # resv.bitis = timezone.now()
            # resv.durum = 'checked_out'
            # resv.save(update_fields=['bitis', 'durum'])
            # Eğer planlanan bitiş saati kalsın diyorsan sadece durum değiştir:
            resv.durum = 'checked_out'
            resv.save(update_fields=['durum'])

        # Event kaydı
        event = CheckEvent.objects.create(
            reservation=resv,
            tip=tip,
            gorevli=request.user
        )

        return Response({
            "detail": "OK",
            "reservation": ReservationDetailSerializer(resv).data,
            "event": CheckEventSerializer(event).data
        }, status=status.HTTP_200_OK)
