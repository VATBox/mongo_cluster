require_relative 'shell'
require_relative 'security'
require_relative '../helpers/json'

module MongoCluster
  module User

    def self.create_root
      result = Shell.eval("db.createUser(#{generate_root_user.to_json})")
      raise "Root user creation fail:\n #{result}" unless all.one?
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
          roles: [{role: "root", db: "admin"}]
      }
    end

  end
end