#!/usr/bin/env ruby

require "groonga"

#command :subscribe
#command :unsubscribe
#command :scan

def subscribe(request)
  user, condition, query, route = parse_request(request)
  query_table = @context['Query']
  query_record = query_table[query]
  unless query_record
    keywords = pick_keywords([], condition)
    query_record = query_table.add(query, :keywords => keywords)
    # todo: update Thread.queries value of corresponding threads
  end
  user_table = @context['User']
  user_record = user_table[user]
  if user_record
    subscriptions = user_record.subscriptions.collect do |query|
      return if query == query_record
      query
    end
    subscriptions << query_record
    user_record.subscriptions = subscriptions
  else
    user_table.add(user,
                   :subscriptions => [query_record],
                   :route => route)
  end
end

def unsubscribe(request)
  user, condition, query, route = parse_request(request)
  query_table = @context['Query']
  query = query_table[query]
  return unless query
  user_table = @context['User']
  user_record = user_table[user]
  return unless user_record
  subscriptions = user_record.subscriptions.select do |q|
    q != query
  end
  user_record.subscriptions = subscriptions
  # todo: update Thread.queries value when subscribers no longer exist
end

def scan(request)
  table = request["table"]
  values = request["values"]
  raise "invalid values" unless values.is_a? Hash
  hits = []
  case table
  when "Thread"
    return if values["name"].nil? || values["name"].empty?
    scan_body(hits, values["name"])
    thread_table = @context['Thread']
    thread_record = thread_table[request["key"]]
    if thread_record
      thread_record.queries = hits
    else
      thread_table.add(request["key"],
                       :name => values["name"],
                       :queries => hits)
    end
  when "Comment"
    scan_thread(hits, values["thread"])
    scan_body(hits, values["body"])
  end
  publish(hits, request)
end

#private
def scan_thread(hits, thread)
  thread_table = @context['Thread']
  thread_record = thread_table[thread]
  return unless thread_record
  thread_record.queries.each do |query|
    hits << query
  end
end

def scan_body(hits, body)
  trimmed = body.strip
  candidates = {}
  @context['Keyword'].scan(trimmed).each do |keyword, word, start, length|
    @context['Query'].select do |query|
      query.keywords =~ keyword
    end.each do |record|
      candidates[record.key] ||= []
      candidates[record.key] << keyword
    end
  end
  candidates.each do |query, keywords|
    hits << query if query_match(query, keywords)
  end
end

def publish(hits, request)
  routes = {}
  hits.each do |query|
    @context['User'].select do |user|
      user.subscriptions =~ query
    end.each do |user|
      routes[user.route.key] ||= []
      routes[user.route.key] << user.key.key
    end
  end
  routes.each do |route, users|
    p [route, users, request]
  end
end

def query_match(query, keywords)
  return true unless EXACT_MATCH
  @conditions = {} unless @conditions
  condition = @conditions[query.id]
  unless condition
    condition = JSON.parse(query.key)
    @conditions[query.id] = condition
    # CAUTION: @conditions can be huge.
  end
  words = {}
  keywords.each do |keyword|
    words[keyword.key] = true
  end
  eval_condition(condition, words)
end

def eval_condition(condition, words)
  case condition
  when Hash
    # todo
  when String
    words[condition]
  when Array
    case condition.first
    when "||"
      condition[1..-1].each do |element|
        return true if eval_condition(element, words)
      end
      false
    when "&&"
      condition[1..-1].each do |element|
        return false unless eval_condition(element, words)
      end
      true
    when "-"
      return false unless eval_condition(condition[1], words)
      condition[2..-1].each do |element|
        return false if eval_condition(element, words)
      end
      true
    end
  end
end

def parse_request(request)
  user = request["user"]
  condition = request["condition"]
  route = request["route"]
  raise "invalid request" if user.nil? || user.empty? || condition.nil?
  query = condition.to_json
  raise "too long query" if query.size > 4095
  [user, condition, query, route]
end

def pick_keywords(memo, condition)
  case condition
  when Hash
    memo << condition["query"]
  when String
    memo << condition
  when Array
    condition[1..-1].each do |element|
      pick_keywords(memo, element)
    end
  end
  memo
end


########## main ##########

EXACT_MATCH = true

database, subscriptions, events = ARGV
@context = Groonga::Context.new
@context.open_database(database)

if File.exists?(subscriptions)
  open(subscriptions).each do |line|
    subscribe(JSON.parse(line))
  end
end

if File.exists?(events)
  open(events).each do |line|
    scan(JSON.parse(line))
  end
end
