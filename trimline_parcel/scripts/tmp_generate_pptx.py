from zipfile import ZipFile, ZIP_DEFLATED
from pathlib import Path
from datetime import datetime
import xml.sax.saxutils as saxutils

root = Path('assets/presentation')
root.mkdir(parents=True, exist_ok=True)

slides = [
    {
        "title": "Trimline Parcel",
        "paragraphs": [
            {"text": "Operational Dashboard Overview", "bullet": False, "size": 3200},
            {"text": "Logistics visibility for Trimline courier teams", "bullet": False, "size": 2400},
        ],
        "image": None,
    },
    {
        "title": "Problem & Goals",
        "paragraphs": [
            {"text": "Manual parcel tracking scattered across spreadsheets and chats", "bullet": True},
            {"text": "Need near real-time status visibility for operations and support", "bullet": True},
            {"text": "Provide a unified workflow to log, update, and audit parcel journeys", "bullet": True},
        ],
        "image": None,
    },
    {
        "title": "Key Features",
        "paragraphs": [
            {"text": "Parcel dashboard with live status cards and workload snapshots", "bullet": True},
            {"text": "Smart search & filtering powered by GetX observable state", "bullet": True},
            {"text": "Guided add/edit form for quick parcel intake and updates", "bullet": True},
            {"text": "Drawer shortcuts for frequent actions and support touchpoints", "bullet": True},
        ],
        "image": None,
    },
    {
        "title": "Solution Architecture",
        "paragraphs": [
            {"text": "Flutter UI consumes GetX controllers, backed by SQLite persistence", "bullet": True},
            {"text": "Controllers orchestrate status changes, validation, and search debounce", "bullet": True},
            {"text": "Extensible layer for integrating external tracking APIs", "bullet": True},
        ],
        "image": {
            "path": "ppt/media/image1.svg",
            "source": Path('assets/presentation/architecture.svg'),
            "rid": "rId2",
            "x": 685800,
            "y": 2667000,
            "cx": 10500000,
            "cy": 3000000,
            "name": "Architecture Diagram",
        },
    },
    {
        "title": "Dashboard Experience",
        "paragraphs": [
            {"text": "Hot actions surfaced in the drawer for one-tap navigation", "bullet": True},
            {"text": "Emphasis on clarity with dark navy palette and accent cues", "bullet": True},
            {"text": "Filter sheet educates operators on parcel lifecycle milestones", "bullet": True},
        ],
        "image": {
            "path": "ppt/media/image2.svg",
            "source": Path('assets/presentation/dashboard_highlights.svg'),
            "rid": "rId2",
            "x": 685800,
            "y": 2476500,
            "cx": 10500000,
            "cy": 3200000,
            "name": "Dashboard Highlights",
        },
    },
    {
        "title": "Roadmap & Next Steps",
        "paragraphs": [
            {"text": "Integrate push notifications for courier events (ready for dispatch, collected)", "bullet": True},
            {"text": "Add analytics exports with parcel aging and SLA breach trends", "bullet": True},
            {"text": "Automate nightly sync with partner tracking systems", "bullet": True},
            {"text": "Harden QA via widget tests for controller-driven flows", "bullet": True},
        ],
        "image": None,
    },
]

slide_width = 12192000
slide_height = 6858000

created = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

files = {}

content_types = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
  '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
  '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
  '  <Default Extension="xml" ContentType="application/xml"/>',
  '  <Default Extension="svg" ContentType="image/svg+xml"/>',
  '  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>',
  '  <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>',
  '  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>',
  '  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>',
  '  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>',
  '  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
]
for idx in range(1, len(slides)+1):
    content_types.append(f'  <Override PartName="/ppt/slides/slide{idx}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>')
content_types.append('</Types>\n')
files['[Content_Types].xml'] = '\n'.join(content_types)

