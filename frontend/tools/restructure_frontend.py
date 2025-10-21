import re
import shutil
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
LIB_DIR = BASE_DIR / "lib"

mapping: dict[str, str] = {}


def add_mapping(old_rel: str, new_rel: str) -> None:
    old_key = old_rel.replace("\\", "/")
    new_value = new_rel.replace("\\", "/")
    existing = mapping.get(old_key)
    if existing and existing != new_value:
        raise ValueError(f"Conflicting mapping for {old_key}: {existing} vs {new_value}")
    mapping[old_key] = new_value


manual_mapping = {
    "auth/contrasena.dart": "features/auth/presentation/screens/contrasena/contrasena.dart",
    "auth/login.dart": "features/auth/presentation/screens/login/login.dart",
    "auth/recuperacion.dart": "features/auth/presentation/screens/recuperacion/recuperacion.dart",
    "auth/registro.dart": "features/auth/presentation/screens/registro/registro.dart",
    "auth/simple_login.dart": "features/auth/presentation/screens/simple_login/simple_login.dart",
    "auth/verificacion.dart": "features/auth/presentation/screens/verificacion/verificacion.dart",
    "home/auspiciadores_screen.dart": "features/home/presentation/screens/auspiciadores/auspiciadores_screen.dart",
    "home/home_screen.dart": "features/home/presentation/screens/home/home_screen.dart",
    "home/merchandising_screen.dart": "features/home/presentation/screens/merchandising/merchandising_screen.dart",
    "home/noticias_screen.dart": "features/home/presentation/screens/noticias/noticias_screen.dart",
    "admin/apoderado_dashboard.dart": "features/admin/presentation/screens/dashboards/apoderado/apoderado_dashboard.dart",
    "admin/base_datos_screen.dart": "features/admin/presentation/screens/usuarios/base_datos/base_datos_screen.dart",
    "admin/directiva_dashboard.dart": "features/admin/presentation/screens/dashboards/directiva/directiva_dashboard.dart",
    "admin/entrenador_dashboard.dart": "features/admin/presentation/screens/dashboards/entrenador/entrenador_dashboard.dart",
    "admin/entrenador_justificantes_screen.dart": "features/admin/presentation/screens/justificantes/entrenador/entrenador_justificantes_screen.dart",
    "admin/gestion_actas_reunion_screen.dart": "features/admin/presentation/screens/actas/gestion/gestion_actas_reunion_screen.dart",
    "admin/gestion_asistencia_screen_wessex.dart": "features/admin/presentation/screens/asistencia/gestion/gestion_asistencia_screen_wessex.dart",
    "admin/gestion_eventos_screen.dart": "features/admin/presentation/screens/eventos/gestion/gestion_eventos_screen.dart",
    "admin/gestion_eventos_screen_corrupted.dart": "features/admin/presentation/screens/eventos/legacy/gestion_eventos_screen_corrupted.dart",
    "admin/gestion_informacion_publica_screen.dart": "features/admin/presentation/screens/informacion_publica/gestion_informacion_publica_screen.dart",
    "admin/gestion_justificantes_screen.dart": "features/admin/presentation/screens/justificantes/gestion/gestion_justificantes_screen.dart",
    "admin/gestion_usuarios_screen.dart": "features/admin/presentation/screens/usuarios/gestion/gestion_usuarios_screen.dart",
    "admin/gestion_vouchers_screen.dart": "features/admin/presentation/screens/pagos/gestion/gestion_vouchers_screen.dart",
    "admin/historial_asistencia_screen_wessex.dart": "features/admin/presentation/screens/asistencia/historial/historial_asistencia_screen_wessex.dart",
    "admin/historial_justificantes_screen.dart": "features/admin/presentation/screens/justificantes/historial/historial_justificantes_screen.dart",
    "admin/historial_sesiones_screen.dart": "features/admin/presentation/screens/asistencia/sesiones/historial_sesiones_screen.dart",
    "admin/historial_vouchers_screen.dart": "features/admin/presentation/screens/pagos/historial/historial_vouchers_screen.dart",
    "admin/inscripciones_screen.dart": "features/admin/presentation/screens/inscripciones/inscripciones_screen.dart",
    "admin/justificante_screen.dart": "features/admin/presentation/screens/justificantes/detalle/justificante_screen.dart",
    "admin/rama_externa_screen.dart": "features/admin/presentation/screens/rama_externa/rama_externa_screen.dart",
    "admin/rama_externa_screen_new.dart": "features/admin/presentation/screens/rama_externa/rama_externa_screen_new.dart",
    "admin/registro_datos_screen.dart": "features/admin/presentation/screens/usuarios/registro/registro_datos_screen.dart",
    "admin/subir_voucher_page.dart": "features/admin/presentation/screens/pagos/subir/subir_voucher_page.dart",
    "admin/tesorera_dashboard.dart": "features/admin/presentation/screens/dashboards/tesorera/tesorera_dashboard.dart",
    "admin/tipos_evento/admin_tipos_evento_screen.dart": "features/admin/presentation/screens/eventos/tipos/admin_tipos_evento_screen.dart",
    "admin/tomar_asistencia_screen.dart": "features/admin/presentation/screens/asistencia/tomar/tomar_asistencia_screen.dart",
    "admin/voucher_pago_screen.dart": "features/admin/presentation/screens/pagos/voucher/voucher_pago_screen.dart",
    "widgets/visualizar_actas_reunion_screen.dart": "features/admin/presentation/screens/actas/visualizar/visualizar_actas_reunion_screen.dart",
}

