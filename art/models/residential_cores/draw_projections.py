"""Draw dimensioned orthographic reference sheets from plans.json."""

import json
from html import escape
from pathlib import Path


HERE = Path(__file__).resolve().parent
COLORS = {
    "silicate": "#c4ba9f", "cream": "#d6c7a4", "ochre": "#bd9458",
    "blue": "#647f8a", "green": "#667565", "ivory": "#d2cbb5",
    "concrete": "#a59f8e",
}
VIEWS = ["PLAN", "FRONT", "RIGHT", "REAR", "LEFT"]


def rect(x, y, w, h, fill, stroke="#3d403c"):
    return f'<rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" fill="{fill}" stroke="{stroke}"/>'


def label(x, y, text, size=15):
    return f'<text x="{x}" y="{y}" font-size="{size}">{escape(text)}</text>'


def pitch_view(pitch, scale, view):
    length, width = pitch["field"]
    goal_width, depth, height = pitch["goal"]
    margin = pitch["runoff"]
    s = scale
    if view == "PLAN":
        x, y = 10 + margin * s, 10 + margin * s
        gate = pitch["gate_width"] * s
        fence_y = 10 + (width + 2 * margin) * s
        return [rect(10, 10, (length + 2 * margin) * s, (width + 2 * margin) * s, "#999875"),
                rect(x, y, length * s, width * s, "none", "#eee9cf"),
                rect(x + length * s / 2, y, .4, width * s, "#eee9cf", "none"),
                f'<circle cx="{x + length * s / 2}" cy="{y + width * s / 2}" r="{2.4 * s}" fill="none" stroke="#eee9cf"/>',
                rect(x - depth * s, y + (width - goal_width) * s / 2, depth * s, goal_width * s, "none"),
                rect(x + length * s, y + (width - goal_width) * s / 2, depth * s, goal_width * s, "none"),
                rect(x + (length * s - gate) / 2, fence_y - 1, gate, 2, "#f1ecdf", "none")]
    long_side = view in ("FRONT", "REAR")
    span = length if long_side else width
    floor = 35
    fence = pitch["fence_height"] * s
    goals = [(10 + (margin - depth) * s, depth), (10 + (length + margin) * s, depth)] if long_side else [
        (10 + (width + 2 * margin - goal_width) * s / 2, goal_width)]
    result = [rect(10, floor - fence, (span + 2 * margin) * s, fence, "#bcbba5")]
    if view == "FRONT":
        gate = pitch["gate_width"]
        result.append(rect(10 + (span + 2 * margin - gate) * s / 2, floor - fence, gate * s, fence, "#f1ecdf", "none"))
    result.extend(rect(x, floor - height * s, w * s, height * s, "none") for x, w in goals)
    return result


def building_view(plan, s, view):
    volumes = plan["volumes"]
    points = [volume["bounds"] for volume in volumes]
    left = min(x for x, *_ in points)
    front = min(y for _, y, *_ in points)
    right = max(x + w for x, _, _, w, _, _ in points)
    rear = max(y + d for _, y, _, _, d, _ in points)
    top = max(z + h for _, _, z, _, _, h in points)
    if view == "PLAN":
        return [rect(10 + (x - left) * s, 10 + (rear - y - d) * s, w * s, d * s, "#6d706c")
                for x, y, _, w, d, _ in points] + [
            rect(10 + (e["at"] - e["width"] / 2 - .45 - left) * s,
                 10 + (rear - e["line"]) * s, (e["width"] + .9) * s, e["canopy"] * s,
                 COLORS[e["material"]]) for e in plan["entries"] if e["canopy"]]
    side = view in ("LEFT", "RIGHT")
    reverse = view in ("REAR", "LEFT")
    near_sign = -1 if view in ("FRONT", "LEFT") else 1
    axis_min, axis_max = (front, rear) if side else (left, right)

    def screen(at):
        return 10 + (axis_max - at if reverse else at - axis_min) * s

    shapes = []
    layers = []
    for volume in volumes:
        x, y, z, w, d, h = volume["bounds"]
        at, length = (y, d) if side else (x, w)
        edge = (x if near_sign < 0 else x + w) if side else (y if near_sign < 0 else y + d)
        fill = COLORS[plan.get("shell_material", volume["material"])]
        layers.append((near_sign * edge, 0, rect(min(screen(at), screen(at + length)),
                      10 + (top - z - h) * s, length * s, h * s, fill)))
    for group in plan["facades"]:
        if group["face"].upper() != view:
            continue
        w, h = group["size"]
        for at in group["at"]:
            for z in group["levels"]:
                layers.append((near_sign * group["line"], 1, rect(screen(at) - w * s / 2,
                              10 + (top - z - h / 2) * s, w * s, h * s, "#71858b")))
    for entry in plan["entries"]:
        if entry.get("face", "front").upper() != view:
            continue
        w, h = entry["width"], entry["height"]
        x, y = screen(entry["at"]), 10 + (top - h) * s
        layers.append((near_sign * entry["line"], 1, rect(x - w * s / 2, y, w * s, h * s, COLORS[entry["material"]])))
        if entry["canopy"]:
            layers.append((near_sign * entry["line"], 2, rect(x - (w + .9) * s / 2, y - .45 * s,
                          (w + .9) * s, .18 * s, COLORS[entry["material"]])))
    shapes.extend(shape for _, _, shape in sorted(layers))
    return shapes


def write_sheet(name, plan, destination):
    if "pitch" in plan:
        length, width = plan["pitch"]["field"]
        dimensions = f"{length} × {width} m playing area · 3 m goals"
        draw = lambda s, view: pitch_view(plan["pitch"], s, view)
    else:
        bounds = [v["bounds"] for v in plan["volumes"]]
        length = max(x + w for x, _, _, w, _, _ in bounds) - min(x for x, *_ in bounds)
        width = max(y + d for _, y, _, _, d, _ in bounds) - min(y for _, y, *_ in bounds)
        height = max(z + h for _, _, z, _, _, h in bounds)
        dimensions = f"{length:g} × {width:g} m footprint · {height:g} m main roof height"
        if name == "school":
            dimensions += " · 48 × 15 m classrooms · 12 × 24 m gym"
        draw = lambda s, view: building_view(plan, s, view)
    scale = min(8, 275 / max(length + 2, width + 3))
    body = [label(36, 44, plan["label"], 28), label(36, 72, dimensions),
            label(36, 96, "Design dimensions · all views at the same scale · front faces the approach", 13)]
    for index, view in enumerate(VIEWS):
        x, y = 36 + index % 3 * 328, 145 + index // 3 * 298
        body.append(f'<g transform="translate({x} {y})">{label(10, 0, view)}{"".join(draw(scale, view))}</g>')
    body.append(label(36, 714, "Ground levels in metres. Roof and entrance details may extend past the wall envelope.", 13))
    document = ('<svg xmlns="http://www.w3.org/2000/svg" width="1030" height="738" viewBox="0 0 1030 738">'
                '<rect width="1030" height="738" fill="#f1ecdf"/>'
                '<g font-family="sans-serif" fill="#343632">' + "".join(body) + '</g></svg>\n')
    (destination / f"{name}.svg").write_text(document, encoding="utf-8")


def main():
    plans = json.loads((HERE / "plans.json").read_text(encoding="utf-8"))
    destination = HERE / "projections"
    destination.mkdir(exist_ok=True)
    for name, plan in plans.items():
        if "same_as" in plan:
            plan = {**plans[plan["same_as"]], **plan}
        write_sheet(name, plan, destination)


if __name__ == "__main__":
    main()
