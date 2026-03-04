from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import Usuario, Rol


class RolSerializer(serializers.ModelSerializer):
    class Meta:
        model = Rol
        fields = "__all__"


class UsuarioSerializer(serializers.ModelSerializer):
    rol_nombre = serializers.CharField(source='rol.nombre', read_only=True)
    area_nombre = serializers.SerializerMethodField()
    secretaria_nombre = serializers.SerializerMethodField()
    nombre_completo = serializers.CharField(read_only=True)

    def get_area_nombre(self, obj):
        return obj.area.nombre if obj.area else ''

    def get_secretaria_nombre(self, obj):
        return obj.secretaria.nombre if obj.secretaria else ''

    def _validar_password(self, password):
        if not password:
            return
        if len(password) < 8:
            raise serializers.ValidationError({'password': 'Mínimo 8 caracteres.'})
        if not any(c.isupper() for c in password):
            raise serializers.ValidationError({'password': 'Al menos una mayúscula.'})
        if not any(c.islower() for c in password):
            raise serializers.ValidationError({'password': 'Al menos una minúscula.'})
        if not any(c.isdigit() for c in password):
            raise serializers.ValidationError({'password': 'Al menos un número.'})
        if not any(c in '!@#$%^&*()_+-=[]{};\':"|,.<>/?`~' for c in password):
            raise serializers.ValidationError({'password': 'Al menos un carácter especial.'})

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        if password:
            validated_data['password'] = make_password(password)
        return super().create(validated_data)

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        if password:
            validated_data['password'] = make_password(password)
        return super().update(instance, validated_data)

    def validate(self, data):
        password = data.get('password')
        if password:
            self._validar_password(password)
        rol = data.get('rol')
        if isinstance(rol, int):
            rol = Rol.objects.filter(pk=rol).first()
        elif self.instance and 'rol' not in data:
            rol = self.instance.rol
        area = data.get('area')
        secretaria = data.get('secretaria')
        if self.instance:
            area = area if 'area' in data else self.instance.area
            secretaria = secretaria if 'secretaria' in data else self.instance.secretaria
        if area and secretaria:
            raise serializers.ValidationError(
                'Un usuario puede pertenecer a un Área O a una Secretaría, no a ambas.'
            )
        if rol and rol.nombre == 'Carga':
            if not area and not secretaria:
                raise serializers.ValidationError(
                    'Para el rol Carga es obligatorio asignar un Área o una Secretaría.'
                )
        return data

    class Meta:
        model = Usuario
        fields = ['id', 'nombre', 'apellido', 'nombre_completo', 'email', 'password', 'rol', 'rol_nombre',
                  'area', 'area_nombre', 'secretaria', 'secretaria_nombre', 'estado', 'fecha_creacion']
        extra_kwargs = {'password': {'write_only': True}}