for old_rel, new_rel in manual_mapping.items():
    add_mapping(old_rel, new_rel)

widget_mapping = {
    "widgets/admin_navbar.dart": "shared/widgets/navigation/admin_navbar.dart",
    "widgets/conflicto_temporal_widgets.dart": "shared/widgets/dialogs/conflicto_temporal_widgets.dart",
    "widgets/custom_drawer.dart": "shared/widgets/navigation/custom_drawer.dart",
    "widgets/custom_navbar_con_notificaciones.dart": "shared/widgets/navigation/custom_navbar_con_notificaciones.dart",
    "widgets/image_upload_widget.dart": "shared/widgets/forms/image_upload_widget.dart",
    "widgets/loading_states.dart": "shared/widgets/states/loading_states.dart",
    "widgets/wessex_widgets.dart": "shared/widgets/layout/wessex_widgets.dart",
}

for old_rel, new_rel in widget_mapping.items():
    add_mapping(old_rel, new_rel)

auto_dirs = [
    ("config", "core/config"),
    ("models", "data/models"),
    ("services", "data/services"),
    ("helpers", "shared/helpers"),
    ("utils", "shared/utils"),
]

for src_dir, dest_dir in auto_dirs:
    src_path = LIB_DIR / src_dir
    if not src_path.exists():
        continue
    for file_path in src_path.rglob("*.dart"):
        rel_old = file_path.relative_to(LIB_DIR).as_posix()
        rel_new = (Path(dest_dir) / file_path.relative_to(src_path)).as_posix()
        add_mapping(rel_old, rel_new)


IMPORT_EXPORT_PATTERN = re.compile(r'^(\s*)(import|export)(\s+)(["\'])([^"\']+)(["\'])(.*)$')


def resolve_import_path(current_file: Path, import_path: str) -> str | None:
    if import_path.startswith("dart:"):
        return None
    if import_path.startswith("package:"):
        if not import_path.startswith("package:wesrugby/"):
            return None
        return import_path[len("package:wesrugby/"):]

    target = (current_file.parent / import_path).resolve()
    try:
        relative = target.relative_to(LIB_DIR)
    except ValueError:
        return None
    return relative.as_posix()


def rewrite_imports() -> tuple[int, int]:
    updated_files = 0
    updated_imports = 0
    for dart_path in sorted(LIB_DIR.rglob("*.dart")):
        original_text = dart_path.read_text(encoding="utf-8")
        lines = original_text.splitlines(keepends=True)
        changed = False
        new_lines: list[str] = []
        for line in lines:
            match = IMPORT_EXPORT_PATTERN.match(line)
            if match:
                import_path = match.group(5)
                resolved = resolve_import_path(dart_path, import_path)
                if resolved and resolved in mapping:
                    new_path = "package:wesrugby/" + mapping[resolved]
                    if import_path != new_path:
                        line = (
                            f"{match.group(1)}{match.group(2)}{match.group(3)}"
                            f"{match.group(4)}{new_path}{match.group(6)}{match.group(7)}"
                        )
                        changed = True
                        updated_imports += 1
            new_lines.append(line)
        if changed:
            dart_path.write_text("".join(new_lines), encoding="utf-8")
            updated_files += 1
    return updated_files, updated_imports


def move_files() -> int:
    moved = 0
    for old_rel, new_rel in sorted(mapping.items(), key=lambda kv: len(kv[0]), reverse=True):
        src = LIB_DIR / old_rel
        dest = LIB_DIR / new_rel
        if not src.exists():
            raise FileNotFoundError(f"Source not found for move: {src}")
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            raise FileExistsError(f"Destination already exists: {dest}")
        shutil.move(str(src), str(dest))
        moved += 1
    return moved


def move_legacy_files() -> None:
    legacy_moves = {
        "lib/home/home_screen.dart.backup": "lib/legacy/home/home_screen.dart.backup",
    }
    for src_rel, dest_rel in legacy_moves.items():
        src = BASE_DIR / src_rel
        if not src.exists():
            continue
        dest = BASE_DIR / dest_rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dest))


def cleanup_obsolete_directories() -> None:
    dirs_to_remove = [
        LIB_DIR / "auth",
        LIB_DIR / "home",
        LIB_DIR / "admin",
        LIB_DIR / "admin/tipos_evento",
        LIB_DIR / "widgets",
        LIB_DIR / "config",
        LIB_DIR / "models",
        LIB_DIR / "services",
        LIB_DIR / "helpers",
        LIB_DIR / "utils",
        LIB_DIR / "presentation",
    ]
    for dir_path in dirs_to_remove:
        if dir_path.exists():
            shutil.rmtree(dir_path)


def main() -> None:
    updated_files, updated_imports = rewrite_imports()
    print(f"Updated imports in {updated_files} files ({updated_imports} modifications).")
    moved = move_files()
    print(f"Moved {moved} files to new locations.")
    move_legacy_files()
    cleanup_obsolete_directories()


if __name__ == "__main__":
    main()
