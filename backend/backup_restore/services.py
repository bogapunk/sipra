"""Servicios de backup y restore para SQL Server, SQLite y scripts externos."""
import os
import shutil
import subprocess
import zipfile
from pathlib import Path
from datetime import datetime

from django.conf import settings
from django.db import connection

# Carpetas y archivos a excluir del backup de código
CODE_BACKUP_EXCLUDE = {
    'node_modules', '__pycache__', '.git', 'venv', 'env', '.venv',
    'dist', '.eggs', '*.egg-info', '.idea', '.vscode', '.DS_Store',
    'backups', 'db.sqlite3', '*.pyc', '.env', '.env.local',
}


def is_mssql():
    """Indica si la base de datos actual es Microsoft SQL Server."""
    return settings.DATABASES['default']['ENGINE'] == 'mssql'


def get_db_path():
    """Ruta del archivo de base de datos actual (solo SQLite)."""
    db_settings = settings.DATABASES['default']
    if db_settings['ENGINE'] == 'django.db.backends.sqlite3':
        return Path(db_settings['NAME'])
    return None


def ensure_backup_dir():
    """Asegura que el directorio de backups exista."""
    backup_dir = Path(settings.BACKUP_DIR)
    backup_dir.mkdir(parents=True, exist_ok=True)
    return backup_dir


def run_external_backup_script():
    """Ejecuta el script externo de backup si está configurado."""
    script_path = getattr(settings, 'BACKUP_SCRIPT_PATH', '') or ''
    if not script_path or not os.path.isfile(script_path):
        return None, "Script de backup no configurado o no existe"
    try:
        result = subprocess.run(
            [script_path],
            capture_output=True,
            text=True,
            timeout=120,
            cwd=os.path.dirname(script_path) or None,
        )
        if result.returncode != 0:
            return None, f"Script falló: {result.stderr or result.stdout or 'código ' + str(result.returncode)}"
        return True, result.stdout or "Backup ejecutado"
    except subprocess.TimeoutExpired:
        return None, "El script de backup excedió el tiempo límite"
    except Exception as e:
        return None, str(e)


def _create_mssql_backup():
    """Crea backup de SQL Server usando Django dumpdata (JSON)."""
    from django.core.management import call_command

    backup_dir = ensure_backup_dir()
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_name = f"backup_{timestamp}.json"
    backup_path = backup_dir / backup_name

    with open(backup_path, 'w', encoding='utf-8') as f:
        call_command(
            'dumpdata',
            '--natural-foreign',
            '--natural-primary',
            stdout=f,
        )
    return str(backup_path)


def create_backup():
    """
    Crea un backup de la base de datos.
    Si BACKUP_SCRIPT_PATH está configurado, ejecuta ese script.
    Si SQL Server: usa dumpdata (JSON).
    Si SQLite: copia el archivo .sqlite3.
    """
    script_path = getattr(settings, 'BACKUP_SCRIPT_PATH', '') or ''
    if script_path and os.path.isfile(script_path):
        ok, msg = run_external_backup_script()
        if not ok:
            raise RuntimeError(msg)
        return msg

    if is_mssql():
        return _create_mssql_backup()

    db_path = get_db_path()
    if not db_path or not db_path.exists():
        raise RuntimeError("Base de datos SQLite no encontrada")

    backup_dir = ensure_backup_dir()
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_name = f"backup_{timestamp}.sqlite3"
    backup_path = backup_dir / backup_name

    shutil.copy2(db_path, backup_path)
    return str(backup_path)


def list_backups():
    """Lista los archivos de backup disponibles (SQL Server, SQLite)."""
    script_path = getattr(settings, 'BACKUP_SCRIPT_PATH', '') or ''
    if script_path:
        return []  # Con script externo, no listamos desde Django

    backup_dir = ensure_backup_dir()
    backups = []
    patterns = ['backup_*.sqlite3']
    if is_mssql():
        patterns = ['backup_*.json']
    files = []
    for pattern in patterns:
        files.extend(list(backup_dir.glob(pattern)))
    for f in sorted(files, reverse=True):
        stat = f.stat()
        backups.append({
            'filename': f.name,
            'path': str(f),
            'size': stat.st_size,
            'created': datetime.fromtimestamp(stat.st_mtime).isoformat(),
        })
    return backups


def _should_exclude_from_code_backup(rel_path: str, name: str) -> bool:
    """Determina si un archivo/carpeta debe excluirse del backup de código."""
    parts = rel_path.replace('\\', '/').lower().split('/')
    name_lower = name.lower()
    if name_lower in CODE_BACKUP_EXCLUDE:
        return True
    if 'node_modules' in parts or '__pycache__' in parts or '.git' in parts:
        return True
    if 'venv' in parts or 'env' in parts or '.venv' in parts:
        return True
    if 'backups' in parts:
        return True
    if name_lower.endswith('.pyc') or name_lower.endswith('.pyo'):
        return True
    if name_lower.startswith('.env'):
        return True
    return False


