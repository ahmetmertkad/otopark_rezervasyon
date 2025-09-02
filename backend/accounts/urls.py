from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView, TokenRefreshView, TokenVerifyView
)
from .views import RegisterView, MeView, LogoutView, ChangePasswordView

urlpatterns = [
    path("auth/register", RegisterView.as_view(), name="register"),
    path("auth/token", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("auth/token/refresh", TokenRefreshView.as_view(), name="token_refresh"),
    path("auth/token/verify", TokenVerifyView.as_view(), name="token_verify"),
    path("auth/me", MeView.as_view(), name="me"),
    path("auth/logout", LogoutView.as_view(), name="logout"),
    path("auth/change-password", ChangePasswordView.as_view(), name="change_password"),
]
