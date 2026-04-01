-- SIPRA Backup - Microsoft SQL Server
-- Generado: 2026-03-27T14:45:32.151927
-- Restaurar con: sqlcmd -S servidor -d Sipra -i archivo.sql

SET NOCOUNT ON;
SET XACT_ABORT ON;

SET IDENTITY_INSERT [dbo].[areas_area] ON;
INSERT INTO [dbo].[areas_area] ([id], [nombre], [descripcion], [estado], [usuario_responsable_area_id], [trial174], [TRIAL361])
VALUES
    (1, 'Presidencia', '', 1, NULL, 'T', 'T'),
    (2, 'Desarrollo', '', 1, NULL, 'T', 'T'),
    (3, 'Infraestructura', '', 1, NULL, 'T', 'T'),
    (4, 'Comunicación', '', 1, NULL, 'T', 'T'),
    (5, 'Recursos Humanos', '', 1, NULL, 'T', 'T');

SET IDENTITY_INSERT [dbo].[areas_area] OFF;
GO

-- Tabla [dbo].[auth_group]: sin datos

-- Tabla [dbo].[auth_group_permissions]: sin datos

SET IDENTITY_INSERT [dbo].[auth_permission] ON;
INSERT INTO [dbo].[auth_permission] ([id], [content_type_id], [codename], [name], [trial177], [TRIAL364])
VALUES
    (1, 1, 'add_logentry', 'Can add log entry', 'T', 'T'),
    (2, 1, 'change_logentry', 'Can change log entry', 'T', 'T'),
    (3, 1, 'delete_logentry', 'Can delete log entry', 'T', 'T'),
    (4, 1, 'view_logentry', 'Can view log entry', 'T', 'T'),
    (5, 2, 'add_permission', 'Can add permission', 'T', 'T'),
    (6, 2, 'change_permission', 'Can change permission', 'T', 'T'),
    (7, 2, 'delete_permission', 'Can delete permission', 'T', 'T'),
    (8, 2, 'view_permission', 'Can view permission', 'T', 'T'),
    (9, 3, 'add_group', 'Can add group', 'T', 'T'),
    (10, 3, 'change_group', 'Can change group', 'T', 'T'),
    (11, 3, 'delete_group', 'Can delete group', 'T', 'T'),
    (12, 3, 'view_group', 'Can view group', 'T', 'T'),
    (13, 4, 'add_user', 'Can add user', 'T', 'T'),
    (14, 4, 'change_user', 'Can change user', 'T', 'T'),
    (15, 4, 'delete_user', 'Can delete user', 'T', 'T'),
    (16, 4, 'view_user', 'Can view user', 'T', 'T'),
    (17, 5, 'add_contenttype', 'Can add content type', 'T', 'T'),
    (18, 5, 'change_contenttype', 'Can change content type', 'T', 'T'),
    (19, 5, 'delete_contenttype', 'Can delete content type', 'T', 'T'),
    (20, 5, 'view_contenttype', 'Can view content type', 'T', 'T'),
    (21, 6, 'add_session', 'Can add session', 'T', 'T'),
    (22, 6, 'change_session', 'Can change session', 'T', 'T'),
    (23, 6, 'delete_session', 'Can delete session', 'T', 'T'),
    (24, 6, 'view_session', 'Can view session', 'T', 'T'),
    (25, 7, 'add_rol', 'Can add rol', 'T', 'T'),
    (26, 7, 'change_rol', 'Can change rol', 'T', 'T'),
    (27, 7, 'delete_rol', 'Can delete rol', 'T', 'T'),
    (28, 7, 'view_rol', 'Can view rol', 'T', 'T'),
    (29, 8, 'add_usuario', 'Can add usuario', 'T', 'T'),
    (30, 8, 'change_usuario', 'Can change usuario', 'T', 'T'),
    (31, 8, 'delete_usuario', 'Can delete usuario', 'T', 'T'),
    (32, 8, 'view_usuario', 'Can view usuario', 'T', 'T'),
    (33, 9, 'add_area', 'Can add area', 'T', 'T'),
    (34, 9, 'change_area', 'Can change area', 'T', 'T'),
    (35, 9, 'delete_area', 'Can delete area', 'T', 'T'),
    (36, 9, 'view_area', 'Can view area', 'T', 'T'),
    (37, 10, 'add_secretaria', 'Can add Secretaría', 'T', 'T'),
    (38, 10, 'change_secretaria', 'Can change Secretaría', 'T', 'T'),
    (39, 10, 'delete_secretaria', 'Can delete Secretaría', 'T', 'T'),
    (40, 10, 'view_secretaria', 'Can view Secretaría', 'T', 'T'),
    (41, 11, 'add_proyecto', 'Can add proyecto', 'T', 'T'),
    (42, 11, 'change_proyecto', 'Can change proyecto', 'T', 'T'),
    (43, 11, 'delete_proyecto', 'Can delete proyecto', 'T', 'T'),
    (44, 11, 'view_proyecto', 'Can view proyecto', 'T', 'T'),
    (45, 12, 'add_etapa', 'Can add etapa', 'T', 'T'),
    (46, 12, 'change_etapa', 'Can change etapa', 'T', 'T'),
    (47, 12, 'delete_etapa', 'Can delete etapa', 'T', 'T'),
    (48, 12, 'view_etapa', 'Can view etapa', 'T', 'T'),
    (49, 13, 'add_proyectoarea', 'Can add proyecto area', 'T', 'T'),
    (50, 13, 'change_proyectoarea', 'Can change proyecto area', 'T', 'T'),
    (51, 13, 'delete_proyectoarea', 'Can delete proyecto area', 'T', 'T'),
    (52, 13, 'view_proyectoarea', 'Can view proyecto area', 'T', 'T'),
    (53, 14, 'add_comentarioproyecto', 'Can add comentario proyecto', 'T', 'T'),
    (54, 14, 'change_comentarioproyecto', 'Can change comentario proyecto', 'T', 'T'),
    (55, 14, 'delete_comentarioproyecto', 'Can delete comentario proyecto', 'T', 'T'),
    (56, 14, 'view_comentarioproyecto', 'Can view comentario proyecto', 'T', 'T'),
    (57, 15, 'add_eje', 'Can add Eje', 'T', 'T'),
    (58, 15, 'change_eje', 'Can change Eje', 'T', 'T'),
    (59, 15, 'delete_eje', 'Can delete Eje', 'T', 'T'),
    (60, 15, 'view_eje', 'Can view Eje', 'T', 'T'),
    (61, 16, 'add_plan', 'Can add Plan', 'T', 'T'),
    (62, 16, 'change_plan', 'Can change Plan', 'T', 'T'),
    (63, 16, 'delete_plan', 'Can delete Plan', 'T', 'T'),
    (64, 16, 'view_plan', 'Can view Plan', 'T', 'T'),
    (65, 17, 'add_programa', 'Can add Programa', 'T', 'T'),
    (66, 17, 'change_programa', 'Can change Programa', 'T', 'T'),
    (67, 17, 'delete_programa', 'Can delete Programa', 'T', 'T'),
    (68, 17, 'view_programa', 'Can view Programa', 'T', 'T'),
    (69, 18, 'add_objetivoestrategico', 'Can add Objetivo Estratégico', 'T', 'T'),
    (70, 18, 'change_objetivoestrategico', 'Can change Objetivo Estratégico', 'T', 'T'),
    (71, 18, 'delete_objetivoestrategico', 'Can delete Objetivo Estratégico', 'T', 'T'),
    (72, 18, 'view_objetivoestrategico', 'Can view Objetivo Estratégico', 'T', 'T'),
    (73, 19, 'add_indicador', 'Can add Indicador', 'T', 'T'),
    (74, 19, 'change_indicador', 'Can change Indicador', 'T', 'T'),
    (75, 19, 'delete_indicador', 'Can delete Indicador', 'T', 'T'),
    (76, 19, 'view_indicador', 'Can view Indicador', 'T', 'T'),
    (77, 20, 'add_proyectoequipo', 'Can add Miembro del equipo', 'T', 'T'),
    (78, 20, 'change_proyectoequipo', 'Can change Miembro del equipo', 'T', 'T'),
    (79, 20, 'delete_proyectoequipo', 'Can delete Miembro del equipo', 'T', 'T'),
    (80, 20, 'view_proyectoequipo', 'Can view Miembro del equipo', 'T', 'T'),
    (81, 21, 'add_tarea', 'Can add tarea', 'T', 'T'),
    (82, 21, 'change_tarea', 'Can change tarea', 'T', 'T'),
    (83, 21, 'delete_tarea', 'Can delete tarea', 'T', 'T'),
    (84, 21, 'view_tarea', 'Can view tarea', 'T', 'T'),
    (85, 22, 'add_historialtarea', 'Can add historial tarea', 'T', 'T'),
    (86, 22, 'change_historialtarea', 'Can change historial tarea', 'T', 'T'),
    (87, 22, 'delete_historialtarea', 'Can delete historial tarea', 'T', 'T'),
    (88, 22, 'view_historialtarea', 'Can view historial tarea', 'T', 'T'),
    (89, 23, 'add_systemrestorelog', 'Can add Log de Restore', 'T', 'T'),
    (90, 23, 'change_systemrestorelog', 'Can change Log de Restore', 'T', 'T'),
    (91, 23, 'delete_systemrestorelog', 'Can delete Log de Restore', 'T', 'T'),
    (92, 23, 'view_systemrestorelog', 'Can view Log de Restore', 'T', 'T'),
    (93, 24, 'add_activesession', 'Can add Sesión activa', 'T', 'T'),
    (94, 24, 'change_activesession', 'Can change Sesión activa', 'T', 'T'),
    (95, 24, 'delete_activesession', 'Can delete Sesión activa', 'T', 'T'),
    (96, 24, 'view_activesession', 'Can view Sesión activa', 'T', 'T'),
    (97, 25, 'add_adjuntoproyecto', 'Can add adjunto proyecto', 'T', 'T'),
    (98, 25, 'change_adjuntoproyecto', 'Can change adjunto proyecto', 'T', 'T'),
    (99, 25, 'delete_adjuntoproyecto', 'Can delete adjunto proyecto', 'T', 'T'),
    (100, 25, 'view_adjuntoproyecto', 'Can view adjunto proyecto', 'T', 'T');

INSERT INTO [dbo].[auth_permission] ([id], [content_type_id], [codename], [name], [trial177], [TRIAL364])
VALUES
    (101, 26, 'add_adjuntotarea', 'Can add adjunto tarea', 'T', 'T'),
    (102, 26, 'change_adjuntotarea', 'Can change adjunto tarea', 'T', 'T'),
    (103, 26, 'delete_adjuntotarea', 'Can delete adjunto tarea', 'T', 'T'),
    (104, 26, 'view_adjuntotarea', 'Can view adjunto tarea', 'T', 'T'),
    (105, 27, 'add_comentariotarea', 'Can add comentario tarea', 'T', 'T'),
    (106, 27, 'change_comentariotarea', 'Can change comentario tarea', 'T', 'T'),
    (107, 27, 'delete_comentariotarea', 'Can delete comentario tarea', 'T', 'T'),
    (108, 27, 'view_comentariotarea', 'Can view comentario tarea', 'T', 'T'),
    (109, 28, 'add_comentarioauditlog', 'Can add comentario audit log', 'T', 'T'),
    (110, 28, 'change_comentarioauditlog', 'Can change comentario audit log', 'T', 'T'),
    (111, 28, 'delete_comentarioauditlog', 'Can delete comentario audit log', 'T', 'T'),
    (112, 28, 'view_comentarioauditlog', 'Can view comentario audit log', 'T', 'T'),
    (113, 29, 'add_adjuntoauditlog', 'Can add adjunto audit log', 'T', 'T'),
    (114, 29, 'change_adjuntoauditlog', 'Can change adjunto audit log', 'T', 'T'),
    (115, 29, 'delete_adjuntoauditlog', 'Can delete adjunto audit log', 'T', 'T'),
    (116, 29, 'view_adjuntoauditlog', 'Can view adjunto audit log', 'T', 'T'),
    (117, 30, 'add_proyectopresupuestoitem', 'Can add Item presupuestario', NULL, 'T'),
    (118, 30, 'change_proyectopresupuestoitem', 'Can change Item presupuestario', NULL, 'T'),
    (119, 30, 'delete_proyectopresupuestoitem', 'Can delete Item presupuestario', NULL, 'T'),
    (120, 30, 'view_proyectopresupuestoitem', 'Can view Item presupuestario', NULL, 'T');

