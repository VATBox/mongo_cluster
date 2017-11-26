
class UserRecord

  attr_reader :id
  attr_reader :queue

  def initialize
    @id = 0
    @queue = Queue.new
    queue.push(1)
  end

  def next
    one(next_id)
  end

  def one(id = @id += 1)
    {
        id: id,
        timestamp: Time.now.to_formatted_s(:db),
        first_name: first_name,
        last_name: last_name,
        drivers_license: random_string(12),
        address: random_address,
        phone: random_phone_number,
        weight: random_number(3),
        eye_color: random_color,
        hair_color: random_color,
        height: random_number(3),
        race: race,
        login_history: random_login_hash
    }
  end

  def many(range)
    range.times.map {one}
  end

  private

  def next_id
    queue
        .shift
        .tap {|id| queue.push(id + 1)}
  end

  def first_name
    ["Kevin", "Mitch", "Tyler", "Jay", "Erik", "Chad", "Philup", "Jane", "Jill", "Luke"].sample
  end

  def last_name
    ["Smith", "Jones", "Black", "White", "Rome", "Rodgers", "Skywalker", "Griffin", "Keys", "Doe"].sample
  end

  def race
    ["White", "African-American", "Asian", "Indian", "Native American", "Latino"].sample
  end

  def random_address
    random_number(5) + [" Main", " First", " Broadway", " Market", " Milton", " Pine"].sample + [" St", " Ln", " Pl", " Ct", "Blvd"].sample
  end

  def random_string(length)
    (0...length).map{ 65.+(rand(26)).chr }.join
  end

  def random_number(length)
    (0...length).map{ rand(9) }.join
  end

  def random_phone_number
    "#{random_number(3)}-#{random_number(3)}-#{random_number(4)}"
  end

  def random_color
    ["Blue", "Brown", "Green", "Red", "Black"].sample
  end

  def random_login_hash
    {:time_stamp => random_time, :ip => "#{random_number(3)}.#{random_number(3)}.#{random_number(3)}", :hostname => random_string(12), :idle_time => rand(300)}
  end

  def random_time
    Time.at(rand * Time.now.to_i)
  end

  def random_field
    info = random_personal_info
    info.delete(:login_history)
    info.keys.sample
  end

end