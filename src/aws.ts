import { config, SESV2 } from 'aws-sdk'
import Handlebars from 'handlebars'
import { htmlToText } from 'html-to-text'
import MailComposer from 'nodemailer/lib/mail-composer'

import fs from 'fs'
import http from 'http'
import path from 'path'

const secretStomperAwsPath = '/run/secrets/stomper_aws'

config.apiVersions = {
  ses: '2019-09-27'
}

if (fs.existsSync(secretStomperAwsPath)) {
  config.loadFromPath(secretStomperAwsPath)
} else {
  console.error('Missing secret!')
  process.exit(1)
}

const ses = new SESV2()
const params = {
  Destination: {
    ToAddresses: [
      'e-mail@jonas-thelemann.de'
    ]
  }
}

export function sendAccountPasswordResetRequestMail (data: string) {
  const json = JSON.parse(data)
  const template = Handlebars.compile(fs.readFileSync(path.resolve(__dirname, './email-templates/accountPasswordResetRequest.html'), 'utf-8'))
  const html = template({
    passwordResetVerificationLink: `https://${process.env.STACK_DOMAIN || 'maevsi.test'}/reset/password?code=${json.account.password_reset_verification}`,
    username: json.account.username,
    stackDomain: process.env.STACK_DOMAIN || 'maevsi.test'
  })

  // json.account.email_address

  new MailComposer({
    from: '"maevsi" <noreply@maev.si>',
    html: html,
    subject: 'Password Reset Request',
    text: htmlToText(html, { tags: { img: { format: 'skip' } } })
  })
    .compile().build(function (err, message) {
      if (err) {
        console.error(err)
      }

      const paramsContent = {
        Content: {
          Raw: {
            Data: message
          }
        }
      }

      ses.sendEmail({ ...params, ...paramsContent }, function (err, data) {
        if (err) console.error(err, err.stack)
        else console.log(data)
      })
    })
}

export function sendAccountRegisterMail (data: string) {
  const json = JSON.parse(data)
  const template = Handlebars.compile(fs.readFileSync(path.resolve(__dirname, './email-templates/accountRegister.html'), 'utf-8'))
  const html = template({
    emailAddressVerificationLink: `https://${process.env.STACK_DOMAIN || 'maevsi.test'}/verify/email-address?code=${json.account.email_address_verification}`,
    username: json.account.username,
    stackDomain: process.env.STACK_DOMAIN || 'maevsi.test'
  })

  // json.account.email_address

  new MailComposer({
    from: '"maevsi" <noreply@maev.si>',
    html: html,
    subject: 'Welcome',
    text: htmlToText(html, { tags: { img: { format: 'skip' } } })
  })
    .compile().build(function (err, message) {
      if (err) {
        console.error(err)
      }

      const paramsContent = {
        Content: {
          Raw: {
            Data: message
          }
        }
      }

      ses.sendEmail({ ...params, ...paramsContent }, function (err, data) {
        if (err) console.error(err, err.stack)
        else console.log(data)
      })
    })
}

export function sendInviteMail (data: string) {
  const json = JSON.parse(data)

  const req = http.request('http://maevsi:3000/ical', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=utf-8'
    }
  }, (res) => {
    new MailComposer({
      from: '"maevsi" <noreply@maev.si>',
      icalEvent: {
        content: res,
        filename: json.event.organizerUsername + '_' + json.event.slug + '.ics',
        method: 'request'
      },
      subject: 'Invite'
    })
      .compile().build(function (err, message) {
        if (err) {
          console.error(err)
        }

        const paramsContent = {
          Content: {
            Raw: {
              Data: message
            }
          }
        }

        ses.sendEmail({ ...params, ...paramsContent }, function (err, data) {
          if (err) console.error(err, err.stack)
          else console.log(data)
        })
      })
  })

  req.on('error', (e) => {
    console.error(`problem with request: ${e.message}`)
  })

  req.write(data)
  req.end()
}
