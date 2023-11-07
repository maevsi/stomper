import { i18nextResolve, templateCompile } from './handlebars.js'

test('compiles template', () => {
  expect(templateCompile('{{__ "maevsi:subtitle"}}', 'en', {})).toBe(
    'Find events, guests and friends 💙❤️💚',
  )
})

test('compiles template in another language', () => {
  expect(templateCompile('{{__ "maevsi:subtitle"}}', 'de', {})).toBe(
    'Finde Veranstaltungen, Gäste und Freunde 💙❤️💚',
  )
})

test('resolves template', () => {
  expect(i18nextResolve('maevsi:subtitle')).toBe(
    'Find events, guests and friends 💙❤️💚',
  )
})

test('resolves template in another language', () => {
  expect(i18nextResolve('maevsi:subtitle', 'de')).toBe(
    'Finde Veranstaltungen, Gäste und Freunde 💙❤️💚',
  )
})
