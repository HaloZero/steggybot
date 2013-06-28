require 'cinch'

class WhoAreThesePeople
  include Cinch::Plugin

  listen_to :channel
  match /addwho ([\w-]+) (.+)/i, method: :add
  match /removewho ([\w-]+)/i, method: :remove
  match /addwhere ([\w-]+) (.+)/i, method: :add_where
  match /removewhere ([\w-]+)/i, method: :remove_where

  def initialize(*args)
    super
    @identities = config[:identities]
  end

  def add(m, username, real_name)
    # add it to the list
    existing_ids = get_identities || {}

    if existing_ids[username.downcase] && (existing_ids[username.downcase][:added_by] == username.downcase)
      if m.user.nick.downcase == username.downcase
        existing_information = existing_ids[username.downcase]
        existing_information[:name] = real_name
        existing_information[:updated_at] = DateTime.now
        existing_ids[username.downcase] = existing_information
      else
        m.reply "#{m.user.nick}: Can't override a user's self-definition."
        return
      end
    else
      existing_ids[username.downcase] = {:name => real_name, :added_by => m.user.nick.downcase, :updated_at => DateTime.now}
    end

    update_identities(existing_ids)

    m.reply "#{m.user.nick}: #{username} successfully added as '#{real_name}'."
  end

  def remove(m, username)
    existing_ids = get_identities || {}

    unless existing_ids[username]
      m.reply "#{m.user.nick}: #{username} not in identities list."
      return
    end

    if m.user.nick.downcase == username.downcase
      existing_ids.delete(username)

      update_identities(existing_ids)

      m.reply "#{m.user.nick}: #{username} removed from identities list."
    else
      m.reply "#{m.user.nick}: Only the identity creator or subject can remove an identity from the list."
    end
  end

  def add_where(m, username, location)
    existing_ids = get_identities || {}

    if existing_ids[username.downcase] && existing_ids[username.downcase][:added_by] == username.downcase
      if m.user.nick.downcase == username.downcase
        existing_information = existing_ids[username.downcase]
        existing_information[:location] = location
        existing_information[:updated_at] = DateTime.now
        existing_ids[username.downcase] = existing_information
      else
        m.reply "#{m.user.nick}: Can't override a user's location."
        return
      end
    else
      m.reply "#{m.user.nick}: #{username} not in identities list."
      return
    end

    update_identities(existing_ids)

    m.reply "#{m.user.nick}: #{username} location has been set to '#{location}'."
  end

  def remove_where(m, username)
    existing_ids = get_identities || {}

    unless existing_ids[username]
      m.reply "#{m.user.nick}: #{username} not in identities list."
      return
    end

    if m.user.nick.downcase == username.downcase
      existing_information = existing_ids[username.downcase]
      existing_information[:location] = nil
      existing_information[:updated_at] = DateTime.now
      existing_ids[username.downcase] = existing_information

      update_identities(existing_ids)

      m.reply "#{m.user.nick}: #{username}'s location has been removed from identities"
    else
      m.reply "#{m.user.nick}: Only the identity creator or subject can remove his location from the list"
    end
  end

  def listen(m)
    who_match = /who *is (\w+)/i.match(m.message)
    if who_match
      user = who_match[1]
      if get_identities && get_identities[user.downcase]
        m.reply "#{m.user.nick}: #{user} is #{get_identities[user.downcase][:name]}"
      end
    end

    where_match = /where *is (\w+)/i.match(m.message)
    if where_match
      user = where_match[1]
      if get_identities && get_identities[user.downcase]
        location = get_identities[user.downcase][:location]
        if location
          m.reply "#{m.user.nick}: #{user} is now at #{get_identities[user.downcase][:location]}"
        else
          m.reply "#{m.user.nick}: No clue where #{user.downcase} is, ask?"
        end
      end
    end
  end

  protected

  def get_identities
    output = File.new(@identities, 'r')
    ids = YAML.load(output.read)
    output.close

    ids
  end

  def update_identities(existing_ids)
    # write it to the file
    output = File.new(@identities, 'w')
    output.puts YAML.dump(existing_ids)
    output.close
  end

end
