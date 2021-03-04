export interface Account {
  email_address: string
  email_address_verification: string
  password_reset_verification: string
  username: string
}

export interface AccountPasswordResetRequestMailOptions {
  account: Account
  template: Template
}

export interface AccountRegistrationMailOptions {
  account: Account
  template: Template
}

export interface MaevsiContact {
  id: BigInt
  accountUsername: string
  emailAddress: string
  emailAddressHash: string
  firstName: string
  lastName: string
  address: string
  authorAccountUsername: string
}

export interface MaevsiEvent {
  id: BigInt
  authorUsername: string
  description: string
  end: Date
  inviteeCountMaximum: number
  isArchived: boolean
  isInPerson: boolean
  isRemote: boolean
  location: string
  name: string
  slug: string
  start: Date
  visibility: ['public', 'private']
}

export interface MaevsiInvitation {
  id: BigInt
  uuid: string
  eventId: BigInt
  contactId: BigInt
  feedback: ['accepted', 'canceled']
  feedbackPaper: ['digital', 'none', 'paper']
}

export interface Mail {
  to: string
  subject: string
}

export interface MessageInvitation {
  invitationId: BigInt
}

export interface MailWithContent extends Mail {
  html?: string
  text?: string
  icalEvent?: Record<string, unknown>
}

export interface Template {
  language: string
  templateNamespace: string
  templateVariables: Record<string, unknown>
}

export interface MailTemplate extends Mail, Template {}
