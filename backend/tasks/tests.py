from datetime import date, timedelta

from django.utils import timezone
from rest_framework.test import APITestCase

from users.models import Rol, Usuario
from tasks.models import Tarea


class TareaViewSetTests(APITestCase):
    def setUp(self):
        self.rol_admin = Rol.objects.create(nombre="Administrador", descripcion="Admin")
        self.admin = Usuario.objects.create(
            nombre="Admin",
            apellido="SIPRA",
            email="admin@test.local",
            password="test",
            rol=self.rol_admin,
            estado=True,
        )
        self.client.force_authenticate(user=self.admin)

    def _crear_tarea(self, *, titulo: str, estado: str, porcentaje_avance: int, dias_offset: int = 0):
        fecha_base = date.today()
        return Tarea.objects.create(
            titulo=titulo,
            descripcion="",
            responsable=self.admin,
            fecha_inicio=fecha_base,
            fecha_vencimiento=fecha_base + timedelta(days=7 + dias_offset),
            estado=estado,
            porcentaje_avance=porcentaje_avance,
            prioridad="Media",
            orden=0,
        )

    def test_resumen_global_devuelve_metricas_correctas(self):
        self._crear_tarea(titulo="T1", estado="Pendiente", porcentaje_avance=0)
        self._crear_tarea(titulo="T2", estado="En proceso", porcentaje_avance=50)
        self._crear_tarea(titulo="T3", estado="Bloqueada", porcentaje_avance=100)

        response = self.client.get("/api/tareas/resumen/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["total"], 3)
        self.assertEqual(response.data["pendientes"], 1)
        self.assertEqual(response.data["en_proceso"], 1)
        self.assertEqual(response.data["bloqueadas"], 1)
        self.assertEqual(response.data["avance_promedio"], 50.0)

    def test_listado_orden_recientes_devuelve_ultimas_primero(self):
        tarea_antigua = self._crear_tarea(titulo="Antigua", estado="Pendiente", porcentaje_avance=10)
        tarea_nueva = self._crear_tarea(titulo="Nueva", estado="Pendiente", porcentaje_avance=20)

        Tarea.objects.filter(id=tarea_antigua.id).update(fecha_creacion=timezone.now() - timedelta(days=2))
        Tarea.objects.filter(id=tarea_nueva.id).update(fecha_creacion=timezone.now())

        response = self.client.get("/api/tareas/", {
            "paginated": 1,
            "page": 1,
            "page_size": 50,
            "orden": "recientes",
        })

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 2)
        titulos = [item["titulo"] for item in response.data["results"]]
        self.assertEqual(titulos, ["Nueva", "Antigua"])
