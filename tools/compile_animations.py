#!/usr/bin/env python3
"""
Compilador de `animations-pack.json` a `src/roblox/shared/AnimationClips.luau`.
Convierte los keyframes descargados desde GitHub Release (o generados localmente)
en un ModuleScript Luau tipado (--!strict) listo para compilar con Rojo.

Uso:
    python3 tools/compile_animations.py \
        --input build/animations/animations-pack.json \
        --output src/roblox/shared/AnimationClips.luau
"""

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


def fmt_num(n: float) -> str:
    if abs(n) < 1e-6:
        return "0"
    return f"{n:.4f}".rstrip("0").rstrip(".")


def format_cframe_expr(bone_data: Dict[str, List[float]]) -> str:
    rot = bone_data.get("rot", [0, 0, 0])
    pos = bone_data.get("pos")

    rx, ry, rz = fmt_num(float(rot[0])), fmt_num(float(rot[1])), fmt_num(float(rot[2]))
    rot_expr = f"CFrame.Angles(math.rad({rx}), math.rad({ry}), math.rad({rz}))"

    if pos and (abs(pos[0]) > 1e-6 or abs(pos[1]) > 1e-6 or abs(pos[2]) > 1e-6):
        px, py, pz = fmt_num(float(pos[0])), fmt_num(float(pos[1])), fmt_num(float(pos[2]))
        return f"CFrame.new({px}, {py}, {pz}) * {rot_expr}"
    return rot_expr


def emit_rig_keyframes(keyframes: List[Dict[str, Any]], indent: str) -> List[str]:
    lines: List[str] = ["{"]
    for kf in keyframes:
        lines.append(f"{indent}\t{{")
        lines.append(f"{indent}\t\tTime = {fmt_num(float(kf['time']))},")
        lines.append(f"{indent}\t\tEasing = \"{kf['easing']}\",")
        lines.append(f"{indent}\t\tBones = {{")
        for bone_name, bone_data in kf.get("bones", {}).items():
            key_repr = f"[\"{bone_name}\"]" if (" " in bone_name or "-" in bone_name) else bone_name
            lines.append(f"{indent}\t\t\t{key_repr} = {format_cframe_expr(bone_data)},")
        lines.append(f"{indent}\t\t}},")
        lines.append(f"{indent}\t}},")
    lines.append(f"{indent}}}")
    return lines


def compile_to_luau(pack: Dict[str, Any]) -> str:
    out: List[str] = [
        "--!strict",
        "--[=[",
        "\tLibrería compilada de animaciones por fotogramas clave (ModuleScript compartido).",
        "\tArchivo generado automáticamente por `tools/compile_animations.py` a partir",
        "\tdel paquete de animaciones (`animations-pack.json`) publicado en GitHub Releases.",
        "\tContiene los clips R15 y R6 para Slide, Dive, Crouch, Jump, Sprint, Aim, ReloadG18 y FireKick.",
        "]=]",
        "",
        "export type KeyframeEntry = {",
        "\tTime: number,",
        "\tEasing: string,",
        "\tBones: { [string]: CFrame },",
        "}",
        "",
        "export type AnimationClip = {",
        "\tDuration: number,",
        "\tLoop: boolean,",
        "\tPriority: string,",
        "\tFadeIn: number,",
        "\tFadeOut: number,",
        "\tR15: { KeyframeEntry },",
        "\tR6: { KeyframeEntry },",
        "}",
        "",
        f"local AnimationClips: {{ [string]: AnimationClip }} = {{",
    ]

    for clip_name, clip in pack.get("clips", {}).items():
        out.append(f"\t{clip_name} = {{")
        out.append(f"\t\tDuration = {fmt_num(float(clip['duration']))},")
        out.append(f"\t\tLoop = {'true' if clip.get('loop', False) else 'false'},")
        out.append(f"\t\tPriority = \"{clip.get('priority', 'Movement')}\",")
        out.append(f"\t\tFadeIn = {fmt_num(float(clip.get('fadeIn', 0.08)))},")
        out.append(f"\t\tFadeOut = {fmt_num(float(clip.get('fadeOut', 0.12)))},")

        r15_lines = emit_rig_keyframes(clip.get("r15", []), "\t\t")
        out.append(f"\t\tR15 = {r15_lines[0]}")
        out.extend(r15_lines[1:-1])
        out.append(f"\t\t{r15_lines[-1]},")

        r6_lines = emit_rig_keyframes(clip.get("r6", []), "\t\t")
        out.append(f"\t\tR6 = {r6_lines[0]}")
        out.extend(r6_lines[1:-1])
        out.append(f"\t\t{r6_lines[-1]},")

        out.append("\t},")

    out.extend([
        "}",
        "",
        "return AnimationClips",
        "",
    ])
    return "\n".join(out)


def main() -> None:
    parser = argparse.ArgumentParser(description="Compila animations-pack.json a AnimationClips.luau.")
    parser.add_argument(
        "--input",
        default="build/animations/animations-pack.json",
        help="Ruta de entrada del JSON de animaciones.",
    )
    parser.add_argument(
        "--output",
        default="src/roblox/shared/AnimationClips.luau",
        help="Ruta de salida del ModuleScript Luau.",
    )
    args = parser.parse_args()

    in_path = Path(args.input)
    with in_path.open("r", encoding="utf-8") as f:
        pack = json.load(f)

    luau_code = compile_to_luau(pack)
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        f.write(luau_code)

    print(f"[Animations] Compilado {len(pack.get('clips', {}))} clips en {out_path}")


if __name__ == "__main__":
    main()
