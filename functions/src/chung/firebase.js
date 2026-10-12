'use strict';

const admin = require('firebase-admin');
const { getFirestore, FieldValue, Timestamp, GeoPoint } = require('firebase-admin/firestore');

if (!admin.apps.length) admin.initializeApp();

const db = getFirestore();

/** Firestore Timestamp / Date / số → mili giây (null nếu không có). */
function ms(v) {
  if (v == null) return null;
  if (typeof v === 'number') return v;
  if (v instanceof Date) return v.getTime();
  if (typeof v.toMillis === 'function') return v.toMillis();
  return null;
}

/** mili giây → Timestamp (giữ nguyên null). */
function ts(v) {
  return v == null ? null : Timestamp.fromMillis(v);
}

module.exports = { admin, db, FieldValue, Timestamp, GeoPoint, ms, ts };
