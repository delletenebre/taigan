"""Repack Blender GLBs with shared external texture files. Mesh data is unchanged."""
import json, struct, hashlib
from pathlib import Path

def share_textures(path):
    path=Path(path);raw=path.read_bytes();jsize=struct.unpack_from('<I',raw,12)[0]
    data=json.loads(raw[20:20+jsize]);tail=20+jsize
    if tail>=len(raw):return
    bsize,btype=struct.unpack_from('<II',raw,tail);assert btype==0x004e4942
    binary=raw[tail+8:tail+8+bsize];views=data.get('bufferViews',[])
    folder=path.parent.parent/'textures/shared';folder.mkdir(exist_ok=True)
    changed=False
    for im in data.get('images',[]):
        if 'bufferView' not in im:continue
        v=views[im.pop('bufferView')];blob=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
        mime=im.pop('mimeType','image/png');suffix='.jpg' if mime=='image/jpeg' else '.png'
        filename=hashlib.sha256(blob).hexdigest()[:24]+suffix
        target=folder/filename
        if not target.exists():target.write_bytes(blob)
        im['uri']='../textures/shared/'+filename
        changed=True
    if not changed:return
    used=set()
    def collect(obj):
        if isinstance(obj,dict):
            for k,v in obj.items():
                if k=='bufferView':used.add(v)
                else:collect(v)
        elif isinstance(obj,list):
            for v in obj:collect(v)
    collect(data)
    remap={old:i for i,old in enumerate(sorted(used))};newviews=[];newbin=bytearray()
    for old in sorted(used):
        v=views[old].copy();offset=v.get('byteOffset',0);length=v['byteLength']
        newbin.extend(b'\0'*((-len(newbin))%4));v['byteOffset']=len(newbin)
        newbin.extend(binary[offset:offset+length]);newviews.append(v)
    def remap_refs(obj):
        if isinstance(obj,dict):
            for k,v in obj.items():
                if k=='bufferView':obj[k]=remap[v]
                else:remap_refs(v)
        elif isinstance(obj,list):
            for v in obj:remap_refs(v)
    remap_refs(data);data['bufferViews']=newviews
    data['buffers']=[{'byteLength':len(newbin)}]
    newbin.extend(b'\0'*((-len(newbin))%4))
    encoded=json.dumps(data,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
    result=struct.pack('<III',0x46546c67,2,28+len(encoded)+len(newbin))
    result+=struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(newbin),0x004e4942)+newbin
    path.write_bytes(result)

if __name__=='__main__':
    root=Path(__file__).resolve().parents[2]
    for path in (root/'assets/models').glob('*.glb'):share_textures(path)
