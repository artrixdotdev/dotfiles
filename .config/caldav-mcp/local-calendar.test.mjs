import test from 'node:test';
import assert from 'node:assert/strict';
import { resolveTimezone, calendarContext, parseFeed, subscriptionsFromXml } from './local-calendar.mjs';
const zone = 'America/Los_Angeles';
test('UTC host uses private fallback; TZ and non-UTC system follow local settings', () => {
  const env = { CALENDAR_TIMEZONE_MODE: 'auto', CALENDAR_TIMEZONE_FALLBACK: zone };
  assert.equal(resolveTimezone(env, 'UTC').timezone, zone);
  assert.equal(resolveTimezone(env, 'Europe/Paris').timezone, 'Europe/Paris');
  assert.equal(resolveTimezone({ ...env, TZ: 'Asia/Tokyo' }, 'UTC').timezone, 'Asia/Tokyo');
  assert.throws(() => resolveTimezone({}, 'UTC'));
});
test('local today differs from UTC; DST days have correct lengths', () => {
  const ctx = calendarContext(new Date('2026-09-10T04:00:00Z'), { timezone: zone });
  assert.equal(ctx.local_date, '2026-09-09');
  assert.equal(ctx.today_start, '2026-09-09T07:00:00.000Z');
  assert.equal(ctx.today_end, '2026-09-10T07:00:00.000Z');
  for (const [date,hours] of [['2026-03-08T12:00:00Z',23],['2026-11-01T12:00:00Z',25]]) {
    const c=calendarContext(new Date(date),{timezone:zone});
    assert.equal((Date.parse(c.today_end)-Date.parse(c.today_start))/3600000,hours);
  }
});
const feed = `BEGIN:VCALENDAR\r\nVERSION:2.0\r\nBEGIN:VEVENT\r\nUID:today\r\nDTSTART;VALUE=DATE:20260909\r\nSUMMARY:Today\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\nUID:tomorrow\r\nDTSTART;VALUE=DATE;VALUE=DATE:20260910\r\nSUMMARY:Tomorrow\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\nUID:late\r\nDTSTART:20260910T065900Z\r\nDTEND:20260910T065900Z\r\nSUMMARY:Late deadline\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\nUID:boundary\r\nDTSTART:20260910T070000Z\r\nSUMMARY:Tomorrow timed\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n`;
test('all-day and zero-duration deadlines respect local day and exclusive range end', () => {
  const events=parseFeed(feed,{start:'2026-09-09T07:00:00Z',end:'2026-09-10T07:00:00Z'},zone);
  assert.deepEqual(events.map(e=>e.uid),['today','late']);
  assert.equal(events[0].start,'2026-09-09T07:00:00.000Z');
  assert.equal(events[0].end,'2026-09-10T07:00:00.000Z');
});
test('subscription discovery handles XML namespace prefixes and escaped URLs', () => {
  const xml='<a:multistatus xmlns:a="DAV:" xmlns:b="http://calendarserver.org/ns/"><a:response><a:href>/cal/sub/</a:href><a:propstat><a:prop><a:displayname>School</a:displayname><a:resourcetype><b:subscribed/></a:resourcetype><b:source><a:href>webcal://school.example/feed?a=1&amp;b=2</a:href></b:source></a:prop><a:status>HTTP/1.1 200 OK</a:status></a:propstat></a:response></a:multistatus>';
  assert.deepEqual(subscriptionsFromXml(xml,'https://dav.example'),[{url:'https://dav.example/cal/sub/',displayName:'School',source:'https://school.example/feed?a=1&b=2'}]);
});
