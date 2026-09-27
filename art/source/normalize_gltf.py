import json, struct
from pathlib import Path
TINTS = {'wool_ivory': (1.0, 0.97, 0.88), 'wool_snow': (1.0, 1.0, 0.98), 'felt_charcoal': (0.012, 0.011, 0.009), 'felt_ash': (0.48, 0.49, 0.46), 'felt_wolf': (0.17, 0.19, 0.18), 'felt_muzzle': (0.48, 0.5, 0.44), 'felt_tan': (0.5, 0.3, 0.14), 'felt_ochre': (0.31, 0.25, 0.044), 'felt_meadow': (0.11, 0.18, 0.032), 'felt_sage': (0.19, 0.27, 0.085), 'felt_pine': (0.055, 0.24, 0.17), 'felt_teal': (0.08, 0.34, 0.27), 'felt_rust': (0.48, 0.095, 0.065), 'felt_gold': (0.69, 0.43, 0.07), 'felt_red': (0.44, 0.045, 0.055), 'felt_linen': (0.83, 0.71, 0.51), 'felt_water': (0.095, 0.29, 0.35), 'felt_water_light': (0.35, 0.59, 0.62), 'felt_rose': (0.6, 0.29, 0.24), 'felt_soil': (0.33, 0.21, 0.12)}

def normalize_gltf(path):
    # Blender's export drops the MixRGB tint and exports unit sheen despite weight.
    # glTF baseColorFactor is linear, matching the authored Principled multiplier.
    path=Path(path);raw=path.read_bytes()
    size=struct.unpack_from('<I',raw,12)[0]
    data=json.loads(raw[20:20+size])
    for material in data.get('materials',[]):
        tint=TINTS.get(material.get('name'))
        if tint:material.setdefault('pbrMetallicRoughness',{})['baseColorFactor']=[*tint,1.0]
        material.get('extensions',{}).pop('KHR_materials_sheen',None)
        if material.get('extensions')=={}:material.pop('extensions',None)
    for key in ['extensionsUsed','extensionsRequired']:
        if key in data:
            data[key]=[x for x in data[key] if x!='KHR_materials_sheen']
            if not data[key]:data.pop(key)
    encoded=json.dumps(data,separators=(',',':')).encode()
    encoded+=b' '*((-len(encoded))%4)
    tail=raw[20+size:]
    result=struct.pack('<III',0x46546c67,2,20+len(encoded)+len(tail))
    result+=struct.pack('<II',len(encoded),0x4e4f534a)+encoded+tail
    path.write_bytes(result)
