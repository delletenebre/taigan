"""Author the editable Godot scenes. Does not generate or modify bitmap art."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def save(path,text): (ROOT/path).write_text(text)
def poly(points): return 'PackedVector2Array('+', '.join(str(v) for p in points for v in p)+')'
# Actor scenes are authored separately with their animation builders.
# Sewn expanding bark / target ring, authored AnimationPlayer rather than draw code.
from math import cos,sin,pi
for name,radius,color,duration in [('bark',155,'0.98, 0.93, 0.77, 0.85',0.65),('target',15,'0.98, 0.93, 0.77, 0.7',0.8)]:
    points=[(round(cos(i*pi/24)*radius,2),round(sin(i*pi/24)*radius*.68,2)) for i in range(49)]
    save(f'scenes/effects/{name}.tscn',f'''[gd_scene load_steps=3 format=3]
[sub_resource type="Animation" id="Animation"]
resource_name = "{name if name=='bark' else 'pulse'}"
length = {duration}
tracks/0/type = "value"
tracks/0/path = NodePath("Ring:scale")
tracks/0/keys = {{"times": PackedFloat32Array(0, {duration}), "transitions": PackedFloat32Array(1, 1), "update": 0, "values": [Vector2(0.15, 0.15), Vector2(1, 1)]}}
tracks/1/type = "value"
tracks/1/path = NodePath("Ring:modulate")
tracks/1/keys = {{"times": PackedFloat32Array(0, {duration}), "transitions": PackedFloat32Array(1, 1), "update": 0, "values": [Color(1, 1, 1, 1), Color(1, 1, 1, 0)]}}
[sub_resource type="AnimationLibrary" id="Library"]
_data = {{&"{name if name=='bark' else 'pulse'}": SubResource("Animation")}}
[node name="{name.title()}" type="Node2D"]
[node name="Ring" type="Line2D" parent="."]
modulate = Color(1, 1, 1, 0)
points = {poly(points)}
width = 2.3
default_color = Color({color})
closed = true
antialiased = true
[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = {{&"": SubResource("Library")}}
''')
# Walk surfaces follow the rendered isometric artwork in screen coordinates.
walk={
'LowerMeadow':[(128,537),(235,515),(338,548),(481,514),(585,563),(691,620),(731,691),(720,818),(729,965),(658,1120),(409,1130),(333,1082),(189,1066),(163,969),(71,881),(68,794),(93,733),(86,607)],
'UpperMeadow':[(95,292),(213,279),(305,293),(339,218),(418,169),(510,148),(619,163),(663,209),(645,326),(706,371),(732,452),(696,509),(567,467),(488,451),(365,450),(305,401),(167,378),(120,355)],
'Bridge':[(368,450),(472,430),(503,519),(394,543)],
'WolfTrail':[(85,87),(151,75),(226,155),(283,240),(305,295),(232,309),(194,235),(145,168)],
'PenInterior':[(486,218),(531,183),(593,190),(641,221),(646,279),(634,332),(614,380),(557,371),(542,334),(476,299),(462,258)]
}
obs={
'WestBoulder':[(98,604),(139,571),(188,604),(197,669),(170,700),(109,686)],
'FrontBoulder':[(390,1011),(413,964),(476,945),(535,979),(554,1059),(510,1090),(423,1081)],
'EastBoulder':[(678,583),(700,568),(728,592),(729,625),(696,635)],
'NorthBoulder':[(674,423),(696,389),(737,400),(749,456),(717,477),(677,458)],
'SouthWall':[(522,854),(716,786),(725,816),(527,890)],
'NorthWall':[(124,366),(342,405),(348,445),(118,403)],
'PenLeft':[(486,207),(467,230),(459,272),(481,306),(530,327),(541,352),(548,376),(524,367),(470,339),(444,303),(440,255),(453,216),(476,194)],
'PenBack':[(476,194),(513,162),(564,154),(612,165),(647,182),(660,212),(642,229),(627,200),(590,181),(545,177),(507,188),(488,210)],
'PenRight':[(642,218),(665,213),(672,267),(667,330),(646,396),(621,397),(639,343),(647,279)]
}
s='''[gd_scene load_steps=13 format=3]
[ext_resource type="Script" path="res://scripts/level.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/art/pasture.png" id="2"]
[ext_resource type="PackedScene" path="res://scenes/actors/sheep_ivory.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/actors/taigan.tscn" id="4"]
[ext_resource type="PackedScene" path="res://scenes/effects/bark.tscn" id="5"]
[ext_resource type="PackedScene" path="res://scenes/effects/target.tscn" id="6"]
[ext_resource type="PackedScene" path="res://scenes/effects/wolf_trail_light.tscn" id="7"]
[ext_resource type="PackedScene" path="res://scenes/actors/sheep_cream.tscn" id="8"]
[ext_resource type="PackedScene" path="res://scenes/actors/sheep_spotted.tscn" id="9"]
[ext_resource type="PackedScene" path="res://scenes/effects/yurt_atmosphere.tscn" id="10"]
[ext_resource type="PackedScene" path="res://scenes/effects/wolf_forest.tscn" id="11"]
[sub_resource type="WorldBoundaryShape2D" id="Unused"]
[node name="Pasture" type="Node2D"]
script = ExtResource("1")
[node name="Artwork" type="Sprite2D" parent="."]
texture = ExtResource("2")
centered = false
scale = Vector2(0.8703507, 0.8708134)
[node name="Walkable" type="Node2D" parent="."]
visible = false
'''
for name,points in walk.items(): s+=f'''[node name="{name}" type="Polygon2D" parent="Walkable"]
polygon = {poly(points)}
color = Color(0.2, 0.7, 0.4, 0.4)
'''
s+='[node name="Obstacles" type="Node2D" parent="."]\n'
for name,points in obs.items(): s+=f'''[node name="{name}" type="StaticBody2D" parent="Obstacles"]
collision_layer = 1
collision_mask = 2
[node name="Shape" type="CollisionPolygon2D" parent="Obstacles/{name}"]
polygon = {poly(points)}
'''
s+='[node name="Markers" type="Node2D" parent="."]\n'
for name,p in [('Entrance',(590,386)),('PenCenter',(577,268)),('WolfSpawn',(120,123)),('BridgeSouth',(450,549)),('BridgeNorth',(419,432))]:
    s+=f'[node name="{name}" type="Marker2D" parent="Markers"]\nposition = Vector2{p}\n'
s+='[node name="TrailLight" parent="Markers/WolfSpawn" instance=ExtResource("7")]\n'
s+='''[node name="Pen" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2
[node name="Shape" type="CollisionPolygon2D" parent="Pen"]
polygon = PackedVector2Array(482, 232, 530, 199, 599, 201, 632, 230, 632, 308, 607, 336, 554, 326, 490, 290)
[node name="Actors" type="Node2D" parent="."]
y_sort_enabled = true
[node name="Taigan" parent="Actors" instance=ExtResource("4")]
position = Vector2(326, 855)
initial_direction = 1
'''
spawns=[(196,736),(254,714),(216,782),(409,698),(444,665),(471,710),(510,649),(532,715),(436,748),(486,760),(402,778),(457,803)]
for i,p in enumerate(spawns):
    s+=f'''[node name="Sheep{i+1:02}" parent="Actors" instance=ExtResource("{[3,8,9][i%3]}")]
position = Vector2{p}
initial_direction = {i%4}
initially_safe = false
'''
# Foreground cutouts use the background texture coordinates directly (no re-rasterization).
# Their local origins sit on their ground line, so Godot y-sorts actors behind them.
for name,points in obs.items():
    if name=='PenBack': continue
    baseline=max(p[1] for p in points)
    # Visual polygons cover exact visible upper silhouettes as well as collision footprints.
    visuals={
    'WestBoulder':[(84,607),(95,576),(126,565),(153,575),(170,604),(193,635),(198,674),(169,697),(106,688),(86,649)],
    'FrontBoulder':[(387,1000),(405,966),(451,945),(482,947),(514,968),(538,1001),(554,1062),(507,1095),(432,1085),(390,1056)],
    'SouthWall':[(521,854),(713,790),(725,796),(731,819),(527,891)],
    'NorthWall':[(125,355),(341,402),(351,434),(338,447),(121,404)],
    }.get(name,points)
    uv=[(round(x/0.8703507,3),round(y/0.8708134,3)) for x,y in visuals]
    local=[(x,y-baseline) for x,y in visuals]
    s+=f'''[node name="{name}Foreground" type="Polygon2D" parent="Actors"]
position = Vector2(0, {baseline})
texture = ExtResource("2")
polygon = {poly(local)}
uv = {poly(uv)}
'''
s+='''[node name="Bark" parent="." instance=ExtResource("5")]
[node name="Target" parent="." instance=ExtResource("6")]
'''
s+='[node name="YurtAtmosphere" parent="." instance=ExtResource("10")]\n'
s+='[node name="WolfForest" parent="Actors" instance=ExtResource("11")]\n'
save('scenes/levels/pasture.tscn',s)
# HUD is entirely editable Controls, using sewn fabric image panels.
s='''[gd_scene load_steps=13 format=3]
[ext_resource type="Script" path="res://scripts/hud.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/art/felt-panel.png" id="2"]
[ext_resource type="FontFile" path="res://assets/fonts/PT_Sans-Web-Regular.ttf" id="3"]
[ext_resource type="Texture2D" path="res://assets/art/sheep-variants.png" id="4"]
[ext_resource type="Texture2D" path="res://assets/ui/ornament.png" id="5"]
[ext_resource type="Texture2D" path="res://assets/ui/wolf-head.png" id="6"]
[sub_resource type="AtlasTexture" id="PanelTexture"]
atlas = ExtResource("2")
region = Rect2(36, 285, 1464, 450)
[sub_resource type="StyleBoxTexture" id="Fabric"]
texture = SubResource("PanelTexture")
texture_margin_left = 0.0
texture_margin_top = 0.0
texture_margin_right = 0.0
texture_margin_bottom = 0.0
[sub_resource type="AtlasTexture" id="SheepIcon"]
atlas = ExtResource("4")
region = Rect2(40, 65, 304, 287)
[sub_resource type="AtlasTexture" id="WolfIcon"]
atlas = ExtResource("6")
region = Rect2(90, 105, 1074, 1020)
[sub_resource type="Theme" id="Theme"]
default_font = ExtResource("3")
default_font_size = 30
Label/colors/font_color = Color(0.95, 0.90, 0.76, 1)
Button/colors/font_color = Color(0.95, 0.90, 0.76, 1)
Button/colors/font_hover_color = Color(1, 0.97, 0.87, 1)
Button/colors/font_disabled_color = Color(0.6, 0.56, 0.46, 1)
Button/styles/normal = SubResource("Fabric")
Button/styles/hover = SubResource("Fabric")
Button/styles/pressed = SubResource("Fabric")
Button/styles/disabled = SubResource("Fabric")
[node name="Interface" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
theme = SubResource("Theme")
script = ExtResource("1")
'''
def rect(name,parent,typ,x,y,w,h,extra=''):
    return f'''[node name="{name}" type="{typ}" parent="{parent}"]
layout_mode = 0
offset_left = {float(x)}
offset_top = {float(y)}
offset_right = {float(x+w)}
offset_bottom = {float(y+h)}
{extra}
'''
for name,x,w,text in [('SheepCount',18,208,'0/12'),('WolfTimer',522,200,'01:00')]:
    s+=rect(name,'.','TextureRect',x,17,w,68,'texture = SubResource("PanelTexture")\nexpand_mode = 1\nstretch_mode = 0\nmouse_filter = 2')
    s+=rect('Icon',name,'TextureRect',8,0,70,64,f'texture = SubResource("{"SheepIcon" if name=="SheepCount" else "WolfIcon"}")\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2')
    s+=rect('Text',name,'Label',78,3,w-83,60,f'text = "{text}"\ntheme_override_font_sizes/font_size = 39\nvertical_alignment = 1\nmouse_filter = 2')
s+=rect('Pause','.','Button',735,17,66,68,'text = "Ⅱ"\ntheme_override_font_sizes/font_size = 38')
s+=rect('Goal','.','TextureRect',192,1365,435,62,'texture = SubResource("PanelTexture")\nexpand_mode = 1\nstretch_mode = 0\nmouse_filter = 2')
s+=rect('Text','Goal','Label',44,0,347,62,'text = "Собери всю отару"\nhorizontal_alignment = 1\nvertical_alignment = 1\nmouse_filter = 2')
for name,x in [('Left',10),('Right',391)]: s+=rect(name,'Goal','TextureRect',x,15,32,32,'texture = ExtResource("5")\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2')
s+=rect('Bark','.','Button',711,1285,83,67,'text = "Гав!"\ntooltip_text = "Пробел или двойной тап — лай"\ntheme_override_font_sizes/font_size = 23')
s+=rect('Hint','.','Label',184,1425,460,26,'text = "Веди касанием · Двойной тап — лай"\nhorizontal_alignment = 1\ntheme_override_font_sizes/font_size = 16\ntheme_override_colors/font_color = Color(0.3, 0.23, 0.16, 0.85)\nmouse_filter = 2')
s+=rect('Overlay','.','ColorRect',0,0,819,1456,'visible = false\ncolor = Color(0.13, 0.10, 0.07, 0.58)')
s+=rect('Card','Overlay','TextureRect',115,476,589,465,'texture = SubResource("PanelTexture")\nexpand_mode = 1\nstretch_mode = 0')
s+=rect('Title','Overlay/Card','Label',25,38,539,60,'text = "Привал"\nhorizontal_alignment = 1\ntheme_override_font_sizes/font_size = 39')
s+=rect('Description','Overlay/Card','Label',30,112,529,158,'text = ""\nhorizontal_alignment = 1\nvertical_alignment = 1\ntheme_override_font_sizes/font_size = 23')
s+=rect('Resume','Overlay/Card','Button',65,285,459,62,'text = "Вернуться к отаре"')
s+=rect('Restart','Overlay/Card','Button',65,361,459,62,'text = "Начать заново"')
save('scenes/ui/hud.tscn',s)
s='''[gd_scene load_steps=10 format=3]
[ext_resource type="Script" path="res://scripts/game.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/levels/pasture.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/ui/hud.tscn" id="3"]
'''
for i,name in enumerate(['bark','howl','pen','win','lose'],4): s+=f'[ext_resource type="AudioStream" path="res://assets/audio/{name}.wav" id="{i}"]\n'
s+='''[sub_resource type="World2D" id="World"]
[node name="Taigan" type="Node2D"]
script = ExtResource("1")
[node name="Pasture" parent="." instance=ExtResource("2")]
[node name="HUD" type="CanvasLayer" parent="."]
[node name="Interface" parent="HUD" instance=ExtResource("3")]
'''
for i,name in enumerate(['bark','howl','pen','win','lose'],4): s+=f'[node name="{name.title()}Sound" type="AudioStreamPlayer" parent="."]\nstream = ExtResource("{i}")\nvolume_db = -8.0\n'
save('scenes/main.tscn',s)
