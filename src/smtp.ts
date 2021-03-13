import fs from 'fs'
import http from 'http'

import consola from 'consola'
import { htmlToText as htmlToTextImported } from 'html-to-text'
import markdownIt from 'markdown-it'
import { createTransport } from 'nodemailer'

import camelcaseKeys = require('camelcase-keys')

import {
  getContact,
  getEvent,
  getInvitation,
  getProfilePicture,
} from './database'
import {
  AccountPasswordResetRequestMailOptions,
  AccountRegistrationMailOptions,
  MaevsiContact,
  MaevsiEvent,
  MaevsiInvitation,
  EventInvitationMailOptions,
  Template,
  Mail,
  MaevsiProfilePicture,
} from './types'
import { i18nextResolve, renderTemplate } from './handlebars'
import { momentFormatDate, momentFormatDuration } from './moment'

const EVENT_DESCRIPTION_TRIM_LENGTH = 250
const HTML_TO_TEXT_OPTIONS = { tags: { img: { format: 'skip' } } }
const MAIL_FROM = '"maevsi" <noreply@maev.si>'
const MOMENT_FORMAT = 'LL LTS'
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
  dataJsonObject: AccountPasswordResetRequestMailOptions,
): void {
  sendMailTemplated(
    {
      to: dataJsonObject.account.email_address,
    },
    {
      language: dataJsonObject.template.language,
      namespace: 'accountPasswordResetRequest',
      variables: {
        passwordResetVerificationLink: `https://${
          process.env.STACK_DOMAIN || 'maevsi.test'
        }/task/account/password/reset?code=${
          dataJsonObject.account.password_reset_verification
        }`,
        username: dataJsonObject.account.username,
        validUntil: momentFormatDate({
          input: dataJsonObject.account.password_reset_verification_valid_until,
          format: MOMENT_FORMAT,
          language: dataJsonObject.template.language,
        }),
      },
    },
  )
}

export function sendAccountRegistrationMail(
  dataJsonObject: AccountRegistrationMailOptions,
): void {
  sendMailTemplated(
    {
      to: dataJsonObject.account.email_address,
    },
    {
      language: dataJsonObject.template.language,
      namespace: 'accountRegistration',
      variables: {
        emailAddressVerificationLink: `https://${
          process.env.STACK_DOMAIN || 'maevsi.test'
        }/task/account/email-address/verify?code=${
          dataJsonObject.account.email_address_verification
        }`,
        username: dataJsonObject.account.username,
        validUntil: momentFormatDate({
          input: dataJsonObject.account.email_address_verification_valid_until,
          format: MOMENT_FORMAT,
          language: dataJsonObject.template.language,
        }),
      },
    },
  )
}

export async function sendEventInvitationMail(
  dataJsonObject: EventInvitationMailOptions,
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

  let eventAuthorProfilePicture: void | MaevsiProfilePicture = await getProfilePicture(
    event.authorUsername,
  ).catch((reason) => consola.error(reason))

  if (eventAuthorProfilePicture) {
    eventAuthorProfilePicture = camelcaseKeys(eventAuthorProfilePicture)
  }

  const req = http.request(
    'http://maevsi:3000/ical',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
    },
    (res) => {
      if (!contact) {
        consola.error(`Could not get contact ${contact}!`)
        return
      }

      if (!event) {
        consola.error(`Could not get contact ${event}!`)
        return
      }

      const namespace = 'eventInvitation'
      const language = dataJsonObject.template.language

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
        eventDescription = htmlToText(markdownIt().render(event.description))

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

      sendMailTemplated(
        {
          icalEvent: {
            content: res,
            filename: event.authorUsername + '_' + event.slug + '.ics',
            method: 'request',
          },
          to: contact.emailAddress,
        },
        {
          language,
          namespace,
          variables: {
            eventAttendanceType,
            eventAuthorProfileHref: `https://${
              process.env.STACK_DOMAIN || 'maevsi.test'
            }/account/${event.authorUsername}`,
            eventAuthorProfilePictureSrc: eventAuthorProfilePicture
              ? TUSD_FILES_URL +
                eventAuthorProfilePicture.uploadStorageKey +
                '+'
              : 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIHN2ZyAgUFVCTElDICctLy9XM0MvL0RURCBTVkcgMS4xLy9FTicgICdodHRwOi8vd3d3LnczLm9yZy9HcmFwaGljcy9TVkcvMS4xL0RURC9zdmcxMS5kdGQnPgo8c3ZnIHdpZHRoPSI0MDFweCIgaGVpZ2h0PSI0MDFweCIgZW5hYmxlLWJhY2tncm91bmQ9Im5ldyAzMTIuODA5IDAgNDAxIDQwMSIgdmVyc2lvbj0iMS4xIiB2aWV3Qm94PSIzMTIuODA5IDAgNDAxIDQwMSIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGcgdHJhbnNmb3JtPSJtYXRyaXgoMS4yMjMgMCAwIDEuMjIzIC00NjcuNSAtODQzLjQ0KSI+Cgk8cmVjdCB4PSI2MDEuNDUiIHk9IjY1My4wNyIgd2lkdGg9IjQwMSIgaGVpZ2h0PSI0MDEiIGZpbGw9IiNFNEU2RTciLz4KCTxwYXRoIGQ9Im04MDIuMzggOTA4LjA4Yy04NC41MTUgMC0xNTMuNTIgNDguMTg1LTE1Ny4zOCAxMDguNjJoMzE0Ljc5Yy0zLjg3LTYwLjQ0LTcyLjktMTA4LjYyLTE1Ny40MS0xMDguNjJ6IiBmaWxsPSIjQUVCNEI3Ii8+Cgk8cGF0aCBkPSJtODgxLjM3IDgxOC44NmMwIDQ2Ljc0Ni0zNS4xMDYgODQuNjQxLTc4LjQxIDg0LjY0MXMtNzguNDEtMzcuODk1LTc4LjQxLTg0LjY0MSAzNS4xMDYtODQuNjQxIDc4LjQxLTg0LjY0MWM0My4zMSAwIDc4LjQxIDM3LjkgNzguNDEgODQuNjR6IiBmaWxsPSIjQUVCNEI3Ii8+CjwvZz4KPC9zdmc+Cg==',
            eventAuthorUsername: event.authorUsername,
            eventDescription,
            eventDuration: event.end
              ? momentFormatDuration({
                  start: event.start,
                  end: event.end,
                  format: MOMENT_FORMAT,
                  language: dataJsonObject.template.language,
                })
              : null,
            // TODO: eventGroupName
            eventLink: `https://${
              process.env.STACK_DOMAIN || 'maevsi.test'
            }/event/${event.authorUsername}/${event.name}`,
            eventName: event.name,
            eventStart: momentFormatDate({
              input: event.start,
              format: MOMENT_FORMAT,
              language: dataJsonObject.template.language,
            }),
            eventVisibility,
          },
        },
      )
    },
  )

  req.on('error', (e) => {
    consola.error(`Problem with request: ${e.message}`)
  })

  req.write(JSON.stringify({ event }))
  req.end()
}
