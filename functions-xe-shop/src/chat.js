// Chat Shop / Xe dọn trọ: `chats/{chatId}` + `chats/{chatId}/messages` (mục 7.3, dùng chung).
// Mở chat, gửi tin, đánh dấu đã đọc đều qua hệ thống; app chỉ đọc (theo firestore.rules).
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { khongCoQuyen, khongTimThay, loi, thamSoSai } from './loi.js';
import { chuoi } from './kiem_tra.js';

const chats = () => getFirestore().collection('chats');

/** Một cuộc trò chuyện cho mỗi cặp người trong mỗi module: id không phụ thuộc ai mở trước. */
export const idChat = (module, a, b) => `${module}_${[a, b].sort().join('_')}`;

async function tenCua(uid) {
  const db = getFirestore();
  const [xt, user] = await Promise.all([
    db.collection('xac_thuc').doc(uid).get(),
    db.collection('users').doc(uid).get(),
  ]);
  return xt.get('hoTenXacThuc') || user.get('name') || 'Người dùng';
}

/**
 * Một trong hai người phải là người bán (có sản phẩm) với Shop, hoặc tài xế (có hồ sơ) với Xe,
 * để không ai dùng chat như kênh nhắn tin tự do.
 */
async function coNguoiCungCap(module, ids) {
  const db = getFirestore();
  if (module === 'xe') {
    const snaps = await Promise.all(ids.map((id) => db.collection('xe_don_tro').doc(id).get()));
    return snaps.some((s) => s.exists);
  }
  const qs = await Promise.all(ids.map((id) => db.collection('products').where('shopId', '==', id).limit(1).get()));
  return qs.some((q) => !q.empty);
}

/** Mở (hoặc lấy lại) cuộc trò chuyện với `tham.otherId`; trả về chatId. */
export async function moChat(module, nd, tham) {
  const otherId = chuoi(tham.otherId, 'Người nhận', { max: 128 });
  if (otherId === nd.uid) throw loi('Không thể tự nhắn cho chính mình.');
  const id = idChat(module, nd.uid, otherId);
  const ref = chats().doc(id);
  if ((await ref.get()).exists) return { id };
  if (!(await coNguoiCungCap(module, [nd.uid, otherId]))) {
    throw loi(module === 'xe' ? 'Chỉ nhắn được với tài xế.' : 'Chỉ nhắn được với người bán.');
  }
  await ref.set({
    module,
    participantIds: [nd.uid, otherId].sort(),
    names: { [nd.uid]: nd.ten, [otherId]: await tenCua(otherId) },
    lastMessage: '',
    lastSenderId: null,
    unread: { [nd.uid]: 0, [otherId]: 0 },
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { id };
}

async function cuaToi(module, nd, chatId, tx) {
  const ref = chats().doc(chuoi(chatId, 'Cuộc trò chuyện', { max: 300 }));
  const snap = await tx.get(ref);
  if (!snap.exists || snap.get('module') !== module) throw khongTimThay('Cuộc trò chuyện');
  if (!snap.get('participantIds').includes(nd.uid)) throw khongCoQuyen();
  return snap;
}

export async function guiTin(module, nd, tham) {
  const text = chuoi(tham.text, 'Tin nhắn', { max: 1000 });
  let id;
  await getFirestore().runTransaction(async (tx) => {
    const snap = await cuaToi(module, nd, tham.chatId, tx);
    const nguoiKia = snap.get('participantIds').find((p) => p !== nd.uid);
    const msg = snap.ref.collection('messages').doc();
    id = msg.id;
    tx.create(msg, { senderId: nd.uid, text, createdAt: FieldValue.serverTimestamp() });
    tx.update(snap.ref, {
      lastMessage: text.slice(0, 200),
      lastSenderId: nd.uid,
      [`unread.${nguoiKia}`]: FieldValue.increment(1),
      [`unread.${nd.uid}`]: 0,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return { id };
}

export async function daDoc(module, nd, tham) {
  if (typeof tham.chatId !== 'string') throw thamSoSai();
  await getFirestore().runTransaction(async (tx) => {
    const snap = await cuaToi(module, nd, tham.chatId, tx);
    if ((snap.get('unread') ?? {})[nd.uid]) tx.update(snap.ref, { [`unread.${nd.uid}`]: 0 });
  });
  return {};
}
