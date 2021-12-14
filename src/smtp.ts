import fs from 'fs'
import http from 'http'

import consola from 'consola'
import handlebars from 'handlebars'
import { htmlToText as htmlToTextImported } from 'html-to-text'
import { createTransport } from 'nodemailer'

import camelcaseKeys = require('camelcase-keys')

import { ack } from './database'
import {
  AccountPasswordResetRequestMailOptions,
  AccountRegistrationMailOptions,
  EventInvitationMailOptions,
  Template,
  Mail,
} from './types'
import { i18nextResolve, renderTemplate } from './handlebars'
import { momentFormatDate, momentFormatDuration } from './moment'

const EVENT_DESCRIPTION_TRIM_LENGTH = 250
const HTML_TO_TEXT_OPTIONS = {
  selectors: [{ selector: 'img', format: 'skip' }],
}
const MAIL_FROM = '"maevsi" <noreply@maev.si>'
const MOMENT_FORMAT = 'LL LT'
const SECRET_STOMPER_NODEMAILER_TRANSPORTER_PATH =
  '/run/secrets/stomper_nodemailer-transporter'
const TUSD_FILES_URL =
  'https://tusd.' + (process.env.STACK_DOMAIN || 'maevsi.test') + '/files/'

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

async function sendMail(mail: Mail) {
  if (
    process.env.NODE_ENV !== 'production' &&
    mail.to.startsWith('mail+sqitch-')
  ) {
    consola.debug(
      'Skipping mail sending for test data email accounts ("mail+sqitch-...").',
    )
    return
  }

  const mailSentData = await NODEMAILER_TRANSPORTER.sendMail({
    from: MAIL_FROM,
    list: {
      // TODO: Add https link: https://github.com/maevsi/maevsi/issues/326
      unsubscribe: `mailto:mail+unsubscribe@maev.si?subject=Unsubscribe%20${mail.to}`,
    },
    ...mail,
  })

  consola.log('Message sent: %s', mailSentData.messageId)
}

function sendMailTemplated(mail: Mail, template: Template) {
  const html = renderTemplate(template)
  sendMail({
    ...mail,
    subject: i18nextResolve(
      `${template.namespace}:subject`,
      template.language,
      template.variables,
    ),
    html,
    text: htmlToText(html),
  })
}

export function sendAccountPasswordResetRequestMail(
  id: number,
  payload: AccountPasswordResetRequestMailOptions,
): void {
  try {
    sendMailTemplated(
      {
        to: payload.account.email_address,
      },
      {
        language: payload.template.language,
        namespace: 'accountPasswordResetRequest',
        variables: {
          emailAddress: payload.account.email_address,
          passwordResetVerificationLink: `https://${
            process.env.STACK_DOMAIN || 'maevsi.test'
          }/task/account/password/reset?code=${
            payload.account.password_reset_verification
          }`,
          username: payload.account.username,
          validUntil: momentFormatDate({
            input: payload.account.password_reset_verification_valid_until,
            format: MOMENT_FORMAT,
            language: payload.template.language,
          }),
        },
      },
    )
    ack(id)
  } catch (e) {
    consola.error(e)
    ack(id, false)
  }
}

export function sendAccountRegistrationMail(
  id: number,
  payload: AccountRegistrationMailOptions,
): void {
  try {
    sendMailTemplated(
      {
        to: payload.account.email_address,
      },
      {
        language: payload.template.language,
        namespace: 'accountRegistration',
        variables: {
          emailAddress: payload.account.email_address,
          emailAddressVerificationLink: `https://${
            process.env.STACK_DOMAIN || 'maevsi.test'
          }/task/account/email-address/verify?code=${
            payload.account.email_address_verification
          }`,
          username: payload.account.username,
          validUntil: momentFormatDate({
            input: payload.account.email_address_verification_valid_until,
            format: MOMENT_FORMAT,
            language: payload.template.language,
          }),
        },
      },
    )
    ack(id)
  } catch (e) {
    consola.error(e)
    ack(id, false)
  }
}

