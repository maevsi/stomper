import { Client } from '@stomp/stompjs'
import { readFileSync } from 'fs'
import { WebSocket } from 'ws'

import {
  sendAccountPasswordResetRequestMail,
  sendAccountRegistrationMail,
  sendEventInvitationMail,
} from './smtp.js'

Object.assign(global, { WebSocket })

if (process.env.RABBITMQ_DEFINITIONS_FILE === undefined) {
  throw new Error('Missing environment variable!')
}

const RABBITMQ_DEFINITIONS = JSON.parse(
  readFileSync(process.env.RABBITMQ_DEFINITIONS_FILE, 'utf8')
)

const client = new Client({
  brokerURL: 'ws://rabbitmq:15674/ws',
  connectHeaders: {
    login: RABBITMQ_DEFINITIONS.users[0].name,
    passcode: RABBITMQ_DEFINITIONS.users[0].password,
  },
  debug: function (str) {
    if (process.env.NODE_ENV !== 'production') {
      console.log(str)
    }
  },
})

client.onConnect = function () {
  ;[
    {
      queueName: 'account_password_reset_request',
      function: sendAccountPasswordResetRequestMail,
    },
    {
      queueName: 'account_registration',
      function: sendAccountRegistrationMail,
    },
    { queueName: 'event_invitation', function: sendEventInvitationMail },
  ].forEach((queueToFunctionMapping) => {
    client.subscribe(
      `/queue/${queueToFunctionMapping.queueName}`,
      function (message) {
        if (!message.body) {
          console.error('got empty message')
        }

        console.log('got message with body ' + message.body)

        try {
          const notification = JSON.parse(message.body)
          queueToFunctionMapping.function(
            notification.id,
            JSON.parse(notification.payload)
          )
          message.ack()
        } catch (e) {
          console.error(e)
        }
      },
      { ack: 'client' }
    )
  })
}

client.onStompError = function (frame) {
  throw new Error(
    'Broker reported error: ' +
      frame.headers.message +
      '\nAdditional details: ' +
      frame.body
  )
}

client.activate()
