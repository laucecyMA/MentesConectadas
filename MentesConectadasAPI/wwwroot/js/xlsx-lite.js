// ===== EXPORTAR A EXCEL =====

const esc = (s) => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]))
  .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '');

const letra = (n) => { let s = ''; for (n++; n > 0; n = Math.floor((n - 1) / 26)) s = String.fromCharCode(65 + (n - 1) % 26) + s; return s; };

// ----- Archivo ZIP -----
const TABLA_CRC = (() => { const t = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
const crc32 = (bytes) => { let c = 0xFFFFFFFF; for (let i = 0; i < bytes.length; i++) c = TABLA_CRC[(c ^ bytes[i]) & 0xFF] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; };

function zip(archivos) {
  const enc = new TextEncoder();
  const ahora = new Date();
  const hora = (ahora.getHours() << 11) | (ahora.getMinutes() << 5) | (ahora.getSeconds() >> 1);
  const fecha = ((ahora.getFullYear() - 1980) << 9) | ((ahora.getMonth() + 1) << 5) | ahora.getDate();
  const partes = [], central = [];
  let pos = 0;
  for (const [nombre, contenido] of archivos) {
    const n = enc.encode(nombre), d = enc.encode(contenido), crc = crc32(d);
    const local = new DataView(new ArrayBuffer(30));
    local.setUint32(0, 0x04034B50, true); local.setUint16(4, 20, true); local.setUint16(6, 0x0800, true); local.setUint16(8, 0, true);
    local.setUint16(10, hora, true); local.setUint16(12, fecha, true); local.setUint32(14, crc, true);
    local.setUint32(18, d.length, true); local.setUint32(22, d.length, true); local.setUint16(26, n.length, true); local.setUint16(28, 0, true);
    partes.push(new Uint8Array(local.buffer), n, d);
    const cd = new DataView(new ArrayBuffer(46));
    cd.setUint32(0, 0x02014B50, true); cd.setUint16(4, 20, true); cd.setUint16(6, 20, true); cd.setUint16(8, 0x0800, true); cd.setUint16(10, 0, true);
    cd.setUint16(12, hora, true); cd.setUint16(14, fecha, true); cd.setUint32(16, crc, true);
    cd.setUint32(20, d.length, true); cd.setUint32(24, d.length, true); cd.setUint16(28, n.length, true);
    cd.setUint32(42, pos, true);
    central.push(new Uint8Array(cd.buffer), n);
    pos += 30 + n.length + d.length;
  }
  const tam = central.reduce((s, p) => s + p.length, 0);
  const fin = new DataView(new ArrayBuffer(22));
  fin.setUint32(0, 0x06054B50, true); fin.setUint16(8, archivos.length, true); fin.setUint16(10, archivos.length, true);
  fin.setUint32(12, tam, true); fin.setUint32(16, pos, true);
  return new Blob([...partes, ...central, new Uint8Array(fin.buffer)], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
}

// ----- Estilos -----
const FORMATOS = { entero: 1, decimal: 164, porcentaje: 165, dinero: 166 };
function crearEstilos() {
  const fuentes = [], rellenos = ['<fill><patternFill patternType="none"/></fill>', '<fill><patternFill patternType="gray125"/></fill>'], bordes = ['<border><left/><right/><top/><bottom/><diagonal/></border>'], xfs = ['<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'];
  const mapa = new Map();
  const reg = (lista, xml) => { let i = lista.indexOf(xml); if (i < 0) { i = lista.length; lista.push(xml); } return i; };
  reg(fuentes, '<font><sz val="11"/><color rgb="FF1B2442"/><name val="Calibri"/><family val="2"/></font>');
  const indice = (e = {}) => {
    const clave = JSON.stringify(e);
    if (mapa.has(clave)) return mapa.get(clave);
    const fuente = reg(fuentes, `<font>${e.negrita ? '<b/>' : ''}${e.cursiva ? '<i/>' : ''}<sz val="${e.tam || 11}"/><color rgb="FF${e.color || '1B2442'}"/><name val="Calibri"/><family val="2"/></font>`);
    const relleno = e.fondo ? reg(rellenos, `<fill><patternFill patternType="solid"><fgColor rgb="FF${e.fondo}"/><bgColor indexed="64"/></patternFill></fill>`) : 0;
    let borde = 0;
    if (e.borde && e.borde !== 'ninguno') { const l = (lado) => `<${lado} style="thin"><color rgb="FF${e.borde}"/></${lado}>`; borde = reg(bordes, `<border>${l('left')}${l('right')}${l('top')}${l('bottom')}<diagonal/></border>`); }
    if (e.bordeInferior) borde = reg(bordes, `<border><left/><right/><top/><bottom style="medium"><color rgb="FF${e.bordeInferior}"/></bottom><diagonal/></border>`);
    const fmt = FORMATOS[e.formato] || 0;
    const xf = `<xf numFmtId="${fmt}" fontId="${fuente}" fillId="${relleno}" borderId="${borde}" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"${fmt ? ' applyNumberFormat="1"' : ''}><alignment horizontal="${e.h || 'left'}" vertical="${e.v || 'center'}"${e.ajustar ? ' wrapText="1"' : ''}${e.sangria ? ` indent="${e.sangria}"` : ''}/></xf>`;
    xfs.push(xf);
    mapa.set(clave, xfs.length - 1);
    return xfs.length - 1;
  };
  const xml = () => `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><numFmts count="3"><numFmt numFmtId="164" formatCode="0.0"/><numFmt numFmtId="165" formatCode="0&quot;%&quot;"/><numFmt numFmtId="166" formatCode="&quot;$&quot;#,##0"/></numFmts><fonts count="${fuentes.length}">${fuentes.join('')}</fonts><fills count="${rellenos.length}">${rellenos.join('')}</fills><borders count="${bordes.length}">${bordes.join('')}</borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="${xfs.length}">${xfs.join('')}</cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>`;
  return { indice, xml };
}

// ----- Libro y hojas -----
export function crearLibro() {
  const estilos = crearEstilos();
  const hojas = [];
  return {
    estilos,
    hojas,
    hoja(nombre, opciones = {}) {
      const h = { nombre: esc(nombre).slice(0, 31), opciones, filas: [], combinadas: [], filtro: '' };
      h.fila = (celdas = [], op = {}) => { h.filas.push({ celdas, alto: op.alto }); return h.filas.length; };
      h.combinar = (rango) => h.combinadas.push(rango);
      h.autoFiltro = (rango) => { h.filtro = rango; };
      hojas.push(h);
      return h;
    }
  };
}

function xmlHoja(h, estilos, nHoja) {
  const o = h.opciones;
  const filas = h.filas.map((f, i) => {
    const celdas = f.celdas.map((c, j) => {
      if (c === null || c === undefined) return '';
      const cel = typeof c === 'object' ? c : { v: c };
      const s = estilos.indice(cel.e || {});
      const ref = letra(j) + (i + 1);
      if (cel.v === null || cel.v === undefined || cel.v === '') return `<c r="${ref}" s="${s}"/>`;
      if (typeof cel.v === 'number' && isFinite(cel.v)) return `<c r="${ref}" s="${s}"><v>${cel.v}</v></c>`;
      return `<c r="${ref}" s="${s}" t="inlineStr"><is><t xml:space="preserve">${esc(cel.v)}</t></is></c>`;
    }).join('');
    return `<row r="${i + 1}"${f.alto ? ` ht="${f.alto}" customHeight="1"` : ''}>${celdas}</row>`;
  }).join('');
  const columnas = (o.anchos || []).map((w, i) => `<col min="${i + 1}" max="${i + 1}" width="${w}" customWidth="1"/>`).join('');
  const congelar = o.congelarFilas
    ? `<pane ySplit="${o.congelarFilas}" topLeftCell="A${o.congelarFilas + 1}" activePane="bottomLeft" state="frozen"/><selection pane="bottomLeft" activeCell="A${o.congelarFilas + 1}" sqref="A${o.congelarFilas + 1}"/>`
    : '';
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetPr>${o.color ? `<tabColor rgb="FF${o.color}"/>` : ''}<pageSetUpPr fitToPage="1"/></sheetPr><sheetViews><sheetView workbookViewId="0"${o.sinCuadricula ? ' showGridLines="0"' : ''}${nHoja === 0 ? ' tabSelected="1"' : ''}>${congelar}</sheetView></sheetViews><sheetFormatPr defaultRowHeight="18"/>${columnas ? `<cols>${columnas}</cols>` : ''}<sheetData>${filas}</sheetData>${h.filtro ? `<autoFilter ref="${h.filtro}"/>` : ''}${h.combinadas.length ? `<mergeCells count="${h.combinadas.length}">${h.combinadas.map(r => `<mergeCell ref="${r}"/>`).join('')}</mergeCells>` : ''}<pageMargins left="0.5" right="0.5" top="0.6" bottom="0.6" header="0.3" footer="0.3"/><pageSetup orientation="landscape" fitToWidth="1" fitToHeight="0"/></worksheet>`;
}

export function libroABlob(libro) {
  const hojasXml = libro.hojas.map((h, i) => xmlHoja(h, libro.estilos, i));
  const n = libro.hojas.length;
  const archivos = [
    ['[Content_Types].xml', `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>${libro.hojas.map((_, i) => `<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`).join('')}<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>`],
    ['_rels/.rels', `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>`],
    ['xl/workbook.xml', `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><bookViews><workbookView xWindow="0" yWindow="0" windowWidth="24000" windowHeight="12000"/></bookViews><sheets>${libro.hojas.map((h, i) => `<sheet name="${h.nombre}" sheetId="${i + 1}" r:id="rId${i + 1}"/>`).join('')}</sheets></workbook>`],
    ['xl/_rels/workbook.xml.rels', `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${libro.hojas.map((_, i) => `<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>`).join('')}<Relationship Id="rId${n + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>`],
    ['xl/styles.xml', libro.estilos.xml()],
    ...hojasXml.map((x, i) => [`xl/worksheets/sheet${i + 1}.xml`, x])
  ];
  return zip(archivos);
}

export function descargarXlsx(libro, nombre) {
  const blob = libroABlob(libro);
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = nombre;
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