SET IDENTITY_INSERT [dbo].[auth_permission] OFF;
GO

-- Tabla [dbo].[auth_user]: sin datos

-- Tabla [dbo].[auth_user_groups]: sin datos

-- Tabla [dbo].[auth_user_user_permissions]: sin datos

SET IDENTITY_INSERT [dbo].[backup_restore_activesession] ON;
INSERT INTO [dbo].[backup_restore_activesession] ([id], [last_activity], [session_key], [user_id], [trial180], [TRIAL367])
VALUES
    (2, '2026-02-26 19:40:13', 'sess_1772125610984_anlenljbrw', 6, 'T', 'T'),
    (4, '2026-02-26 18:06:02', 'sess_1772125960625_hh47lzyx5n', 2, 'T', 'T'),
    (5, '2026-02-27 19:01:33', 'sess_1772195043775_dla59sz3qz', 6, 'T', 'T'),
    (11, '2026-02-27 19:02:42', 'sess_1772215322624_8j91ee26up', 2, 'T', 'T'),
    (15, '2026-02-27 19:02:49', 'sess_1772217253752_1o6m9st6zr', 4, 'T', 'T'),
    (16, '2026-03-02 13:43:30', 'sess_1772457503127_8xprlvktam', 6, 'T', 'T'),
    (19, '2026-03-04 14:58:52', 'sess_1772459016088_sb39d37tdw', 6, 'T', 'T'),
    (26, '2026-03-04 14:56:31', 'sess_1772549823440_gg6zw8xvpc', 6, 'T', 'T'),
    (29, '2026-03-04 13:17:15', 'sess_1772563082396_t7iey1h6ow', 9, 'T', 'T'),
    (30, '2026-03-04 17:24:53', 'sess_1772638725413_2kancn7et0', 6, 'T', 'T'),
    (31, '2026-03-05 19:35:46', 'sess_1772653896329_ce3khgrwy9', 6, NULL, 'T'),
    (34, '2026-03-06 20:06:30', 'sess_1772803124855_evbv1wk3ui', 13, NULL, 'T'),
    (36, '2026-03-06 20:06:31', 'sess_1772826488753_8ekgws76p', 9, NULL, 'T'),
    (41, '2026-03-09 16:40:09', 'sess_1773073928663_wybull04fh', 9, NULL, 'T'),
    (42, '2026-03-09 16:40:13', 'sess_1773073932787_tnueix0sbb', 6, NULL, 'T'),
    (43, '2026-03-10 14:23:44', 'sess_1773152624039_xebi8qm8cc', 6, NULL, 'T'),
    (45, '2026-03-10 15:01:04', 'sess_1773154862844_hwhl4wbcl5', 6, NULL, 'T'),
    (46, '2026-03-11 14:13:37', 'sess_1773155079455_mkgsme1ppt', 6, NULL, 'T'),
    (47, '2026-03-10 15:45:26', 'sess_1773156298746_fqdwh57e0x', 9, NULL, 'T'),
    (51, '2026-03-11 16:52:23', 'sess_1773238546837_nf4e8h49n9', 6, NULL, 'T'),
    (52, '2026-03-11 16:52:23', 'sess_1773239155918_iuth7ei7y2', 15, NULL, 'T'),
    (56, '2026-03-11 17:19:43', 'sess_1773249575213_gbrskwut7d', 6, NULL, 'T'),
    (62, '2026-03-11 17:51:44', 'sess_1773250304552_cfqe1lh8e4', 6, NULL, 'T'),
    (64, '2026-03-11 17:50:34', 'sess_1773250834551_11m7kqv0bh', 2, NULL, 'T'),
    (93, '2026-03-11 20:16:50', 'sess_1773260210241_akyvz12krt', 6, NULL, 'T'),
    (100, '2026-03-11 20:35:41', 'sess_1773261341172_j4qaiw30e8', 6, NULL, 'T'),
    (101, '2026-03-11 20:42:39', 'sess_1773261399297_eyinswbslb', 6, NULL, 'T'),
    (113, '2026-03-11 21:08:23', 'sess_1773262947925_ixinbyhnox', 6, NULL, 'T'),
    (117, '2026-03-12 12:25:28', 'sess_1773317488127_bcy5qxd92f', 6, NULL, 'T'),
    (118, '2026-03-12 12:24:44', 'sess_1773317564010_t7gk88poaz', 17, NULL, 'T'),
    (124, '2026-03-12 16:12:40', 'sess_1773323120431_vmbf1ji3du', 17, NULL, 'T'),
    (123, '2026-03-12 16:12:40', 'sess_1773329003664_x4qrxhd7t7', 6, NULL, 'T'),
    (126, '2026-03-12 17:30:47', 'sess_1773336647319_1hgexmtjki', 17, NULL, 'T'),
    (128, '2026-03-12 19:39:10', 'sess_1773341230298_jk2ybgwupt', 6, NULL, 'T'),
    (129, '2026-03-12 19:39:25', 'sess_1773341238365_7e1ern3w41', 17, NULL, 'T'),
    (130, '2026-03-12 19:01:29', 'sess_1773342089081_fi2mkzt5h9', 17, NULL, 'T'),
    (140, '2026-03-16 13:35:38', 'sess_1773663437419_4qmien59iz', 6, NULL, 'T'),
    (145, '2026-03-17 12:21:23', 'sess_1773749843289_01ddfhb6f5', 6, NULL, 'T'),
    (162, '2026-03-18 19:58:17', 'sess_1773863897543_skq0yg1shx', 6, NULL, 'T'),
    (163, '2026-03-18 19:58:17', 'sess_1773863897640_jx1eqjgvsv', 6, NULL, 'T'),
    (167, '2026-03-26 13:57:21', 'sess_1774531466851_g3e7ut6rmo', 6, NULL, NULL),
    (168, '2026-03-26 18:30:48', 'sess_1774533459049_i748i4d1jq', 6, NULL, NULL),
    (169, '2026-03-27 17:45:31', 'sess_1774631461711_yb4p7z6d09', 6, NULL, NULL);

SET IDENTITY_INSERT [dbo].[backup_restore_activesession] OFF;
GO

SET IDENTITY_INSERT [dbo].[backup_restore_systemrestorelog] ON;
INSERT INTO [dbo].[backup_restore_systemrestorelog] ([id], [backup_file], [executed_at], [ip_address], [user_id], [trial180], [TRIAL370])
VALUES
    (1, 'backup_20260305_135003.json', '2026-03-06 13:01:42', '127.0.0.1/32                           ', 6, NULL, 'T'),
    (2, 'backup_20260305_135003.json', '2026-03-06 13:04:00', '127.0.0.1/32                           ', 6, NULL, 'T');

SET IDENTITY_INSERT [dbo].[backup_restore_systemrestorelog] OFF;
GO

-- Tabla [dbo].[django_admin_log]: sin datos

SET IDENTITY_INSERT [dbo].[django_content_type] ON;
INSERT INTO [dbo].[django_content_type] ([id], [app_label], [model], [trial180], [TRIAL370])
VALUES
    (1, 'admin', 'logentry', 'T', 'T'),
    (2, 'auth', 'permission', 'T', 'T'),
    (3, 'auth', 'group', 'T', 'T'),
    (4, 'auth', 'user', 'T', 'T'),
    (5, 'contenttypes', 'contenttype', 'T', 'T'),
    (6, 'sessions', 'session', 'T', 'T'),
    (7, 'users', 'rol', 'T', 'T'),
    (8, 'users', 'usuario', 'T', 'T'),
    (9, 'areas', 'area', 'T', 'T'),
    (10, 'secretarias', 'secretaria', 'T', 'T'),
    (11, 'projects', 'proyecto', 'T', 'T'),
    (12, 'projects', 'etapa', 'T', 'T'),
    (13, 'projects', 'proyectoarea', 'T', 'T'),
    (14, 'projects', 'comentarioproyecto', 'T', 'T'),
    (15, 'projects', 'eje', 'T', 'T'),
    (16, 'projects', 'plan', 'T', 'T'),
    (17, 'projects', 'programa', 'T', 'T'),
    (18, 'projects', 'objetivoestrategico', 'T', 'T'),
    (19, 'projects', 'indicador', 'T', 'T'),
    (20, 'projects', 'proyectoequipo', 'T', 'T'),
    (21, 'tasks', 'tarea', 'T', 'T'),
    (22, 'tasks', 'historialtarea', 'T', 'T'),
    (23, 'backup_restore', 'systemrestorelog', 'T', 'T'),
    (24, 'backup_restore', 'activesession', 'T', 'T'),
    (25, 'projects', 'adjuntoproyecto', 'T', 'T'),
    (26, 'tasks', 'adjuntotarea', 'T', 'T'),
    (27, 'tasks', 'comentariotarea', 'T', 'T'),
    (28, 'projects', 'comentarioauditlog', 'T', 'T'),
    (29, 'projects', 'adjuntoauditlog', 'T', 'T'),
    (30, 'projects', 'proyectopresupuestoitem', NULL, 'T');

SET IDENTITY_INSERT [dbo].[django_content_type] OFF;
GO

SET IDENTITY_INSERT [dbo].[django_migrations] ON;
INSERT INTO [dbo].[django_migrations] ([id], [app], [name], [applied], [trial180], [TRIAL374])
VALUES
    (1, 'contenttypes', '0001_initial', '2026-02-26 17:01:20', 'T', 'T'),
    (2, 'auth', '0001_initial', '2026-02-26 17:01:20', 'T', 'T'),
    (3, 'admin', '0001_initial', '2026-02-26 17:01:20', 'T', 'T'),
    (4, 'admin', '0002_logentry_remove_auto_add', '2026-02-26 17:01:20', 'T', 'T'),
    (5, 'admin', '0003_logentry_add_action_flag_choices', '2026-02-26 17:01:20', 'T', 'T'),
    (6, 'users', '0001_initial', '2026-02-26 17:01:20', 'T', 'T'),
    (7, 'areas', '0001_initial', '2026-02-26 17:01:20', 'T', 'T'),
    (8, 'areas', '0002_area_responsable', '2026-02-26 17:01:21', 'T', 'T'),
    (9, 'contenttypes', '0002_remove_content_type_name', '2026-02-26 17:01:21', 'T', 'T'),
    (10, 'auth', '0002_alter_permission_name_max_length', '2026-02-26 17:01:21', 'T', 'T'),
    (11, 'auth', '0003_alter_user_email_max_length', '2026-02-26 17:01:21', 'T', 'T'),
    (12, 'auth', '0004_alter_user_username_opts', '2026-02-26 17:01:21', 'T', 'T'),
    (13, 'auth', '0005_alter_user_last_login_null', '2026-02-26 17:01:21', 'T', 'T'),
    (14, 'auth', '0006_require_contenttypes_0002', '2026-02-26 17:01:21', 'T', 'T'),
    (15, 'auth', '0007_alter_validators_add_error_messages', '2026-02-26 17:01:21', 'T', 'T'),
    (16, 'auth', '0008_alter_user_username_max_length', '2026-02-26 17:01:21', 'T', 'T'),
    (17, 'auth', '0009_alter_user_last_name_max_length', '2026-02-26 17:01:21', 'T', 'T'),
    (18, 'auth', '0010_alter_group_name_max_length', '2026-02-26 17:01:21', 'T', 'T'),
    (19, 'auth', '0011_update_proxy_permissions', '2026-02-26 17:01:21', 'T', 'T'),
    (20, 'auth', '0012_alter_user_first_name_max_length', '2026-02-26 17:01:21', 'T', 'T'),
    (21, 'users', '0002_add_usuario_area', '2026-02-26 17:01:21', 'T', 'T'),
    (22, 'users', '0003_usuario_apellido', '2026-02-26 17:01:21', 'T', 'T'),
    (23, 'users', '0004_alter_usuario_apellido', '2026-02-26 17:01:21', 'T', 'T'),
    (24, 'secretarias', '0001_inicial', '2026-02-26 17:01:21', 'T', 'T'),
    (25, 'users', '0005_area_secretaria_tarea_usuario', '2026-02-26 17:01:21', 'T', 'T'),
    (26, 'backup_restore', '0001_initial', '2026-02-26 17:01:21', 'T', 'T'),
    (27, 'projects', '0001_initial', '2026-02-26 17:01:22', 'T', 'T'),
    (28, 'projects', '0002_add_comentario_proyecto', '2026-02-26 17:01:22', 'T', 'T'),
    (29, 'projects', '0003_planificacion_2026', '2026-02-26 17:01:22', 'T', 'T'),
    (30, 'projects', '0004_indicadores_y_objetivo', '2026-02-26 17:01:22', 'T', 'T'),
    (31, 'projects', '0005_agregar_secretaria', '2026-02-26 17:01:22', 'T', 'T'),
    (32, 'projects', '0006_proyecto_responsable_area_equipo', '2026-02-26 17:01:23', 'T', 'T'),
    (33, 'sessions', '0001_initial', '2026-02-26 17:01:23', 'T', 'T'),
    (34, 'tasks', '0001_initial', '2026-02-26 17:01:23', 'T', 'T'),
    (35, 'tasks', '0002_area_secretaria_tarea_usuario', '2026-02-26 17:01:23', 'T', 'T'),
    (36, 'tasks', '0003_historial_porcentaje_anterior', '2026-02-26 17:01:23', 'T', 'T'),
    (37, 'tasks', '0004_tarea_proyecto_opcional', '2026-02-26 17:01:23', 'T', 'T'),
    (38, 'tasks', '0005_tarea_estado_index', '2026-02-26 17:01:23', 'T', 'T'),
    (39, 'tasks', '0006_tarea_padre_subtareas', '2026-02-27 18:54:01', 'T', 'T'),
    (40, 'users', '0006_hash_passwords', '2026-03-03 13:23:10', 'T', 'T'),
    (41, 'projects', '0007_adjuntoproyecto', '2026-03-03 17:45:01', 'T', 'T'),
    (42, 'tasks', '0007_adjuntotarea_comentariotarea_and_more', '2026-03-03 17:45:02', 'T', 'T'),
    (43, 'projects', '0008_comentarioproyecto_editado_por_and_more', '2026-03-03 18:54:07', 'T', 'T'),
    (44, 'tasks', '0008_comentariotarea_editado_por_and_more', '2026-03-03 18:54:07', 'T', 'T'),
    (45, 'projects', '0009_adjuntoauditlog', '2026-03-03 19:23:15', 'T', 'T'),
    (46, 'tasks', '0009_tarea_orden', '2026-03-06 14:14:23', NULL, 'T'),
    (47, 'users', '0007_usuario_token_version', '2026-03-09 13:52:15', NULL, 'T'),
    (48, 'projects', '0010_proyecto_estado_index', '2026-03-11 13:51:55', NULL, 'T'),
    (49, 'tasks', '0010_historial_fecha_index', '2026-03-11 13:51:55', NULL, 'T'),
    (50, 'projects', '0011_proyecto_compound_indexes', '2026-03-11 19:51:20', NULL, 'T'),
    (51, 'tasks', '0011_tarea_compound_indexes', '2026-03-11 19:51:20', NULL, 'T'),
    (52, 'projects', '0012_remove_proyecto_projects_proy_estado_idx', '2026-03-16 14:23:48', NULL, 'T'),
    (53, 'projects', '0013_proyectopresupuestoitem_and_more', '2026-03-16 14:26:03', NULL, 'T'),
    (54, 'tasks', '0012_remove_historialtarea_tasks_hist_tarea_fecha_idx_and_more', '2026-03-16 14:26:03', NULL, 'T');

