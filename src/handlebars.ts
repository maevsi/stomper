import fs from 'fs'
import Handlebars from 'handlebars'
import i18next from 'i18next'
import Backend from 'i18next-fs-backend'
import path from 'path'
import { Template } from './types'

const HandlebarsI18n = require('handlebars-i18n')

const STACK_DOMAIN = process.env.STACK_DOMAIN || 'maevsi.test'

i18next
  .use(Backend)
  .init({
    backend: {
      addPath: path.join(__dirname, './locales/{{lng}}/{{ns}}.missing.json'),
      loadPath: path.join(__dirname, './locales/{{lng}}/{{ns}}.json')
    },
    debug: typeof process.env.NODE_ENV === 'string' && !['production', 'test'].includes(process.env.NODE_ENV),
    defaultNS: 'maevsi',
    fallbackLng: process.env.NODE_ENV !== 'production' ? 'dev' : 'en',
    initImmediate: false,
    lng: 'en',
    ns: ['accountRegistration', 'accountPasswordResetRequest', 'maevsi'],
    preload: fs.readdirSync(path.join(__dirname, './locales')).filter((fileName: any) => {
      const joinedPath = path.join(path.join(__dirname, './locales'), fileName)
      const isDirectory = fs.lstatSync(joinedPath).isDirectory()
      return isDirectory
    })
  })

HandlebarsI18n.init()

export function renderTemplate (args: Template) {
  if (process.env.NODE_ENV !== 'production') {
    i18next.reloadResources()
  }

  const template = Handlebars.compile(fs.readFileSync(path.resolve(__dirname, `./email-templates/${args.templateNamespace}.html`), 'utf-8'))
  i18next.changeLanguage(args.language)
  return template({
    stackDomain: STACK_DOMAIN,
    ...args.templateVariables
  })
}

export function i18nextResolve (id: string) {
  return i18next.t(id)
}
