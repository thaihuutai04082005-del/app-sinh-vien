// UniHub beta: phục vụ web app Flutter (static assets) + API ảnh và dữ liệu trên Workers KV
// (KV có trong gói Free, không cần thẻ; R2 thì bắt buộc thêm phương thức thanh toán).
//   POST /api/upload                 multipart: file, folder  -> { url, key }
//   GET  /images/<key>                                        -> ảnh từ KV
//   GET  /videos/<key>                                        -> video từ KV (hỗ trợ Range để tua)
//   GET  /api/<collection>                                    -> { items: [...] } mới nhất trước
//   GET  /api/<collection>/<id>                               -> document
//   POST /api/<collection>           JSON                     -> document đã tạo
// <collection>: products | booking_xe. Tên field khớp mục 7.3 để sau này chuyển sang Firestore.
// Tạm lưu mỗi document là 1 giá trị JSON trên KV cho bản demo; chưa có đăng nhập.
// Giới hạn KV Free: 1.000 lượt ghi/ngày, 100.000 lượt đọc/ngày, 1 GB.

const MB = 1024 * 1024;
const MAX_IMAGE_BYTES = 5 * MB;
// KV giới hạn 25 MiB mỗi giá trị, tương đương video điện thoại khoảng 30–60 giây.
const MAX_VIDEO_BYTES = 25 * MB;
const FOLDERS = new Set(['products', 'booking_xe']);

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Range',
  'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Accept-Ranges',
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (/^\/(api|images|videos)\//.test(url.pathname)) {
      if (request.method === 'OPTIONS') {
        return new Response(null, { status: 204, headers: CORS_HEADERS });
      }
      if (url.pathname === '/api/upload' && request.method === 'POST') {
        return upload(request, env, url);
      }
      const media = url.pathname.match(/^\/(images|videos)\/(.+)$/);
      if (media && request.method === 'GET') {
        return serveMedia(request, env, media[1] === 'images' ? 'img' : 'vid', media[2]);
      }
      const match = url.pathname.match(/^\/api\/([a-z_]+)(?:\/([A-Za-z0-9-]+))?$/);
      const schema = match && COLLECTIONS[match[1]];
      if (schema) {
        const [, collection, id] = match;
        if (request.method === 'GET') {
          return id ? getDocument(env, collection, id) : listDocuments(env, collection);
        }
        if (request.method === 'POST' && !id) {
          return createDocument(request, env, collection, schema);
        }
      }
      return json({ error: 'Không tìm thấy.' }, 404);
    }

    return env.ASSETS.fetch(request);
  },
};

async function upload(request, env, url) {
  const declaredLength = Number(request.headers.get('Content-Length') ?? 0);
  if (declaredLength > MAX_VIDEO_BYTES + 64 * 1024) {
    return json({ error: 'File vượt quá 25 MB.' }, 413);
  }

  let form;
  try {
    form = await request.formData();
  } catch {
    return json({ error: 'Dữ liệu gửi lên không hợp lệ.' }, 400);
  }

  const folder = form.get('folder');
  const file = form.get('file');
  if (!FOLDERS.has(folder)) {
    return json({ error: 'Thư mục không hợp lệ.' }, 400);
  }
  if (!(file instanceof File) || file.size === 0) {
    return json({ error: 'Chưa có file.' }, 400);
  }

  const bytes = new Uint8Array(await file.arrayBuffer());
  const type = detectMediaType(bytes);
  if (!type) {
    return json({ error: 'Chỉ chấp nhận ảnh JPG, PNG, WEBP, GIF hoặc video MP4, MOV, WEBM.' }, 415);
  }
  const isVideo = type.mime.startsWith('video/');
  if (bytes.length > (isVideo ? MAX_VIDEO_BYTES : MAX_IMAGE_BYTES)) {
    return json({ error: isVideo ? 'Video vượt quá 25 MB.' : 'Ảnh vượt quá 5 MB.' }, 413);
  }

  const key = `${folder}/${crypto.randomUUID()}.${type.ext}`;
  await env.STORE.put(`${isVideo ? 'vid' : 'img'}:${key}`, bytes, {
    metadata: { contentType: type.mime },
  });

  // Qua Cloudflare Tunnel, wrangler dev chỉ thấy http; dùng proto gốc để URL là https.
  const proto = request.headers.get('X-Forwarded-Proto') === 'https' ? 'https:' : url.protocol;
  const path = isVideo ? 'videos' : 'images';
  return json({ url: `${proto}//${url.host}/${path}/${key}`, key }, 200);
}

async function serveMedia(request, env, prefix, key) {
  const { value, metadata } = await env.STORE.getWithMetadata(`${prefix}:${key}`, {
    type: 'arrayBuffer',
    cacheTtl: 86400,
  });
  if (!value) return json({ error: 'Không tìm thấy file.' }, 404);

  const headers = new Headers(CORS_HEADERS);
  headers.set('Content-Type', metadata?.contentType ?? 'application/octet-stream');
  // Tên file là UUID, không bao giờ bị ghi đè nên cache lâu được.
  headers.set('Cache-Control', 'public, max-age=31536000, immutable');
  headers.set('X-Content-Type-Options', 'nosniff');
  headers.set('Accept-Ranges', 'bytes');

  // Trình duyệt (nhất là Safari/iPhone) cần Range để phát và tua video.
  const total = value.byteLength;
  const range = request.headers.get('Range')?.match(/^bytes=(\d*)-(\d*)$/);
  if (range && (range[1] || range[2])) {
    let start = range[1] ? Number(range[1]) : total - Number(range[2]);
    let end = range[1] && range[2] ? Number(range[2]) : total - 1;
    start = Math.max(0, start);
    end = Math.min(end, total - 1);
    if (start > end) {
      headers.set('Content-Range', `bytes */${total}`);
      return new Response(null, { status: 416, headers });
    }
    headers.set('Content-Range', `bytes ${start}-${end}/${total}`);
    return new Response(value.slice(start, end + 1), { status: 206, headers });
  }
  return new Response(value, { headers });
}

