import fs from 'node:fs';
import { xml2js } from 'xml-js';
import { getLocalDateParts, zonedTimeToUtc, formatInTimezone } from '@miguelarios/pim-core';
import { parseIcsEvents } from '@miguelarios/pim-core/ics';
import { CalDavService } from './node_modules/@miguelarios/cal-mcp/dist/services/CalDavService.js';

function validZone(zone) {
  if (!zone) return false;
  try { new Intl.DateTimeFormat('en', { timeZone: zone }); return true; } catch { return false; }
}
export function resolveTimezone(env = process.env, systemZone) {
  const mode = env.CALENDAR_TIMEZONE_MODE || 'auto';
  if (mode !== 'auto') {
    if (!validZone(mode)) throw Error('Invalid private calendar timezone');
    return { timezone: mode, timezone_source: 'configured' };
  }
  if (env.TZ && validZone(env.TZ)) return { timezone: env.TZ, timezone_source: 'TZ environment' };
  if (systemZone === undefined) {
    try { systemZone = fs.realpathSync('/etc/localtime').split('/zoneinfo/')[1]; } catch {}
    if (!systemZone) {
      try { systemZone = fs.readFileSync('/etc/timezone', 'utf8').trim(); } catch {}
    }
  }
  if (validZone(systemZone) && !['UTC', 'Etc/UTC', 'Etc/GMT', 'GMT'].includes(systemZone))
    return { timezone: systemZone, timezone_source: 'system' };
  const fallback = env.CALENDAR_TIMEZONE_FALLBACK;
  if (!validZone(fallback)) throw Error('UTC host: set timezone_fallback in private caldav.json to your IANA timezone');
  return { timezone: fallback, timezone_source: 'private fallback (host timezone is UTC or unavailable)' };
}
export function calendarContext(now = new Date(), resolved = resolveTimezone()) {
  const { timezone } = resolved;
  const { year, month, day } = getLocalDateParts(now, timezone);
  return { ...resolved, local_now: formatInTimezone(now.toISOString(), timezone),
    local_date: `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`,
    today_start: zonedTimeToUtc(year, month, day, 0, 0, timezone).toISOString(),
    today_end: zonedTimeToUtc(year, month, day + 1, 0, 0, timezone).toISOString() };
}
const children = (el, name) => (el?.elements || []).filter(e => e.type === 'element' && e.name.split(':').at(-1) === name);
const child = (el, name) => children(el, name)[0];
const value = el => (el?.elements || []).filter(e => ['text', 'cdata'].includes(e.type)).map(e => e.text ?? e.cdata).join('');
export function subscriptionsFromXml(xml, base) {
  const root = child(xml2js(xml), 'multistatus');
  if (!root) throw Error('Invalid subscription discovery response');
  return children(root, 'response').flatMap(response => {
    const prop = children(response, 'propstat').filter(p => / 200 /.test(value(child(p, 'status')))).map(p => child(p, 'prop'));
    const p = prop.find(p => child(child(p, 'resourcetype'), 'subscribed'));
    if (!p) return [];
    const source = value(child(child(p, 'source'), 'href')).replace(/^webcal:/, 'https:');
    const url = new URL(value(child(response, 'href')), base).href;
    return [{ url, displayName: value(child(p, 'displayname')) || 'Subscribed calendar', source }];
  });
}
export function parseFeed(data, range, timezone) {
  // Upstream anchors DATE at UTC midnight. Re-anchor all-day values before
  // filtering, otherwise tomorrow's all-day assignments appear this evening.
  const padded = range && { start: new Date(Date.parse(range.start) - 86400000).toISOString(), end: new Date(Date.parse(range.end) + 86400000).toISOString() };
  return parseIcsEvents(data, padded, timezone).map(event => {
    if (!event.all_day) return event;
    const midnight = iso => { const [y,m,d] = iso.slice(0,10).split('-').map(Number); return zonedTimeToUtc(y,m,d,0,0,timezone).toISOString(); };
    let end = event.end;
    if (end === event.start) end = new Date(Date.parse(end) + 86400000).toISOString();
    return { ...event, start: midnight(event.start), end: midnight(end) };
  }).filter(e => !range || (Date.parse(e.start) < Date.parse(range.end) &&
    (Date.parse(e.end) > Date.parse(range.start) || (e.start === e.end && Date.parse(e.start) >= Date.parse(range.start)))));
}
export class LocalCalendarService extends CalDavService {
  subscriptions = new Map();
  feedCache = new Map();
  constructor(config, feedFetch) { super(config); this.feedFetch = feedFetch; }
  async getClient(account) {
    const client = await super.getClient(account);
    if (client.localSubscriptions) return client;
    client.localSubscriptions = true;
    const fetchCalendars = client.fetchCalendars.bind(client);
    const fetchObjects = client.fetchCalendarObjects.bind(client);
    client.fetchCalendars = async (...args) => {
      const calendars = await fetchCalendars(...args);
      const response = await fetch(client.account.homeUrl, { method: 'PROPFIND',
        headers: { Depth: '1', 'Content-Type': 'application/xml', Authorization: `Basic ${Buffer.from(`${account.username}:${account.password}`).toString('base64')}` },
        body: '<d:propfind xmlns:d="DAV:" xmlns:cs="http://calendarserver.org/ns/"><d:prop><d:displayname/><d:resourcetype/><cs:source/></d:prop></d:propfind>' });
      if (!response.ok) throw Error('Linked calendar discovery failed');
      const subscriptions = subscriptionsFromXml(await response.text(), account.url);
      for (const [url, sub] of this.subscriptions) if (sub.provider === account.id) this.subscriptions.delete(url);
      for (const sub of subscriptions) {
        this.subscriptions.set(sub.url, { ...sub, provider: account.id });
        calendars.push({ url: sub.url, displayName: sub.displayName, components: ['VEVENT'] });
      }
      return calendars;
    };
    client.fetchCalendarObjects = async options => {
      const sub = this.subscriptions.get(options.calendar.url);
      if (!sub) return fetchObjects(options);
      return [{ url: sub.url, data: await this.readFeed(sub) }];
    };
    return client;
  }
  async readFeed(sub) {
    const cached = this.feedCache.get(sub.source);
    if (cached && Date.now() - cached.time < 60000) return cached.data;
    try {
      const data = await this.feedFetch(sub.source);
      if (!data.includes('BEGIN:VCALENDAR')) throw Error();
      this.feedCache.set(sub.source, { data, time: Date.now() });
      return data;
    } catch { throw Error('Linked calendar feed could not be read; results are incomplete. Check private allowed_subscription_origins.'); }
  }
  async fetchPrivileges(client, url) {
    if (this.subscriptions.has(url)) return false;
    return super.fetchPrivileges(client, url);
  }
  async subscription(calendarId) {
    const { account, calendarName } = this.resolveAccount(calendarId);
    const client = await this.getClient(account);
    const calendar = await this.findCalendar(client, calendarName, account.id);
    return this.subscriptions.get(calendar.url);
  }
  async listEventsFull(id, start, end) {
    const sub = await this.subscription(id);
    if (!sub) return super.listEventsFull(id, start, end);
    return parseFeed(await this.readFeed(sub), { start, end }, this.timezone).map(e => this.toEventFull(e, id));
  }
  async listEvents(id, start, end) {
    const sub = await this.subscription(id);
    if (!sub) return super.listEvents(id, start, end);
    return this.listEventsFull(id, start, end);
  }
  async getEvent(id, uid) {
    const sub = await this.subscription(id);
    if (!sub) return super.getEvent(id, uid);
    const event = parseFeed(await this.readFeed(sub), undefined, this.timezone).find(e => e.uid === uid);
    if (!event) throw Error('Event not found in linked calendar');
    return this.toEventFull(event, id);
  }
}
// Every mutation remains blocked for read-only subscriptions, even if another
// MCP client enables tools that Codex does not expose.
for (const name of ['createEvent', 'updateEvent', 'deleteEvent', 'moveEvent', 'fetchRawCalendarObject', 'updateCalendar', 'deleteCalendar']) {
  LocalCalendarService.prototype[name] = async function(id, ...args) {
    if (await this.subscription(id)) throw Error('Linked calendars are read-only');
    if (name === 'moveEvent' && await this.subscription(args[1])) throw Error('Linked calendars are read-only');
    return CalDavService.prototype[name].call(this, id, ...args);
  };
}
