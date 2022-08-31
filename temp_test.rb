require "tzinfo"
puts(TZInfo::Timezone.get("CET").now)

require "date"
puts(Time.now.getlocal)