SET IDENTITY_INSERT [dbo].[django_migrations] OFF;
GO

-- Tabla [dbo].[django_session]: sin datos

SET IDENTITY_INSERT [dbo].[projects_adjuntoauditlog] ON;
INSERT INTO [dbo].[projects_adjuntoauditlog] ([id], [tipo], [adjunto_id], [accion], [fecha], [nombre_archivo], [nombre_anterior], [nombre_nuevo], [proyecto_id], [tarea_id], [usuario_id], [trial183], [TRIAL374])
VALUES
    (1, 'tarea', 2, 'eliminar', '2026-03-03 19:33:19', 'web-iconos_-02.png', '', '', 11, 29, 9, 'T', 'T'),
    (2, 'proyecto', 1, 'eliminar', '2026-03-03 19:42:44', 'LOGO-COLOR-1536x403.png', '', '', 11, NULL, 6, 'T', 'T'),
    (3, 'tarea', 3, 'eliminar', '2026-03-03 19:55:47', 'Recurso-1.png', '', '', 11, 30, 6, 'T', 'T');

SET IDENTITY_INSERT [dbo].[projects_adjuntoauditlog] OFF;
GO

-- Tabla [dbo].[projects_adjuntoproyecto]: sin datos

SET IDENTITY_INSERT [dbo].[projects_comentarioauditlog] ON;
INSERT INTO [dbo].[projects_comentarioauditlog] ([id], [tipo], [comentario_id], [accion], [fecha], [texto_anterior], [texto_nuevo], [proyecto_id], [tarea_id], [usuario_id], [trial183], [TRIAL377])
VALUES
    (1, 'tarea', 3, 'eliminar', '2026-03-03 19:13:44', 'holisss', '', 11, 29, 6, 'T', 'T');

SET IDENTITY_INSERT [dbo].[projects_comentarioauditlog] OFF;
GO

SET IDENTITY_INSERT [dbo].[projects_comentarioproyecto] ON;
INSERT INTO [dbo].[projects_comentarioproyecto] ([id], [texto], [fecha], [proyecto_id], [usuario_id], [editado_por_id], [fecha_edicion], [trial183], [TRIAL377])
VALUES
    (3, 'SE INICIO EL PROYECTO  DE PRATICAS CON Colegio antonio marte', '2026-03-02 15:53:19', 11, 9, NULL, NULL, 'T', 'T');

SET IDENTITY_INSERT [dbo].[projects_comentarioproyecto] OFF;
GO

SET IDENTITY_INSERT [dbo].[projects_eje] ON;
INSERT INTO [dbo].[projects_eje] ([id_eje], [nombre_eje], [trial187], [TRIAL377])
VALUES
    (1, 'Fortalecimiento de la Economía del Conocimiento', 'T', 'T'),
    (2, 'Impulso a la Ciencia y Tecnología', 'T', 'T'),
    (3, 'Transformación Digital y Gobierno Abierto', 'T', 'T'),
    (4, 'Gestión y Fortalecimiento Institucional', 'T', 'T'),
    (5, 'Fortalecimiento del Acceso y Desarrollo Cultural', 'T', 'T'),
    (6, 'Monetización y Generación de Recursos Propios', 'T', 'T');

SET IDENTITY_INSERT [dbo].[projects_eje] OFF;
GO

-- Tabla [dbo].[projects_etapa]: sin datos

-- Tabla [dbo].[projects_indicador]: sin datos

SET IDENTITY_INSERT [dbo].[projects_objetivoestrategico] ON;
INSERT INTO [dbo].[projects_objetivoestrategico] ([id], [descripcion], [programa_id], [trial187], [TRIAL380])
VALUES
    (1, 'Acelerar el desarrollo de startups fueguinas.', '1.1', 'T', 'T'),
    (2, 'Reducir la brecha de talento en tecnologías clave.', '1.2', 'T', 'T'),
    (3, 'Generar conocimiento y soluciones para desafíos provinciales.', '1.3', 'T', 'T'),
    (4, 'Ampliar el ecosistema de empresas de la Economía del Conocimiento.', '1.4', 'T', 'T'),
    (5, 'Sensibilización y transferencia de conocimiento.', '1.5', 'T', 'T'),
    (6, 'Exportación de servicios basados en conocimiento.', '1.6', 'T', 'T'),
    (7, 'Fomentar vocaciones científicas y promover la apropiación social del conocimiento.', '2.1', 'T', 'T'),
    (8, 'Centralizar y coordinar vinculaciones con el sistema científico-tecnológico.', '2.2', 'T', 'T'),
    (9, 'Fortalecer el sistema científico, tecnológico e innovador provincial.', '2.3', 'T', 'T'),
    (10, 'Optimizar eficiencia y transparencia.', '3.1', 'T', 'T'),
    (11, 'Garantizar transparencia y optimización de recursos.', '3.2', 'T', 'T'),
    (12, 'Desarrollar marcos normativos y mejora continua en seguridad informática.', '3.3', 'T', 'T'),
    (13, 'Actualizar telecomunicaciones, terminales, virtualización y almacenamiento.', '3.4', 'T', 'T'),
    (14, 'Implementar procesos ágiles y eficientes.', '3.9', 'T', 'T'),
    (15, 'Fortalecer capacidades institucionales del sector público.', '4.1', 'T', 'T'),
    (16, 'Promover convenios y articulaciones interinstitucionales.', '4.2', 'T', 'T'),
    (17, 'Fortalecer conectividad y resiliencia digital.', '4.3', 'T', 'T'),
    (18, 'Modernizar el parque tecnológico.', '4.4', 'T', 'T'),
    (19, 'Adoptar soluciones innovadoras e interoperables.', '4.5', 'T', 'T'),
    (20, 'Garantizar disponibilidad y seguridad de datos.', '4.6', 'T', 'T'),
    (21, 'Consolidar almacenamiento digital seguro y escalable.', '4.7', 'T', 'T'),
    (22, 'Garantizar mejora continua y auditorías periódicas.', '4.8', 'T', 'T'),
    (23, 'Reforzar normativa de protección y ciberseguridad.', '4.9', 'T', 'T'),
    (24, 'Promover producción y acceso a contenidos culturales.', '5.1', 'T', 'T'),
    (25, 'Impulsar comercialización de artistas locales.', '5.2', 'T', 'T'),
    (26, 'Fortalecer redes y proyectos audiovisuales.', '5.3', 'T', 'T'),
    (27, 'Ampliar acceso cultural a toda la población.', '5.4', 'T', 'T'),
    (28, 'Revalorizar expresiones tradicionales.', '5.5', 'T', 'T'),
    (29, 'Articular acuerdos estratégicos.', '6.1', 'T', 'T'),
    (30, 'Desarrollar soluciones digitales rentables.', '6.2', 'T', 'T'),
    (31, 'Generar y administrar recursos sostenibles.', '6.3', 'T', 'T');

SET IDENTITY_INSERT [dbo].[projects_objetivoestrategico] OFF;
GO

SET IDENTITY_INSERT [dbo].[projects_plan] ON;
INSERT INTO [dbo].[projects_plan] ([id_plan], [nombre_plan], [proposito_politica_publica], [vision_estrategica], [eje_id], [trial187], [TRIAL380])
VALUES
    (1, '1. Fortalecimiento de la Economía del Conocimiento', 'Posicionar a la provincia como hub tecnológico, fomentando el talento local y el crecimiento de empresas de base tecnológica.', 'Consolidar a la provincia como hub tecnológico de referencia, impulsando startups, talento especializado e internacionalización de servicios basados en conocimiento.', 1, 'T', 'T'),
    (2, '2. Impulso a la Ciencia y Tecnología', 'Fomentar la investigación aplicada al territorio y la divulgación científica.', 'Consolidar la soberanía del conocimiento mediante articulación institucional y apropiación social de la ciencia.', 2, 'T', 'T'),
    (3, '3. Transformación Digital y Gobierno Abierto', 'Modernizar la gestión pública con infraestructura digital centrada en el ciudadano.', 'Consolidar un Estado moderno, ágil y transparente.', 3, 'T', 'T'),
    (4, '4. Gestión y Fortalecimiento Institucional', 'Transformar la arquitectura operativa del Estado Provincial.', 'Consolidar un modelo de gestión pública resiliente y tecnológicamente robusto.', 4, 'T', 'T'),
    (5, '5. Fortalecimiento del Acceso y Desarrollo Cultural', 'Promover identidad fueguina y democratizar el acceso cultural.', 'Consolidar un ecosistema cultural inclusivo y participativo.', 5, 'T', 'T'),
    (6, '6. Monetización y Generación de Recursos Propios', 'Generar ingresos para sostenibilidad de la Agencia.', 'Garantizar autonomía financiera mediante articulación público-privada.', 6, 'T', 'T');

SET IDENTITY_INSERT [dbo].[projects_plan] OFF;
GO