export async function sendEventInvitationMail(
  id: number,
  payload: EventInvitationMailOptions,
): Promise<void> {
  payload = camelcaseKeys(payload, { deep: true })

  const {
    emailAddress,
    event,
    invitationUuid,
    eventAuthorProfilePictureUploadStorageKey,
  } = payload.data

  const req = http.request(
    'http://maevsi:3000/api/ical',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
    },
    (res) => {
      if (!invitationUuid) {
        consola.error(`Could not get invitation uuid ${invitationUuid}!`)
        return
      }

      if (!emailAddress) {
        consola.error(`Could not get email address ${emailAddress}!`)
        return
      }

      if (!event) {
        consola.error(`Could not get contact ${event}!`)
        return
      }

      const namespace = 'eventInvitation'
      const language = payload.template.language

      const eventAttendanceType = [
        ...(event.isInPerson
          ? [
              i18nextResolve(
                `${namespace}:eventAttendanceTypeInPerson`,
                language,
              ),
            ]
          : []),
        ...(event.isRemote
          ? [i18nextResolve(`${namespace}:eventAttendanceTypeRemote`, language)]
          : []),
      ].join(', ')

      let eventDescription

      if (event.description !== null) {
        eventDescription = htmlToText(
          handlebars.compile(event.description)({
            contact: { emailAddress },
            event,
            invitation: {
              uuid: invitationUuid,
            },
          }),
        )

        if (event.description.length > EVENT_DESCRIPTION_TRIM_LENGTH) {
          eventDescription =
            eventDescription.substring(0, EVENT_DESCRIPTION_TRIM_LENGTH) + '…'
        }
      }

      let eventVisibility

      if (event.isArchived) {
        eventVisibility = i18nextResolve(`${namespace}:isArchived`, language)
      } else if (event.visibility === 'public') {
        eventVisibility = i18nextResolve(
          `${namespace}:eventVisibilityIsPublic`,
          language,
        )
      } else if (event.visibility === 'private') {
        eventVisibility = i18nextResolve(
          `${namespace}:eventVisibilityIsPrivate`,
          language,
        )
      } else {
        consola.error(
          `Event is neither archived nor has it a visibility of public or private: ${event}`,
        )
      }

      try {
        sendMailTemplated(
          {
            icalEvent: {
              content: res,
              filename: event.authorUsername + '_' + event.slug + '.ics',
              method: 'request',
            },
            to: emailAddress,
          },
          {
            language,
            namespace,
            variables: {
              emailAddress,
              eventAttendanceType,
              eventAuthorProfileHref: `https://${
                process.env.STACK_DOMAIN || 'maevsi.test'
              }/account/${event.authorUsername}`,
              eventAuthorProfilePictureSrc:
                eventAuthorProfilePictureUploadStorageKey
                  ? TUSD_FILES_URL +
                    eventAuthorProfilePictureUploadStorageKey +
                    '+'
                  : 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIHN2ZyAgUFVCTElDICctLy9XM0MvL0RURCBTVkcgMS4xLy9FTicgICdodHRwOi8vd3d3LnczLm9yZy9HcmFwaGljcy9TVkcvMS4xL0RURC9zdmcxMS5kdGQnPgo8c3ZnIHdpZHRoPSI0MDFweCIgaGVpZ2h0PSI0MDFweCIgZW5hYmxlLWJhY2tncm91bmQ9Im5ldyAzMTIuODA5IDAgNDAxIDQwMSIgdmVyc2lvbj0iMS4xIiB2aWV3Qm94PSIzMTIuODA5IDAgNDAxIDQwMSIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGcgdHJhbnNmb3JtPSJtYXRyaXgoMS4yMjMgMCAwIDEuMjIzIC00NjcuNSAtODQzLjQ0KSI+Cgk8cmVjdCB4PSI2MDEuNDUiIHk9IjY1My4wNyIgd2lkdGg9IjQwMSIgaGVpZ2h0PSI0MDEiIGZpbGw9IiNFNEU2RTciLz4KCTxwYXRoIGQ9Im04MDIuMzggOTA4LjA4Yy04NC41MTUgMC0xNTMuNTIgNDguMTg1LTE1Ny4zOCAxMDguNjJoMzE0Ljc5Yy0zLjg3LTYwLjQ0LTcyLjktMTA4LjYyLTE1Ny40MS0xMDguNjJ6IiBmaWxsPSIjQUVCNEI3Ii8+Cgk8cGF0aCBkPSJtODgxLjM3IDgxOC44NmMwIDQ2Ljc0Ni0zNS4xMDYgODQuNjQxLTc4LjQxIDg0LjY0MXMtNzguNDEtMzcuODk1LTc4LjQxLTg0LjY0MSAzNS4xMDYtODQuNjQxIDc4LjQxLTg0LjY0MWM0My4zMSAwIDc4LjQxIDM3LjkgNzguNDEgODQuNjR6IiBmaWxsPSIjQUVCNEI3Ii8+CjwvZz4KPC9zdmc+Cg==',
              eventAuthorUsername: event.authorUsername,
              eventDescription,
              eventDuration: event.end
                ? momentFormatDuration({
                    start: event.start,
                    end: event.end,
                    format: MOMENT_FORMAT,
                    language: payload.template.language,
                  })
                : null,
              // TODO: eventGroupName
              eventLink: `https://${
                process.env.STACK_DOMAIN || 'maevsi.test'
              }/task/event/unlock?ic=${invitationUuid}`,
              eventName: event.name,
              eventStart: momentFormatDate({
                input: event.start,
                format: MOMENT_FORMAT,
                language: payload.template.language,
              }),
              eventVisibility,
            },
          },
        )
        ack(id)
      } catch (e) {
        consola.error(e)
        ack(id, false)
      }
    },
  )

  req.on('error', (e) => {
    consola.error(`Problem with request: ${e.message}`)
  })

  req.write(JSON.stringify({ event }))
  req.end()
}
