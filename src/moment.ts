import moment from 'moment-timezone'

import { DateFormatOptions } from './types'

export function dateFormat(options: DateFormatOptions): string {
  moment.locale(options.language)
  return moment.utc(options.input).format(options.format)
}
