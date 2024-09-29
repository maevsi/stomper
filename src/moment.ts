import moment from 'moment-timezone'

import type { DateFormatOptions, DurationFormatOptions } from './types.ts'

export const momentFormatDate = (options: DateFormatOptions) => {
  moment.locale(options.language)
  return moment.utc(options.input).format(options.format)
}

export const momentFormatDuration = (options: DurationFormatOptions) => {
  moment.locale(options.language)
  return moment
    .duration(moment(options.end).diff(moment(options.start)))
    .humanize()
}
