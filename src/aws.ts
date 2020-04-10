import { config, SES } from 'aws-sdk'

config.apiVersions = {
  ses: '2010-12-01'
}

config.loadFromPath('/run/secrets/stomper_aws')

var ses = new SES()
var params = {
  Destination: { /* required */
    //   BccAddresses: [
    //     'STRING_VALUE',
    //     /* more items */
    //   ],
    //   CcAddresses: [
    //     'STRING_VALUE',
    //     /* more items */
    //   ],
    ToAddresses: [
      'e-mail@jonas-thelemann.de'
    ]
  },
  Source: 'Maevsi <noreply@maev.si>', /* required */
  Template: 'MyTemplate', /* required */
  TemplateData: '{ "name":"Jonas", "favoriteanimal": "dog" }', /* required */
  ConfigurationSetName: 'default'
  // ReplyToAddresses: [
  //   'STRING_VALUE',
  //   /* more items */
  // ],
  // ReturnPath: 'STRING_VALUE',
  // ReturnPathArn: 'STRING_VALUE',
  // SourceArn: 'STRING_VALUE',
  // Tags: [
  //   {
  //     Name: 'STRING_VALUE', /* required */
  //     Value: 'STRING_VALUE' /* required */
  //   },
  //   /* more items */
  // ],
  // TemplateArn: 'STRING_VALUE'
}

export function trigger (templateData: string) {
  params.TemplateData = templateData

  ses.sendTemplatedEmail(params, function (err, data) {
    if (err) console.log(err, err.stack) // an error occurred
    else console.log(data) // successful response
  })
}
