"""
Asigna un proyecto a un usuario para que lo vea en "Mis Proyectos" y "Cargar avances".
Uso: python manage.py asignar_proyecto_usuario --proyecto=4 --usuario=David --area=Desarrollo

Opciones:
  --proyecto: ID o nombre del proyecto
  --usuario: email o nombre del usuario (ej: David, david@...)
  --area: nombre del área a asignar al proyecto (ProyectoArea)
  --responsable: si se indica, crea una tarea de ejemplo con el usuario como responsable (si el proyecto no tiene tareas)
"""
from django.core.management.base import BaseCommand
from users.models import Usuario
from projects.models import Proyecto, ProyectoArea, Etapa
from areas.models import Area
from tasks.models import Tarea


class Command(BaseCommand):
    help = 'Asigna un proyecto a un usuario para que lo vea en Mis Proyectos / Cargar avances'

    def add_arguments(self, parser):
        parser.add_argument('--proyecto', type=str, required=True, help='ID o nombre del proyecto')
        parser.add_argument('--usuario', type=str, required=True, help='Email o nombre del usuario')
        parser.add_argument('--area', type=str, help='Nombre del área - asigna el proyecto a esta área')
        parser.add_argument('--responsable', action='store_true', help='Asignar usuario como responsable de tareas existentes')

    def handle(self, *args, **options):
        proy_arg = options['proyecto']
        user_arg = options['usuario']
        area_nombre = options.get('area')
        hacer_responsable = options.get('responsable', False)

        proyecto = None
        if proy_arg.isdigit():
            proyecto = Proyecto.objects.filter(id=int(proy_arg)).first()
        if not proyecto:
            proyecto = Proyecto.objects.filter(nombre__icontains=proy_arg).first()
        if not proyecto:
            self.stdout.write(self.style.ERROR(f'Proyecto "{proy_arg}" no encontrado.'))
            return

        usuario = Usuario.objects.filter(email__icontains=user_arg).first()
        if not usuario:
            usuario = Usuario.objects.filter(nombre__icontains=user_arg).first()
        if not usuario:
            self.stdout.write(self.style.ERROR(f'Usuario "{user_arg}" no encontrado.'))
            return

        cambios = []

        if area_nombre:
            area = Area.objects.filter(nombre__iexact=area_nombre).first()
            if not area:
                area = Area.objects.filter(nombre__icontains=area_nombre).first()
            if area:
                _, created = ProyectoArea.objects.get_or_create(proyecto=proyecto, area=area)
                if created:
                    cambios.append(f'Proyecto "{proyecto.nombre}" asignado al área "{area.nombre}"')
                else:
                    cambios.append(f'Proyecto "{proyecto.nombre}" ya estaba en el área "{area.nombre}"')
                if not usuario.area_id or usuario.area_id != area.id:
                    usuario.area = area
                    usuario.save(update_fields=['area'])
                    cambios.append(f'Usuario "{usuario.nombre_completo}" asignado al área "{area.nombre}"')
            else:
                self.stdout.write(self.style.WARNING(f'Área "{area_nombre}" no encontrada.'))

        if hacer_responsable:
            tareas = Tarea.objects.filter(proyecto=proyecto)
            if not tareas.exists():
                etapa = Etapa.objects.filter(proyecto=proyecto).first()
                if etapa:
                    area_tarea = usuario.area or Area.objects.first()
                    if area_tarea:
                        t = Tarea.objects.create(
                            proyecto=proyecto, etapa=etapa, area=area_tarea,
                            titulo='Tarea asignada', responsable=usuario,
                            fecha_inicio=proyecto.fecha_inicio, fecha_vencimiento=proyecto.fecha_fin_estimada,
                        )
                        cambios.append(f'Tarea "{t.titulo}" creada con {usuario.nombre_completo} como responsable.')
                else:
                    self.stdout.write(self.style.WARNING('El proyecto no tiene etapas. Cree una etapa primero.'))
            else:
                count = tareas.update(responsable=usuario)
                cambios.append(f'{count} tarea(s) actualizadas con {usuario.nombre_completo} como responsable.')

        if cambios:
            self.stdout.write(self.style.SUCCESS('\n'.join(cambios)))
        else:
            self.stdout.write(self.style.WARNING('No se realizaron cambios. Use --area y/o --responsable.'))
