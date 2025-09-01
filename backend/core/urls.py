from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from reservations.views import RatePlanViewSet
from reservations.views import ParkingLotViewSet

# DRF router
router = DefaultRouter()
router.register(r'lots', ParkingLotViewSet, basename='lots')
router.register(r'rateplans', RatePlanViewSet, basename='rateplans')

urlpatterns = [
    path('admin/', admin.site.urls),

    # API endpointleri
    path('api/', include(router.urls)),
]
