"""Handlers de logging compatibles con Windows (archivo bloqueado durante rotación)."""
from __future__ import annotations

import logging.handlers
import sys


class WindowsSafeRotatingFileHandler(logging.handlers.RotatingFileHandler):
    """
    RotatingFileHandler que no provoca "Logging error" si rename() falla.

    En Windows, RotatingFileHandler renombra sipra.log -> sipra.log.1; si el archivo
    está abierto en el IDE, OneDrive o antivirus, WinError 32 impide el renombrado.
    En ese caso se omite la rotación y el registro sigue escribiendo en el mismo archivo.
    """

    _rotate_warning_emitted = False

    def doRollover(self) -> None:
        try:
            super().doRollover()
        except (PermissionError, OSError):
            if not WindowsSafeRotatingFileHandler._rotate_warning_emitted:
                WindowsSafeRotatingFileHandler._rotate_warning_emitted = True
                try:
                    sys.stderr.write(
                        '[logging] No se pudo rotar el archivo de log (suele estar abierto en el editor '
                        'o bloqueado por OneDrive). Cierre backend/logs/sipra.log en el IDE o ignore este aviso.\n'
                    )
                except Exception:
                    pass
