#!/usr/bin/env python3

import os
import sys

FIXES = {
    "meson.build": [
        (
            "    elif not with_gallium_swrast\n"
            "      error('xlib based GLX requires softpipe or llvmpipe.')",
            "    elif not with_gallium_swrast and not with_gallium_virgl\n"
            "      error('xlib based GLX requires softpipe, llvmpipe, or virgl.')",
        ),
    ],
    "hud_context.c": [
        (
            '"DCL IN[0..1]\\n"\n'
            '         "DCL OUT[0], POSITION\\n"\n'
            '         "DCL OUT[1], COLOR[0]\\n" /* color */',
            '"DCL IN[0]\\n"\n'
            '         "DCL IN[1]\\n"\n'
            '         "DCL OUT[0], POSITION\\n"\n'
            '         "DCL OUT[1], COLOR[0]\\n" /* color */',
        ),
        (
            '"DCL IN[0..1]\\n"\n'
            '         "DCL OUT[0], POSITION\\n"\n'
            '         "DCL OUT[1], GENERIC[0]\\n" /* texcoord */',
            '"DCL IN[0]\\n"\n'
            '         "DCL IN[1]\\n"\n'
            '         "DCL OUT[0], POSITION\\n"\n'
            '         "DCL OUT[1], GENERIC[0]\\n" /* texcoord */',
        ),
    ],
    "inline_sw_helper.h": [
        (
            '#if defined(GALLIUM_VIRGL)\n'
            '   if (screen == NULL && strcmp(driver, "virpipe") == 0) {',
            '#ifdef GALLIUM_VIRGL\n'
            '   if (screen == NULL && strcmp(driver, "virpipe") == 0) {',
        ),
        (
            '#if defined(GALLIUM_D3D12)\n'
            '      (sw_vk || only_sw) ? "" : "d3d12",\n'
            '#endif\n'
            '#if defined(GALLIUM_LLVMPIPE)\n'
            '      "llvmpipe",',
            '#if defined(GALLIUM_D3D12)\n'
            '      (sw_vk || only_sw) ? "" : "d3d12",\n'
            '#endif\n'
            '#if defined(GALLIUM_VIRGL)\n'
            '      (sw_vk ? "" : "virpipe"),\n'
            '#endif\n'
            '#if defined(GALLIUM_LLVMPIPE)\n'
            '      "llvmpipe",',
        ),
    ],
    "vl_winsys_xlib_swrast.c": [
        (
            "enum pipe_format x11_window_format = "
            "vl_dri2_format_for_depth(&scrn->base, x11_window_attrs.depth);",
            "enum pipe_format x11_window_format = x11_window_attrs.depth == 24 ?\n"
            "      PIPE_FORMAT_B8G8R8X8_UNORM : PIPE_FORMAT_B8G8R8A8_UNORM;",
        ),
    ],
    "context.c": [
        (
            "      if (!check_compatible(newCtx, drawBuffer)) {\n"
            "         _mesa_warning(newCtx,\n"
            '              "MakeCurrent: incompatible visuals for context and drawbuffer");\n'
            "         return GL_FALSE;\n"
            "      }",
            "      if (!check_compatible(newCtx, drawBuffer)) {\n"
            "         _mesa_warning(newCtx,\n"
            '              "MakeCurrent: incompatible visuals for context and drawbuffer");\n'
            "         if (!_mesa_is_winsys_fbo(drawBuffer))\n"
            "            return GL_FALSE;\n"
            "      }",
        ),
        (
            "      if (!check_compatible(newCtx, readBuffer)) {\n"
            "         _mesa_warning(newCtx,\n"
            '              "MakeCurrent: incompatible visuals for context and readbuffer");\n'
            "         return GL_FALSE;\n"
            "      }",
            "      if (!check_compatible(newCtx, readBuffer)) {\n"
            "         _mesa_warning(newCtx,\n"
            '              "MakeCurrent: incompatible visuals for context and readbuffer");\n'
            "         if (!_mesa_is_winsys_fbo(readBuffer))\n"
            "            return GL_FALSE;\n"
            "      }",
        ),
    ],
    "virgl_screen.c": [
        (
            "   struct virgl_context *vctx = virgl_context(ctx);\n"
            "\n"
            "   if (vws->flush_frontbuffer) {\n"
            "      virgl_flush_eq(vctx, vctx, NULL);\n"
            "      vws->flush_frontbuffer(vws, vctx->cbuf, vres->hw_res, level, layer, winsys_drawable_handle,\n"
            "                             nboxes == 1 ? sub_box : NULL);\n"
            "   }",
            "   struct virgl_context *vctx = ctx ? virgl_context(ctx) : NULL;\n"
            "\n"
            "   if (vws->flush_frontbuffer && vctx) {\n"
            "      virgl_flush_eq(vctx, vctx, NULL);\n"
            "      vws->flush_frontbuffer(vws, vctx->cbuf, vres->hw_res, level, layer, winsys_drawable_handle,\n"
            "                             nboxes == 1 ? sub_box : NULL);\n"
            "   }",
        ),
    ],
}


def find_files(root, names):
    """Return {filename: [full paths found]} for each target name.

    meson.build exists in almost every subdirectory of a Meson project,
    so it's only looked up at the tree root. Every other filename here is
    distinctive enough to search for recursively.
    """
    found = {name: [] for name in names}

    root_meson = os.path.join(root, "meson.build")
    if "meson.build" in found and os.path.isfile(root_meson):
        found["meson.build"].append(root_meson)

    recursive_names = {n for n in names if n != "meson.build"}
    for dirpath, _, filenames in os.walk(root):
        for filename in filenames:
            if filename in recursive_names:
                found[filename].append(os.path.join(dirpath, filename))

    return found


def apply_fixes(path, replacements):
    with open(path) as f:
        content = f.read()

    changed = False
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new, 1)
            changed = True
        else:
            print(f"  {path}: anchor not found, one fix skipped")

    if changed:
        with open(path, "w") as f:
            f.write(content)
        print(f"  {path}: patched")
    else:
        print(f"  {path}: no changes applied")


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    found = find_files(root, FIXES.keys())

    for filename, replacements in FIXES.items():
        paths = found[filename]
        if not paths:
            print(f"{filename}: not found under {root}")
            continue
        for path in paths:
            apply_fixes(path, replacements)


if __name__ == "__main__":
    main()
