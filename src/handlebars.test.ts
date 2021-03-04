import { i18nextResolve } from './handlebars'

test('resolves internationalization', () => {
  expect(i18nextResolve('maevsi:subtitle')).toBe(
    'The manager for events supported by invitees.',
  )
})
