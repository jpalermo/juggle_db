class Database
  class MissingKeyError < StandardError; end

  include Singleton
  DELAY = 0.1.seconds
  READ_TIMEOUT = DELAY * 2 + 1.seconds

  def self.start
    instance.start
  end

  def initialize
    @read_queues = Hash.new { |hash, key| hash[key] = [] }
    @key_versions = Hash.new { |hash, key| hash[key] = [0] }
    @deleted_keys = {}
    @send_history = {}
  end

  def start
    NATS.subscribe('db_loop') { |message| process_message(message) }
  end

  def save_message(message)
    message.sender = client_id
    NATS.publish('db_loop', message.to_json)
  end

  def update(message)
    message.version += 1
    save_message(message)
  end

  def read(key)
    message_queue = QueueWithTimeout.new
    @read_queues[key].push message_queue
    message_queue.pop_with_timeout(READ_TIMEOUT)
  rescue ThreadError
    raise MissingKeyError
  ensure
    @read_queues[key].delete(message_queue)
  end

  def delete(message)
    @deleted_keys[message.id] = true
    message.deleted = true
    update(message)
  end

  private

  def client_id
    @client_id ||= SecureRandom.uuid
  end

  def process_message(message_string)
    message = Message.from_string(message_string)
    return if message.sender == client_id

    if @deleted_keys[message.id]
      @key_versions.delete message.id
      return
    end

    return unless verify_interval(message)

    @send_history[message.id] = Time.now

    if message.deleted?
      @deleted_keys[message.id] = true
      return
    end

    return if @key_versions[message.id].max > message.version
    @key_versions[message.id] << message.version

    notify_readers(message)
    EM.add_timer DELAY, ->() { save_message(message) }
  end

  def notify_readers(message)
    @read_queues[message.key].each do |message_queue|
      message_queue << message
    end
  end

  def verify_interval(message)
    return true if @key_versions[message.id].max < message.version
    return false if @send_history[message.id].present? && Time.now - @send_history[message.id] < DELAY
    true
  end
end
# message = Message.new(key: 'test_key', body: 'is this safe?').save
# message = Message.find 'test_key'
