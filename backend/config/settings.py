import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# Cargar .env si existe (para DATABASE_URL, etc.)
_env_path = BASE_DIR / '.env'
if not _env_path.exists():
    _env_path = BASE_DIR.parent / '.env'
if _env_path.exists():
    try:
        from dotenv import load_dotenv  # type: ignore[reportMissingImports]
        load_dotenv(_env_path)
    except ImportError:
        pass

DEBUG = os.environ.get('DEBUG', '1') in ('1', 'true', 'True', 'yes')
# En producción, definir SECRET_KEY y ALLOWED_HOSTS en variables de entorno
SECRET_KEY = os.environ.get('SECRET_KEY') or (
    'django-insecure-dev-key-change-in-production' if DEBUG else None
)
if not SECRET_KEY:
    raise ValueError('SECRET_KEY es obligatoria en producción. Defínela en variables de entorno.')
_allowed = os.environ.get('ALLOWED_HOSTS', '').strip()
ALLOWED_HOSTS = [h.strip() for h in _allowed.split(',') if h.strip()] if _allowed else ['*']

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

# Selector de base de datos:
# - DB_PROVIDER=sqlite   -> usa db.sqlite3
# - DB_PROVIDER=postgres -> usa PostgreSQL local o DATABASE_URL
# - Si existe DATABASE_URL y DB_PROVIDER no está definido, usa PostgreSQL automáticamente.
_db_provider_env = os.environ.get('DB_PROVIDER')
DB_PROVIDER = (_db_provider_env or 'sqlite').strip().lower()

SQLITE_DATABASE = {
    'ENGINE': 'django.db.backends.sqlite3',
    'NAME': BASE_DIR / 'db.sqlite3',
    'OPTIONS': {
        'timeout': 20,
    }
}

# PostgreSQL configurable por variables de entorno (valores por defecto locales)
POSTGRES_DATABASE = {
    'ENGINE': 'django.db.backends.postgresql',
    'NAME': os.environ.get('POSTGRES_DB_NAME', 'sipra'),
    'USER': os.environ.get('POSTGRES_DB_USER', 'postgres'),
    'PASSWORD': os.environ.get('POSTGRES_DB_PASSWORD', '30153846'),
    'HOST': os.environ.get('POSTGRES_DB_HOST', 'localhost'),
    'PORT': int(os.environ.get('POSTGRES_DB_PORT', '5432')),
    'CONN_MAX_AGE': 600,
}

# Si existe DATABASE_URL, tiene prioridad para Postgres (útil en Render/Docker)
_db_url = os.environ.get('DATABASE_URL')
if _db_url:
    from urllib.parse import urlparse
    _parsed = urlparse(_db_url)
    POSTGRES_DATABASE = {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': _parsed.path[1:] if _parsed.path else 'sipra',
        'USER': _parsed.username or 'postgres',
        'PASSWORD': _parsed.password or '',
        'HOST': _parsed.hostname or 'localhost',
        'PORT': _parsed.port or 5432,
        'CONN_MAX_AGE': 600,
    }

# Selección final:
# - Forzar postgres por variable
# - O activar postgres automáticamente si hay DATABASE_URL
_use_postgres = (DB_PROVIDER == 'postgres') or bool(_db_url)

DATABASES = {
    'sqlite': SQLITE_DATABASE,
    'postgres': POSTGRES_DATABASE,
    'default': POSTGRES_DATABASE if _use_postgres else SQLITE_DATABASE,
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

# CORS: en desarrollo permite todo; en producción restringir con CORS_ALLOWED_ORIGINS
CORS_ALLOW_ALL_ORIGINS = DEBUG
if not DEBUG:
    _cors_origins = os.environ.get('CORS_ALLOWED_ORIGINS', '').strip()
    CORS_ALLOWED_ORIGINS = [o.strip() for o in _cors_origins.split(',') if o.strip()] if _cors_origins else []
else:
    CORS_ALLOWED_ORIGINS = []  # No usado cuando ALL_ORIGINS=True

# Backup & Restore
BACKUP_DIR = Path(os.environ.get('BACKUP_DIR', BASE_DIR / 'backups'))
CODE_BACKUP_DIR = Path(os.environ.get('CODE_BACKUP_DIR', BACKUP_DIR / 'code'))
BACKUP_SCRIPT_PATH = os.environ.get('BACKUP_SCRIPT_PATH', '')  # ej: /opt/scripts/backup.sh
ACTIVE_SESSION_MINUTES = int(os.environ.get('ACTIVE_SESSION_MINUTES', 5))
