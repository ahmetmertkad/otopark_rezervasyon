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

class CheckEventViewSet(viewsets.ModelViewSet):
    """
    /check-events/ CRUD
    Sadece admin (veya görevli) kullanıcılar yazma yapabilsin diye IsAdminUser.
    """
    queryset = CheckEvent.objects.select_related('reservation', 'gorevli').all()
    serializer_class = CheckEventSerializer
    permission_classes = [permissions.IsAdminUser]
