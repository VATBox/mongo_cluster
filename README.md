# MongoCluster

DevOps tool to install Mongo Cluster on Amazon EC2 instances via CloudFormation

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mongo_cluster'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongo_cluster
    
##Requirements

### OS
[Amazon Linux AMI](https://aws.amazon.com/amazon-linux-ami/)

### Packages

      yum -y update
      yum install -y git
      yum install -y jq
      yum install -y xfsprogs
      yum --enablerepo=epel install node npm -y
      yum install -y mongodb-org
      yum install -y munin-node
      yum install -y libcgroup
      yum install -y mongo-10gen-server mongodb-org-shell
      yum install -y sysstat
      yum install -y datadog-agent
      yum install -y ruby23
      yum install -y ruby23-devel
      alternatives --set ruby /usr/bin/ruby2.3

### CloudFormation

##### AWS::KMS::Key

`To decrypt DataDog API, Mongo User and KeyFile`

##### AWS::EFS::FileSystem

`Elastic storage for generic action, backup and dumps`

##### AWS::S3::Bucket

`Bucket to store dump tars`

## Usage

### Install Mongo

    $ /usr/local/bin/install_mongo

##### Metadata on PrimaryInstance

      Configuration:
        storage:
          data:
            path: !FindInMap [storage, data, path]
            device: !FindInMap [storage, data, device]
          journal:
            path: !FindInMap [storage, journal, path]
            device: !FindInMap [storage, journal, device]
          log:
            path: !FindInMap [storage, log, path]
            device: !FindInMap [storage, log, device]
        security:
          username: !GetAtt EncryptedUsername.CipherText
          password: !GetAtt EncryptedPassword.CipherText
          authorization: !Ref Authorization
          keyFile:
            path: /mongo_auth/mongodb.key
            value: !GetAtt EncryptedKeyFile.CipherText
        replication:
          name: !Ref ReplicaSetName
          port: !Ref Port
          size: !Ref Size

* Name tag each volume $instance_name/$path (MongoCluster-PrimaryInstance/data).
* Set [ulimits](https://docs.mongodb.com/manual/reference/ulimit/) and [udev for WiredTiger](https://docs.mongodb.com/manual/administration/production-notes/)
* Build xfs filesystem on each device, skip if already xfs.
* Create storage mounts for log, journal, data and efs based on metadata.
* Decrypt KeyFile resource with KMS to `/mongo_auth/mongodb.key`.
* Define Mongo Configuration to `/etc/mongod.conf` based on metadata.
* Set the Mongo Service to boot at startup.
    
### Install Monitor

    $ /usr/local/bin/install_monitor
    
##### Metadata on PrimaryInstance

      Configuration:
        monitor:
          api_key: !If [Monitor, !GetAtt EncryptedDataDogApiKey.CipherText, !Ref DataDogApiKey]
          
* Define DataDog Configuration to `/etc/dd-agent/datadog.conf`.
* Integrate Mongo statistics to DataDog via Configuration in `/etc/dd-agent/conf.d/mongo.yaml`

### Install Backup Scheduler

    $ /usr/local/bin/install_backup_scheduler
    $ /usr/local/bin/backup_scheduler start|stop|status|restart

##### Metadata on PrimaryInstance

      Configuration:
        backup:
          enabled: !Ref Backup
          snapshot_interval: !Ref SnapshotInterval
          retention_expiration:
            minutely: !Ref MinutelyExpriation
            hourly: !Ref HourlyExpiration
            daily: !Ref DailyExpiration
            
* Backup retention policy (expiration in x days) based on metadata.
* Create backup daemon to schedule snapshot, dump and clean up jobs.

## Define ReplicaSet

    $ /usr/local/bin/define_replica_set

##### Metadata on each ReplicaInstance

      ReplicaMember:
        id: 1
        host: !Sub
          - ${Host}:${Port}
          - {Host: !GetAtt PrimaryNetworkInterface.PrimaryPrivateIpAddress, Port: !Ref Port}
        hidden: false
        priority: 10
        votes: 1
      
* Should run only on the Primary instance.
* Wait to all CloudFormation's instances to complete creation.
* Initiate ReplicaSet based on all instances metadata
* Create root and monitor users.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mongo_cluster. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MongoCluster project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/mongo_cluster/blob/master/CODE_OF_CONDUCT.md).
