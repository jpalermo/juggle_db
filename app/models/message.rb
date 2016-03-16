class Message
  attr_reader :key
  attr_accessor :sender, :version, :body, :deleted, :id
  alias_method :deleted?, :deleted

  def self.from_string(string)
    json = JSON.parse(string)
    new(**json.symbolize_keys)
  end

  def self.find(key)
    Database.instance.read(key)
  end

  def initialize(key:, body:, sender: nil, version: nil, deleted: nil, id: nil)
    @key = key
    @body = body
    @sender = sender
    @version = version
    @deleted = deleted
    @id = id
  end

  def id
    @id ||= SecureRandom.uuid
  end

  def body=(body)
    @dirty = true
    @body = body
  end

  def version
    @version ||= 1
  end

  def to_hash
    {
      key: key,
      body: body,
      sender: sender,
      version: version,
      deleted: deleted,
      id: id
    }
  end

  def save
    if @dirty
      Database.instance.update(self)
    else
      Database.instance.save_message(self)
    end
    self
  end

  def delete
    Database.instance.delete(self)
  end

  def to_s
    "Key: #{key}\nBody: #{body}"
  end
end
