# Графика

Встроенный `image_gen`, исходный референс пользователя. Финальные изображения хранятся в `assets/art`.

## Пастбище

Edit the reference, preserving its exact portrait composition, framing, lighting, terrain shapes, felt textures, rocks, bushes, woven red/teal/cream Kyrgyz embroidery, river, wooden bridge, stone enclosure, yurt, rugs and linen backdrop. Remove animals, their shadows, reaction lines, UI and movement arrow. Open the wooden gate, preserving the posts. Empty pasture for moving 2D sprites. Needle-felt wool fibers everywhere, handmade miniature quality. No text or UI.

## Овца и тайган

Transparent 4-column, 3-row sprite atlas in the reference's needle-felt miniature style, fixed isometric camera. Four views per species: right/down, left/up, front, rear. Ivory sheep with small black head; black Kyrgyz Taigan with slim body, long legs and floppy ears. Soft upper-left lighting, no floor or baked shadows. Bottom row of the first draft is superseded by the separate wolf atlas.

## Волк — пропорции из увеличенного референса

Финальный спрайт: `assets/art/wolf-v5.png`, built-in image_gen. Предыдущие варианты сохранены отдельно.

Основной референс: `docs/reference.png`. Крупный план волков: `docs/wolf-reference.png`.

Пользователь отклонил коротколапого волка с большой круглой головой: он слишком похож на плюшевого щенка. Нужен именно вытянутый стилизованный волк с верхней дорожки, с тонкими лапами, узкой светлой мордой, маленькими жёлтыми глазами и чуть сердитым выражением.

Reproduce the foreground reference wolf faithfully: long narrow gray-brown torso, slim straight legs and small pale toes, narrow elongated ivory muzzle, small black nose, upright triangular ears, narrow tapering raised tail. Small yellow eyes, gently lowered eyelids, slightly stern alert expression. Dense short pressed felt wool; no plush puppy proportions, inflated cheek pads or heavy eyebrows. Four views in a transparent 2×2 atlas: right/down, left/up, front, rear. Fixed isometric camera, warm upper-left light.

Refinement with the larger reference: narrow legs to 60% of the draft thickness, reduce feet and tail bulk, lower the head slightly and lengthen the tapered muzzle. Preserve atlas layout, alpha, lighting, scale and directions; keep margins around each sprite.

Последнее уточнение пользователя: тельце чуть пухлее, волчонок должен напоминать войлочную игрушку и быть чуточку милее. В версии v4 немного округлены живот, спина и бока, смягчён взгляд; длина лап и пропорции головы сохранены. Полный запрос built-in image_gen: `docs/wolf-v4-prompt.txt`.

Версия v5: пользователь уточнил, что материал ещё не выглядит войлоком, и попросил ещё немного пухлости. Поверхность заменена на плотный матовый валяный материал с короткими спутанными волокнами и мягкими краями. Тельце стало округлее. Запрос встроенного image_gen: `docs/wolf-v5-prompt.txt`. Для четырёх ракурсов в сцене заданы собственные области атласа и уровни стоп, чтобы не обрезать лапы и не менять точку опоры.

## Три варианта овец

Файл `assets/art/sheep-variants.png`, сетка 4×3: четыре направления и три окраса. Сцены `sheep_ivory.tscn`, `sheep_cream.tscn`, `sheep_spotted.tscn` наследуют `sheep.tscn`.

Create three reference-matching sheep variants in a transparent 4-column, 3-row sprite atlas. Row 1: white wool with small black face and dark legs. Row 2: warm cream wool, small light gray face, dark gray ears and feet. Row 3: off-white wool, pale face, dark ears and eye patches, small gray flank patch. Each row shows right/down, left/up, front and rear views. Compact continuous oval felt bodies, tiny heads, short slender legs, quiet natural colors, fixed isometric view and soft upper-left light. No horns, accessories, shadows or labels.

## Интерфейс

Extract and recreate the dark brown stitched felt UI plate from the reference's sheep counter. One blank horizontal capsule on transparent alpha, dense matte wool, softly rounded plush edge, delicate beige running stitches. No text, icons, shine or ornaments.

## Иконка волка

`assets/ui/wolf-head.png`, built-in image_gen.

Extract/recreate only the wolf head icon from the top timer badge of the larger reference. Isolated front-view gray felt head with narrow ivory muzzle, small black nose, yellow eyes, slightly stern expression, triangular ears and gray felt cheek tufts. Transparent alpha; no badge, text, body, shoulders or neck stump. Preserve the reference UI icon proportions.

## Солнце и луна для верхнего таймера — 30 сентября 2026

Built-in imagegen, transparent background. Файлы: `assets/ui/sun-felt.png`, `assets/ui/moon-felt.png`. Светлый фон плашек создан шейдером существующей текстуры, без её перерисовки.

### Солнце

Use case: stylized-concept. Asset type: one small HUD sun icon for a handmade wool felt pastoral mobile game. Generate a SINGLE centered SUN, circular warm golden-yellow felt disc with 8 short rounded padded felt rays, softly needle-felted wool fibers, slightly raised sewn edges and subtle natural shading from upper left. No face, no text, no separate stars or objects. Readable bold silhouette at 40 pixels. Front-facing flat orthographic appliqué, warm ochre outer seams so it contrasts against a pale cream felt HUD background. Restrained tactile game art, no plastic, no glossy 3D, no emoji, no photographic background, no drop shadow outside the object. Square transparent canvas, icon occupies 82 percent of canvas width and height, centered. Genuinely transparent background.

### Луна

Use case: stylized-concept. Asset type: one small HUD moon icon for a handmade wool felt pastoral mobile game. Generate a SINGLE centered CRESCENT MOON, opening facing right, made of pale ivory softly needle-felted wool with a thick rounded crescent body, subtle warm gray-blue stitched outline and soft natural shading from upper left. No face, no text, no stars or separate objects. Readable bold silhouette at 40 pixels. Front-facing flat orthographic felt appliqué, outer seams gray-blue so it contrasts against a pale cream felt HUD background. Restrained tactile game art, no plastic, no glossy 3D, no emoji, no photographic background, no drop shadow outside the object. Square transparent canvas, icon occupies 78 percent of canvas width and height, centered. Genuinely transparent background.
