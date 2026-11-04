# Civic venues production atlas

Built-in ImageGen, 2026-11-03. Reference: `../culture_house/multiview-1997-v3.png`, material/mosaic/banner direction only. User authorized the texture/model production pass within the selected visual directions. Inspected original1774x887: correct4x2 layout, brick/plaster/stone/mural/banner present. Prepared separately with `tools/optimize_asset.py --profile facade --approved` before Blender integration. No labels or alpha. Exact UV regions and material tint factors are in `art/models/civic_venues/build_assets.py`.

```text
Create a PRODUCTION ALBEDO TEXTURE ATLAS for two buildings in a painted realistic strategy game, fictional Slavic city August1997. Landscape image EXACTLY2:1 aspect ratio, ideally2048x1024 pixels. EXACT FOUR COLUMNS by TWO ROWS of equal SQUARE tiles, each tile fills its cell edge-to-edge; NO GUTTERS, no borders, no labels, no page background, no lighting direction, no cast shadows, no3D objects or whole buildings. Uniform diffuse albedo lighting. The supplied House of Culture reference guides tile3 brick, tile4 concrete and the mosaic/banner graphic style only, NOT the atlas layout.
TOP ROW, LEFT TO RIGHT:
1. Warm ivory mineral plaster, fine restrained grain, maintained, subtle low contrast mottling. Seamless in both directions.
2. Polished reddish brown stone cladding slab surface with restrained mineral veining, slight natural tonal variation, NO seams/grid or highlights. Seamless in both directions.
3. Modest late-Soviet red-orange brick wall, realistic staggered small bricks and pale grey mortar, restrained weathering, not ruins. Seamless in both directions.
4. Warm pale grey concrete/precast facing, restrained subtle vertical streaks and stone grain, NO panel borders or windows; seamless in both directions.
BOTTOM ROW, LEFT TO RIGHT:
5. Dark charcoal grey painted metal ROOF surface, faint fine longitudinal standing-seam lines, subtle low contrast wear, NO shiny specular or rust disaster. Seamless.
6. Warm brown wood door/bench planks, fine longitudinal grain and discreet narrow plank joints, maintained and slightly worn; seamless.
7. A COMPLETE flat SQUARE Soviet civic ceramic mosaic mural in warm ochre/cream/terracotta/muted blue: abstract stylized human figure with raised arms, sun and geometric sweeping ribbon forms, graphic recognizable1970s public art. Tiny irregular ceramic tesserae. Intact, functional, no political emblems, lettering or border. Same earthy mural direction as reference. This is a FLAT FULL-SURFACE ARTWORK, no wall perspective, no ad on this tile.
8. This final square is divided into TWO equal horizontal rectangles. UPPER HALF is a cheap1997 yellow vinyl AD BANNER, flat straight-on full-bleed artwork: large red/dark-blue Russian headline EXACTLY 'ИМПОРТНАЯ ТЕХНИКА', smaller 'ТЕЛЕВИЗОРЫ • ВИДЕО', one modest bulky CRT television and black VHS recorder illustration. No brands, no modern flat TVs/phones, no folds/shadows/grommets (those are modeled). LOWER HALF contains TWO simple side-by-side1997 poster artworks, one purple/magenta disco dance silhouettes poster and one cream/blue video cassette rental poster with Cyrillic 'ВИДЕОПРОКАТ'. No perspective, no physical bulletin board. These printed graphics intentionally contrast with muted building tiles.
Keep exact4x2 grid tile boundaries. Textures must be useful to UV-map onto separate meshes, not an illustrative materials moodboard. No watermark, title, annotations or environmental background.
```
