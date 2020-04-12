import { config, SESV2 } from 'aws-sdk'
import MailComposer from 'nodemailer/lib/mail-composer'

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

export function trigger (templateData: string) {
  new MailComposer({
    from: '"Maevsi" <noreply@maev.si>',
    html: '<h1>h1</h1>',
    subject: 'SES',
    text: 'Hello'
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
