import { i18nextResolve, templateCompile } from './handlebars'

test('compiles template', () => {
  expect(templateCompile('{{__ "maevsi:subtitle"}}', 'en', {})).toBe(
    'The manager for events supported by invitees.',
  )
})

test('compiles template in another language', () => {
  expect(templateCompile('{{__ "maevsi:subtitle"}}', 'de', {})).toBe(
    'Der Eventmanager für Veranstaltungen, die von Teilnehmenden unterstützt werden.',
  )
})

test('resolves template', () => {
  expect(i18nextResolve('maevsi:subtitle')).toBe(
    'The manager for events supported by invitees.',
  )
})

test('resolves template in another language', () => {
  expect(i18nextResolve('maevsi:subtitle', 'de')).toBe(
    'Der Eventmanager für Veranstaltungen, die von Teilnehmenden unterstützt werden.',
  )
})
