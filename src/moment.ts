import moment from 'moment-timezone'

import { DateFormatOptions, DurationFormatOptions } from './types.js'

export function momentFormatDate(options: DateFormatOptions): string {
  moment.locale(options.language)
  return moment.utc(options.input).format(options.format)
}

export function momentFormatDuration(options: DurationFormatOptions): string {
  moment.locale(options.language)
  return moment
    .duration(moment(options.end).diff(moment(options.start)))
    .humanize()
}
