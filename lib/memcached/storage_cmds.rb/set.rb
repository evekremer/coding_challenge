class Memcached::StorageCommand::SetCommand < Memcached::StorageCommand
    def initialize(command_name, command_split, connection)
        super(command_name, command_split, connection)
        store_new_item
    end
end