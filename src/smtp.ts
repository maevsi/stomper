import { existsSync, readFileSync } from 'node:fs'

import handlebars from 'handlebars'
import { htmlToText as htmlToTextImported } from 'html-to-text'
import { createTransport } from 'nodemailer'

import camelcaseKeys from 'camelcase-keys'

import { ack } from './database.js'
import { i18nextResolve, renderTemplate } from './handlebars.js'
import { momentFormatDate, momentFormatDuration } from './moment.js'
import type {
  AccountPasswordResetRequestMailOptions,
  AccountRegistrationMailOptions,
  EventInvitationMailOptions,
  Template,
  Mail,
} from './types.js'

const EVENT_DESCRIPTION_TRIM_LENGTH = 250
const HTML_TO_TEXT_OPTIONS = {
  selectors: [
    { selector: 'a', options: { ignoreHref: true } },
    { selector: 'img', format: 'skip' },
  ],
}
const LOCALE_DEFAULT = 'en'
const MAIL_FROM = '"maevsi" <noreply@maev.si>'
const MOMENT_FORMAT = 'LL LT'
const SECRET_STOMPER_NODEMAILER_TRANSPORTER_PATH =
  '/run/secrets/stomper_nodemailer-transporter'
const TUSD_FILES_URL =
  'https://tusd.' + (process.env.STACK_DOMAIN || 'maevsi.test') + '/files/'

if (!existsSync(SECRET_STOMPER_NODEMAILER_TRANSPORTER_PATH)) {
  throw new Error('The SMTP configuration secret is missing!')
}

const NODEMAILER_TRANSPORTER = createTransport(
  JSON.parse(readFileSync(SECRET_STOMPER_NODEMAILER_TRANSPORTER_PATH, 'utf-8')),
)

const htmlToText = (html: string) =>
  htmlToTextImported(html, HTML_TO_TEXT_OPTIONS)

const sendMail = async (mail: Mail) => {
  if (
    process.env.NODE_ENV !== 'production' &&
    mail.to.startsWith('mail+sqitch-')
  ) {
    console.debug(
      'Skipping mail sending for test data email accounts ("mail+sqitch-...").',
    )
    return
  }

  const mailSentData = await NODEMAILER_TRANSPORTER.sendMail({
    from: MAIL_FROM,
    list: {
      // TODO: add https link (https://github.com/maevsi/maevsi/issues/326)
      unsubscribe: `mailto:contact+unsubscribe@maev.si?subject=Unsubscribe%20${mail.to}`,
    },
    ...mail,
  })

  console.log('Message sent: %s', mailSentData.messageId)
}

const sendMailTemplated = (mail: Mail, template: Template) => {
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

export const sendAccountPasswordResetRequestMail = (
  id: number,
  payload: AccountPasswordResetRequestMailOptions,
) => {
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
          }${
            payload.template.language !== LOCALE_DEFAULT
              ? '/' + payload.template.language
              : ''
          }/account/password/reset?code=${
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
    console.error(e)
    ack(id, false)
  }
}

