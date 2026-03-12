from django.db import models
from users.models import Usuario
from areas.models import Area


class Eje(models.Model):
    """Eje estratégico de la planificación 2026."""
    id_eje = models.IntegerField(primary_key=True)
    nombre_eje = models.CharField(max_length=300)

    class Meta:
        ordering = ['id_eje']
        verbose_name = 'Eje'
        verbose_name_plural = 'Ejes'

    def __str__(self):
        return self.nombre_eje


class Plan(models.Model):
    """Plan asociado a un eje estratégico."""
    id_plan = models.IntegerField(primary_key=True)
    eje = models.ForeignKey(Eje, on_delete=models.CASCADE, related_name='planes')
    nombre_plan = models.CharField(max_length=300)
    proposito_politica_publica = models.TextField(blank=True)
    vision_estrategica = models.TextField(blank=True)

    class Meta:
        ordering = ['id_plan']
        verbose_name = 'Plan'
        verbose_name_plural = 'Planes'

    def __str__(self):
        return self.nombre_plan


class Programa(models.Model):
    """Programa asociado a un plan."""
    id_programa = models.CharField(max_length=10, primary_key=True)
    plan = models.ForeignKey(Plan, on_delete=models.CASCADE, related_name='programas')
    nombre_programa = models.CharField(max_length=500)

    class Meta:
        ordering = ['id_programa']
        verbose_name = 'Programa'
        verbose_name_plural = 'Programas'

    def __str__(self):
        return self.nombre_programa


class ObjetivoEstrategico(models.Model):
    """Objetivo estratégico asociado a un programa."""
    programa = models.ForeignKey(Programa, on_delete=models.CASCADE, related_name='objetivos_estrategicos')
    descripcion = models.TextField()

    class Meta:
        ordering = ['id']
        verbose_name = 'Objetivo Estratégico'
        verbose_name_plural = 'Objetivos Estratégicos'

    def __str__(self):
        return self.descripcion[:80] + ('...' if len(self.descripcion) > 80 else '')


class Proyecto(models.Model):
    ESTADOS = [
        ("Activo", "Activo"),
        ("En pausa", "En pausa"),
        ("Finalizado", "Finalizado"),
    ]

    nombre = models.CharField(max_length=150)
    descripcion = models.TextField(blank=True)
    fecha_inicio = models.DateField()
    fecha_fin_estimada = models.DateField()
    fecha_fin_real = models.DateField(null=True, blank=True)
    estado = models.CharField(max_length=20, choices=ESTADOS, default="Activo")
    porcentaje_avance = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    creado_por = models.ForeignKey(Usuario, on_delete=models.PROTECT)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    programa = models.ForeignKey(
        Programa, on_delete=models.SET_NULL, null=True, blank=True, related_name='proyectos'
    )
    objetivo_estrategico = models.ForeignKey(
        ObjetivoEstrategico, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='proyectos'
    )
    # Responsable Principal: puede cargar avances, crear tareas, asignar, cerrar proyecto
    usuario_responsable = models.ForeignKey(
        Usuario, on_delete=models.PROTECT, null=True, blank=True,
        related_name='proyectos_a_cargo'
    )
    # Dependencia organizacional: área XOR secretaría (uno debe tener valor)
    area = models.ForeignKey(
        Area, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='proyectos'
    )
    secretaria = models.ForeignKey(
        'secretarias.Secretaria', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='proyectos'
    )

    def clean(self):
        from django.core.exceptions import ValidationError
        if self.area and self.secretaria:
            raise ValidationError('Seleccione solo un Área o una Secretaría, no ambos.')

    def __str__(self):
        return self.nombre

    class Meta:
        indexes = [
            models.Index(fields=["estado", "fecha_fin_estimada"], name="proy_estado_fin_idx"),
            models.Index(fields=["area", "estado"], name="proy_area_estado_idx"),
            models.Index(fields=["secretaria", "estado"], name="proy_sec_estado_idx"),
        ]


class Indicador(models.Model):
    """Indicador de seguimiento asociado a un proyecto."""
    proyecto = models.ForeignKey(
        Proyecto, on_delete=models.CASCADE, related_name='indicadores'
    )
    descripcion = models.TextField(blank=True)
    unidad_medida = models.CharField(max_length=50, blank=True)
    frecuencia = models.CharField(max_length=50, blank=True)

    class Meta:
        verbose_name = 'Indicador'
        verbose_name_plural = 'Indicadores'

    def __str__(self):
        return self.descripcion[:60] + ('...' if len(self.descripcion) > 60 else '')