INSERT INTO [dbo].[projects_programa] ([id_programa], [nombre_programa], [plan_id], [trial187], [TRIAL380])
VALUES
    ('1.1', 'Impulso al Emprendedurismo Tech', 1, 'T', 'T'),
    ('1.2', 'Desarrollo de Talento', 1, 'T', 'T'),
    ('1.3', 'Proyectos de I+D Estratégica', 1, 'T', 'T'),
    ('1.4', 'Promoción y Radicación de Empresas', 1, 'T', 'T'),
    ('1.5', 'Actividades de Divulgación', 1, 'T', 'T'),
    ('1.6', 'Internacionalización de Servicios', 1, 'T', 'T'),
    ('2.1', 'Apropiación Social de la Ciencia, Tecnología e Innovación', 2, 'T', 'T'),
    ('2.2', 'Vinculación y Articulación Institucional', 2, 'T', 'T'),
    ('2.3', 'Desarrollo de Capacidades Científico-Tecnológicas', 2, 'T', 'T'),
    ('3.1', 'Modernización del Estado', 3, 'T', 'T'),
    ('3.2', 'Modernización Administrativa y Financiera', 3, 'T', 'T'),
    ('3.3', 'Fortalecimiento de la Ciberseguridad', 3, 'T', 'T'),
    ('3.4', 'Modernización y Fortalecimiento de Infraestructura Digital', 3, 'T', 'T'),
    ('3.9', 'Actualización y Mejora de Procesos', 3, 'T', 'T'),
    ('4.1', 'Desarrollo y Gestión del Talento Interno', 4, 'T', 'T'),
    ('4.2', 'Alianzas Estratégicas y Comunicación Institucional', 4, 'T', 'T'),
    ('4.3', 'Actualización de Infraestructura de Telecomunicaciones', 4, 'T', 'T'),
    ('4.4', 'Actualización de Terminales de Usuarios', 4, 'T', 'T'),
    ('4.5', 'Implementación de Herramientas de Software', 4, 'T', 'T'),
    ('4.6', 'Infraestructura de Virtualización', 4, 'T', 'T'),
    ('4.7', 'Infraestructura de Almacenamiento', 4, 'T', 'T'),
    ('4.8', 'Plan de Revisión y Mejora Continua', 4, 'T', 'T'),
    ('4.9', 'Marco Normativo en Ciberseguridad', 4, 'T', 'T'),
    ('5.1', 'Promoción y Circulación Cultural', 5, 'T', 'T'),
    ('5.2', 'Ferias y Mercados', 5, 'T', 'T'),
    ('5.3', 'Circulación Audiovisual', 5, 'T', 'T'),
    ('5.4', 'Democratización Cultural', 5, 'T', 'T'),
    ('5.5', 'Fortalecimiento del Patrimonio Cultural', 5, 'T', 'T'),
    ('6.1', 'Acuerdos Público-Privados', 6, 'T', 'T'),
    ('6.2', 'Plataformas y Servicios para Terceros', 6, 'T', 'T'),
    ('6.3', 'Administración Financiera Sustentable', 6, 'T', 'T');

GO

