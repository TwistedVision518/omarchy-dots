#!/usr/bin/env python3
"""Rebuild the Sakura-Mochi XCursor + hyprcursor theme from Adwaita."""
from __future__ import annotations

import shutil
import struct
import subprocess
from collections import defaultdict
from pathlib import Path

from PIL import Image

SRC = Path("/usr/share/icons/Adwaita/cursors")
BUILD = Path("/tmp/sakura-cursor-build")
THEME_NAME = "Sakura-Mochi"
INSTALL = Path.home() / ".local/share/icons" / THEME_NAME

FILL = (0xC4, 0xB5, 0xFD)
FILL_DARK = (0x7C, 0x65, 0xB5)
OUTLINE = (0x2A, 0x1F, 0x3D)
OUTLINE_SOFT = (0x5A, 0x47, 0x86)

XCURSOR_IMAGE = 0xFFFD0002
ANIMATED_SHAPES = {"arrow", "pointer"}
PULSE_FACTORS = (0.86, 1.0, 0.92, 0.86)


def read_xcursor(path: Path):
    data = path.read_bytes()
    if data[:4] != b"Xcur":
        raise ValueError(f"not xcursor: {path}")
    _hs, _ver, ntoc = struct.unpack_from("<III", data, 4)
    frames = []
    for i in range(ntoc):
        typ, subtype, position = struct.unpack_from("<III", data, 16 + i * 12)
        if typ != XCURSOR_IMAGE:
            continue
        hs, _t, size, _v, w, h, xhot, yhot, delay = struct.unpack_from("<IIIIIIIII", data, position)
        pix = data[position + hs : position + hs + w * h * 4]
        img = Image.frombytes("RGBA", (w, h), pix, "raw", "BGRA")
        frames.append({"size": size, "w": w, "h": h, "xhot": xhot, "yhot": yhot, "delay": delay or 50, "img": img})
    return frames


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def recolor(img: Image.Image, pulse_factor: float = 1.0) -> Image.Image:
    px = img.load()
    w, h = img.size
    out = Image.new("RGBA", (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                op[x, y] = (0, 0, 0, 0)
                continue
            lum = (r + g + b) / (3 * 255.0)
            if lum < 0.45:
                rgb = lerp(FILL_DARK, FILL, lum / 0.45)
            else:
                rgb = lerp(OUTLINE_SOFT, OUTLINE, (lum - 0.45) / 0.55)
            rgb = tuple(min(255, int(channel * pulse_factor)) for channel in rgb)
            op[x, y] = (*rgb, a)
    return out


def write_png_frames(name, frames, png_dir: Path):
    png_dir.mkdir(parents=True, exist_ok=True)
    by_size = defaultdict(list)
    for i, fr in enumerate(frames):
        factors = PULSE_FACTORS if name in ANIMATED_SHAPES else (1.0,)
        for phase, factor in enumerate(factors):
            recolored = recolor(fr["img"], factor)
            frame_index = i * len(factors) + phase
            path = png_dir / f"{name}_{fr['size']}_{frame_index:03d}.png"
            recolored.save(path)
            by_size[fr["size"]].append({
                **fr,
                "delay": 140,
                "png": path,
                "img": recolored,
            })
    return by_size


def build_xcursor(name, by_size, out_dir: Path, cfg_dir: Path):
    cfg = cfg_dir / f"{name}.cursor"
    lines = []
    for size in sorted(by_size):
        frames = by_size[size]
        animated = len(frames) > 1
        for fr in frames:
            xhot = min(fr["xhot"], fr["w"] - 1)
            yhot = min(fr["yhot"], fr["h"] - 1)
            if animated:
                lines.append(f"{size} {xhot} {yhot} {fr['png']} {fr['delay']}")
            else:
                lines.append(f"{size} {xhot} {yhot} {fr['png']}")
    cfg.write_text("\n".join(lines) + "\n")
    subprocess.run(["xcursorgen", str(cfg), str(out_dir / name)], check=True)


def build_hypr_shape(name, by_size, hypr_dir: Path):
    shape = hypr_dir / name
    shape.mkdir(parents=True, exist_ok=True)
    sizes = sorted(by_size)
    preferred = 48 if 48 in by_size else sizes[len(sizes) // 2]
    frames = by_size[preferred]
    fr0 = frames[0]
    hx = fr0["xhot"] / max(fr0["w"], 1)
    hy = fr0["yhot"] / max(fr0["h"], 1)
    define_sizes = []
    for fr in frames:
        dest = shape / fr["png"].name
        if not dest.exists():
            shutil.copy2(fr["png"], dest)
        if len(frames) > 1:
            define_sizes.append(f"{preferred},{fr['png'].name},{fr['delay']}")
        else:
            define_sizes.append(f"{preferred},{fr['png'].name}")
    for size in sizes:
        if size == preferred:
            continue
        fr = by_size[size][0]
        dest = shape / fr["png"].name
        if not dest.exists():
            shutil.copy2(fr["png"], dest)
        if len(by_size[size]) == 1:
            define_sizes.append(f"{size},{fr['png'].name}")
    meta = [
        "resize_algorithm = bilinear",
        f"hotspot_x = {hx:.4f}",
        f"hotspot_y = {hy:.4f}",
    ] + [f"define_size = {ds}" for ds in define_sizes]
    (shape / "meta.hl").write_text("\n".join(meta) + "\n")


def main():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    xcur_out = BUILD / "xcursor"
    xcur_out.mkdir(parents=True)
    hypr_work = BUILD / "hypr-work"
    hypr_cursors = hypr_work / "hyprcursors"
    hypr_cursors.mkdir(parents=True)
    png_root = BUILD / "png"
    cfg_dir = BUILD / "cfg"
    cfg_dir.mkdir()

    entries = sorted(SRC.iterdir(), key=lambda p: p.name)
    real_files = [p for p in entries if not p.is_symlink()]
    links = [p for p in entries if p.is_symlink()]

    for src in real_files:
        frames = read_xcursor(src)
        by_size = write_png_frames(src.name, frames, png_root / src.name)
        build_xcursor(src.name, by_size, xcur_out, cfg_dir)
        build_hypr_shape(src.name, by_size, hypr_cursors)
        print(f"built {src.name}")

    for link in links:
        target = link.readlink().name
        dest = xcur_out / link.name
        if (xcur_out / target).exists() and not dest.exists():
            dest.symlink_to(target)
        meta_path = hypr_cursors / target / "meta.hl"
        if meta_path.exists():
            text = meta_path.read_text()
            if "define_override" in text:
                lines = []
                for ln in text.splitlines():
                    if ln.startswith("define_override = "):
                        existing = ln.split("=", 1)[1].strip()
                        names = [n.strip() for n in existing.replace(";", ",").split(",") if n.strip()]
                        if link.name not in names:
                            names.append(link.name)
                        lines.append("define_override = " + ";".join(names))
                    else:
                        lines.append(ln)
                meta_path.write_text("\n".join(lines) + "\n")
            else:
                meta_path.write_text(text.rstrip() + f"\ndefine_override = {link.name}\n")

    index = f"""[Icon Theme]
Name={THEME_NAME}
Comment=Sakura Mochi pink cursor theme for Omarchy
Inherits=Adwaita

[Cursor Theme]
Name={THEME_NAME}
"""
    if INSTALL.exists():
        shutil.rmtree(INSTALL)
    INSTALL.mkdir(parents=True)
    (INSTALL / "index.theme").write_text(index)
    shutil.copytree(xcur_out, INSTALL / "cursors")

    (hypr_work / "manifest.hl").write_text(
        f"name = {THEME_NAME}\ndescription = Sakura Mochi accent-pink cursors\nversion = 1.0\ncursors_directory = hyprcursors\n"
    )
    out = BUILD / "hypr-out"
    out.mkdir()
    subprocess.run(["hyprcursor-util", "--create", str(hypr_work), "-o", str(out)], check=True)
    created = next(out.glob("theme_*"))
    shutil.copy2(created / "manifest.hl", INSTALL / "manifest.hl")
    if (INSTALL / "hyprcursors").exists():
        shutil.rmtree(INSTALL / "hyprcursors")
    shutil.copytree(created / "hyprcursors", INSTALL / "hyprcursors")
    print(f"Installed {INSTALL}")


if __name__ == "__main__":
    main()
