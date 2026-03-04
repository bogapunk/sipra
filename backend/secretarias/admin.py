from django.contrib import admin
from .models import Secretaria


@admin.register(Secretaria)
class SecretariaAdmin(admin.ModelAdmin):
    list_display = ('codigo', 'nombre', 'activa', 'fecha_creacion')
    list_filter = ('activa',)
    search_fields = ('codigo', 'nombre')