export const sendAccountRegistrationMail = (
  id: number,
  payload: AccountRegistrationMailOptions,
) => {
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
          }${
            payload.template.language !== LOCALE_DEFAULT
              ? '/' + payload.template.language
              : ''
          }/account/verify?code=${payload.account.email_address_verification}`,
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
    console.error(e)
    ack(id, false)
  }
}

export const sendEventInvitationMail = async (
  id: number,
  payload: EventInvitationMailOptions,
) => {
  payload = camelcaseKeys(payload, { deep: true })

  const {
    emailAddress,
    event,
    invitationId,
    eventAuthorProfilePictureUploadStorageKey,
    eventAuthorUsername,
  } = payload.data

  const res = await (
    await fetch('http://maevsi:3000/api/ical', {
      body: JSON.stringify({
        contact: { emailAddress },
        event: {
          ...event,
          accountByAuthorAccountId: {
            username: eventAuthorUsername,
          },
        },
        invitation: {
          id: invitationId,
        },
      }),
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
    })
  ).text()

  if (!invitationId) {
    console.error(`Could not get invitation id ${invitationId}!`)
    return
  }

  if (!emailAddress) {
    console.error(`Could not get email address ${emailAddress}!`)
    return
  }

  if (!event) {
    console.error(`Could not get contact ${event}!`)
    return
  }

  const namespace = 'eventInvitation'
  const language = payload.template.language

  const eventAttendanceType = [
    ...(event.isInPerson
      ? [i18nextResolve(`${namespace}:eventAttendanceTypeInPerson`, language)]
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
          id: invitationId,
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
    console.error(
      `Event is neither archived nor has it a visibility of public or private: ${event}`,
    )
  }

  try {
    sendMailTemplated(
      {
        from: `"${eventAuthorUsername}" <noreply@maev.si>`,
        icalEvent: {
          content: res,
          filename: eventAuthorUsername + '_' + event.slug + '.ics',
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
          }/accounts/${eventAuthorUsername}`,
          eventAuthorProfilePictureSrc:
            eventAuthorProfilePictureUploadStorageKey
              ? TUSD_FILES_URL + eventAuthorProfilePictureUploadStorageKey
              : 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIHN2ZyAgUFVCTElDICctLy9XM0MvL0RURCBTVkcgMS4xLy9FTicgICdodHRwOi8vd3d3LnczLm9yZy9HcmFwaGljcy9TVkcvMS4xL0RURC9zdmcxMS5kdGQnPgo8c3ZnIHdpZHRoPSI0MDFweCIgaGVpZ2h0PSI0MDFweCIgZW5hYmxlLWJhY2tncm91bmQ9Im5ldyAzMTIuODA5IDAgNDAxIDQwMSIgdmVyc2lvbj0iMS4xIiB2aWV3Qm94PSIzMTIuODA5IDAgNDAxIDQwMSIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGcgdHJhbnNmb3JtPSJtYXRyaXgoMS4yMjMgMCAwIDEuMjIzIC00NjcuNSAtODQzLjQ0KSI+Cgk8cmVjdCB4PSI2MDEuNDUiIHk9IjY1My4wNyIgd2lkdGg9IjQwMSIgaGVpZ2h0PSI0MDEiIGZpbGw9IiNFNEU2RTciLz4KCTxwYXRoIGQ9Im04MDIuMzggOTA4LjA4Yy04NC41MTUgMC0xNTMuNTIgNDguMTg1LTE1Ny4zOCAxMDguNjJoMzE0Ljc5Yy0zLjg3LTYwLjQ0LTcyLjktMTA4LjYyLTE1Ny40MS0xMDguNjJ6IiBmaWxsPSIjQUVCNEI3Ii8+Cgk8cGF0aCBkPSJtODgxLjM3IDgxOC44NmMwIDQ2Ljc0Ni0zNS4xMDYgODQuNjQxLTc4LjQxIDg0LjY0MXMtNzguNDEtMzcuODk1LTc4LjQxLTg0LjY0MSAzNS4xMDYtODQuNjQxIDc4LjQxLTg0LjY0MWM0My4zMSAwIDc4LjQxIDM3LjkgNzguNDEgODQuNjR6IiBmaWxsPSIjQUVCNEI3Ii8+CjwvZz4KPC9zdmc+Cg==',
          eventAuthorUsername: eventAuthorUsername,
          eventDescription,
          eventDuration: event.end
            ? momentFormatDuration({
                start: event.start,
                end: event.end,
                format: MOMENT_FORMAT,
                language: payload.template.language,
              })
            : null,
          // TODO: add event group (https://github.com/maevsi/maevsi/issues/92)
          eventLink: `https://${process.env.STACK_DOMAIN || 'maevsi.test'}${
            payload.template.language !== LOCALE_DEFAULT
              ? '/' + payload.template.language
              : ''
          }/invitation/unlock?ic=${invitationId}`,
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
    console.error(e)
    ack(id, false)
  }
}
