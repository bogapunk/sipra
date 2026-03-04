"""
Carga los datos de planificación 2026: ejes, planes, programas y objetivos estratégicos.
"""
from django.core.management.base import BaseCommand
from projects.models import Eje, Plan, Programa, ObjetivoEstrategico


DATOS = [
    # EJE 1
    {
        'eje': (1, 'Fortalecimiento de la Economía del Conocimiento'),
        'plan': (1, '1. Fortalecimiento de la Economía del Conocimiento',
                 'Posicionar a la provincia como hub tecnológico, fomentando el talento local y el crecimiento de empresas de base tecnológica.',
                 'Consolidar a la provincia como hub tecnológico de referencia, impulsando startups, talento especializado e internacionalización de servicios basados en conocimiento.'),
        'programas': [
            ('1.1', 'Impulso al Emprendedurismo Tech'),
            ('1.2', 'Desarrollo de Talento'),
            ('1.3', 'Proyectos de I+D Estratégica'),
            ('1.4', 'Promoción y Radicación de Empresas'),
            ('1.5', 'Actividades de Divulgación'),
            ('1.6', 'Internacionalización de Servicios'),
        ],
        'objetivos': [
            'Acelerar el desarrollo de startups fueguinas.',
            'Reducir la brecha de talento en tecnologías clave.',
            'Generar conocimiento y soluciones para desafíos provinciales.',
            'Ampliar el ecosistema de empresas de la Economía del Conocimiento.',
            'Sensibilización y transferencia de conocimiento.',
            'Exportación de servicios basados en conocimiento.',
        ],
    },
    # EJE 2
    {
        'eje': (2, 'Impulso a la Ciencia y Tecnología'),
        'plan': (2, '2. Impulso a la Ciencia y Tecnología',
                 'Fomentar la investigación aplicada al territorio y la divulgación científica.',
                 'Consolidar la soberanía del conocimiento mediante articulación institucional y apropiación social de la ciencia.'),
        'programas': [
            ('2.1', 'Apropiación Social de la Ciencia, Tecnología e Innovación'),
            ('2.2', 'Vinculación y Articulación Institucional'),
            ('2.3', 'Desarrollo de Capacidades Científico-Tecnológicas'),
        ],
        'objetivos': [
            'Fomentar vocaciones científicas y promover la apropiación social del conocimiento.',
            'Centralizar y coordinar vinculaciones con el sistema científico-tecnológico.',
            'Fortalecer el sistema científico, tecnológico e innovador provincial.',
        ],
    },
    # EJE 3
    {
        'eje': (3, 'Transformación Digital y Gobierno Abierto'),
        'plan': (3, '3. Transformación Digital y Gobierno Abierto',
                 'Modernizar la gestión pública con infraestructura digital centrada en el ciudadano.',
                 'Consolidar un Estado moderno, ágil y transparente.'),
        'programas': [
            ('3.1', 'Modernización del Estado'),
            ('3.2', 'Modernización Administrativa y Financiera'),
            ('3.3', 'Fortalecimiento de la Ciberseguridad'),
            ('3.4', 'Modernización y Fortalecimiento de Infraestructura Digital'),
            ('3.9', 'Actualización y Mejora de Procesos'),
        ],
        'objetivos': [
            'Optimizar eficiencia y transparencia.',
            'Garantizar transparencia y optimización de recursos.',
            'Desarrollar marcos normativos y mejora continua en seguridad informática.',
            'Actualizar telecomunicaciones, terminales, virtualización y almacenamiento.',
            'Implementar procesos ágiles y eficientes.',
        ],
    },
    # EJE 4
    {
        'eje': (4, 'Gestión y Fortalecimiento Institucional'),
        'plan': (4, '4. Gestión y Fortalecimiento Institucional',
                 'Transformar la arquitectura operativa del Estado Provincial.',
                 'Consolidar un modelo de gestión pública resiliente y tecnológicamente robusto.'),
        'programas': [
            ('4.1', 'Desarrollo y Gestión del Talento Interno'),
            ('4.2', 'Alianzas Estratégicas y Comunicación Institucional'),
            ('4.3', 'Actualización de Infraestructura de Telecomunicaciones'),
            ('4.4', 'Actualización de Terminales de Usuarios'),
            ('4.5', 'Implementación de Herramientas de Software'),
            ('4.6', 'Infraestructura de Virtualización'),
            ('4.7', 'Infraestructura de Almacenamiento'),
            ('4.8', 'Plan de Revisión y Mejora Continua'),
            ('4.9', 'Marco Normativo en Ciberseguridad'),
        ],
        'objetivos': [
            'Fortalecer capacidades institucionales del sector público.',
            'Promover convenios y articulaciones interinstitucionales.',
            'Fortalecer conectividad y resiliencia digital.',
            'Modernizar el parque tecnológico.',
            'Adoptar soluciones innovadoras e interoperables.',
            'Garantizar disponibilidad y seguridad de datos.',
            'Consolidar almacenamiento digital seguro y escalable.',
            'Garantizar mejora continua y auditorías periódicas.',
            'Reforzar normativa de protección y ciberseguridad.',
        ],
    },
    # EJE 5
    {
        'eje': (5, 'Fortalecimiento del Acceso y Desarrollo Cultural'),
        'plan': (5, '5. Fortalecimiento del Acceso y Desarrollo Cultural',
                 'Promover identidad fueguina y democratizar el acceso cultural.',
                 'Consolidar un ecosistema cultural inclusivo y participativo.'),
        'programas': [
            ('5.1', 'Promoción y Circulación Cultural'),
            ('5.2', 'Ferias y Mercados'),
            ('5.3', 'Circulación Audiovisual'),
            ('5.4', 'Democratización Cultural'),
            ('5.5', 'Fortalecimiento del Patrimonio Cultural'),
        ],
        'objetivos': [
            'Promover producción y acceso a contenidos culturales.',
            'Impulsar comercialización de artistas locales.',
            'Fortalecer redes y proyectos audiovisuales.',
            'Ampliar acceso cultural a toda la población.',
            'Revalorizar expresiones tradicionales.',
        ],
    },
    # EJE 6
    {
        'eje': (6, 'Monetización y Generación de Recursos Propios'),
        'plan': (6, '6. Monetización y Generación de Recursos Propios',
                 'Generar ingresos para sostenibilidad de la Agencia.',
                 'Garantizar autonomía financiera mediante articulación público-privada.'),
        'programas': [
            ('6.1', 'Acuerdos Público-Privados'),
            ('6.2', 'Plataformas y Servicios para Terceros'),
            ('6.3', 'Administración Financiera Sustentable'),
        ],
        'objetivos': [
            'Articular acuerdos estratégicos.',
            'Desarrollar soluciones digitales rentables.',
            'Generar y administrar recursos sostenibles.',
        ],
    },
]