// Nhận diện theo nội dung file (magic bytes), không tin tên file/Content-Type do client gửi.
export function detectMediaType(b) {
  if (b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) {
    return { ext: 'jpg', mime: 'image/jpeg' };
  }
  if (b.length >= 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47) {
    return { ext: 'png', mime: 'image/png' };
  }
  if (b.length >= 6 && b[0] === 0x47 && b[1] === 0x49 && b[2] === 0x46 && b[3] === 0x38) {
    return { ext: 'gif', mime: 'image/gif' };
  }
  if (
    b.length >= 12 &&
    String.fromCharCode(...b.slice(0, 4)) === 'RIFF' &&
    String.fromCharCode(...b.slice(8, 12)) === 'WEBP'
  ) {
    return { ext: 'webp', mime: 'image/webp' };
  }
  // MP4/MOV: hộp "ftyp" ở byte 4; brand "qt  " là video quay từ iPhone.
  if (b.length >= 12 && String.fromCharCode(...b.slice(4, 8)) === 'ftyp') {
    return String.fromCharCode(...b.slice(8, 12)) === 'qt  '
      ? { ext: 'mov', mime: 'video/quicktime' }
      : { ext: 'mp4', mime: 'video/mp4' };
  }
  if (b.length >= 4 && b[0] === 0x1a && b[1] === 0x45 && b[2] === 0xdf && b[3] === 0xa3) {
    return { ext: 'webm', mime: 'video/webm' };
  }
  return null;
}

const MAX_DOC_BYTES = 16 * 1024;
const LIST_LIMIT = 50;

const str = (max) => (v) => typeof v === 'string' && v.trim().length > 0 && v.length <= max;
const mediaList = (path, min, max) => (v) =>
  Array.isArray(v) && v.length >= min && v.length <= max &&
  v.every((u) => typeof u === 'string' && u.length <= 300 && u.includes(`/${path}/`));
const imageList = (max) => mediaList('images', 1, max);
// `videos` chưa có trong mục 7.3: field bổ sung, không bắt buộc, tối đa 1 video.
const videoList = mediaList('videos', 0, 1);

// Field client được gửi lên + điều kiện hợp lệ. id, status, createdAt do server gán.
const COLLECTIONS = {
  products: {
    fields: {
      name: str(120),
      images: imageList(8),
      price: (v) => Number.isInteger(v) && v > 0 && v <= 100_000_000,
      sizes: (v) => Array.isArray(v) && v.length <= 10 && v.every(str(20)),
      stock: (v) => Number.isInteger(v) && v >= 0 && v <= 100_000,
      category: (v) => ['ao', 'quan', 'phu_kien'].includes(v),
      videos: videoList,
    },
    build: (doc) => ({
      shopId: '',
      ...doc,
      status: doc.stock > 0 ? 'active' : 'out_of_stock',
    }),
  },
  booking_xe: {
    fields: {
      fromAddress: str(200),
      toAddress: str(200),
      itemPhotos: imageList(6),
      scheduledAt: (v) => typeof v === 'string' && !Number.isNaN(Date.parse(v)),
      videos: videoList,
    },
    build: (doc) => ({
      userId: '',
      driverId: '',
      quotedPrice: null,
      ...doc,
      status: 'pending',
    }),
  },
};

async function createDocument(request, env, collection, schema) {
  const raw = await request.text();
  if (raw.length > MAX_DOC_BYTES) return json({ error: 'Dữ liệu quá lớn.' }, 413);

  let input;
  try {
    input = JSON.parse(raw);
  } catch {
    return json({ error: 'Dữ liệu không hợp lệ.' }, 400);
  }

  const doc = {};
  for (const [field, isValid] of Object.entries(schema.fields)) {
    let value = typeof input?.[field] === 'string' ? input[field].trim() : input?.[field];
    if (field === 'videos' && value === undefined) value = [];
    if (!isValid(value)) return json({ error: `Trường "${field}" không hợp lệ.` }, 400);
    doc[field] = value;
  }

  // id bắt đầu bằng thời gian đảo ngược để KV list (sắp theo key) trả về bài mới nhất trước.
  const now = Date.now();
  const id = `${String(9_999_999_999_999 - now).padStart(13, '0')}-${crypto.randomUUID().slice(0, 8)}`;
  const saved = { id, ...schema.build(doc), createdAt: new Date(now).toISOString() };

  await env.STORE.put(`data:${collection}/${id}`, JSON.stringify(saved));
  return json(saved, 201);
}

async function listDocuments(env, collection) {
  const listed = await env.STORE.list({ prefix: `data:${collection}/`, limit: LIST_LIMIT });
  const items = await Promise.all(
    listed.keys.map(({ name }) => env.STORE.get(name, { type: 'json', cacheTtl: 60 })),
  );
  return json({ items: items.filter(Boolean) }, 200);
}

async function getDocument(env, collection, id) {
  const doc = await env.STORE.get(`data:${collection}/${id}`, { type: 'json' });
  if (!doc) return json({ error: 'Không tìm thấy.' }, 404);
  return json(doc, 200);
}

function json(body, status) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json; charset=utf-8' },
  });
}