files['_rels/.rels'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
'''

files['docProps/app.xml'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Codex Generator</Application>
  <PresentationFormat>16x9</PresentationFormat>
  <Slides>{slide_count}</Slides>
  <Notes>0</Notes>
  <HiddenSlides>0</HiddenSlides>
  <MMClips>0</MMClips>
</Properties>
'''.format(slide_count=len(slides))

files['docProps/core.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Trimline Parcel Overview</dc:title>
  <dc:subject>Parcel operations dashboard</dc:subject>
  <dc:creator>Codex Assistant</dc:creator>
  <cp:lastModifiedBy>Codex Assistant</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">{created}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">{created}</dcterms:modified>
</cp:coreProperties>
'''

slide_id_base = 256
sld_id_entries = '\n'.join(f'    <p:sldId id="{slide_id_base + idx}" r:id="rId{idx+1}"/>' for idx in range(len(slides)))
files['ppt/presentation.xml'] = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:sldMasterIdLst>
    <p:sldMasterId r:id="rId1"/>
  </p:sldMasterIdLst>
  <p:sldIdLst>
{sld_id_entries}
  </p:sldIdLst>
  <p:sldSz cx="{slide_width}" cy="{slide_height}"/>
  <p:notesSz cx="6858000" cy="9144000"/>
</p:presentation>
'''

rel_entries = ['  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>']
for idx in range(len(slides)):
    rel_entries.append(f'  <Relationship Id="rId{idx+2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide{idx+1}.xml"/>')
files['ppt/_rels/presentation.xml.rels'] = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n' + '\n'.join(rel_entries) + '\n</Relationships>\n'

files['ppt/slideMasters/slideMaster1.xml'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:bg>
      <p:bgPr>
        <a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>
      </p:bgPr>
    </p:bg>
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr>
    <a:masterClrMapping/>
  </p:clrMapOvr>
  <p:sldLayoutIdLst>
    <p:sldLayoutId id="1" r:id="rId1"/>
  </p:sldLayoutIdLst>
</p:sldMaster>
'''

files['ppt/slideMasters/_rels/slideMaster1.xml.rels'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>
'''

files['ppt/slideLayouts/slideLayout1.xml'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank" preserve="1">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr>
    <a:masterClrMapping/>
  </p:clrMapOvr>
</p:sldLayout>
'''

files['ppt/slideLayouts/_rels/slideLayout1.xml.rels'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
</Relationships>
'''

files['ppt/theme/theme1.xml'] = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Custom Dark">
  <a:themeElements>
    <a:clrScheme name="Trimline">
      <a:dk1><a:srgbClr val="000000"/></a:dk1>
      <a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="0F172A"/></a:dk2>
      <a:lt2><a:srgbClr val="E2E8F0"/></a:lt2>
      <a:accent1><a:srgbClr val="2563EB"/></a:accent1>
      <a:accent2><a:srgbClr val="38BDF8"/></a:accent2>
      <a:accent3><a:srgbClr val="FBBF24"/></a:accent3>
      <a:accent4><a:srgbClr val="10B981"/></a:accent4>
      <a:accent5><a:srgbClr val="F472B6"/></a:accent5>
      <a:accent6><a:srgbClr val="F97316"/></a:accent6>
      <a:hlink><a:srgbClr val="2563EB"/></a:hlink>
      <a:folHlink><a:srgbClr val="1D4ED8"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="Trimline Typeface">
      <a:majorFont>
        <a:latin typeface="Segoe UI"/>
      </a:majorFont>
      <a:minorFont>
        <a:latin typeface="Segoe UI"/>
      </a:minorFont>
    </a:fontScheme>
    <a:fmtScheme name="Trimline Format">
      <a:fillStyleLst>
        <a:solidFill><a:schemeClr val="accent1"/></a:solidFill>
        <a:solidFill><a:schemeClr val="accent2"/></a:solidFill>
      </a:fillStyleLst>
      <a:lnStyleLst>
        <a:ln w="9525"><a:solidFill><a:schemeClr val="accent1"/></a:solidFill></a:ln>
        <a:ln w="9525"><a:solidFill><a:schemeClr val="accent2"/></a:solidFill></a:ln>
      </a:lnStyleLst>
      <a:effectStyleLst>
        <a:effectStyle><a:effectLst/></a:effectStyle>
      </a:effectStyleLst>
      <a:bgFillStyleLst>
        <a:solidFill><a:schemeClr val="lt1"/></a:solidFill>
      </a:bgFillStyleLst>
    </a:fmtScheme>
  </a:themeElements>
</a:theme>
'''

def build_paragraph(p):
    text = saxutils.escape(p["text"])
    size = p.get("size", 2600)
    if p.get("bullet", False):
        return f'''      <a:p>\n        <a:pPr lvl="0">\n          <a:spcBef><a:spcPts val="200"/></a:spcBef>\n          <a:buChar char="•"/>\n        </a:pPr>\n        <a:r>\n          <a:rPr lang="en-US" sz="{size}"/>\n          <a:t>{text}</a:t>\n        </a:r>\n        <a:endParaRPr lang="en-US" sz="{size}"/>\n      </a:p>'''
    else:
        return f'''      <a:p>\n        <a:pPr algn="ctr"/>\n        <a:r>\n          <a:rPr lang="en-US" sz="{size}"/>\n          <a:t>{text}</a:t>\n        </a:r>\n        <a:endParaRPr lang="en-US" sz="{size}"/>\n      </a:p>'''

def build_slide_xml(idx, slide):
    title = saxutils.escape(slide["title"])
    paragraphs = '\n'.join(build_paragraph(p) for p in slide["paragraphs"])
    title_box = f'''      <p:sp>\n        <p:nvSpPr>\n          <p:cNvPr id="2" name="Title {idx}"/>\n          <p:cNvSpPr txBox="1"/>\n          <p:nvPr/>\n        </p:nvSpPr>\n        <p:spPr>\n          <a:xfrm>\n            <a:off x="685800" y="411480"/>\n            <a:ext cx="10886400" cy="1143000"/>\n          </a:xfrm>\n        </p:spPr>\n        <p:txBody>\n          <a:bodyPr wrap="square"/>\n          <a:lstStyle/>\n          <a:p>\n            <a:pPr algn="ctr"/>\n            <a:r>\n              <a:rPr lang="en-US" sz="5200" b="1"/>\n              <a:t>{title}</a:t>\n            </a:r>\n            <a:endParaRPr lang="en-US" sz="5200"/>\n          </a:p>\n        </p:txBody>\n      </p:sp>'''
    body_box = f'''      <p:sp>\n        <p:nvSpPr>\n          <p:cNvPr id="3" name="Content {idx}"/>\n          <p:cNvSpPr txBox="1"/>\n          <p:nvPr/>\n        </p:nvSpPr>\n        <p:spPr>\n          <a:xfrm>\n            <a:off x="685800" y="1651000"/>\n            <a:ext cx="10886400" cy="3302000"/>\n          </a:xfrm>\n        </p:spPr>\n        <p:txBody>\n          <a:bodyPr wrap="square"/>\n          <a:lstStyle/>\n{paragraphs}\n        </p:txBody>\n      </p:sp>'''
    image_xml = ''
    if slide["image"]:
        img = slide["image"]
        image_xml = f'''      <p:pic>\n        <p:nvPicPr>\n          <p:cNvPr id="4" name="{saxutils.escape(img['name'])}"/>\n          <p:cNvPicPr/>\n          <p:nvPr/>\n        </p:nvPicPr>\n        <p:blipFill>\n          <a:blip r:embed="{img['rid']}"/>\n          <a:stretch><a:fillRect/></a:stretch>\n        </p:blipFill>\n        <p:spPr>\n          <a:xfrm>\n            <a:off x="{img['x']}" y="{img['y']}"/>\n            <a:ext cx="{img['cx']}" cy="{img['cy']}"/>\n          </a:xfrm>\n          <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>\n        </p:spPr>\n      </p:pic>'''
    slide_xml = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:bg>
      <p:bgPr>
        <a:solidFill><a:srgbClr val="0F172A"/></a:solidFill>
      </p:bgPr>
    </p:bg>
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
{title_box}
{body_box}
{image_xml}
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr>
    <a:masterClrMapping/>
  </p:clrMapOvr>
</p:sld>
'''
    return slide_xml

slide_rel_template = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>{image_rel}
</Relationships>
'''

for idx, slide in enumerate(slides, start=1):
    files[f'ppt/slides/slide{idx}.xml'] = build_slide_xml(idx, slide)
    if slide["image"]:
        image_rel = f"\n  <Relationship Id=\"{slide['image']['rid']}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image\" Target=\"../media/{Path(slide['image']['path']).name}\"/>"
    else:
        image_rel = ''
    files[f'ppt/slides/_rels/slide{idx}.xml.rels'] = slide_rel_template.format(image_rel=image_rel)

for slide in slides:
    if slide["image"]:
        files[slide["image"]["path"]] = slide["image"]["source"].read_text(encoding='utf-8')

pptx_path = root / 'Trimline_Parcel_Presentation.pptx'
with ZipFile(pptx_path, 'w', ZIP_DEFLATED) as zf:
    for path, content in files.items():
        data = content.encode('utf-8') if isinstance(content, str) else content
        zf.writestr(path, data)

print(f'Generated {pptx_path}')