def ensure_code_backup_dir():
    """Asegura que el directorio de backups de código exista."""
    code_dir = Path(settings.CODE_BACKUP_DIR)
    code_dir.mkdir(parents=True, exist_ok=True)
    return code_dir


def create_code_backup():
    """
    Genera una copia de seguridad del código del sistema en formato ZIP.
    Almacena el archivo en la carpeta interna CODE_BACKUP_DIR.
    Excluye node_modules, __pycache__, venv, .git, backups, etc.
    """
    project_root = Path(settings.BASE_DIR).parent
    if not project_root.exists():
        raise RuntimeError(f"Directorio raíz del proyecto no encontrado: {project_root}")

    code_backup_dir = ensure_code_backup_dir()
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    zip_name = f"codigo_backup_{timestamp}.zip"
    zip_path = code_backup_dir / zip_name

    total_files = 0
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(project_root):
            # Filtrar directorios a excluir (modifica dirs in-place para que walk no los recorra)
            dirs[:] = [d for d in dirs if not _should_exclude_from_code_backup(
                os.path.relpath(os.path.join(root, d), project_root), d
            )]
            rel_root = os.path.relpath(root, project_root)
            if rel_root == '.':
                rel_root = ''
            for f in files:
                if _should_exclude_from_code_backup(
                    os.path.join(rel_root, f) if rel_root else f, f
                ):
                    continue
                full_path = os.path.join(root, f)
                arcname = os.path.join(rel_root, f) if rel_root else f
                try:
                    zf.write(full_path, arcname)
                    total_files += 1
                except (OSError, zipfile.LargeZipFile) as e:
                    # Ignorar archivos que no se pueden leer (permisos, etc.)
                    pass

    return str(zip_path)


def delete_backup(filename: str):
    """Elimina un archivo de backup de BD. Valida que el nombre sea seguro."""
    if not filename or '..' in filename or '/' in filename or '\\' in filename:
        raise RuntimeError("Nombre de archivo no válido")
    if not filename.endswith('.sqlite3') and not filename.endswith('.sql') and not filename.endswith('.json'):
        raise RuntimeError("Solo se pueden eliminar archivos de backup de BD (.sqlite3, .sql, .json)")
    backup_dir = ensure_backup_dir()
    path = backup_dir / filename
    if not path.exists():
        raise RuntimeError("Archivo de backup no encontrado")
    if path.resolve() != (backup_dir / filename).resolve():
        raise RuntimeError("Ruta no permitida")
    path.unlink()
    return True


def delete_code_backup(filename: str):
    """Elimina un archivo de backup de código. Valida que el nombre sea seguro."""
    if not filename or '..' in filename or '/' in filename or '\\' in filename:
        raise RuntimeError("Nombre de archivo no válido")
    if not filename.startswith('codigo_backup_') or not filename.endswith('.zip'):
        raise RuntimeError("Solo se pueden eliminar backups de código (.zip)")
    code_dir = ensure_code_backup_dir()
    path = code_dir / filename
    if not path.exists():
        raise RuntimeError("Archivo de backup no encontrado")
    if path.resolve() != (code_dir / filename).resolve():
        raise RuntimeError("Ruta no permitida")
    path.unlink()
    return True


def list_code_backups():
    """Lista los backups de código disponibles (archivos .zip)."""
    code_dir = Path(settings.CODE_BACKUP_DIR)
    if not code_dir.exists():
        return []
    backups = []
    for f in sorted(code_dir.glob('codigo_backup_*.zip'), reverse=True):
        stat = f.stat()
        backups.append({
            'filename': f.name,
            'path': str(f),
            'size': stat.st_size,
            'created': datetime.fromtimestamp(stat.st_mtime).isoformat(),
        })
    return backups


def _restore_mssql(backup_path: Path):
    """Restaura SQL Server desde un dump JSON (dumpdata)."""
    from django.core.management import call_command

    connection.close()
    try:
        call_command('flush', '--no-input')
        call_command('loaddata', str(backup_path))
    except Exception as e:
        connection.ensure_connection()
        raise RuntimeError(f"Restore falló: {e}") from e
    connection.ensure_connection()
    return str(backup_path)


def restore_from_file(backup_path: str):
    """
    Restaura la base de datos desde un archivo de backup.
    SQL Server: loaddata desde JSON. SQLite: copia el archivo.
    """
    path = Path(backup_path)
    if not path.is_absolute():
        path = Path(settings.BACKUP_DIR) / path
    if not path.exists():
        raise RuntimeError(f"Archivo de backup no encontrado: {path}")

    if is_mssql():
        if path.suffix.lower() != '.json':
            raise RuntimeError("Para SQL Server use un backup .json (dumpdata)")
        return _restore_mssql(path)

    db_path = get_db_path()
    if not db_path:
        raise RuntimeError("Restore solo soportado para SQL Server o SQLite")

    connection.close()
    shutil.copy2(path, db_path)
    connection.ensure_connection()
    return str(path)
