"""
Script opcional para Blender (bpy): exporta acciones de un Rig R15 en Blender
al formato exacto `animations-pack.json` usado por el pipeline de GitHub Releases.

Uso en Blender headless:
    blender mi_rig_r15.blend --background --python tools/blender_export_r15.py -- build/animations/animations-pack.json
"""

import json
import math
import sys
from pathlib import Path

try:
    import bpy  # type: ignore
except ImportError:
    bpy = None


def export_blender_actions(output_path: str) -> None:
    if bpy is None:
        raise RuntimeError("Este script debe ejecutarse dentro de Blender (`blender --background --python ...`).")

    armature = next((obj for obj in bpy.data.objects if obj.type == "ARMATURE"), None)
    if armature is None:
        raise RuntimeError("No se encontró un Armature en la escena de Blender.")

    scene = bpy.context.scene
    fps = scene.render.fps or 30
    clips = {}

    for action in bpy.data.actions:
        armature.animation_data_create()
        armature.animation_data.action = action
        frame_start = int(action.frame_range[0])
        frame_end = int(action.frame_range[1])
        duration = max(0.05, (frame_end - frame_start) / fps)

        keyframe_points = sorted({int(kp.co.x) for fc in action.fcurves for kp in fc.keyframe_points})
        if not keyframe_points:
            keyframe_points = [frame_start, frame_end]

        r15_frames = []
        for frame in keyframe_points:
            scene.frame_set(frame)
            bones_dict = {}
            for pbone in armature.pose.bones:
                euler = pbone.rotation_euler
                loc = pbone.location
                bones_dict[pbone.name] = {
                    "rot": [
                        round(math.degrees(euler.x), 3),
                        round(math.degrees(euler.y), 3),
                        round(math.degrees(euler.z), 3),
                    ],
                    "pos": [round(loc.x, 4), round(loc.y, 4), round(loc.z, 4)],
                }
            r15_frames.append({
                "time": round((frame - frame_start) / fps, 4),
                "easing": "Linear",
                "bones": bones_dict,
            })

        clips[action.name] = {
            "duration": round(duration, 4),
            "loop": action.name in {"Crouch", "Sprint", "Aim", "EquipG18"},
            "priority": "Action",
            "fadeIn": 0.08,
            "fadeOut": 0.12,
            "r15": r15_frames,
            "r6": [],
        }

    out = Path(output_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8") as f:
        json.dump({"schemaVersion": 1, "packName": "BlenderExport_R15", "clips": clips}, f, indent=2)


if __name__ == "__main__":
    argv = sys.argv
    out_arg = "build/animations/animations-pack.json"
    if "--" in argv:
        idx = argv.index("--")
        if idx + 1 < len(argv):
            out_arg = argv[idx + 1]
    export_blender_actions(out_arg)
