#!/usr/bin/env python3
import os

def replace_in_file(filepath, search_text, replace_text):
    """Searches for a block of text in a file and replaces it."""
    if not os.path.exists(filepath):
        print(f"[SKIP] {filepath} not found.")
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if search_text in content:
        content = content.replace(search_text, replace_text)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"[SUCCESS] Reverted changes in {filepath}")
    elif replace_text in content:
        print(f"[SKIP] {filepath} already seems to have this reverted.")
    else:
        print(f"[WARNING] Could not find target text in {filepath}. Has the file changed heavily?")

def create_file(filepath, content):
    """Creates a file with the given content."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"[SUCCESS] Created {filepath}")

def delete_file(filepath):
    """Deletes a file if it exists."""
    if os.path.exists(filepath):
        os.remove(filepath)
        print(f"[SUCCESS] Deleted {filepath}")
    else:
        print(f"[SKIP] {filepath} already deleted or missing.")

def main():
    # 1. Standard text replacements (Reverting by finding the "new" code and swapping back to "old")
    replacements = [
        (
            "src/egl/meson.build",
            "link_with : [link_for_egl],", 
            "link_with : [link_for_egl, libglapi],"
        ),
        (
            "src/gallium/targets/dri/dri.sym.in",
            "{\n\tglobal:\n                # shared-glapi exported from libgallium:\n                _glapi_get_context;\n                _glapi_get_dispatch;\n                _glapi_get_dispatch_table_size;\n                _glapi_get_proc_address;\n                _glapi_get_proc_offset;\n                _glapi_set_context;\n                _glapi_set_dispatch;\n                _glapi_tls_Context;\n                _glapi_tls_Dispatch;\n\n\t\tddebug_screen_create;",
            "{\n\tglobal:\n\t\tddebug_screen_create;"
        ),
        (
            "src/gallium/targets/dri/meson.build",
            "libgallium_dri = shared_library(\n  name_suffix : libname_suffix,\n)\n\nshared_glapi_lib = libgallium_dri\n",
            "libgallium_dri = shared_library(\n  name_suffix : libname_suffix,\n)\n"
        ),
        (
            "src/gallium/targets/libgl-xlib/libgl-xlib.sym",
            "{\n\tglobal:\n                _glapi_Dispatch;\n                _glapi_tls_Dispatch;\n                _glapi_get_dispatch_table_size; # only for tests\n                _glapi_get_proc_offset; # only for tests\n\t\tgl*;",
            "{\n\tglobal:\n\t\tgl*;"
        ),
        (
            "src/gallium/targets/libgl-xlib/meson.build",
            "  darwin_versions: '4.0.0',\n)\n\nshared_glapi_lib = libgl\n",
            "  darwin_versions: '4.0.0',\n)\n"
        ),
        (
            "src/gallium/targets/wgl/meson.build",
            "  install : true,\n)\nlibgallium_wgl_build_dir = meson.current_build_dir()\n\nshared_glapi_lib = libgallium_wgl\n",
            "  install : true,\n)\nlibgallium_wgl_build_dir = meson.current_build_dir()\n"
        ),
        (
            "src/glx/meson.build",
            "link_with : [libglapi_static],",
            "link_with : [libglapi_static, libglapi],"
        ),
        (
            "src/mapi/es1api/meson.build",
            "link_with : shared_glapi_lib,",
            "link_with : libglapi,"
        ),
        (
            "src/mapi/es2api/meson.build",
            "link_with : shared_glapi_lib,",
            "link_with : libglapi,"
        ),
        (
            "src/mapi/meson.build",
            "else\n  libglapi = []\nendif\n",
            "else\n  libglapi = []\nendif\nif not with_glvnd\n  if with_gles1\n    subdir('es1api')\n  endif\n  if with_gles2\n    subdir('es2api')\n  endif\nendif\n"
        ),
        (
            "src/mapi/shared-glapi/meson.build",
            "libglapi = static_library(\n  'glapi',\n",
            "libglapi = shared_library(\n  'glapi',\n"
        ),
        (
            "src/mapi/shared-glapi/meson.build",
            "  dependencies : [dep_thread, idep_mesautil],\n  install : false,\n)\nlibglapi_build_dir = meson.current_build_dir()",
            "  dependencies : [dep_thread, idep_mesautil],\n  soversion : host_machine.system() == 'windows' ? '' : '0',\n  version : '0.0.0',\n  name_prefix : host_machine.system() == 'windows' ? 'lib' : [],  # always use lib, but avoid warnings on !windows\n  install : true,\n)\nlibglapi_build_dir = meson.current_build_dir()\n\nif with_any_opengl and with_tests\n  test(\n    'shared-glapi-test',\n    executable(\n      ['shared-glapi-test', glapitable_h],\n      'tests/check_table.cpp',\n      cpp_args : [cpp_msvc_compat_args],\n      include_directories : [inc_src, inc_include, inc_mapi],\n      link_with : [libglapi],\n      dependencies : [dep_thread, idep_gtest, idep_mesautilc11],\n    ),\n    suite : ['mapi'],\n    protocol : 'gtest',\n  )\n  if with_symbols_check\n    test(\n      'shared-glapi symbols check',\n      symbols_check,\n      args : [\n        '--lib', libglapi,\n        '--symbols-file', files('glapi-symbols.txt'),\n        symbols_check_args,\n      ],\n      suite : ['mapi'],\n    )\n  endif\nendif\n"
        ),
        (
            "src/mesa/meson.build",
            "if with_platform_windows\n  _mesa_windows_args += [\n    '-D_GDI32_',    # prevent gl* being declared __declspec(dllimport) in MS headers\n  ]\nendif",
            "if with_platform_windows\n  _mesa_windows_args += [\n    '-D_GLAPI_NO_EXPORTS',\n    '-D_GDI32_',    # prevent gl* being declared __declspec(dllimport) in MS headers\n  ]\n  if not with_shared_glapi\n    # prevent _glapi_* from being declared __declspec(dllimport)\n    _mesa_windows_args += '-D_GLAPI_NO_EXPORTS'\n  endif\nendif"
        ),
        (
            "src/mesa/state_tracker/tests/meson.build",
            "libmesa, shared_glapi_lib, libgallium,",
            "libmesa, libglapi, libgallium,"
        ),
        (
            "src/meson.build",
            "# These require libgallium (shared_glapi_lib)\nif with_gallium and (with_glx != 'disabled' or with_egl)\n\n  if with_gles1 and not with_glvnd\n    subdir('mapi/es1api')\n  endif\n  if with_gles2 and not with_glvnd\n    subdir('mapi/es2api')\n  endif\n  if with_tests and with_shared_glapi\n    subdir('mapi/shared-glapi/tests')\n    subdir('mesa/main/tests')\n    subdir('mesa/state_tracker/tests')\n  endif\nendif",
            "if with_gallium and with_tests\n  # This has to be here since it requires libgallium, and subdir cannot\n  # contain ..\n  subdir('mesa/main/tests')\n  if with_shared_glapi\n    subdir('mesa/state_tracker/tests')\n  endif\nendif"
        )
    ]

    for filepath, search_text, replace_text in replacements:
        replace_in_file(filepath, search_text, replace_text)

    # 2. File Restorations (Recreating deleted files)
    glapi_symbols_content = """_glapi_Context
_glapi_Dispatch
_glapi_add_dispatch
_glapi_check_multithread
_glapi_destroy_multithread
_glapi_get_context
_glapi_get_dispatch
_glapi_get_dispatch_table_size
_glapi_get_proc_address
_glapi_get_proc_name
_glapi_get_proc_offset
_glapi_new_nop_table
_glapi_noop_enable_warnings
_glapi_set_context
_glapi_set_dispatch
_glapi_set_nop_handler
_glapi_set_warning_func
(optional) _glapi_tls_Context
(optional) _glapi_tls_Dispatch
_glthread_GetID
"""
    create_file("src/mapi/shared-glapi/glapi-symbols.txt", glapi_symbols_content)

    # 3. File Deletions (Removing files created by the patch)
    delete_file("src/mapi/shared-glapi/tests/meson.build")

    print("\nRevert operation complete!")

if __name__ == "__main__":
    main()
