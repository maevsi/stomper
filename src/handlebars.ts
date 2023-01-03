import { readdirSync, lstatSync, readFileSync } from 'fs'
import { resolve, join, dirname } from 'path'

import handlebars from 'handlebars'
import { changeLanguage, use, t, reloadResources } from 'i18next'
import Backend from 'i18next-fs-backend'
import { fileURLToPath } from 'url'

import { Template } from './types.js'

const STACK_DOMAIN = process.env.STACK_DOMAIN || 'maevsi.test'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

use(Backend).init({
  backend: {
    addPath: join(__dirname, './locales/{{lng}}/{{ns}}.missing.json'),
    loadPath: join(__dirname, './locales/{{lng}}/{{ns}}.json'),
  },
  debug:
    typeof process.env.NODE_ENV === 'string' &&
    !['production', 'test'].includes(process.env.NODE_ENV),
  defaultNS: 'maevsi',
  fallbackLng: process.env.NODE_ENV !== 'production' ? 'dev' : 'en',
  initImmediate: false,
  lng: 'en',
  ns: [
    'accountRegistration',
    'accountPasswordResetRequest',
    'eventInvitation',
    'maevsi',
  ],
  preload: readdirSync(join(__dirname, './locales')).filter((fileName) => {
    const joinedPath = join(join(__dirname, './locales'), fileName)
    const isDirectory = lstatSync(joinedPath).isDirectory()
    return isDirectory
  }),
})

handlebars.registerHelper('__', (str: string, attributes: { hash: object }) => {
  return new handlebars.SafeString(t(str, attributes.hash))
})

export function templateCompile(
  string: string,
  language: string,
  templateVariables: Record<string, unknown>
): string {
  changeLanguage(language)
  return handlebars.compile(string)({
    stackDomain: STACK_DOMAIN,
    ...templateVariables,
  })
}

export function renderTemplate(template: Template): string {
  if (process.env.NODE_ENV !== 'production') {
    reloadResources()
  }

  return templateCompile(
    readFileSync(
      resolve(__dirname, `./email-templates/${template.namespace}.html`),
      'utf-8'
    ),
    template.language,
    template.variables
  )
}

export function i18nextResolve(
  id: string,
  language = 'en',
  options: Record<string, unknown> = {}
): string {
  changeLanguage(language)
  return t(id, options)
}
