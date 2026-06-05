from django.http import HttpResponse
from rest_framework import status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from users.access import ROL_ADMIN, ROL_VISUALIZACION, require_roles

from .models import Eje
from .planificacion_import import (
    LEGACY_ANIO,
    PLANTILLA_CSV,
    import_planificacion_rows,
    parse_planificacion_file,
)


class PlanificacionPeriodosView(APIView):
    """Lista los años de planificación disponibles."""

    def get(self, request):
        require_roles(
            request.user,
            ROL_ADMIN,
            ROL_VISUALIZACION,
            message='Solo Administrador o Visualización pueden consultar la planificación.',
        )
        from django.utils import timezone
        actual = timezone.now().year
        periodos = sorted(set(Eje.objects.values_list('anio', flat=True).distinct()) | {LEGACY_ANIO, actual})
        return Response({
            'periodos': periodos,
            'actual': actual,
            'planificacion_base': LEGACY_ANIO,
        })


class PlanificacionPlantillaView(APIView):
    """Descarga plantilla CSV para importación masiva."""

    def get(self, request):
        require_roles(
            request.user,
            ROL_ADMIN,
            ROL_VISUALIZACION,
            message='Solo Administrador o Visualización pueden consultar la planificación.',
        )
        response = HttpResponse(PLANTILLA_CSV, content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = 'attachment; filename="plantilla_planificacion.csv"'
        return response


class PlanificacionImportView(APIView):
    """Importa planificación anual desde Excel (.xlsx) o CSV."""

    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        require_roles(
            request.user,
            ROL_ADMIN,
            message='Solo el Administrador puede importar planificación.',
        )
        archivo = request.FILES.get('archivo')
        if not archivo:
            return Response({'detail': 'Debe adjuntar un archivo.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            anio = int(request.data.get('anio') or request.query_params.get('anio') or 0)
        except (TypeError, ValueError):
            return Response({'detail': 'El año indicado no es válido.'}, status=status.HTTP_400_BAD_REQUEST)

        if anio < 2000 or anio > 2100:
            return Response({'detail': 'El año debe estar entre 2000 y 2100.'}, status=status.HTTP_400_BAD_REQUEST)

        if anio == LEGACY_ANIO:
            return Response(
                {
                    'detail': (
                        'La planificación 2026 ya está cargada en el sistema. '
                        'Gestiónela desde el panel (ABM). Para cargar otro período, seleccione un año distinto.'
                    ),
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        nombre = getattr(archivo, 'name', '') or 'archivo.csv'
        ext = nombre.rsplit('.', 1)[-1].lower() if '.' in nombre else ''
        if ext not in ('csv', 'xlsx', 'xlsm'):
            return Response(
                {'detail': 'Formato no soportado. Use archivos .xlsx o .csv.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        max_mb = 10
        if getattr(archivo, 'size', 0) > max_mb * 1024 * 1024:
            return Response(
                {'detail': f'El archivo excede el tamaño máximo de {max_mb} MB.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            content = archivo.read()
            rows = parse_planificacion_file(nombre, content)
            stats = import_planificacion_rows(rows, anio, request.user)
        except ValueError as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception:
            return Response(
                {'detail': 'Error al procesar el archivo. Verifique el formato y la plantilla.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({
            'anio': anio,
            'mensaje': f'Planificación {anio} importada correctamente.',
            'estadisticas': stats,
        })