class Command(BaseCommand):
    help = 'Carga ejes, planes, programas y objetivos estratégicos de la planificación 2026'

    def handle(self, *args, **options):
        for item in DATOS:
            id_eje, nombre_eje = item['eje']
            eje, _ = Eje.objects.update_or_create(
                id_eje=id_eje,
                defaults={'nombre_eje': nombre_eje}
            )

            id_plan, nombre_plan, proposito, vision = item['plan']
            plan, _ = Plan.objects.update_or_create(
                id_plan=id_plan,
                defaults={
                    'eje': eje,
                    'nombre_plan': nombre_plan,
                    'proposito_politica_publica': proposito,
                    'vision_estrategica': vision,
                }
            )

            for i, (id_prog, nombre_prog) in enumerate(item['programas']):
                programa, _ = Programa.objects.update_or_create(
                    id_programa=id_prog,
                    defaults={
                        'plan': plan,
                        'nombre_programa': nombre_prog,
                    }
                )
                obj_desc = item['objetivos'][i] if i < len(item['objetivos']) else ''
                if obj_desc:
                    ObjetivoEstrategico.objects.get_or_create(
                        programa=programa,
                        descripcion=obj_desc,
                    )

        self.stdout.write(self.style.SUCCESS(
            f'Planificación 2026 cargada: {Eje.objects.count()} ejes, '
            f'{Plan.objects.count()} planes, {Programa.objects.count()} programas, '
            f'{ObjetivoEstrategico.objects.count()} objetivos estratégicos.'
        ))
