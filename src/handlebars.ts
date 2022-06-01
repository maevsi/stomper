import fs from 'fs'
import Handlebars from 'handlebars'
import { changeLanguage, use, t, reloadResources } from 'i18next'
import Backend from 'i18next-fs-backend'
import path from 'path'
import { fileURLToPath } from 'url'

import { Template } from './types.js'

const STACK_DOMAIN = process.env.STACK_DOMAIN || 'maevsi.test'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

use(Backend).init({
  backend: {
    addPath: path.join(__dirname, './locales/{{lng}}/{{ns}}.missing.json'),
    loadPath: path.join(__dirname, './locales/{{lng}}/{{ns}}.json'),
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
  preload: fs
    .readdirSync(path.join(__dirname, './locales'))
    .filter((fileName) => {
      const joinedPath = path.join(path.join(__dirname, './locales'), fileName)
      const isDirectory = fs.lstatSync(joinedPath).isDirectory()
      return isDirectory
    }),
})

Handlebars.registerHelper('__', function (str, attributes) {
  return new Handlebars.SafeString(t(str, attributes.hash))
})

export function templateCompile(
  string: string,
  language: string,
  templateVariables: Record<string, unknown>,
): string {
  changeLanguage(language)
  return Handlebars.compile(string)({
    stackDomain: STACK_DOMAIN,
    ...templateVariables,
  })
}

export function renderTemplate(template: Template): string {
  if (process.env.NODE_ENV !== 'production') {
    reloadResources()
  }

  return templateCompile(
    fs.readFileSync(
      path.resolve(__dirname, `./email-templates/${template.namespace}.html`),
      'utf-8',
    ),
    template.language,
    template.variables,
  )
}

export function i18nextResolve(
  id: string,
  language = 'en',
  options?: Record<string, unknown>,
): string {
  changeLanguage(language)
  return t(id, options)
}