SET IDENTITY_INSERT [dbo].[projects_proyecto] ON;
INSERT INTO [dbo].[projects_proyecto] ([id], [nombre], [descripcion], [fecha_inicio], [fecha_fin_estimada], [fecha_fin_real], [estado], [porcentaje_avance], [fecha_creacion], [creado_por_id], [programa_id], [objetivo_estrategico_id], [secretaria_id], [usuario_responsable_id], [area_id], [trial187], [fuente_financiamiento], [presupuesto_total], [TRIAL383])
VALUES
    (11, 'Prácticas Profesionalizantes Colegio antonio marte', 'Prácticas Profesionalizantes Colegio antonio marte , prácticas reales 2026 para los alumnos.', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 15:25:19', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (12, 'Práctica profesionalizante en Producción Audiovisual y Streaming (Colegio Marte - Tutor Laura Funes)', 'Práctica profesionalizante en Producción Audiovisual y Streaming (Colegio Marte - Tutor Laura Funes)', '2026-03-02', '2026-07-30', NULL, 'Activo', 0.0, '2026-03-02 17:10:04', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (13, 'Práctica profesionalizante- Automatización de Huerta (Colegio Marte)', 'Práctica profesionalizante- Automatización de Huerta (Colegio Marte- Tutor Mauro Gonzalez)', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 17:20:52', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (14, 'Pasantías No Rentadas 6to Año - Colegio kloketen', 'Pasantías No Rentadas 6to Año - Colegio kloketen', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 17:33:36', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (16, 'Plan de Capacitación Cisco 2026', 'Plan de Capacitación Cisco 2026', '2026-03-02', '2026-12-31', NULL, 'Activo', 0.0, '2026-03-02 17:44:39', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (17, 'Centro de Economía y Conocimiento de China', 'Centro de Economía y Conocimiento de China', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 17:51:21', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (18, 'PFI 2026: Proyecto Manejo del Fuego', 'PFI 2026: Proyecto Manejo del Fuego', '2026-03-02', '2026-03-28', NULL, 'Activo', 0.0, '2026-03-02 17:58:38', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (19, 'Regularización Administrativa IDE (Expediente)', 'Regularización Administrativa IDE (Expediente)', '2026-03-02', '2026-03-28', NULL, 'Activo', 0.0, '2026-03-02 18:03:31', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (20, 'Resolución de Prestación de Servicios IDE', 'Resolución de Prestación de Servicios IDE (Carmen)', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 18:07:23', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (21, 'Gestión de RRHH: Reducción Horaria', 'Gestión de RRHH: Reducción Horaria', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 18:15:37', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (22, 'Revisión y Ajuste de Horarios Polos', 'Revisión y Ajuste de Horarios Polos', '2026-03-02', '2026-07-30', NULL, 'Activo', 0.0, '2026-03-02 18:20:34', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (24, 'Plataforma Educativa FP', 'Plataforma Educativa FP (Ever)', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 18:52:09', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (25, 'TDR Formación Profesional Videojuegos', 'TDR Formación Profesional Videojuegos', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 18:56:03', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (26, 'Convenio Marco de Educación', 'Convenio Marco de Educación (Fernanda)', '2026-03-02', '2026-03-28', NULL, 'Activo', 0.0, '2026-03-02 18:58:35', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (28, 'Simposio 2026 Agencia de Innovación', 'Simposio 2026 Agencia de Innovación', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:04:29', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (29, 'Reunión IPAP 15 de Marzo (Egresados TS)', 'Reunión IPAP 15 de Marzo (Egresados TS)', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:07:27', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (30, 'Ampliación de Prácticas Profesionales (Anexo 11)', 'Ampliación de Prácticas Profesionales (Anexo 11)', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:09:47', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (31, 'Proyecto Biotecnología', 'Proyecto Biotecnología', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:13:13', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (32, 'Agenda Semana de Malvinas', 'Agenda Semana de Malvinas', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:18:09', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (33, 'Semana de la Creatividad e Innovación (21 de Abril)', 'Semana de la Creatividad e Innovación (21 de Abril)', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:22:23', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (34, 'Convenio Jala University', 'Convenio Jala University', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:25:43', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (35, 'Acción Comunitaria "Estudia con Malvinas"', 'Acción Comunitaria "Estudia con Malvinas"', '2026-03-02', '2026-03-28', NULL, 'Activo', 0.0, '2026-03-02 19:28:27', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (36, 'TDR Segunda Fase Matemática (Malvina)', 'TDR Segunda Fase Matemática (Malvina)', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:33:35', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (37, 'Sistema de Rendiciones COFECYT', 'Sistema de Rendiciones COFECYT', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:36:41', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (38, 'Aplicación Registro y Base de Datos', 'Aplicación Registro y Base de Datos (Horacio)', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:39:25', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (39, 'Proyecto Piloto Jóvenes y Adultos (EPS)', 'Proyecto Piloto Jóvenes y Adultos (EPS)', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:42:11', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (40, 'Formación en IA para Asesores Pedagógicos', 'Formación en IA para Asesores Pedagógicos', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:44:27', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (41, 'Plan Provincial de Inteligencia Artificial (PIPIA)', 'Plan Provincial de Inteligencia Artificial (PIPIA)', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:47:17', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (42, 'Plan de Turismo Científico 2026', 'Plan de Turismo Científico 2026', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:49:45', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (43, 'Producción del Streaming "Ciencia en Fuego"', 'Producción del Streaming "Ciencia en Fuego"', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:52:09', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (44, 'Actualización de diseño de los Diarios de Campo', 'Actualización de diseño de los Diarios de Campo', '2026-03-02', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-02 19:55:18', 6, NULL, NULL, 7, 9, NULL, 'T', 'Provincial', '0.00', 'T'),
    (54, 'Desembolso de fondos de Nación (2do)', 'Desembolso de fondos de Nación (2do)', '2026-03-06', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-06 13:51:27', 13, NULL, NULL, 7, 9, NULL, NULL, 'Provincial', '0.00', 'T'),
    (52, 'Articulación con Instituciones - Talleres', 'Articulación con Instituciones - Talleres', '2026-03-06', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-06 16:26:27', 13, NULL, NULL, 7, 9, NULL, NULL, 'Provincial', '0.00', 'T'),
    (53, 'Vinculación con BOUNDY EDTECH APP', 'Vinculación con BOUNDY EDTECH APP', '2026-03-06', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-06 16:43:57', 13, NULL, NULL, 7, 9, NULL, NULL, 'Provincial', '0.00', 'T'),
    (55, 'RESOLVER CONVENIO CON CADIC', 'RESOLVER CONVENIO CON CADIC', '2026-03-06', '2026-06-30', NULL, 'Activo', 0.0, '2026-03-06 14:09:32', 13, NULL, NULL, 7, 9, NULL, NULL, 'Provincial', '0.00', 'T'),
    (69, 'Articulación con el Ministerio de Educación para la Transformación Educativa (Hito Central):', 'Articulación con el Ministerio de Educación para la Transformación Educativa (Hito Central):', '2026-03-17', '2026-03-21', NULL, 'Activo', 0.0, '2026-03-16 14:50:21', 6, NULL, NULL, 3, 17, NULL, NULL, 'CFI', '23552000.00', 'T'),
    (68, 'costos', 'costos de servidores 2026', '2026-03-11', '2026-03-14', NULL, 'Activo', 0.0, '2026-03-11 22:11:42', 6, NULL, NULL, 3, 17, NULL, NULL, 'Otros', '1000000.00', 'T');

SET IDENTITY_INSERT [dbo].[projects_proyecto] OFF;
GO

-- Tabla [dbo].[projects_proyectoarea]: sin datos

-- Tabla [dbo].[projects_proyectoequipo]: sin datos

INSERT INTO [dbo].[projects_proyectopresupuestoitem] ([id], [categoria_gasto], [monto], [detalle], [numero_expediente], [es_viaticos], [dotacion_tipo], [horas_hombre], [orden], [proyecto_id], [TRIAL387])
VALUES
    (1, 'Equipamiento', '1000.00', 'sin erogación provincial', '', 0, '', NULL, 0, 69, 'T'),
    (2, 'Gastos operativos y logisticos', '0.00', 'sin erogación provincial', '', 0, '', NULL, 1, 69, 'T'),
    (3, 'Dotacion', '0.00', 'sin erogación provincial', '', 0, '', NULL, 2, 69, 'T'),
    (4, 'Equipamiento', '500000.00', 'gastos de mas', '', 0, '', NULL, 0, 68, 'T'),
    (5, 'Gastos operativos y logisticos', '100000.00', 'movilidad', '', 0, '', NULL, 1, 68, 'T'),
    (6, 'Dotacion', '350000.00', 'personal de agencia', '', 0, '', NULL, 2, 68, 'T');

GO

SET IDENTITY_INSERT [dbo].[secretarias_secretaria] ON;
INSERT INTO [dbo].[secretarias_secretaria] ([id], [codigo], [nombre], [descripcion], [activa], [fecha_creacion], [fecha_modificacion], [usuario_creacion], [usuario_modificacion], [trial190], [TRIAL387])
VALUES
    (6, 'ADM', 'Administración y Gestión', 'Secretaría de gestión institucional', 1, '2026-03-02 11:05:44', '2026-03-27 13:43:02', '', '', 'T', 'T'),
    (4, 'CUL', 'Cultura', 'Secretaría de promoción cultural y desarrollo creativo', 1, '2026-03-02 02:05:44', '2026-03-27 13:43:02', '', '', 'T', 'T'),
    (2, 'CYT', 'Ciencia y Tecnología', 'Secretaría orientada a la investigación científica y desarrollo tecnológico', 1, '2026-03-02 05:05:44', '2026-03-27 13:43:02', '', '', 'T', 'T'),
    (1, 'EC', 'Economía del Conocimiento', 'Secretaría orientada al desarrollo del sector tecnológico y economía basada en conocimiento', 1, '2026-03-01 23:05:44', '2026-03-27 13:43:02', '', '', 'T', 'T'),
    (7, 'Econ-CyT', 'Economia del Conocimiento - Ciencia y Tecnologia', 'Secretaria de Economía del Conocimiento  y Secretaria de Ciencia y Tecnología.', 1, '2026-03-02 15:16:31', '2026-03-02 15:17:44', '', '', 'T', 'T'),
    (5, 'GOB', 'Gobierno Abierto', 'Secretaría de modernización y transparencia', 1, '2026-03-02 02:05:44', '2026-03-27 13:43:02', '', '', 'T', 'T'),
    (21, 'SAI', 'AUDITOR INTERNO', 'AUDITOR INTERNO', 1, '2026-03-09 13:33:53', '2026-03-09 13:33:53', '', '', NULL, 'T'),
    (15, 'SC', 'SECRETARÍA DE CULTURA', 'SECRETARÍA DE CULTURA', 1, '2026-03-09 13:31:28', '2026-03-09 13:31:28', '', '', NULL, 'T'),
    (13, 'SCYT', 'SECRETARÍA DE CIENCIA Y TECNOLOGÍA', 'SECRETARÍA DE CIENCIA Y TECNOLOGÍA', 1, '2026-03-09 13:30:39', '2026-03-09 13:30:39', '', '', NULL, 'T'),
    (20, 'SEC', 'SECRETARÍA DE ECONOMÍA DEL CONOCIMIENTO', 'SECRETARÍA DE ECONOMÍA DEL CONOCIMIENTO', 1, '2026-03-09 13:33:29', '2026-03-09 13:33:29', '', '', NULL, 'T'),
    (9, 'SIA', 'SECRETARÍA DE INNOVACIÓN ADMINISTRATIVA', 'SECRETARÍA DE INNOVACIÓN ADMINISTRATIVA', 1, '2026-03-09 13:26:36', '2026-03-09 13:26:36', '', '', NULL, 'T'),
    (11, 'SPYFT', 'SECRETARÍA DE GESTIÓN, POLOS Y FÁBRICAS DE TALENTO', 'SECRETARÍA DE GESTIÓN, POLOS Y FÁBRICAS DE TALENTO', 1, '2026-03-09 13:28:33', '2026-03-09 13:28:33', '', '', NULL, 'T'),
    (17, 'SSD', 'SECRETARÍA DE SERVICIOS DIGITALES', 'SECRETARÍA DE SERVICIOS DIGITALES', 1, '2026-03-09 13:32:21', '2026-03-09 13:32:21', '', '', NULL, 'T'),
    (14, 'SSDYEP', 'SUBSECRETARÍA DE DISEÑO Y EJECUCIÓN PROYECTOS', 'SUBSECRETARÍA DE DISEÑO Y EJECUCIÓN PROYECTOS', 1, '2026-03-09 13:31:01', '2026-03-09 13:31:01', '', '', NULL, 'T'),
    (12, 'SSGI', 'SUBSECRETARÍA DE GESTIÓN INSTITUCIONAL', 'SUBSECRETARÍA DE GESTIÓN INSTITUCIONAL', 1, '2026-03-09 13:29:13', '2026-03-09 13:29:13', '', '', NULL, 'T'),
    (10, 'SSIA', 'SUBSECRETARIA DE INNOVACIÓN ADMINISTRATIVA', 'SUBSECRETARIA DE INNOVACIÓN ADMINISTRATIVA', 1, '2026-03-09 13:27:15', '2026-03-09 13:27:15', '', '', NULL, 'T'),
    (16, 'SSIC', 'SUBSECRETARIA INDUSTRIAS CREATIVAS', 'SUBSECRETARIA INDUSTRIAS CREATIVAS', 1, '2026-03-09 13:31:47', '2026-03-09 13:31:47', '', '', NULL, 'T'),
    (19, 'SSIT', 'SUBSECRETARIA DE INFRAESTRUCTURA TECNOLÓGICA', 'SUBSECRETARIA DE INFRAESTRUCTURA TECNOLÓGICA', 1, '2026-03-09 13:33:09', '2026-03-09 13:33:09', '', '', NULL, 'T'),
    (18, 'SSSD', 'SUBSECRETARIA DE SERVICIOS DIGITALES', 'SUBSECRETARIA DE SERVICIOS DIGITALES', 1, '2026-03-09 13:32:49', '2026-03-09 13:32:49', '', '', NULL, 'T'),
    (3, 'TEC', 'Tecnología', 'Secretaría de innovación y transformación digital', 1, '2026-03-02 02:05:44', '2026-03-27 13:43:02', '', '', 'T', 'T');

SET IDENTITY_INSERT [dbo].[secretarias_secretaria] OFF;
GO

INSERT INTO [dbo].[sqlite_sequence] ([name], [seq], [trial190], [TRIAL387])
VALUES
    ('django_migrations', '45', 'T', 'T'),
    ('django_admin_log', '0', 'T', 'T'),
    ('django_content_type', '29', 'T', 'T'),
    ('auth_permission', '116', 'T', 'T'),
    ('auth_group', '0', 'T', 'T'),
    ('auth_user', '0', 'T', 'T'),
    ('users_usuario', '9', 'T', 'T'),
    ('tasks_tarea', '160', 'T', 'T'),
    ('users_rol', '3', 'T', 'T'),
    ('areas_area', '5', 'T', 'T'),
    ('projects_proyecto', '48', 'T', 'T'),
    ('projects_etapa', '6', 'T', 'T'),
    ('tasks_historialtarea', '38', 'T', 'T'),
    ('backup_restore_activesession', '30', 'T', 'T'),
    ('projects_objetivoestrategico', '31', 'T', 'T'),
    ('secretarias_secretaria', '7', 'T', 'T'),
    ('projects_proyectoequipo', '3', 'T', 'T'),
    ('projects_comentarioproyecto', '3', 'T', 'T'),
    ('projects_indicador', '2', 'T', 'T'),
    ('tasks_comentariotarea', '4', 'T', 'T'),
    ('tasks_adjuntotarea', '3', 'T', 'T'),
    ('projects_adjuntoproyecto', '1', 'T', 'T'),
    ('projects_comentarioauditlog', '1', 'T', 'T'),
    ('projects_adjuntoauditlog', '3', 'T', 'T');

GO

SET IDENTITY_INSERT [dbo].[tasks_adjuntotarea] ON;
INSERT INTO [dbo].[tasks_adjuntotarea] ([id], [archivo], [nombre_original], [fecha], [subido_por_id], [tarea_id], [trial190], [TRIAL390])
VALUES
    (1, 'adjuntos/tareas/2026/03/LOGO-COLOR-1536x403.png', 'LOGO-COLOR-1536x403.png', '2026-03-03 18:05:48', 2, 29, 'T', 'T');

SET IDENTITY_INSERT [dbo].[tasks_adjuntotarea] OFF;
GO

SET IDENTITY_INSERT [dbo].[tasks_comentariotarea] ON;
INSERT INTO [dbo].[tasks_comentariotarea] ([id], [texto], [fecha], [tarea_id], [usuario_id], [editado_por_id], [fecha_edicion], [trial190], [TRIAL390])
VALUES
    (1, 'demo!!!', '2026-03-03 18:37:14', 28, 4, NULL, NULL, 'T', 'T'),
    (4, 'holis', '2026-03-03 19:19:12', 29, 9, NULL, NULL, 'T', 'T');

SET IDENTITY_INSERT [dbo].[tasks_comentariotarea] OFF;
GO

SET IDENTITY_INSERT [dbo].[tasks_historialtarea] ON;
INSERT INTO [dbo].[tasks_historialtarea] ([id], [comentario], [porcentaje_avance], [fecha], [tarea_id], [usuario_id], [porcentaje_anterior], [trial193], [TRIAL390])
VALUES
    (31, '', 1, '2026-03-03 18:10:16', 29, 4, 1, 'T', 'T'),
    (32, 'sadsadasfaf', 1, '2026-03-03 18:10:35', 29, 4, 1, 'T', 'T'),
    (33, 'sdadasdasdadasdas', 2, '2026-03-03 18:10:46', 29, 4, 1, 'T', 'T'),
    (34, 'demos1', 100, '2026-03-03 18:40:48', 28, 9, 100, 'T', 'T'),
    (35, 'hola opcional', 2, '2026-03-03 18:41:08', 29, 9, 2, 'T', 'T'),
    (36, 'cometario opcional', 2, '2026-03-03 18:44:09', 29, 9, 2, 'T', 'T'),
    (37, '', 2, '2026-03-03 19:14:15', 29, 9, 2, 'T', 'T'),
    (38, '', 1, '2026-03-03 19:53:51', 30, 9, 1, 'T', 'T');

SET IDENTITY_INSERT [dbo].[tasks_historialtarea] OFF;
GO

SET IDENTITY_INSERT [dbo].[tasks_tarea] ON;
INSERT INTO [dbo].[tasks_tarea] ([id], [titulo], [descripcion], [fecha_inicio], [fecha_vencimiento], [estado], [porcentaje_avance], [prioridad], [fecha_creacion], [area_id], [etapa_id], [responsable_id], [secretaria_id], [proyecto_id], [tarea_padre_id], [trial193], [orden], [TRIAL393])
VALUES
    (28, 'Redactar nota de elevación con las 4 ofertas integradoras', 'Redactar nota de elevación con las 4 ofertas integradoras', '2026-03-02', '2026-03-06', 'Finalizada', 100, 'Media', '2026-03-02 15:31:43', NULL, NULL, 9, 7, 11, NULL, 'T', 0, 'T'),
    (29, 'Enviar el proyecto formal a la dirección de la escuela.', 'Enviar el proyecto formal a la dirección de la escuela.', '2026-03-02', '2026-03-06', 'En proceso', 2, 'Media', '2026-03-02 15:32:50', NULL, NULL, 9, 7, 11, NULL, 'T', 0, 'T'),
    (30, 'Definir topes de estudiantes por proyecto y criterios de renovación.', 'Definir topes de estudiantes por proyecto y criterios de renovación.', '2026-03-02', '2026-03-06', 'En proceso', 1, 'Media', '2026-03-02 15:33:29', NULL, NULL, 9, 7, 11, NULL, 'T', 0, 'T'),
    (31, 'Coordinar con la escuela la devolución del proyecto firmado.', 'Coordinar con la escuela la devolución del proyecto firmado.', '2026-03-02', '2026-03-07', 'Pendiente', 1, 'Alta', '2026-03-02 15:34:35', NULL, NULL, 9, 7, 11, NULL, 'T', 0, 'T'),
    (32, 'Fijar cronograma y fechas de inicio de las prácticas', 'Fijar cronograma y fechas de inicio de las prácticas', '2026-03-02', '2026-03-06', 'En proceso', 1, 'Media', '2026-03-02 15:35:20', NULL, NULL, 9, 7, 11, NULL, 'T', 0, 'T'),
    (33, 'Designar tutores internos para el seguimiento pedagógico y técnico.', 'Designar tutores internos para el seguimiento pedagógico y técnico.', '2026-03-02', '2026-03-06', 'En proceso', 1, 'Media', '2026-03-02 15:36:09', NULL, NULL, 9, 7, 11, NULL, 'T', 0, 'T'),
    (34, 'iniciar la inducción y capacitación redacción de cv y entrevistas laborales (a cargo de IPAP))', 'iniciar la inducción y capacitación redacción de cv y entrevistas laborales (a cargo de IPAP))', '2026-03-02', '2026-03-06', 'En proceso', 1, 'Media', '2026-03-02 15:36:55', NULL, NULL, 9, 7, 11, NULL, 'T', 0, 'T'),
    (35, 'Convocatoria y postulaciones a las prácticas', 'Convocatoria y postulaciones a las prácticas', '2026-03-02', '2026-03-06', 'En proceso', 1, 'Baja', '2026-03-02 15:37:51', NULL, NULL, 9, 7, 11, NULL, 'T', 0, 'T'),
    (36, 'Difusión institucional', 'Difusión institucional', '2026-03-02', '2026-03-06', 'En proceso', 1, 'Media', '2026-03-02 15:38:47', NULL, NULL, 9, 7, 11, 35, 'T', 0, 'T'),
    (38, 'Iniciar las prácticas', 'Iniciar las prácticas', '2026-03-02', '2026-03-06', 'En proceso', 1, 'Media', '2026-03-02 15:40:17', NULL, NULL, 9, 7, 11, NULL, 'T', 0, 'T'),
    (39, 'Presentación institucional y bienvenida', 'Presentación institucional y bienvenida', '2026-03-02', '2026-03-06', 'En proceso', 1, 'Media', '2026-03-02 15:42:16', NULL, NULL, 9, 7, 11, 38, 'T', 0, 'T'),
    (40, 'Realizar inventario técnico y validar disponibilidad de equipos en el Polo.', 'Realizar inventario técnico y validar disponibilidad de equipos en el Polo.', '2026-03-02', '2026-06-30', 'En proceso', 1, 'Media', '2026-03-02 17:10:52', NULL, NULL, 9, 7, 12, NULL, 'T', 0, 'T'),
    (41, 'Diseñar el plan de contenidos/guiones para las prácticas con alumnos.', 'Diseñar el plan de contenidos/guiones para las prácticas con alumnos.', '2026-03-02', '2026-03-21', 'En proceso', 1, 'Media', '2026-03-02 17:11:37', NULL, NULL, 9, 7, 12, NULL, 'T', 0, 'T'),
    (42, 'Establecer el cronograma de rodaje mensual.', 'Establecer el cronograma de rodaje mensual.', '2026-03-02', '2026-03-21', 'En proceso', 1, 'Media', '2026-03-02 17:12:13', NULL, NULL, 9, 7, 12, NULL, 'T', 0, 'T'),
    (43, 'Coordinar las etapas de postproducción y edición con los estudiantes', 'Coordinar las etapas de postproducción y edición con los estudiantes', '2026-03-02', '2026-03-21', 'En proceso', 1, 'Media', '2026-03-02 17:13:01', NULL, NULL, 9, 7, 12, NULL, 'T', 0, 'T'),
    (44, 'Realizar visita técnica a IPES FA para diagnóstico del estado de la huerta.', 'Realizar visita técnica a IPES FA para diagnóstico del estado de la huerta.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:22:44', NULL, NULL, 9, 7, 13, NULL, 'T', 0, 'T'),
    (45, 'Entrevistar a los responsables institucionales de la huerta sobre necesidades y expectativas.', 'Entrevistar a los responsables institucionales de la huerta sobre necesidades y expectativas.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:23:25', NULL, NULL, 9, 7, 13, NULL, 'T', 0, 'T'),
    (46, 'Elaborar propuesta técnica de sensibilización pedagógica.', 'Elaborar propuesta técnica de sensibilización pedagógica.', '2026-03-02', '2026-03-21', 'En proceso', 1, 'Media', '2026-03-02 17:23:58', NULL, NULL, 9, 7, 13, NULL, 'T', 0, 'T'),
    (47, 'Diseñar el plan técnico de automatización.', 'Diseñar el plan técnico de automatización.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:25:47', NULL, NULL, 9, 7, 13, NULL, 'T', 0, 'T'),
    (48, 'Presupuestar componentes tecnológicos y materiales requeridos', 'Presupuestar componentes tecnológicos y materiales requeridos', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:26:41', NULL, NULL, 9, 7, 13, NULL, 'T', 0, 'T'),
    (49, 'Relevar cupos y perfiles solicitados en las áreas de la Agencia', 'Relevar cupos y perfiles solicitados en las áreas de la Agencia', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:36:54', NULL, NULL, 9, 7, 14, NULL, 'T', 0, 'T'),
    (50, 'Identificar estudiantes interesados en el Colegio Kloketen (Anexo 11).', 'Identificar estudiantes interesados en el Colegio Kloketen (Anexo 11).', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:37:32', NULL, NULL, 9, 7, 14, NULL, 'T', 0, 'T'),
    (51, 'Armar el programa detallado de tareas y objetivos para el pasante.', 'Armar el programa detallado de tareas y objetivos para el pasante.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:38:00', NULL, NULL, 9, 7, 14, NULL, 'T', 0, 'T'),
    (52, 'Vincular los perfiles de los alumnos con la oferta formativa de Cisco', 'Vincular los perfiles de los alumnos con la oferta formativa de Cisco', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:38:27', NULL, NULL, 9, 7, 14, NULL, 'T', 0, 'T'),
    (55, 'Cruzar la base de datos de cursos con la oferta actual de los Polos (Azahala)', 'Cruzar la base de datos de cursos con la oferta actual de los Polos (Azahala)', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:45:13', NULL, NULL, 9, 7, 16, NULL, 'T', 0, 'T'),
    (56, 'Identificar contenidos para evitar superposiciones con trayectos existentes.', 'Identificar contenidos para evitar superposiciones con trayectos existentes.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:45:56', NULL, NULL, 9, 7, 16, NULL, 'T', 0, 'T'),
    (57, 'Definir los trayectos formativos específicos para 2026', 'Definir los trayectos formativos específicos para 2026', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:47:24', NULL, NULL, 9, 7, 16, NULL, 'T', 0, 'T'),
    (58, 'Elaborar el cronograma de activación gradual para validación de Abel', 'Elaborar el cronograma de activación gradual para validación de Abel', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:47:57', NULL, NULL, 9, 7, 16, NULL, 'T', 0, 'T'),
    (59, 'Recopilar antecedentes, convenios previos y objetivos estratégicos.', 'Recopilar antecedentes, convenios previos y objetivos estratégicos.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:52:40', NULL, NULL, 9, 7, 17, NULL, 'T', 0, 'T'),
    (60, 'Redactar el documento base del proyecto del Centro.', 'Redactar el documento base del proyecto del Centro.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:53:16', NULL, NULL, 9, 7, 17, NULL, 'T', 0, 'T'),
    (61, 'Definir y convocar a los actores interinstitucionales involucrados.', 'Definir y convocar a los actores interinstitucionales involucrados.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:53:44', NULL, NULL, 9, 7, 17, NULL, 'T', 0, 'T'),
    (62, 'Establecer una hoja de ruta de implementación a corto plazo.', 'Establecer una hoja de ruta de implementación a corto plazo.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:54:16', NULL, NULL, 9, 7, 17, NULL, 'T', 0, 'T'),
    (63, 'Integrar formalmente al equipo de la IDE al grupo de trabajo', 'Integrar formalmente al equipo de la IDE al grupo de trabajo', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:59:11', NULL, NULL, 9, 7, 18, NULL, 'T', 0, 'T'),
    (64, 'Coordinar con Abel el calendario de reuniones semanales de seguimiento.', 'Coordinar con Abel el calendario de reuniones semanales de seguimiento.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 17:59:43', NULL, NULL, 9, 7, 18, NULL, 'T', 0, 'T'),
    (65, 'Establecer plazos de entrega para el borrador del proyecto general', 'Establecer plazos de entrega para el borrador del proyecto general', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:00:17', NULL, NULL, 9, 7, 18, NULL, 'T', 0, 'T'),
    (66, 'Cuantificar recursos y presupuestar según requisitos de la convocatoria.', 'Cuantificar recursos y presupuestar según requisitos de la convocatoria.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:00:49', NULL, NULL, 9, 7, 18, NULL, 'T', 0, 'T'),
    (67, 'Recopilar la normativa vigente y redactar la carta de intención.', 'Recopilar la normativa vigente y redactar la carta de intención.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:04:38', NULL, NULL, 9, 7, 19, NULL, 'T', 0, 'T'),
    (68, 'Subir la documentación completa al sistema de expedientes electrónicos.', 'Subir la documentación completa al sistema de expedientes electrónicos.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:05:09', NULL, NULL, 9, 7, 19, NULL, 'T', 0, 'T'),
    (69, 'Gestionar el pase para firma de las autoridades (Secretaría/Agencia).', 'Gestionar el pase para firma de las autoridades (Secretaría/Agencia).', '2026-03-02', '2026-03-28', 'En proceso', 11, 'Media', '2026-03-02 18:05:49', NULL, NULL, 9, 7, 19, NULL, 'T', 0, 'T'),
    (70, 'Realizar seguimiento semanal del estado del expediente hasta su aprobación.', 'Realizar seguimiento semanal del estado del expediente hasta su aprobación.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:06:21', NULL, NULL, 9, 7, 19, NULL, 'T', 0, 'T'),
    (71, 'Redactar el cuerpo técnico de la resolución (tarifarios/servicios).', 'Redactar el cuerpo técnico de la resolución (tarifarios/servicios).', '2026-03-02', '2026-05-18', 'En proceso', 1, 'Media', '2026-03-02 18:07:58', NULL, NULL, 9, 7, 20, NULL, 'T', 0, 'T'),
    (72, 'Validar el borrador con el área legal de la Agencia.', 'Validar el borrador con el área legal de la Agencia.', '2026-03-02', '2026-04-27', 'En proceso', 1, 'Media', '2026-03-02 18:08:29', NULL, NULL, 9, 7, 20, NULL, 'T', 0, 'T'),
    (73, 'Gestionar la firma de la resolución.', 'Gestionar la firma de la resolución.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:09:37', NULL, NULL, 9, 7, 20, NULL, 'T', 0, 'T'),
    (74, 'Notificar formalmente a las áreas contables y administrativas.', 'Notificar formalmente a las áreas contables y administrativas.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:10:07', NULL, NULL, 9, 7, 20, NULL, 'T', 0, 'T'),
    (75, 'Evaluar la viabilidad técnica y operativa de la reducción de jornada.', 'Evaluar la viabilidad técnica y operativa de la reducción de jornada.', '2026-03-02', '2026-04-27', 'En proceso', 1, 'Media', '2026-03-02 18:16:10', NULL, NULL, 9, 7, 21, NULL, 'T', 0, 'T'),
    (76, 'Redactar la nota de notificación formal para Recursos Humanos.', 'Redactar la nota de notificación formal para Recursos Humanos.', '2026-03-02', '2026-04-30', 'En proceso', 1, 'Media', '2026-03-02 18:17:43', NULL, NULL, 9, 7, 21, NULL, 'T', 0, 'T'),
    (77, 'Solicitar al agente la actualización de su Declaración Jurada.', 'Solicitar al agente la actualización de su Declaración Jurada.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:18:13', NULL, NULL, 9, 7, 21, NULL, 'T', 0, 'T'),
    (78, 'Coordinar con liquidación de haberes el ajuste correspondiente.', 'Coordinar con liquidación de haberes el ajuste correspondiente.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:18:43', NULL, NULL, 9, 7, 21, NULL, 'T', 0, 'T'),
    (79, 'Analizar la carga horaria de Archie para garantizar la cobertura de sala.', 'Analizar la carga horaria de Archie para garantizar la cobertura de sala.', '2026-03-02', '2026-04-30', 'En proceso', 1, 'Media', '2026-03-02 18:21:15', NULL, NULL, 9, 7, 22, NULL, 'T', 0, 'T'),
    (80, 'Cotejar esquemas con la normativa vigente y los horarios de Gaby en Drive.', 'Cotejar esquemas con la normativa vigente y los horarios de Gaby en Drive.', '2026-03-02', '2026-04-04', 'En proceso', 1, 'Media', '2026-03-02 18:21:51', NULL, NULL, 9, 7, 22, NULL, 'T', 0, 'T'),
    (81, 'Definir el nuevo cuadro de rotación de personal.', 'Definir el nuevo cuadro de rotación de personal.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:22:16', NULL, NULL, 9, 7, 22, NULL, 'T', 0, 'T'),
    (82, 'Notificar el esquema final a los agentes involucrados.', 'Notificar el esquema final a los agentes involucrados.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:22:41', NULL, NULL, 9, 7, 22, NULL, 'T', 0, 'T'),
    (83, 'Evaluar técnica y funcionalmente la plataforma de inscripción de Polos.', 'Evaluar técnica y funcionalmente la plataforma de inscripción de Polos.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:52:56', NULL, NULL, 9, 7, 24, NULL, 'T', 0, 'T'),
    (84, 'Determinar si es posible integrar módulos de foros y seguimiento.', 'Determinar si es posible integrar módulos de foros y seguimiento.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:53:27', NULL, NULL, 9, 7, 24, NULL, 'T', 0, 'T'),
    (85, 'Gestionar, de ser necesario, acceso urgente al Campus Moodle existente.', 'Gestionar, de ser necesario, acceso urgente al Campus Moodle existente.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:53:55', NULL, NULL, 9, 7, 24, NULL, 'T', 0, 'T'),
    (86, 'Configurar el sistema de matriculación y seguimiento de alumnos.', 'Configurar el sistema de matriculación y seguimiento de alumnos.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:54:24', NULL, NULL, 9, 7, 24, NULL, 'T', 0, 'T'),
    (87, 'Realizar la revisión técnica final y dar cierre al TDR redactado.', 'Realizar la revisión técnica final y dar cierre al TDR redactado.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:56:42', NULL, NULL, 9, 7, 25, NULL, 'T', 0, 'T'),
    (88, 'Iniciar el circuito administrativo para la contratación/licitación.', 'Iniciar el circuito administrativo para la contratación/licitación.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:57:10', NULL, NULL, 9, 7, 25, NULL, 'T', 0, 'T'),
    (89, 'Estructurar y cargar los contenidos específicos en la plataforma virtual.', 'Estructurar y cargar los contenidos específicos en la plataforma virtual.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:57:39', NULL, NULL, 9, 7, 25, NULL, 'T', 0, 'T'),
    (90, 'Revisar el estado del borrador enviado a la contraparte (Fernanda).', 'Revisar el estado del borrador enviado a la contraparte (Fernanda).', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:59:19', NULL, NULL, 9, 7, 26, NULL, 'T', 0, 'T'),
    (91, 'Solicitar formalmente los aportes técnicos de Educación.', 'Solicitar formalmente los aportes técnicos de Educación.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 18:59:57', NULL, NULL, 9, 7, 26, NULL, 'T', 0, 'T'),
    (92, 'Elevar por urgencia si no hay respuesta en plazos establecidos.', 'Elevar por urgencia si no hay respuesta en plazos establecidos.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:00:23', NULL, NULL, 9, 7, 26, NULL, 'T', 0, 'T'),
    (93, 'Coordinar la logística para la firma protocolar del convenio.', 'Coordinar la logística para la firma protocolar del convenio.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:00:54', NULL, NULL, 9, 7, 26, NULL, 'T', 0, 'T'),
    (94, 'Definir el eje temático y los objetivos centrales del evento.', 'Definir el eje temático y los objetivos centrales del evento.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:04:58', NULL, NULL, 9, 7, 28, NULL, 'T', 0, 'T'),
    (95, 'Mapear y contactar a disertantes, actores externos y patrocinadores.', 'Mapear y contactar a disertantes, actores externos y patrocinadores.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:05:34', NULL, NULL, 9, 7, 28, NULL, 'T', 0, 'T'),
    (96, 'Elaborar el presupuesto detallado (logística, locación, técnica).', 'Elaborar el presupuesto detallado (logística, locación, técnica).', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:06:04', NULL, NULL, 9, 7, 28, NULL, 'T', 0, 'T'),
    (97, 'Incorporar la fecha oficial en la agenda institucional y de la Agencia.', 'Incorporar la fecha oficial en la agenda institucional y de la Agencia.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:06:33', NULL, NULL, 9, 7, 28, NULL, 'T', 0, 'T'),
    (98, 'Elaborar propuesta de actualización para perfiles de RRHH y Administración.', 'Elaborar propuesta de actualización para perfiles de RRHH y Administración.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:08:03', NULL, NULL, 9, 7, 29, NULL, 'T', 0, 'T'),
    (99, 'Relevar necesidades de formación tecnológica del cuerpo docente IPAP.', 'Relevar necesidades de formación tecnológica del cuerpo docente IPAP.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:08:35', NULL, NULL, 9, 7, 29, NULL, 'T', 0, 'T'),
    (100, 'Analizar la factibilidad jurídica de un convenio específico Agencia-IPAP.', 'Analizar la factibilidad jurídica de un convenio específico Agencia-IPAP.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:09:01', NULL, NULL, 9, 7, 29, NULL, 'T', 0, 'T'),
    (101, 'Identificar instituciones para prácticas de Desarrollo Web fuera del Martes.', 'Identificar instituciones para prácticas de Desarrollo Web fuera del Martes.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:11:11', NULL, NULL, 9, 7, 30, NULL, 'T', 0, 'T'),
    (102, 'Analizar perfiles de Técnico Superior que requieran plazas de práctica.', 'Analizar perfiles de Técnico Superior que requieran plazas de práctica.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:11:38', NULL, NULL, 9, 7, 30, NULL, 'T', 0, 'T'),
    (103, 'Validar con Supervisión de Educación Superior la viabilidad de las plazas.', 'Validar con Supervisión de Educación Superior la viabilidad de las plazas.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:12:07', NULL, NULL, 9, 7, 30, NULL, 'T', 0, 'T'),
    (104, 'Revisar el cronograma de ejecución y plazos de presentación formal.', 'Revisar el cronograma de ejecución y plazos de presentación formal.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:16:13', NULL, NULL, 9, 7, 31, NULL, 'T', 0, 'T'),
    (105, 'Coordinar con la Unidad de Contrataciones el seguimiento del expediente.', 'Coordinar con la Unidad de Contrataciones el seguimiento del expediente.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:16:46', NULL, NULL, 9, 7, 31, NULL, 'T', 0, 'T'),
    (106, 'Designar a los responsables técnicos para la certificación de hitos.', 'Designar a los responsables técnicos para la certificación de hitos.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:17:15', NULL, NULL, 9, 7, 31, NULL, 'T', 0, 'T'),
    (107, 'Diseñar la actividad central (Soberanía + Ciencia) de la Agencia.', 'Diseñar la actividad central (Soberanía + Ciencia) de la Agencia.', '2026-03-02', '2026-04-24', 'En proceso', 1, 'Media', '2026-03-02 19:19:01', NULL, NULL, 9, 7, 32, NULL, 'T', 0, 'T'),
    (108, 'Cargar el cronograma detallado de acciones en el Drive compartido.', 'Cargar el cronograma detallado de acciones en el Drive compartido.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:20:34', NULL, NULL, 9, 7, 32, NULL, 'T', 0, 'T'),
    (109, 'Coordinar con Prensa la difusión de las actividades programadas.', 'Coordinar con Prensa la difusión de las actividades programadas.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:21:15', NULL, NULL, 9, 7, 32, NULL, 'T', 0, 'T'),
    (110, 'Diseñar el calendario de actividades de la Agencia para toda la semana.', 'Diseñar el calendario de actividades de la Agencia para toda la semana.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:23:45', NULL, NULL, 9, 7, 33, NULL, 'T', 0, 'T'),
    (111, 'Convocar a otras Secretarías para integrar propuestas transversales.', 'Convocar a otras Secretarías para integrar propuestas transversales.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:24:13', NULL, NULL, 9, 7, 33, NULL, 'T', 0, 'T'),
    (112, 'Cargar el calendario final en la agenda mensual para evitar solapamientos.', 'Cargar el calendario final en la agenda mensual para evitar solapamientos.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:24:45', NULL, NULL, 9, 7, 33, NULL, 'T', 0, 'T'),
    (113, 'Analizar el rol y compromisos de la Agencia en el borrador (Maru/Emiliano).', 'Analizar el rol y compromisos de la Agencia en el borrador (Maru/Emiliano).', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:26:15', NULL, NULL, 9, 7, 34, NULL, 'T', 0, 'T'),
    (114, 'Segmentar los grupos de difusión (especialmente Colegio Martes).', 'Segmentar los grupos de difusión (especialmente Colegio Martes).', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:26:43', NULL, NULL, 9, 7, 34, NULL, 'T', 0, 'T'),
    (115, 'Solicitar a Jala el temario técnico del cursillo de admisión.', 'Solicitar a Jala el temario técnico del cursillo de admisión.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:27:12', NULL, NULL, 9, 7, 34, NULL, 'T', 0, 'T'),
    (116, 'Diseñar programa de tutoría/acompañamiento para los postulantes.', 'Diseñar programa de tutoría/acompañamiento para los postulantes.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:27:41', NULL, NULL, 9, 7, 34, NULL, 'T', 0, 'T'),
    (117, 'Gestionar el diseño y la impresión del banner para el aula en Tolhuin.', 'Gestionar el diseño y la impresión del banner para el aula en Tolhuin.', '2026-03-02', '2026-03-28', 'Pendiente', 1, 'Media', '2026-03-02 19:29:02', NULL, NULL, 9, 7, 35, NULL, 'T', 0, 'T'),
    (118, 'Definir el cronograma de apertura del espacio a la comunidad.', 'Definir el cronograma de apertura del espacio a la comunidad.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:29:46', NULL, NULL, 9, 7, 35, NULL, 'T', 0, 'T'),
    (119, 'Seleccionar las sesiones de Malvinas que actuarán como eje expositivo.', 'Seleccionar las sesiones de Malvinas que actuarán como eje expositivo.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:30:12', NULL, NULL, 9, 7, 35, NULL, 'T', 0, 'T'),
    (120, 'Incorporar los ajustes técnicos surgidos de la reunión presencial al TDR.', 'Incorporar los ajustes técnicos surgidos de la reunión presencial al TDR.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:34:10', NULL, NULL, 9, 7, 36, NULL, 'T', 0, 'T'),
    (121, 'Finalizar el presupuesto detallado y el cronograma de ejecución', 'Finalizar el presupuesto detallado y el cronograma de ejecución', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:34:40', NULL, NULL, 9, 7, 36, NULL, 'T', 0, 'T'),
    (122, 'Coordinar las pruebas de campo con alumnos del trayecto Quimiceros.', 'Coordinar las pruebas de campo con alumnos del trayecto Quimiceros.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:35:16', NULL, NULL, 9, 7, 36, NULL, 'T', 0, 'T'),
    (123, 'Verificar con Ema el alta efectiva de usuarios en la plataforma UNA.', 'Verificar con Ema el alta efectiva de usuarios en la plataforma UNA.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:37:14', NULL, NULL, 9, 7, 37, NULL, 'T', 0, 'T'),
    (124, 'Requerir a Mariel Navarro el informe actualizado de proyectos pendientes.', 'Requerir a Mariel Navarro el informe actualizado de proyectos pendientes.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:37:44', NULL, NULL, 9, 7, 37, NULL, 'T', 0, 'T'),
    (125, 'Designar al responsable operativo del seguimiento administrativo semanal.', 'Designar al responsable operativo del seguimiento administrativo semanal.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:38:15', NULL, NULL, 9, 7, 37, NULL, 'T', 0, 'T'),
    (126, 'Definir los campos y variables estandarizadas para la carga de datos.', 'Definir los campos y variables estandarizadas para la carga de datos.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:39:53', NULL, NULL, 9, 7, 38, NULL, 'T', 0, 'T'),
    (127, 'Validar el prototipo funcional de la aplicación con el equipo de gestión.', 'Validar el prototipo funcional de la aplicación con el equipo de gestión.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:40:22', NULL, NULL, 9, 7, 38, NULL, 'T', 0, 'T'),
    (128, 'Realizar la migración de datos desde los archivos Excel dispersos.', 'Realizar la migración de datos desde los archivos Excel dispersos.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:41:12', NULL, NULL, 9, 7, 38, NULL, 'T', 0, 'T'),
    (129, 'Revisar la articulación normativa bajo Resolución CFE 308/2016.', 'Revisar la articulación normativa bajo Resolución CFE 308/2016.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:42:43', NULL, NULL, 9, 7, 39, NULL, 'T', 0, 'T'),
    (130, 'Coordinar con el agente capacitador el plan de seguimiento escolar.', 'Coordinar con el agente capacitador el plan de seguimiento escolar.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:43:13', NULL, NULL, 9, 7, 39, NULL, 'T', 0, 'T');

INSERT INTO [dbo].[tasks_tarea] ([id], [titulo], [descripcion], [fecha_inicio], [fecha_vencimiento], [estado], [porcentaje_avance], [prioridad], [fecha_creacion], [area_id], [etapa_id], [responsable_id], [secretaria_id], [proyecto_id], [tarea_padre_id], [trial193], [orden], [TRIAL393])
VALUES
    (131, 'Completar la escritura del proyecto final en el Drive compartido.', 'Completar la escritura del proyecto final en el Drive compartido.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:43:41', NULL, NULL, 9, 7, 39, NULL, 'T', 0, 'T'),
    (132, 'Diseñar el programa formativo orientado a Inteligencia Artificial.', 'Diseñar el programa formativo orientado a Inteligencia Artificial.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:44:59', NULL, NULL, 9, 7, 40, NULL, 'T', 0, 'T'),
    (133, 'Definir modalidad (híbrida), carga horaria y cronograma de clases.', 'Definir modalidad (híbrida), carga horaria y cronograma de clases.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:45:35', NULL, NULL, 9, 7, 40, NULL, 'T', 0, 'T'),
    (134, 'Elaborar el kit de materiales pedagógicos para la réplica institucional.', 'Elaborar el kit de materiales pedagógicos para la réplica institucional.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:46:01', NULL, NULL, 9, 7, 40, NULL, 'T', 0, 'T'),
    (135, 'Actualizar el borrador del plan provincial integrando nuevas directrices.', 'Actualizar el borrador del plan provincial integrando nuevas directrices.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:48:00', NULL, NULL, 9, 7, 41, NULL, 'T', 0, 'T'),
    (136, 'Definir la participación de Industrias Culturales y la Bolsa de Talento.', 'Definir la participación de Industrias Culturales y la Bolsa de Talento.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:48:35', NULL, NULL, 9, 7, 41, NULL, 'T', 0, 'T'),
    (137, 'Coordinar reunión de vinculación con "Punto" y docente de biomateriales.', 'Coordinar reunión de vinculación con "Punto" y docente de biomateriales.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:49:02', NULL, NULL, 9, 7, 41, NULL, 'T', 0, 'T'),
    (138, 'Evaluar técnicamente la propuesta integral enviada por Estefi.', 'Evaluar técnicamente la propuesta integral enviada por Estefi.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:50:29', NULL, NULL, 9, 7, 42, NULL, 'T', 0, 'T'),
    (139, 'Validar los diseños pedagógicos de las bitácoras y diarios de campo.', 'Validar los diseños pedagógicos de las bitácoras y diarios de campo.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:50:53', NULL, NULL, 9, 7, 42, NULL, 'T', 0, 'T'),
    (140, 'Gestionar con la diseñadora de IPAP la impresión de las versiones 2026.', 'Gestionar con la diseñadora de IPAP la impresión de las versiones 2026.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:51:20', NULL, NULL, 9, 7, 42, NULL, 'T', 0, 'T'),
    (141, 'Establecer los ejes temáticos y la línea editorial de la temporada 2026.', 'Establecer los ejes temáticos y la línea editorial de la temporada 2026.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:52:36', NULL, NULL, 9, 7, 43, NULL, 'T', 0, 'T'),
    (142, 'Coordinar con Laura el cronograma de rodaje, locaciones y técnica.', 'Coordinar con Laura el cronograma de rodaje, locaciones y técnica.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:53:03', NULL, NULL, 9, 7, 43, NULL, 'T', 0, 'T'),
    (143, 'Relevar y convocar a científicos y referentes para las entrevistas.', 'Relevar y convocar a científicos y referentes para las entrevistas.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:53:27', NULL, NULL, 9, 7, 43, NULL, 'T', 0, 'T'),
    (144, 'Integrar a estudiantes del Colegio Martes en roles de asistencia técnica.', 'Integrar a estudiantes del Colegio Martes en roles de asistencia técnica.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:53:51', NULL, NULL, 9, 7, 43, NULL, 'T', 0, 'T'),
    (145, 'Ejecutar el plan de difusión (clips/redes) tras cada lanzamiento.', 'Ejecutar el plan de difusión (clips/redes) tras cada lanzamiento.', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:54:16', NULL, NULL, 9, 7, 43, NULL, 'T', 0, 'T'),
    (146, 'Revisar los aportes enviados por las profes', 'Revisar los aportes enviados por las profes', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:55:46', NULL, NULL, 9, 7, 44, NULL, 'T', 0, 'T'),
    (147, 'Coordinar con IPAP el diseño con las modificaciones', 'Coordinar con IPAP el diseño con las modificaciones', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:56:15', NULL, NULL, 9, 7, 44, NULL, 'T', 0, 'T'),
    (148, 'Compra de Insumos para la impresión', 'Compra de Insumos para la impresión', '2026-03-02', '2026-03-28', 'En proceso', 1, 'Media', '2026-03-02 19:56:45', NULL, NULL, 9, 7, 44, NULL, 'T', 0, 'T'),
    (175, 'Definir responsable de articulación', 'Definir responsable de articulación', '2026-03-06', '2026-03-31', 'En proceso', 1, 'Media', '2026-03-06 13:36:39', NULL, NULL, 9, 7, 52, NULL, NULL, 0, 'T'),
    (177, 'Ver estado de cuenta con los transportes', 'Ver estado de cuenta con los transportes', '2026-03-06', '2026-03-31', 'En proceso', 1, 'Media', '2026-03-06 13:39:29', NULL, NULL, 9, 7, 52, NULL, NULL, 0, 'T'),
    (176, 'Confeccionar listado de instituciones con sus respectivos contactos', 'Confeccionar listado de instituciones con sus respectivos contactos', '2026-03-06', '2026-03-31', 'En proceso', 1, 'Media', '2026-03-06 16:38:39', NULL, NULL, 9, 7, 52, NULL, NULL, 0, 'T'),
    (178, 'Definir rol de la Agencia', 'Definir rol de la Agencia', '2026-03-06', '2026-03-31', 'En proceso', 1, 'Media', '2026-03-06 13:44:46', NULL, NULL, 9, 7, 53, NULL, NULL, 0, 'T'),
    (179, 'Generar canales de comunicación con referentes institucionales secundarios', 'Generar canales de comunicación con referentes institucionales secundarios', '2026-03-06', '2026-03-31', 'En proceso', 1, 'Media', '2026-03-06 13:46:59', NULL, NULL, 9, 7, 53, NULL, NULL, 0, 'T'),
    (180, 'Contribuir en la generación de Proyectos desde la Agencia', 'Contribuir en la generación de Proyectos desde la Agencia', '2026-03-06', '2026-03-31', 'En proceso', 1, 'Media', '2026-03-06 13:49:17', NULL, NULL, 9, 7, 53, NULL, NULL, 0, 'T'),
    (37, 'Selección de perfiles y entrevistas (AIF)', 'Selección de perfiles y entrevistas (AIF)', '2026-03-02', '2026-03-30', 'En proceso', 1, 'Baja', '2026-03-02 18:39:32', NULL, NULL, 9, 7, 11, 35, 'T', 0, 'T'),
    (181, 'Solicitar a Mariel Navarro estado de proyectos PFI 22/23', 'Solicitar a Mariel Navarro estado de proyectos PFI 22/23', '2026-03-06', '2026-03-31', 'En proceso', 1, 'Media', '2026-03-06 22:52:01', NULL, NULL, 9, 7, 54, NULL, NULL, 1, 'T'),
    (183, 'Articular con Paola Rojas (admin)', 'Articular con Paola Rojas (admin)', '2026-03-06', '2026-03-31', 'En proceso', 1, 'Media', '2026-03-07 02:08:15', NULL, NULL, 9, 7, 54, NULL, NULL, 3, 'T'),
    (182, 'Informarnos sobre procedimiento administrativo', 'Informarnos sobre procedimiento administrativo', '2026-03-06', '2026-03-31', 'En proceso', 1, 'Media', '2026-03-06 19:54:01', NULL, NULL, 9, 7, 54, NULL, NULL, 2, 'T');

SET IDENTITY_INSERT [dbo].[tasks_tarea] OFF;
GO

SET IDENTITY_INSERT [dbo].[users_rol] ON;
INSERT INTO [dbo].[users_rol] ([id], [nombre], [descripcion], [trial197], [TRIAL393])
VALUES
    (1, 'Administrador', 'Acceso total al sistema', 'T', 'T'),
    (2, 'Carga', 'Puede crear y editar proyectos y tareas', 'T', 'T'),
    (3, 'Visualización', 'Solo lectura', 'T', 'T');

SET IDENTITY_INSERT [dbo].[users_rol] OFF;
GO

SET IDENTITY_INSERT [dbo].[users_usuario] ON;
INSERT INTO [dbo].[users_usuario] ([id], [nombre], [email], [password], [estado], [fecha_creacion], [rol_id], [area_id], [apellido], [secretaria_id], [trial197], [token_version], [TRIAL393])
VALUES
    (1, 'Admin', 'admin@admin.com', 'pbkdf2_sha256$600000$TfYOMWEmCY1f0SVQKtsVqD$MwpMUwgCEgiz2aftiOplx73/XxdLvEXKGraAcFaMuf0=', 1, '2026-02-26 17:01:36', 1, NULL, 'Sistema', NULL, 'T', 1, 'T'),
    (14, 'Administrador', 'admin@sipra.local', 'pbkdf2_sha256$600000$BWZHCTaJ0AsYYF5l1vwzyd$Ku0dbz/Nmwnf6vLAf+IEweoxMvA4kzv+umYimhx2Xs4=', 1, '2026-03-09 13:54:23', 1, NULL, 'SIPRA', NULL, NULL, 1, 'T'),
    (9, 'Abel Omar', 'aocortez@aif.gob.ar', 'pbkdf2_sha256$600000$vro6p16rhCOjMdppY6j7LP$YKa+fYd0muG2SKLkGlN78bZceKYzUW3PBuCvLZ5DAQw=', 1, '2026-03-02 18:22:08', 2, NULL, 'Cortez', 7, 'T', 2, 'T'),
    (6, 'horacio david', 'bogarin1983@gmail.com', 'pbkdf2_sha256$600000$iftWTp9OzjUkXt3613soxe$KCMf09fUSvuQBnclx/zDCysyZpc6rWVL553Hf3ySPjw=', 1, '2026-02-26 23:06:38', 1, NULL, 'bogarin', NULL, 'T', 3, 'T'),
    (3, 'Usuario', 'carga@test.com', 'carga123', 1, '2026-02-26 17:01:37', 2, 2, 'Carga', NULL, 'T', 1, 'T'),
    (18, 'demo2030', 'demo2030@gmail.com', 'pbkdf2_sha256$600000$KnfBgm9MGtfIy0NCwmNgU1$9H8usIQDeuineXlUSxutZ15Pwa1xoh9EfGeJYbuam1M=', 1, '2026-03-19 17:46:10', 1, NULL, 'demo2030', NULL, NULL, 1, NULL),
    (16, 'Gestion', 'gestion.proyectos@sipra.local', 'pbkdf2_sha256$600000$KqFkuDCnHnsRxjLw0ELqjk$irmLldCLhJIO1QBpPH+RiiR+6epZDmfepERKv/VFUao=', 1, '2026-03-09 13:54:24', 2, 2, 'Proyectos', NULL, NULL, 1, 'T'),
    (19, 'yesica', 'jcasadidio@aif.gob.ar', 'pbkdf2_sha256$600000$jaiRQavvNzUEH6DqLD9i06$gGNB+x0Wej5Vj1g39MIjzo47p/3ahLMAR9fBIXLdTMY=', 1, '2026-03-27 17:28:50', 1, NULL, 'casadidio', NULL, NULL, 1, NULL),
    (4, 'Juancito', 'juancito@test.com', 'pbkdf2_sha256$600000$ThTwLvNzhyP0ktjqqULWbz$U/jY3F6MNZLO53uOICcc1KgPtwyG7MlxeBymsa5Ur4E=', 1, '2026-02-26 17:05:44', 2, NULL, 'Perez', 7, 'T', 1, 'T'),
    (17, 'maxi', 'lopez@gmail.com', 'pbkdf2_sha256$600000$qdOXueZiHLnqTUE8sd3fD1$UjvfLAEKFo+XGHe+RQd5I23evyVpaQ9RAQYZigVCJQ0=', 1, '2026-03-11 19:10:53', 2, NULL, 'lopez', 3, NULL, 1, 'T'),
    (7, 'matias', 'mati@gmail.com', 'pbkdf2_sha256$600000$dxqdRhhasWQzijuxEOAeDB$ku9EoCWT2I/7zxTYycfgfQyE/XLzBKLf2wRcgD38CAo=', 0, '2026-02-27 13:13:04', 2, NULL, 'araujo', 4, 'T', 1, 'T'),
    (13, 'matias', 'matias@gmail.com', 'pbkdf2_sha256$600000$mlic0hQ6fHIbktOThJ5AOW$rC86qZ1430iNSh09OEeL0YkRI/39KgGYwyeF5DvpvR4=', 1, '2026-03-06 13:18:31', 1, NULL, 'araujo', NULL, NULL, 1, 'T'),
    (8, 'maximiliano', 'maxitorres@gmail.com', 'Tdf3015**|', 0, '2026-03-02 16:56:31', 1, NULL, 'Torres', NULL, 'T', 1, 'T'),
    (5, 'Pepe', 'pepe@test.com', 'carga123', 0, '2026-02-26 17:05:44', 2, 2, 'García', NULL, 'T', 1, 'T'),
    (15, 'Consulta', 'visualizacion@sipra.local', 'pbkdf2_sha256$600000$VjkZ0do522tq1t6Occvdjq$G29tILSZfKCElWaFoYtYUHcfbyb1Fw+tPhl11i5nBV8=', 1, '2026-03-09 16:54:23', 3, 1, 'General', NULL, NULL, 2, 'T'),
    (2, 'Usuario', 'visualizador@test.com', 'pbkdf2_sha256$600000$DLJb1IBNj4tXBkCra8puHF$YHar6qf9fW/kvmfaUs7kq2BCd25LkdnIw4ASRRSA8kg=', 1, '2026-02-26 17:01:37', 3, 1, 'Visualizador', NULL, 'T', 1, 'T');

SET IDENTITY_INSERT [dbo].[users_usuario] OFF;
GO
