import { config, SESV2 } from 'aws-sdk'
import MailComposer from 'nodemailer/lib/mail-composer'

import http from 'http'

config.apiVersions = {
  ses: '2019-09-27'
}
config.loadFromPath('/run/secrets/stomper_aws')

var ses = new SESV2()
var params = {
  Destination: {
    ToAddresses: [
      'e-mail@jonas-thelemann.de'
    ]
  }
}

export function accountRegisterMail (data: string) {
  const json = JSON.parse(data)

  new MailComposer({
    from: '"Maevsi" <noreply@maev.si>',
    html: [json.account.username, json.account.email_address, json.account.email_address_verification].join(' '),
    subject: 'Welcome',
    text: [json.account.username, json.account.email_address, json.account.email_address_verification].join(' ')
  })
    .compile().build(function (err, message) {
      console.error(err)

      var paramsContent = {
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

export function inviteMail (data: string) {
  const json = JSON.parse(data)

  const req = http.request('http://maevsi:8080/ical', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    }
  }, (res) => {
    new MailComposer({
      from: '"Maevsi" <noreply@maev.si>',
      icalEvent: {
        content: res,
        filename: json.event.organizerUsername + '_' + json.event.slug + '.ics',
        method: 'request'
      },
      subject: 'Invite'
    })
      .compile().build(function (err, message) {
        console.error(err)

        var paramsContent = {
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
