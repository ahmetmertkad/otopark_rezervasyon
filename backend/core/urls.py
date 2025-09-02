from django.contrib import admin
from django.urls import path, include


urlpatterns = [
    path('admin/', admin.site.urls),

    # API endpointleri
    path('reservation/', include('reservations.urls')),
    path('account/', include('accounts.urls')),
]
