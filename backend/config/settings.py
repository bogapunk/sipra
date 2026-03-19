import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# Cargar .env si existe (para DB_*, etc.)
_env_path = BASE_DIR / '.env'
if not _env_path.exists():
    _env_path = BASE_DIR.parent / '.env'
if _env_path.exists():
    try:
        from dotenv import load_dotenv  # type: ignore[reportMissingImports]
        load_dotenv(_env_path)
    except ImportError:
        pass

def _env_bool(name: str, default: bool = False) -> bool:
    return (os.environ.get(name, '1' if default else '0') or '').strip().lower() in (
        '1', 'true', 'yes', 'on'
    )


def _env_list(name: str, default: list[str] | None = None) -> list[str]:
    raw = (os.environ.get(name, '') or '').strip()
    if not raw:
        return list(default or [])
    return [item.strip() for item in raw.split(',') if item.strip()]


DEBUG = _env_bool('DEBUG', False)
# En producción, definir SECRET_KEY y ALLOWED_HOSTS en variables de entorno.
SECRET_KEY = os.environ.get('SECRET_KEY') or (
    'django-insecure-local-dev-only' if DEBUG else None
)
if not SECRET_KEY:
    raise ValueError('SECRET_KEY es obligatoria en producción. Defínela en variables de entorno.')
ALLOWED_HOSTS = _env_list('ALLOWED_HOSTS', ['localhost', '127.0.0.1'] if DEBUG else [])
if not DEBUG and not ALLOWED_HOSTS:
    raise ValueError('ALLOWED_HOSTS es obligatoria en producción. Defínela en variables de entorno.')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'users',
    'areas',
    'secretarias',
    'projects',
    'tasks',
    'dashboards',
    'backup_restore',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.gzip.GZipMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'
WSGI_APPLICATION = 'config.wsgi.application'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# Base de datos: Microsoft SQL Server 2022 (DB_TYPE=mssql)
def _env_str(name: str, default: str = '') -> str:
    return (os.environ.get(name, default) or default).strip()


def _env_host(name: str, default: str = 'localhost') -> str:
    """
    Normaliza host para evitar errores por espacios/comillas accidentales
    en variables de entorno (ej: "localhost ").
    """
    raw = _env_str(name, default).strip().strip('"').strip("'")
    if not raw:
        return default
    return raw.split()[0]


def _build_mssql_database() -> dict:
    """Configuración para Microsoft SQL Server (DB_TYPE=mssql)."""
    driver = _env_str(
        'DB_ODBC_DRIVER',
        'ODBC Driver 17 for SQL Server',  # Driver 17 más común en Windows; use 18 si lo tiene
    )
    return {
        'ENGINE': 'mssql',
        'NAME': _env_str('DB_NAME', 'Sipra'),
        'USER': _env_str('DB_USER', 'SA'),
        'PASSWORD': _env_str('DB_PASSWORD', ''),
        'HOST': _env_host('DB_HOST', 'localhost'),
        'PORT': _env_str('DB_PORT', '1433') or '',
        'CONN_MAX_AGE': int(_env_str('DB_CONN_MAX_AGE', '600')),
        'OPTIONS': {
            'driver': driver,
            'extra_params': 'TrustServerCertificate=yes',
        },
    }


DB_TYPE = _env_str('DB_TYPE', 'mssql').lower()
if DB_TYPE != 'mssql':
    raise ValueError('SIPRA usa exclusivamente Microsoft SQL Server. Defina DB_TYPE=mssql.')

DEFAULT_DATABASE = _build_mssql_database()

DATABASES = {
    'default': DEFAULT_DATABASE,
}

LANGUAGE_CODE = 'es'
TIME_ZONE = 'America/Argentina/Buenos_Aires'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
MEDIA_URL = '/media/'
MEDIA_ROOT = Path(os.environ.get('MEDIA_ROOT', BASE_DIR / 'media'))
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': ['users.jwt_auth.JWTAuthentication'],
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.IsAuthenticated'],
}

# CORS / CSRF
CORS_ALLOW_ALL_ORIGINS = _env_bool('CORS_ALLOW_ALL_ORIGINS', DEBUG)
CORS_ALLOWED_ORIGINS = [] if CORS_ALLOW_ALL_ORIGINS else _env_list('CORS_ALLOWED_ORIGINS')
CSRF_TRUSTED_ORIGINS = _env_list('CSRF_TRUSTED_ORIGINS')

if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_SSL_REDIRECT = _env_bool('SECURE_SSL_REDIRECT', False)
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'

# Logging (consola + archivo rotativo)
LOG_LEVEL = _env_str('LOG_LEVEL', 'DEBUG' if DEBUG else 'INFO').upper()
LOG_DIR = Path(_env_str('LOG_DIR', str(BASE_DIR / 'logs')))
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / _env_str('LOG_FILE_NAME', 'sipra.log')
LOG_MAX_BYTES = int(_env_str('LOG_MAX_BYTES', str(10 * 1024 * 1024)))
LOG_BACKUP_COUNT = int(_env_str('LOG_BACKUP_COUNT', '10'))

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'standard': {
            'format': '[{asctime}] {levelname} {name}: {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'standard',
            'level': LOG_LEVEL,
        },
        'file': {
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': str(LOG_FILE),
            'maxBytes': LOG_MAX_BYTES,
            'backupCount': LOG_BACKUP_COUNT,
            'formatter': 'standard',
            'level': LOG_LEVEL,
            'encoding': 'utf-8',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': LOG_LEVEL,
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': LOG_LEVEL,
            'propagate': False,
        },
        'django.request': {
            'handlers': ['console', 'file'],
            'level': 'WARNING',
            'propagate': False,
        },
    },
}

# Backup & Restore
# Estructura: backups/sql/YYYY-MM-DD/sipra_*.sql (local y producción)
BACKUP_DIR = Path(os.environ.get('BACKUP_DIR', BASE_DIR / 'backups'))
BACKUP_SQL_DIR = Path(os.environ.get('BACKUP_SQL_DIR', BACKUP_DIR / 'sql'))
CODE_BACKUP_DIR = Path(os.environ.get('CODE_BACKUP_DIR', BACKUP_DIR / 'code'))
BACKUP_SCRIPT_PATH = os.environ.get('BACKUP_SCRIPT_PATH', '')  # opcional: script externo
ACTIVE_SESSION_MINUTES = int(os.environ.get('ACTIVE_SESSION_MINUTES', 5))
JWT_EXPIRES_HOURS = int(os.environ.get('JWT_EXPIRES_HOURS', '8'))
JWT_ISSUER = _env_str('JWT_ISSUER', 'sipra')
JWT_AUDIENCE = _env_str('JWT_AUDIENCE', 'sipra-web')
MAX_UPLOAD_SIZE_MB = int(os.environ.get('MAX_UPLOAD_SIZE_MB', '10'))
ALLOWED_UPLOAD_EXTENSIONS = _env_list(
    'ALLOWED_UPLOAD_EXTENSIONS',
    ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'csv', 'txt', 'png', 'jpg', 'jpeg', 'webp']
)