class ProyectoArea(models.Model):
    proyecto = models.ForeignKey(Proyecto, on_delete=models.CASCADE)
    area = models.ForeignKey(Area, on_delete=models.CASCADE)

    class Meta:
        unique_together = ("proyecto", "area")


class ProyectoEquipo(models.Model):
    """Miembros del equipo asignados a un proyecto (participan, permisos limitados)."""
    proyecto = models.ForeignKey(Proyecto, on_delete=models.CASCADE, related_name='equipo')
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='proyectos_equipo')

    class Meta:
        unique_together = ("proyecto", "usuario")
        verbose_name = "Miembro del equipo"
        verbose_name_plural = "Equipo del proyecto"


class Etapa(models.Model):
    proyecto = models.ForeignKey(Proyecto, on_delete=models.CASCADE, related_name="etapas")
    nombre = models.CharField(max_length=120)
    orden = models.IntegerField(default=1)
    estado = models.CharField(max_length=30, blank=True)
    porcentaje_avance = models.DecimalField(max_digits=5, decimal_places=2, default=0)

    class Meta:
        ordering = ["orden"]


class ComentarioProyecto(models.Model):
    """Comentarios u observaciones sobre el avance del proyecto (para jefes/dirección)."""
    proyecto = models.ForeignKey(Proyecto, on_delete=models.CASCADE, related_name="comentarios")
    usuario = models.ForeignKey(Usuario, on_delete=models.PROTECT)
    texto = models.TextField()
    fecha = models.DateTimeField(auto_now_add=True)
    fecha_edicion = models.DateTimeField(null=True, blank=True)
    editado_por = models.ForeignKey(
        Usuario, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="comentarios_proyecto_editados"
    )

    class Meta:
        ordering = ["-fecha"]


class ComentarioAuditLog(models.Model):
    """Registro de ediciones/eliminaciones de comentarios por administrador."""
    ACCION_CHOICES = [("editar", "Editar"), ("eliminar", "Eliminar")]
    TIPO_CHOICES = [("proyecto", "Proyecto"), ("tarea", "Tarea")]

    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES)
    comentario_id = models.IntegerField()
    accion = models.CharField(max_length=20, choices=ACCION_CHOICES)
    usuario = models.ForeignKey(Usuario, on_delete=models.PROTECT)
    fecha = models.DateTimeField(auto_now_add=True)
    texto_anterior = models.TextField(blank=True)
    texto_nuevo = models.TextField(blank=True)
    proyecto_id = models.IntegerField(null=True, blank=True)
    tarea_id = models.IntegerField(null=True, blank=True)

    class Meta:
        ordering = ["-fecha"]


class AdjuntoAuditLog(models.Model):
    """Registro de ediciones/eliminaciones de adjuntos (trazabilidad para administrador)."""
    ACCION_CHOICES = [("editar", "Editar"), ("eliminar", "Eliminar")]
    TIPO_CHOICES = [("proyecto", "Proyecto"), ("tarea", "Tarea")]

    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES)
    adjunto_id = models.IntegerField()
    accion = models.CharField(max_length=20, choices=ACCION_CHOICES)
    usuario = models.ForeignKey(Usuario, on_delete=models.PROTECT)
    fecha = models.DateTimeField(auto_now_add=True)
    nombre_archivo = models.CharField(max_length=255, blank=True)
    nombre_anterior = models.CharField(max_length=255, blank=True)
    nombre_nuevo = models.CharField(max_length=255, blank=True)
    proyecto_id = models.IntegerField(null=True, blank=True)
    tarea_id = models.IntegerField(null=True, blank=True)

    class Meta:
        ordering = ["-fecha"]


class AdjuntoProyecto(models.Model):
    """Archivos adjuntos a un proyecto."""
    proyecto = models.ForeignKey(Proyecto, on_delete=models.CASCADE, related_name="adjuntos")
    archivo = models.FileField(upload_to="adjuntos/proyectos/%Y/%m/")
    nombre_original = models.CharField(max_length=255)
    subido_por = models.ForeignKey(Usuario, on_delete=models.PROTECT)
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-fecha"]
