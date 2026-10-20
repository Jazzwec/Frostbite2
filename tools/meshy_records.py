"""Writes assets/models/meshy/<name>.meshy.json for every model in assets/models/meshy/ledger.json
that has its raw download (<name>_meshy6.glb or _t2.5.glb) and no record yet.

    python tools/meshy_records.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MESHY = ROOT / "assets" / "models" / "meshy"
PARAMS = {"remove_lighting": True, "image_enhancement": False, "should_remesh": True, "topology": "triangle",
          "should_texture": True, "enable_pbr": False, "texture_resolution": "2k", "auto_size": True,
          "origin_at": "bottom", "target_formats": ["glb"]}


def main():
    ledger = json.loads((MESHY / "ledger.json").read_text(encoding="utf-8"))
    spent = 0
    for name, entry in ledger.items():
        if name.startswith("_"):
            continue
        task, model, credits, poly = entry[:4]
        spent += credits
        record = MESHY / f"{name}.meshy.json"
        tag = "meshy6" if model == "meshy-6" else model.replace("meshy-", "")
        download = MESHY / f"{name}_{tag}.glb"
        if record.exists() or not download.exists():
            continue
        params = dict(PARAMS, target_polycount=poly)
        if model.startswith("meshy-t"):
            params = dict(params, model_type="smart-topology")
            params.pop("remove_lighting")
        ref = f"source_art/concept/ink/{name}.png"
        record.write_text(json.dumps({
            "task_id": task, "date": "2026-10-20", "ai_model": model, "endpoint": "image-to-3d", "credits": credits,
            "params": params, "reference": ref, "reference_model": "gpt-6-astra (tools/chatgpt/chatgpt.py image --for-3d)",
            "download": str(download.relative_to(ROOT)).replace("\\", "/"),
        }, indent=2) + "\n", encoding="utf-8")
        print("wrote", record.name)
    print("credits in the ledger:", spent)


if __name__ == "__main__":
    main()
