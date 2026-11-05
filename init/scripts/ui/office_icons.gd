# Small, single-ink pictograms. SVG source stays editable and independent of fonts.
extends RefCounted

const QUEST_TYPES := {"plea": "request", "conflict": "balance", "crisis": "alarm", "offer": "handshake"}
const PATHS := {
	"request": '<path d="M3 13v15h26V13M3 13l13 10 13-10M3 13l6-5m14 0 6 5M9 17V3h14v14M12 7h8m-8 4h6"/>',
	"balance": '<path d="M16 3v25M8 29h16M4 9h24M7 9 2 21h10ZM25 9l-5 12h10ZM13 5l3-3 3 3"/>',
	"alarm": '<path d="M5 24h22v5H5ZM8 24V15a8 8 0 0 1 16 0v9M16 1v3M3 7l3 3m23-3-3 3M1 17h3m24 0h3"/>',
	"handshake": '<path d="m2 12 5-7 6 4m6 0 6-4 5 7-5 7M7 18l7 8c1 1 2 1 3 0l9-10M10 10l4-2 7 2 3 5M20 10l-6 5c-2 2-5 0-3-2l3-3M10 20l3-3m0 6 3-3m0 6 3-3M2 12l5 6 4-7m19 1-5 7-4-8"/>',
	"residents": '<g fill="white" stroke="none"><circle cx="7" cy="8" r="3.5"/><circle cx="25" cy="8" r="3.5"/><circle cx="16" cy="10" r="4.5"/><path d="M1 25V18c0-6 10-6 12-1v8ZM19 25V18c2-5 12-5 12 1v6ZM8 29v-9c0-7 16-7 16 0v9Z"/></g>',
	"wallet": '<path d="M4 12V7l21-4v8M3 11h26v18H3ZM22 17h7v7h-7Z"/><path d="m9 9 1-5 10 2-1 5M25 20h1"/>',
	"residents_outline": '<circle cx="8" cy="8" r="3"/><circle cx="24" cy="8" r="3"/><circle cx="16" cy="11" r="4"/><path d="M2 24v-5c0-4 3-6 6-6m24 11v-5c0-4-3-6-8-6M9 28v-6c0-5 3-7 7-7s7 2 7 7v6Z"/>',
	"business": '<rect x="3" y="10" width="26" height="18" rx="2"/><path d="M11 10V5h10v5M3 17l13 4 13-4M16 18v5"/>',
	"police": '<path d="m3 12 13-7 13 7-4 7H7ZM7 19h18v4c-5 5-13 5-18 0ZM7 16h18"/>',
	"church": '<path d="M4 29V16l7-4V9c0-3 2-5 5-5s5 2 5 5v3l7 4v13M11 29V17h10v12M16 1v6M13 3h6M15 29v-7h2v7"/>',
	"boss": '<path d="M11 15V7c0-5 10-5 10 0v8M3 17h26v4H3ZM6 21v8m20-8v8M13 21v8h6v-8"/>',
	"locate": '<circle cx="16" cy="16" r="9"/><path d="M16 2v8m0 12v8M2 16h8m12 0h8"/>',
	"map": '<path d="m3 7 8-3 10 3 8-3v23l-8 3-10-3-8 3ZM11 4v23M21 7v23"/>',
	"folder": '<path d="M3 27V6h10l4 5h12v16Z"/>',
	"newspaper": '<rect x="3" y="5" width="26" height="23" rx="1"/><path d="M7 10h18M7 15h7v8H7ZM18 15h7m-7 4h7m-7 4h7"/>',
	"clock": '<circle cx="16" cy="16" r="12"/><path d="M16 8v9h7"/>',
	"phone": '<path d="m9 3 5 8-4 4c2 4 4 6 8 8l4-4 7 5c-2 7-7 7-13 3C9 23 4 16 3 10 2 6 5 3 9 3Z"/>',
	"pen": '<path d="m5 21 15-15 6 6-15 15-8 2ZM18 8l6 6M5 21l6 6M23 3l6 6-3 3-6-6Z"/>',
	"money": '<rect x="2" y="7" width="28" height="18" rx="1"/><circle cx="16" cy="16" r="5"/><path d="M6 12v8m20-8v8"/>',
}
static var _cache: Dictionary = {}


static func texture(key: String, pixels: int = 24) -> Texture2D:
	var cache_key := "%s@%d" % [key, pixels]
	if not _cache.has(cache_key):
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><g fill="none" stroke="white" stroke-width="2.7" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % PATHS.get(key, PATHS["folder"])
		var image := Image.new()
		image.load_svg_from_string(svg, float(pixels) / 32.0)
		_cache[cache_key] = ImageTexture.create_from_image(image)
	return _cache[cache_key]


static func quest_texture(kind: String, pixels: int = 32) -> Texture2D:
	return texture(QUEST_TYPES.get(kind, "request"), pixels)
