import fs from 'fs'
import http from 'http'

import consola from 'consola'
import { htmlToText as htmlToTextImported } from 'html-to-text'
import { createTransport } from 'nodemailer'

import camelcaseKeys = require('camelcase-keys')

import { getContact, getEvent, getInvitation } from './database'
import {
  AccountPasswordResetRequestMailOptions,
  AccountRegistrationMailOptions,
  MaevsiContact,
  MaevsiEvent,
  MaevsiInvitation,
  MailTemplate,
  MailWithContent,
  MessageInvitation,
} from './types'
import { i18nextResolve, renderTemplate } from './handlebars'
import { dateFormat } from './moment'

const HTML_TO_TEXT_OPTIONS = { tags: { img: { format: 'skip' } } }
const MAIL_FROM = '"maevsi" <noreply@maev.si>'
const MOMENT_FORMAT = 'LL LTS'
const SECRET_STOMPER_NODEMAILER_TRANSPORTER_PATH =
  '/run/secrets/stomper_nodemailer-transporter'

if (!fs.existsSync(SECRET_STOMPER_NODEMAILER_TRANSPORTER_PATH)) {
  throw new Error('The STMP configuration secret is missing!')
}

const NODEMAILER_TRANSPORTER = createTransport(
  JSON.parse(
    fs.readFileSync(SECRET_STOMPER_NODEMAILER_TRANSPORTER_PATH, 'utf-8'),
  ),
)

function htmlToText(html: string) {
  return htmlToTextImported(html, HTML_TO_TEXT_OPTIONS)
}

async function sendMail(mailWithConfig: MailWithContent) {
  const mailSentData = await NODEMAILER_TRANSPORTER.sendMail({
    from: MAIL_FROM,
    ...mailWithConfig,
  })

  consola.log('Message sent: %s', mailSentData.messageId)
}

function sendMailTemplated(args: MailTemplate) {
  const html = renderTemplate({
    language: args.language,
    templateNamespace: args.templateNamespace,
    templateVariables: args.templateVariables,
  })
  sendMail({
    to: args.to,
    subject: i18nextResolve(`${args.templateNamespace}:subject`),
    html,
    text: htmlToText(html),
  })
}

export function sendAccountPasswordResetRequestMail(
  dataJsonObject: AccountPasswordResetRequestMailOptions,
): void {
  sendMailTemplated({
    to: dataJsonObject.account.email_address,
    language: dataJsonObject.template.language,
    templateNamespace: 'accountPasswordResetRequest',
    templateVariables: {
      passwordResetVerificationLink: `https://${
        process.env.STACK_DOMAIN || 'maevsi.test'
      }/task/account/password/reset?code=${
        dataJsonObject.account.password_reset_verification
      }`,
      username: dataJsonObject.account.username,
      validUntil: dateFormat({
        input: dataJsonObject.account.password_reset_verification_valid_until,
        format: MOMENT_FORMAT,
        language: dataJsonObject.template.language,
      }),
    },
  })
}

export function sendAccountRegistrationMail(
  dataJsonObject: AccountRegistrationMailOptions,
): void {
  sendMailTemplated({
    to: dataJsonObject.account.email_address,
    language: dataJsonObject.template.language,
    templateNamespace: 'accountRegistration',
    templateVariables: {
      emailAddressVerificationLink: `https://${
        process.env.STACK_DOMAIN || 'maevsi.test'
      }/task/account/email-address/verify?code=${
        dataJsonObject.account.email_address_verification
      }`,
      username: dataJsonObject.account.username,
      validUntil: dateFormat({
        input: dataJsonObject.account.email_address_verification_valid_until,
        format: MOMENT_FORMAT,
        language: dataJsonObject.template.language,
      }),
    },
  })
}

export async function sendInvitationMail(
  dataJsonObject: MessageInvitation,
): Promise<void> {
  dataJsonObject = camelcaseKeys(dataJsonObject)

  let invitation: void | MaevsiInvitation = await getInvitation(
    dataJsonObject.invitationId,
  ).catch((reason) => consola.error(reason))

  if (!invitation) {
    return
  }

  invitation = camelcaseKeys(invitation)

  let contact: void | MaevsiContact = await getContact(
    invitation.contactId,
  ).catch((reason) => consola.error(reason))

  if (!contact) {
    return
  }

  contact = camelcaseKeys(contact)

  let event: void | MaevsiEvent = await getEvent(
    invitation.eventId,
  ).catch((reason) => consola.error(reason))

  if (!event) {
    return
  }

  event = camelcaseKeys(event)

  const req = http.request(
    'http://maevsi:3000/ical',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
    },
    (res) => {
      if (!contact || !event) {
        return
      }

      sendMail({
        to: contact.emailAddress,
        subject: 'Invitation',
        icalEvent: {
          content: res,
          filename: event.authorUsername + '_' + event.slug + '.ics',
          method: 'request',
        },
      })
    },
  )

  req.on('error', (e) => {
    consola.error(`Problem with request: ${e.message}`)
  })

  req.write(JSON.stringify({ event }))
  req.end()
}
