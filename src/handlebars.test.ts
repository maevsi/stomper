import { describe, expect, it } from 'vitest'
import { i18nextResolve, templateCompile } from './handlebars.js'

describe('handlebars', () => {
  it('compiles template', () => {
    expect(templateCompile('{{__ "maevsi:subtitle"}}', 'en', {})).toBe(
      'Find events, guests and friends 💙❤️💚',
    )
  })

  it('compiles template in another language', () => {
    expect(templateCompile('{{__ "maevsi:subtitle"}}', 'de', {})).toBe(
      'Finde Veranstaltungen, Gäste und Freunde 💙❤️💚',
    )
  })

  it('resolves template', () => {
    expect(i18nextResolve('maevsi:subtitle')).toBe(
      'Find events, guests and friends 💙❤️💚',
    )
  })

  it('resolves template in another language', () => {
    expect(i18nextResolve('maevsi:subtitle', 'de')).toBe(
      'Finde Veranstaltungen, Gäste und Freunde 💙❤️💚',
    )
  })
})
