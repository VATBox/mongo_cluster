require_relative 'shell'
require_relative 'security'
require_relative '../data_dog'
require_relative '../helpers/json'

module MongoCluster
  module User

    def self.create_root
      drop_user('admin')
      create_user(generate_root_user)
    end

    def self.create_data_dog
      drop_user('datadog')
      create_user(generate_data_dog_user) unless DataDog.api_key.blank?
    end

    def self.create_user(user_hash)
      Shell.eval("db.createUser(#{user_hash.to_json})")
    end

    def self.drop_user(user_name)
      Shell.eval("db.dropUser(#{user_name.to_json})")
    end

    def self.all
      users = Shell.eval("JSON.stringify(db.getUsers())")
      JSON.parse_with_cast(users)
    end

    private

    def self.generate_root_user
      {
          user: Security.settings.username,
          pwd: Security.settings.password,
          roles: [{role: 'root', db: 'admin'}]
      }
    end

    def self.generate_data_dog_user
      {
          user: 'datadog',
          pwd: DataDog.api_key,
          roles: [
              {role: 'read', db: 'admin' },
              {role: 'clusterMonitor', db: 'admin'},
              {role: 'read', db: 'local'}
          ]
      }
    end

  end
end