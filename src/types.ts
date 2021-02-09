export interface MaevsiContact {
  id: BigInt,
  accountUsername: string,
  emailAddress: string,
  emailAddressHash: string,
  firstName: string,
  lastName: string,
  address: string,
  authorAccountUsername: string,
}

export interface MaevsiEvent {
  id: BigInt,
  authorUsername: string,
  description: string,
  end: Date,
  inviteeCountMaximum: number,
  isArchived: boolean,
  isInPerson: boolean,
  isRemote: boolean,
  location: string,
  name: string,
  slug: string,
  start: Date,
  visibility: ['public', 'private'],
}

export interface MaevsiInvitation {
  id: BigInt,
  uuid: string,
  eventId: BigInt,
  contactId: BigInt,
  feedback: ['accepted', 'canceled'],
  feedbackPaper: ['digital', 'none', 'paper'],
}

export interface MessageInvitation {
  invitationId: BigInt,
}

export interface SendMailConfig {
  to: string,
  subject: string,
  html?: string,
  text?: string,
  icalEvent?: object
}
