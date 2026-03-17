from rest_framework.test import APITestCase

from areas.models import Area
from projects.models import Proyecto
from users.models import Rol, Usuario


class ProyectoPresupuestoTests(APITestCase):
    def setUp(self):
        self.rol_admin = Rol.objects.create(nombre="Administrador", descripcion="Admin")
        self.admin = Usuario.objects.create(
            nombre="Admin",
            apellido="SIPRA",
            email="admin-proyectos@test.local",
            password="test",
            rol=self.rol_admin,
            estado=True,
        )
        self.area = Area.objects.create(nombre="Planificacion", descripcion="", estado=True)
        self.client.force_authenticate(user=self.admin)

    def _payload_base(self):
        return {
            "nombre": "Proyecto con presupuesto",
            "descripcion": "Proyecto de prueba",
            "fecha_inicio": "2026-03-01",
            "fecha_fin_estimada": "2026-06-30",
            "estado": "Activo",
            "presupuesto_total": "1357500.00",
            "fuente_financiamiento": "CFI",
            "usuario_responsable": self.admin.id,
            "area": self.area.id,
            "secretaria": None,
            "equipo": [],
            "presupuesto_items": [
                {
                    "categoria_gasto": "Equipamiento",
                    "monto": "1357500.00",
                    "detalle": "",
                    "orden": 0,
                },
                {
                    "categoria_gasto": "Gastos operativos y logisticos",
                    "monto": "0.00",
                    "detalle": "Sin erogacion operativa",
                    "orden": 1,
                },
                {
                    "categoria_gasto": "Dotacion",
                    "monto": "0.00",
                    "detalle": "Personal de la Agencia de Innovacion",
                    "orden": 2,
                },
            ],
        }

    def test_crea_proyecto_con_presupuesto_y_items(self):
        response = self.client.post("/api/proyectos/", self._payload_base(), format="json")

        self.assertEqual(response.status_code, 201)
        proyecto = Proyecto.objects.get(nombre="Proyecto con presupuesto")
        self.assertEqual(str(proyecto.presupuesto_total), "1357500.00")
        self.assertEqual(proyecto.fuente_financiamiento, "CFI")
        self.assertEqual(proyecto.presupuesto_items.count(), 3)

    def test_rechaza_gastos_que_superan_presupuesto_total(self):
        payload = self._payload_base()
        payload["presupuesto_total"] = "1000.00"
        payload["presupuesto_items"][0]["monto"] = "1200.00"

        response = self.client.post("/api/proyectos/", payload, format="json")

        self.assertEqual(response.status_code, 400)
        self.assertIn("presupuesto_items", response.data)

    def test_actualiza_items_presupuestarios_en_edicion(self):
        create_response = self.client.post("/api/proyectos/", self._payload_base(), format="json")
        self.assertEqual(create_response.status_code, 201)
        proyecto_id = create_response.data["id"]
        item_id = create_response.data["presupuesto_items"][0]["id"]

        payload = {
            "presupuesto_total": "1500000.00",
            "fuente_financiamiento": "Provincial",
            "presupuesto_items": [
                {
                    "id": item_id,
                    "categoria_gasto": "Equipamiento",
                    "monto": "1500000.00",
                    "detalle": "",
                    "orden": 0,
                }
            ],
        }

        response = self.client.patch(f"/api/proyectos/{proyecto_id}/", payload, format="json")

        self.assertEqual(response.status_code, 200)
        proyecto = Proyecto.objects.get(id=proyecto_id)
        self.assertEqual(str(proyecto.presupuesto_total), "1500000.00")
        self.assertEqual(proyecto.fuente_financiamiento, "Provincial")
        self.assertEqual(proyecto.presupuesto_items.count(), 1)
