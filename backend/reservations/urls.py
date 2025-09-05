from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CheckByQRView, ParkingLotViewSet, RatePlanViewSet, ReservationViewSet, CheckEventViewSet

router = DefaultRouter()

router.register(r'reservations', ReservationViewSet, basename='reservations')
router.register(r'check-events', CheckEventViewSet, basename='check-events')
router.register(r'lots', ParkingLotViewSet, basename='lots')
router.register(r'rateplans', RatePlanViewSet, basename='rateplans')

urlpatterns = [
    path('', include(router.urls)),
    path('check-by-qr/', CheckByQRView.as_view(), name='check-by-qr'),
]