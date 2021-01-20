import fs from 'fs'
import http from 'http'
import path from 'path'

import Handlebars from 'handlebars'
import { htmlToText as htmlToTextImported } from 'html-to-text'
import nodemailer from 'nodemailer'

import { getContact, getEvent, getInvitation } from './database'
import { MaevsiContact, MaevsiEvent, MaevsiInvitation, MessageInvitation, SendMailConfig } from './types'

const camelcaseKeys = require('camelcase-keys')
const consola = require('consola')

const HTML_TO_TEXT_OPTIONS = { tags: { img: { format: 'skip' } } }
const MAIL_FROM = '"maevsi" <noreply@maev.si>'
const SECRET_STOMPER_NODEMAILER_TRANSPORTER_PATH = '/run/secrets/stomper_nodemailer-transporter'
const STACK_DOMAIN = process.env.STACK_DOMAIN || 'maevsi.test'

if (!fs.existsSync(SECRET_STOMPER_NODEMAILER_TRANSPORTER_PATH)) {
  consola.error('The STMP configuration secret is missing!')
  process.exit(1)
}

const NODEMAILER_TRANSPORTER = nodemailer.createTransport(JSON.parse(fs.readFileSync(SECRET_STOMPER_NODEMAILER_TRANSPORTER_PATH, 'utf-8')))

function htmlToText (html: string) {
  return htmlToTextImported(html, HTML_TO_TEXT_OPTIONS)
}

async function sendMail (sendMailConfig: SendMailConfig) {
  const mailSentData = await NODEMAILER_TRANSPORTER.sendMail({
    from: MAIL_FROM,
    ...sendMailConfig
  })

  consola.log('Message sent: %s', mailSentData.messageId)
}

function sendMailTemplated (to: string, subject: string, templateFileName: string, templateVariables: object) {
  const template = Handlebars.compile(fs.readFileSync(path.resolve(__dirname, `./email-templates/${templateFileName}.html`), 'utf-8'))
  const html = template({
    stackDomain: STACK_DOMAIN,
    ...templateVariables
  })

  sendMail({ to, subject, html, text: htmlToText(html) })
}

export function sendAccountPasswordResetRequestMail (dataJsonObject: any) {
  sendMailTemplated(
    dataJsonObject.account.email_address,
    'Password Reset Request',
    'accountPasswordResetRequest',
    {
      passwordResetVerificationLink: `https://${process.env.STACK_DOMAIN || 'maevsi.test'}/task/account/password/reset?code=${dataJsonObject.account.password_reset_verification}`,
      username: dataJsonObject.account.username
    }
  )
}

export function sendAccountRegisterMail (dataJsonObject: any) {
  sendMailTemplated(
    dataJsonObject.account.email_address,
    'Welcome',
    'accountRegister',
    {
      emailAddressVerificationLink: `https://${process.env.STACK_DOMAIN || 'maevsi.test'}/task/account/email-address/verify?code=${dataJsonObject.account.email_address_verification}`,
      username: dataJsonObject.account.username
    }
  )
}

export async function sendInvitationMail (dataJsonObject: MessageInvitation) {
  dataJsonObject = camelcaseKeys(dataJsonObject)
  const invitation: MaevsiInvitation = camelcaseKeys(await getInvitation(dataJsonObject.invitationId).catch((reason) => consola.error(reason)))

  if (!invitation) {
    return
  }

  const contact: MaevsiContact = camelcaseKeys(await getContact(invitation.contactId).catch((reason) => consola.error(reason)))
  const event: MaevsiEvent = camelcaseKeys(await getEvent(invitation.eventId).catch((reason) => consola.error(reason)))

  const req = http.request('http://maevsi:3000/ical', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=utf-8'
    }
  }, (res) => {
    sendMail({
      to: contact.emailAddress,
      subject: 'Invitation',
      icalEvent: {
        content: res,
        filename: event.organizerUsername + '_' + event.slug + '.ics',
        method: 'request'
      }
    })
  })

  req.on('error', (e) => {
    consola.error(`Problem with request: ${e.message}`)
  })

  req.write(JSON.stringify({ event }))
  req.end()
}
