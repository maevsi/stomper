// eslint-disable-next-line import/default
import stompJs from '@stomp/stompjs'
import consola from 'consola'
import fs from 'fs'
import websocket from 'websocket'

import {
  sendAccountPasswordResetRequestMail,
  sendAccountRegistrationMail,
  sendEventInvitationMail,
} from './smtp.js'

Object.assign(global, { WebSocket: websocket.w3cwebsocket })

if (process.env.RABBITMQ_DEFINITIONS_FILE === undefined) {
  throw new Error('Missing environment variable!')
}

const RABBITMQ_DEFINITIONS = JSON.parse(
  fs.readFileSync(process.env.RABBITMQ_DEFINITIONS_FILE, 'utf8'),
)

const client = new stompJs.Client({
  brokerURL: 'ws://rabbitmq:15674/ws',
  connectHeaders: {
    login: RABBITMQ_DEFINITIONS.users[0].name,
    passcode: RABBITMQ_DEFINITIONS.users[0].password,
  },
  debug: function (str) {
    if (process.env.NODE_ENV !== 'production') {
      consola.log(str)
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
          consola.error('got empty message')
        }

        consola.log('got message with body ' + message.body)

        try {
          const notification = JSON.parse(message.body)
          queueToFunctionMapping.function(
            notification.id,
            JSON.parse(notification.payload),
          )
          message.ack()
        } catch (e) {
          consola.error(e)
        }
      },
      { ack: 'client' },
    )
  })
}

client.onStompError = function (frame) {
  throw new Error(
    'Broker reported error: ' +
      frame.headers.message +
      '\nAdditional details: ' +
      frame.body,
  )
}

client.activate()
