'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { quet } = require('../src/tro/logic/canh_bao_chat');

test('bắt "chuyển khoản" dù viết không dấu, tách chữ, viết tắt', () => {
  for (const s of ['Em chuyển khoản trước nhé', 'chuyen khoan', 'c.h.u.y.e.n k.h.o.a.n giúp anh', 'CK trước cho anh', 'c.k nha']) {
    assert.ok(quet(s).length, s);
  }
});

test('không bắt "check", "tick" (CK khớp nguyên từ)', () => {
  assert.deepEqual(quet('Em check lại rồi, tick giúp anh'), []);
});

test('momo: "trả bằng momo trên app" không cảnh báo, "chuyển momo trước cho anh" có cảnh báo', () => {
  assert.deepEqual(quet('Em trả bằng momo trên app nha'), []);
  assert.deepEqual(quet('chuyển momo trước cho anh'), ['momo']);
});

test('bắt số tài khoản, STK, zalo, QR, cọc trước', () => {
  assert.ok(quet('Gửi STK đi').includes('stk'));
  assert.ok(quet('kết bạn Zalo nha').includes('zalo'));
  assert.ok(quet('quét QR').includes('qr'));
  assert.ok(quet('Cọc trước 500k').includes('coc truoc'));
});
