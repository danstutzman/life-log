require 'sqlite3'

db = SQLite3::Database.new('mySymptoms-2019-01-11.mhsd')

symptoms = []
sql = %q[
  SELECT
    zdatetime - zduration + (31 * 365 + 8) * 24 * 3600 AS started_at,
    zdatetime + (31 * 365 + 8) * 24 * 3600 AS ended_at,
    zreactioneventtype.zname,
    znotes
  FROM zreactionevent
  JOIN zreaction ON zreaction.zreactionevent = zreactionevent.z_pk
  JOIN zreactioneventtype
    ON zreaction.zreactioneventtype = zreactioneventtype.z_pk
  ORDER BY zdatetime;
]
db.execute(sql) do |row|
  symptoms.push({
    started_at: row[0],
    ended_at: row[1],
    name: row[2],
    notes: row[3]
  })
end

started_ats = symptoms.map { |symptom| symptom[:started_at] }
begin_date = Date.new(2019, 1, 1) # Time.at(started_ats.min).to_date
ended_ats = symptoms.map { |symptom| symptom[:ended_at] }
end_date = Time.at(ended_ats.max).to_date

LEFT_MARGIN = 100
DAY_WIDTH = 600
File.open('symptoms.html', 'w') do |file|
  file.puts '<html>'
  file.puts '<head>'
  file.puts '<style>'
  file.puts 'body { font-family: sans-serif; }'
  file.puts '.date { }'
  file.puts '.hour { position: absolute; height: 500px; width: 1px; background-color: #aaa; }'
  file.puts '.hour.bold { background-color: black; }'
  file.puts '.sleep { position: absolute; height: 10px; background-color: black; }'
  file.puts '</style>'
  file.puts '</head>'
  file.puts '<body>'

  25.times do |hour|
    left = LEFT_MARGIN + hour * DAY_WIDTH / 24
    bold = (hour % 4 == 0) ? 'bold' : ''
    file.puts "<div class='hour #{bold}' style='left: #{left}px'></div>"
  end

  begin_date.upto(end_date) do |date|
    file.puts "<div class='date'>#{date}"
    symptoms.each do |symptom|
      if symptom[:name] == 'Sleep Quality'
        if symptom[:started_at] >= date.to_time.to_i &&
           symptom[:started_at] < (date + 1).to_time.to_i
          left = LEFT_MARGIN +
            (symptom[:started_at] - date.to_time.to_i) * DAY_WIDTH / (3600 * 24)
          ended_at = [symptom[:ended_at], (date + 1).to_time.to_i].min
          width = (ended_at - symptom[:started_at]) * DAY_WIDTH / (3600 * 24)
          file.puts "<div class='sleep' style='left: #{left}px; width: #{width}px'></div>"
        end
      end
    end
    file.puts '</div>'
  end

  file.puts '</body>'
  file.puts '</html>'
end
