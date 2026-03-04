from django.urls import path, include
from rest_framework.routers import DefaultRouter
from users.views import UsuarioViewSet, RolViewSet, UsuariosParaSelectorView
from areas.views import AreaViewSet
from secretarias.views import SecretariaViewSet
from projects.views import (
    EjeViewSet, PlanViewSet, ProgramaViewSet, ObjetivoEstrategicoViewSet, IndicadorViewSet,
    ProyectoViewSet, ProyectoAreaViewSet, ProyectoEquipoViewSet, EtapaViewSet, ComentarioProyectoViewSet,
)
from tasks.views import TareaViewSet, HistorialTareaViewSet
from backup_restore.views import (
    BackupListView,
    BackupCreateView,
    CodeBackupListView,
    CodeBackupCreateView,
    RestoreView,
    SessionHeartbeatView,
    SessionEndView,
)
from dashboards.views import (
    DashboardEjecutivoView,
    ProyectosPorUsuarioView,
    ProyectosDashboardView,
    EvolucionProyectoView,
    AlertasVencimientoView,
    AvancesPorAreaView,
    AvancesPorSecretariaView,
    PlanificacionArbolView,
)

router = DefaultRouter()
router.register("roles", RolViewSet)
router.register("usuarios", UsuarioViewSet)
router.register("areas", AreaViewSet)
router.register("secretarias", SecretariaViewSet)
router.register("ejes", EjeViewSet)
router.register("planes", PlanViewSet)
router.register("programas", ProgramaViewSet)
router.register("objetivos-estrategicos", ObjetivoEstrategicoViewSet)
router.register("indicadores", IndicadorViewSet)
router.register("proyectos", ProyectoViewSet)
router.register("proyecto-area", ProyectoAreaViewSet)
router.register("proyecto-equipo", ProyectoEquipoViewSet)
router.register("etapas", EtapaViewSet)
router.register("comentarios-proyecto", ComentarioProyectoViewSet)
router.register("tareas", TareaViewSet)
router.register("historial", HistorialTareaViewSet)

urlpatterns = [
    path("usuarios/selector/", UsuariosParaSelectorView.as_view()),
    path("", include(router.urls)),
    path("dashboard/ejecutivo/", DashboardEjecutivoView.as_view()),
    path("dashboard/proyectos/", ProyectosDashboardView.as_view()),
    path("dashboard/proyectos/<int:proyecto_id>/evolucion/", EvolucionProyectoView.as_view()),
    path("dashboard/usuarios/<int:usuario_id>/proyectos/", ProyectosPorUsuarioView.as_view()),
    path("dashboard/alertas-vencimiento/", AlertasVencimientoView.as_view()),
    path("avances/por-area/", AvancesPorAreaView.as_view()),
    path("avances/por-secretaria/", AvancesPorSecretariaView.as_view()),
    path("planificacion/arbol/", PlanificacionArbolView.as_view()),
    path("backup-restore/backups/", BackupListView.as_view()),
    path("backup-restore/backup/", BackupCreateView.as_view()),
    path("backup-restore/code-backups/", CodeBackupListView.as_view()),
    path("backup-restore/code-backup/", CodeBackupCreateView.as_view()),
    path("backup-restore/restore/", RestoreView.as_view()),
    path("backup-restore/session/heartbeat/", SessionHeartbeatView.as_view()),
    path("backup-restore/session/end/", SessionEndView.as_view()),
]
