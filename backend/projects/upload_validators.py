from __future__ import annotations

from pathlib import Path

from django.conf import settings
from rest_framework import serializers


def validate_uploaded_file(file_obj):
    if not file_obj:
        return file_obj

    max_size_mb = max(int(getattr(settings, 'MAX_UPLOAD_SIZE_MB', 10)), 1)
    max_size_bytes = max_size_mb * 1024 * 1024
    if getattr(file_obj, 'size', 0) > max_size_bytes:
        raise serializers.ValidationError(
            f'El archivo excede el tamaño máximo permitido de {max_size_mb} MB.'
        )

    allowed_exts = {
        ext.lower().lstrip('.')
        for ext in getattr(settings, 'ALLOWED_UPLOAD_EXTENSIONS', [])
        if ext
    }
    extension = Path(getattr(file_obj, 'name', '')).suffix.lower().lstrip('.')
    if allowed_exts and extension not in allowed_exts:
        raise serializers.ValidationError(
            'Tipo de archivo no permitido. Extensiones válidas: '
            + ', '.join(sorted(allowed_exts))
        )
    return file_obj


def validate_original_filename(value: str):
    cleaned = (value or '').strip()
    if not cleaned:
        raise serializers.ValidationError('El nombre del archivo es obligatorio.')
    if len(cleaned) > 255:
        raise serializers.ValidationError('El nombre del archivo no puede superar los 255 caracteres.')
    return cleaned
