import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-dev-key-change-in-production')
DEBUG = os.environ.get('DEBUG', '1') in ('1', 'true', 'True', 'yes')
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split(',')

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

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# PostgreSQL cuando se usa Docker (DATABASE_URL)
_db_url = os.environ.get('DATABASE_URL')
if _db_url:
    from urllib.parse import urlparse
    _parsed = urlparse(_db_url)
    DATABASES['default'] = {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': _parsed.path[1:] if _parsed.path else 'seguimiento_proyectos',
        'USER': _parsed.username or 'postgres',
        'PASSWORD': _parsed.password or '',
        'HOST': _parsed.hostname or 'db',
        'PORT': _parsed.port or 5432,
        'CONN_MAX_AGE': 600,
    }

LANGUAGE_CODE = 'es'
TIME_ZONE = 'America/Argentina/Buenos_Aires'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.AllowAny'],
}

CORS_ALLOW_ALL_ORIGINS = True

# Backup & Restore
BACKUP_DIR = Path(os.environ.get('BACKUP_DIR', BASE_DIR / 'backups'))
CODE_BACKUP_DIR = Path(os.environ.get('CODE_BACKUP_DIR', BACKUP_DIR / 'code'))
BACKUP_SCRIPT_PATH = os.environ.get('BACKUP_SCRIPT_PATH', '')  # ej: /opt/scripts/backup.sh
ACTIVE_SESSION_MINUTES = int(os.environ.get('ACTIVE_SESSION_MINUTES', 5))
