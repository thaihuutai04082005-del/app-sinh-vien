import assert from 'node:assert/strict';
import { test } from 'node:test';
import { idChat } from '../src/chat.js';

test('mỗi cặp người một cuộc trò chuyện mỗi module, ai mở trước cũng vậy', () => {
  assert.equal(idChat('shop', 'b', 'a'), 'shop_a_b');
  assert.equal(idChat('shop', 'a', 'b'), 'shop_a_b');
  assert.notEqual(idChat('xe', 'a', 'b'), idChat('shop', 'a', 'b'));
});
