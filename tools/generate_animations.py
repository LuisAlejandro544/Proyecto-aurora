#!/usr/bin/env python3
"""
Generador de animaciones por fotogramas clave (Keyframes) para Ruinas 1v1.
Crea el paquete `build/animations/animations-pack.json` con secuencias cuadro por cuadro,
curvas de suavizado (Easing) y soporte para avatares R15 y R6.

Uso:
    python3 tools/generate_animations.py --output build/animations/animations-pack.json
"""

import argparse
import json
import os
from pathlib import Path
from typing import Any, Dict, List


def kf(
    time: float,
    easing: str,
    bones: Dict[str, Dict[str, List[float]]],
) -> Dict[str, Any]:
    return {
        "time": round(time, 4),
        "easing": easing,
        "bones": bones,
    }


def pose(rot_deg: List[float], pos: List[float] | None = None) -> Dict[str, List[float]]:
    entry: Dict[str, List[float]] = {"rot": rot_deg}
    if pos is not None:
        entry["pos"] = pos
    return entry


def build_animations_pack() -> Dict[str, Any]:
    clips: Dict[str, Any] = {
        "Slide": {
            "duration": 0.62,
            "loop": False,
            "priority": "Action",
            "fadeIn": 0.08,
            "fadeOut": 0.14,
            "r15": [
                kf(0.00, "QuadOut", {
                    "Root": pose([12, -4, 0], [0, -0.35, 0]),
                    "Waist": pose([-6, 4, 0]),
                    "RightHip": pose([25, 0, -2]),
                    "RightKnee": pose([-20, 0, 0]),
                    "LeftHip": pose([15, 0, 4]),
                    "LeftKnee": pose([-45, 0, 0]),
                }),
                kf(0.11, "CubicOut", {
                    "Root": pose([42, -16, 0], [0, -1.25, 0]),
                    "Waist": pose([-14, 16, 0]),
                    "RightHip": pose([68, 0, -6]),
                    "RightKnee": pose([-10, 0, 0]),
                    "LeftHip": pose([26, 0, 8]),
                    "LeftKnee": pose([-96, 0, 0]),
                    "LeftShoulder": pose([-34, 0, -18]),
                    "LeftElbow": pose([28, 0, 0]),
                }),
                kf(0.42, "Linear", {
                    "Root": pose([40, -14, 0], [0, -1.22, 0]),
                    "Waist": pose([-12, 14, 0]),
                    "RightHip": pose([65, 0, -6]),
                    "RightKnee": pose([-12, 0, 0]),
                    "LeftHip": pose([24, 0, 8]),
                    "LeftKnee": pose([-94, 0, 0]),
                    "LeftShoulder": pose([-30, 0, -16]),
                    "LeftElbow": pose([24, 0, 0]),
                }),
                kf(0.62, "QuadInOut", {
                    "Root": pose([-8, 0, 0], [0, -1.02, 0]),
                    "Waist": pose([10, 0, 0]),
                    "RightHip": pose([58, 0, 4]),
                    "RightKnee": pose([-84, 0, 0]),
                    "LeftHip": pose([54, 0, -4]),
                    "LeftKnee": pose([-80, 0, 0]),
                }),
            ],
            "r6": [
                kf(0.00, "QuadOut", {
                    "RootJoint": pose([16, 0, 0], [0, -0.4, 0]),
                    "Right Hip": pose([0, 0, 28]),
                    "Left Hip": pose([0, 0, -22]),
                }),
                kf(0.14, "CubicOut", {
                    "RootJoint": pose([42, 0, 0], [0, -1.3, 0]),
                    "Right Hip": pose([0, 0, 64]),
                    "Left Hip": pose([0, 0, -48]),
                }),
                kf(0.62, "QuadInOut", {
                    "RootJoint": pose([0, 0, 0], [0, -1.0, 0]),
                    "Right Hip": pose([0, 0, 46]),
                    "Left Hip": pose([0, 0, -46]),
                }),
            ],
        },
        "Dive": {
            "duration": 0.75,
            "loop": False,
            "priority": "Action2",
            "fadeIn": 0.06,
            "fadeOut": 0.16,
            "r15": [
                kf(0.00, "QuadOut", {
                    "Root": pose([-28, 0, 0], [0, -0.25, 0]),
                    "Waist": pose([18, 0, 0]),
                    "RightShoulder": pose([65, 0, 8]),
                    "LeftShoulder": pose([65, 0, -8]),
                    "RightHip": pose([35, 0, 4]),
                    "LeftHip": pose([35, 0, -4]),
                    "RightKnee": pose([-55, 0, 0]),
                    "LeftKnee": pose([-55, 0, 0]),
                }),
                kf(0.16, "CubicOut", {
                    "Root": pose([-78, 0, 0], [0, -1.42, 0]),
                    "Waist": pose([14, 0, 0]),
                    "Neck": pose([48, 0, 0]),
                    "RightShoulder": pose([108, 0, 10]),
                    "LeftShoulder": pose([108, 0, -10]),
                    "RightElbow": pose([18, 0, 0]),
                    "LeftElbow": pose([18, 0, 0]),
                    "RightHip": pose([-16, 0, 6]),
                    "LeftHip": pose([-16, 0, -6]),
                    "RightKnee": pose([-16, 0, 0]),
                    "LeftKnee": pose([-16, 0, 0]),
                }),
                kf(0.50, "Linear", {
                    "Root": pose([-82, 0, 0], [0, -1.52, 0]),
                    "Waist": pose([10, 0, 0]),
                    "Neck": pose([44, 0, 0]),
                    "RightShoulder": pose([96, 0, 14]),
                    "LeftShoulder": pose([96, 0, -14]),
                    "RightElbow": pose([36, 0, 0]),
                    "LeftElbow": pose([36, 0, 0]),
                    "RightHip": pose([-10, 0, 6]),
                    "LeftHip": pose([-10, 0, -6]),
                    "RightKnee": pose([-24, 0, 0]),
                    "LeftKnee": pose([-24, 0, 0]),
                }),
                kf(0.75, "QuadOut", {
                    "Root": pose([-72, 0, 0], [0, -1.55, 0]),
                    "Waist": pose([16, 0, 0]),
                    "Neck": pose([36, 0, 0]),
                    "RightShoulder": pose([74, 0, 16]),
                    "LeftShoulder": pose([74, 0, -16]),
                    "RightElbow": pose([52, 0, 0]),
                    "LeftElbow": pose([52, 0, 0]),
                    "RightHip": pose([8, 0, 5]),
                    "LeftHip": pose([8, 0, -5]),
                }),
            ],
            "r6": [
                kf(0.00, "QuadOut", {
                    "RootJoint": pose([-30, 0, 0], [0, -0.3, 0]),
                    "Right Shoulder": pose([0, 0, 60]),
                    "Left Shoulder": pose([0, 0, -60]),
                }),
                kf(0.18, "CubicOut", {
                    "RootJoint": pose([-76, 0, 0], [0, -1.5, 0]),
                    "Right Shoulder": pose([0, 0, 98]),
                    "Left Shoulder": pose([0, 0, -98]),
                }),
                kf(0.75, "Linear", {
                    "RootJoint": pose([-74, 0, 0], [0, -1.55, 0]),
                    "Right Shoulder": pose([0, 0, 86]),
                    "Left Shoulder": pose([0, 0, -86]),
                }),
            ],
        },
        "Crouch": {
            "duration": 0.20,
            "loop": True,
            "priority": "Movement",
            "fadeIn": 0.10,
            "fadeOut": 0.12,
            "r15": [
                kf(0.00, "QuadInOut", {
                    "Root": pose([-10, 0, 0], [0, -1.05, 0]),
                    "Waist": pose([12, 0, 0]),
                    "RightHip": pose([62, 0, 5]),
                    "LeftHip": pose([56, 0, -5]),
                    "RightKnee": pose([-88, 0, 0]),
                    "LeftKnee": pose([-82, 0, 0]),
                }),
            ],
            "r6": [
                kf(0.00, "QuadInOut", {
                    "RootJoint": pose([0, 0, 0], [0, -1.0, 0]),
                    "Right Hip": pose([0, 0, 48]),
                    "Left Hip": pose([0, 0, -48]),
                }),
            ],
        },
        "Jump": {
            "duration": 0.42,
            "loop": False,
            "priority": "Movement",
            "fadeIn": 0.06,
            "fadeOut": 0.12,
            "r15": [
                kf(0.00, "QuadOut", {
                    "Waist": pose([-10, 0, 0]),
                    "RightHip": pose([32, 0, 0]),
                    "LeftHip": pose([18, 0, 0]),
                    "RightKnee": pose([-54, 0, 0]),
                    "LeftKnee": pose([-28, 0, 0]),
                }),
                kf(0.24, "QuadInOut", {
                    "Waist": pose([-6, 0, 0]),
                    "RightHip": pose([22, 0, 0]),
                    "LeftHip": pose([14, 0, 0]),
                    "RightKnee": pose([-36, 0, 0]),
                    "LeftKnee": pose([-22, 0, 0]),
                }),
                kf(0.42, "Linear", {
                    "Waist": pose([-4, 0, 0]),
                    "RightHip": pose([16, 0, 0]),
                    "LeftHip": pose([10, 0, 0]),
                    "RightKnee": pose([-26, 0, 0]),
                    "LeftKnee": pose([-18, 0, 0]),
                }),
            ],
            "r6": [
                kf(0.00, "QuadOut", {
                    "Right Hip": pose([0, 0, 24]),
                    "Left Hip": pose([0, 0, -18]),
                }),
                kf(0.42, "Linear", {
                    "Right Hip": pose([0, 0, 14]),
                    "Left Hip": pose([0, 0, -12]),
                }),
            ],
        },
        "Sprint": {
            "duration": 0.40,
            "loop": True,
            "priority": "Movement",
            "fadeIn": 0.12,
            "fadeOut": 0.12,
            "r15": [
                kf(0.00, "QuadInOut", {
                    "Waist": pose([-14, 3, 0]),
                    "RightShoulder": pose([36, 16, -12]),
                    "RightElbow": pose([34, 0, 0]),
                }),
                kf(0.20, "QuadInOut", {
                    "Waist": pose([-15, -3, 0]),
                    "RightShoulder": pose([42, 20, -10]),
                    "RightElbow": pose([38, 0, 0]),
                }),
                kf(0.40, "QuadInOut", {
                    "Waist": pose([-14, 3, 0]),
                    "RightShoulder": pose([36, 16, -12]),
                    "RightElbow": pose([34, 0, 0]),
                }),
            ],
            "r6": [
                kf(0.00, "Linear", {
                    "Right Shoulder": pose([0, 0, 46]),
                }),
            ],
        },
        "EquipG18": {
            "duration": 0.25,
            "loop": True,
            "priority": "UpperBody",
            "fadeIn": 0.08,
            "fadeOut": 0.10,
            "r15": [
                kf(0.00, "Linear", {
                    "RightShoulder": pose([64, 8, -6]),
                    "RightElbow": pose([18, 0, 0]),
                }),
            ],
            "r6": [
                kf(0.00, "Linear", {
                    "Right Shoulder": pose([0, 0, 68]),
                }),
            ],
        },
        "Aim": {
            "duration": 0.20,
            "loop": True,
            "priority": "UpperBodyHigh",
            "fadeIn": 0.08,
            "fadeOut": 0.10,
            "r15": [
                kf(0.00, "CubicOut", {
                    "Neck": pose([-4, -6, 0]),
                    "RightShoulder": pose([84, 8, -4]),
                    "RightElbow": pose([12, 0, 0]),
                    "LeftShoulder": pose([74, -26, 16]),
                    "LeftElbow": pose([34, 0, 0]),
                }),
            ],
            "r6": [
                kf(0.00, "CubicOut", {
                    "Right Shoulder": pose([0, 0, 86]),
                    "Left Shoulder": pose([0, 18, -72]),
                }),
            ],
        },
        "ReloadG18": {
            "duration": 1.45,
            "loop": False,
            "priority": "UpperAction",
            "fadeIn": 0.08,
            "fadeOut": 0.12,
            "r15": [
                kf(0.00, "QuadOut", {
                    "RightShoulder": pose([78, 8, -6]),
                    "RightElbow": pose([22, 0, 0]),
                    "LeftShoulder": pose([64, -18, 12]),
                    "LeftElbow": pose([32, 0, 0]),
                }),
                # Inclinar pistola y bajar mano izquierda al cargador
                kf(0.22, "CubicOut", {
                    "Neck": pose([-10, -8, 4]),
                    "RightShoulder": pose([68, -18, 14]),
                    "RightElbow": pose([42, 0, 0]),
                    "RightWrist": pose([0, 0, 18]),
                    "LeftShoulder": pose([24, 10, -14]),
                    "LeftElbow": pose([48, 0, 0]),
                }),
                # Extraer cargador vacío
                kf(0.48, "QuadInOut", {
                    "Neck": pose([-12, -6, 4]),
                    "RightShoulder": pose([72, -16, 12]),
                    "RightElbow": pose([46, 0, 0]),
                    "RightWrist": pose([-8, 0, 16]),
                    "LeftShoulder": pose([8, 16, -22]),
                    "LeftElbow": pose([28, 0, 0]),
                }),
                # Insertar cargador extendido nuevo
                kf(0.84, "BackOut", {
                    "Neck": pose([-8, -8, 2]),
                    "RightShoulder": pose([66, -14, 10]),
                    "RightElbow": pose([44, 0, 0]),
                    "RightWrist": pose([4, 0, 14]),
                    "LeftShoulder": pose([58, -16, 14]),
                    "LeftElbow": pose([52, 0, 0]),
                }),
                # Tirar de la corredera hacia atrás
                kf(1.12, "CubicOut", {
                    "Neck": pose([-6, -4, 0]),
                    "RightShoulder": pose([74, -8, 4]),
                    "RightElbow": pose([32, 0, 0]),
                    "RightWrist": pose([8, 0, 6]),
                    "LeftShoulder": pose([72, -24, 18]),
                    "LeftElbow": pose([68, 0, 0]),
                }),
                # Volver a postura lista
                kf(1.45, "QuadInOut", {
                    "Neck": pose([0, 0, 0]),
                    "RightShoulder": pose([82, 8, -6]),
                    "RightElbow": pose([14, 0, 0]),
                    "RightWrist": pose([0, 0, 0]),
                    "LeftShoulder": pose([70, -22, 14]),
                    "LeftElbow": pose([30, 0, 0]),
                }),
            ],
            "r6": [
                kf(0.00, "QuadOut", {
                    "Right Shoulder": pose([0, 0, 78]),
                    "Left Shoulder": pose([0, 0, -56]),
                }),
                kf(0.35, "CubicOut", {
                    "Right Shoulder": pose([-15, 0, 64]),
                    "Left Shoulder": pose([0, 0, -18]),
                }),
                kf(0.85, "BackOut", {
                    "Right Shoulder": pose([-10, 0, 68]),
                    "Left Shoulder": pose([0, 14, -64]),
                }),
                kf(1.45, "QuadInOut", {
                    "Right Shoulder": pose([0, 0, 82]),
                    "Left Shoulder": pose([0, 14, -70]),
                }),
            ],
        },
        "FireKick": {
            "duration": 0.09,
            "loop": False,
            "priority": "Recoil",
            "fadeIn": 0.01,
            "fadeOut": 0.05,
            "r15": [
                kf(0.00, "CubicOut", {
                    "RightShoulder": pose([92, 8, -4]),
                    "RightWrist": pose([14, 0, 0]),
                }),
                kf(0.09, "QuadOut", {
                    "RightShoulder": pose([82, 8, -6]),
                    "RightWrist": pose([0, 0, 0]),
                }),
            ],
            "r6": [
                kf(0.00, "CubicOut", {
                    "Right Shoulder": pose([0, 0, 94]),
                }),
                kf(0.09, "QuadOut", {
                    "Right Shoulder": pose([0, 0, 82]),
                }),
            ],
        },
    }

    return {
        "schemaVersion": 1,
        "packName": "Ruinas1v1_Animations",
        "clips": clips,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Genera animations-pack.json por keyframes.")
    parser.add_argument(
        "--output",
        default="build/animations/animations-pack.json",
        help="Ruta de salida del archivo JSON de animaciones.",
    )
    args = parser.parse_args()

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    pack = build_animations_pack()
    with out_path.open("w", encoding="utf-8") as f:
        json.dump(pack, f, indent=2, ensure_ascii=False)

    print(f"[Animations] Paquete generado con {len(pack['clips'])} clips en {out_path}")


if __name__ == "__main__":
    main()
