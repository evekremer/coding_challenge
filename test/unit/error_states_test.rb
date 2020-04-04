require_relative "../test_helper"

class ErrorStatesTest < BaseTest
    
    ####### Invalid command termination and types
    
    def test_bad_termination_get
        socket.puts "get #{key}"
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end

    def test_bad_termination_set
        socket.puts "set #{key} 5 5000 6"
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end

    def test_numeric_command
        socket.puts 111111
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end

    def test_nil_command
        socket.puts nil
        reply = ""
        2.times { reply += socket.gets }
        assert_equal "CLIENT_ERROR Commands must be terminated by '\r\n'\r\n", reply
    end
    
    ####### Key and value that exceed max length

    def test_key_too_long
        key = "k" * (MAX_KEY_LENGTH + 1)

        send_storage_cmd("set", key, 4, 6230, value.length(), false, value, false)
        assert_equal "CLIENT_ERROR <key> has more than #{MAX_KEY_LENGTH} characters\r\n", socket.gets

        socket.puts "get #{key}\r\n"
        assert_equal "CLIENT_ERROR <key> has more than #{MAX_KEY_LENGTH} characters\r\n", socket.gets
    end

    def test_value_too_long
        value = "v" * (MAX_VALUE_LENGTH + 1)

        send_storage_cmd("set", key, 4, 6230, value.length(), false, value, false)
        assert_equal "CLIENT_ERROR <value> has more than #{MAX_VALUE_LENGTH} characters\r\n", socket.gets
        
        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    # # ####### Invalid command name

    def test_invalid_command_name_1
        send_storage_cmd("invalid_cmd_name", key, 8, 0, value.length(), false, value, false)
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
        socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_invalid_command_name_2
        send_storage_cmd("se", key, 8, 0, value.length(), false, value, false)
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
        socket.gets
    
        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_invalid_command_name_3
        send_storage_cmd("sett", key, 8, 0, value.length(), false, value, false)
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
        socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_invalid_command_name_3
        send_storage_cmd(" ", key, 8, 0, value.length(), false, value, false)
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
        socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    # Case sensitive command name

    def test_case_sensitive_set
        send_storage_cmd("SET", key, 5, 50000, 0, false, nil, false)
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
        socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end
    
    def test_case_sensitive_add
        send_storage_cmd("ADD", key, 5, 50000, 0, false, nil, false)
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
        socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end
    
    def test_case_sensitive_replace
        send_storage_cmd("REPLACE", key, 5, 50000, 0, false, nil, false)
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
        socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_case_sensitive_prepend
        send_storage_cmd("PREPEND", key, 5, 50000, 0, false, nil, false)
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
        socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_case_sensitive_append
        send_storage_cmd("APPEND", key, 5, 50000, 0, false, nil, false)
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
        socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end
    
    def test_case_sensitive_cas
        send_storage_cmd("CAS", key, 5, 50000, 0, 1, nil, false)
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
        socket.gets

        reply = send_get_cmd(key)
        assert_equal END_MSG, reply
    end

    def test_case_sensitive_get
        socket.puts "GET #{key}\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
    end

    def test_case_sensitive_gets
        socket.puts "GETS #{key}\r\n"
        assert_equal INVALID_COMMAND_NAME_MSG, socket.gets
    end
end